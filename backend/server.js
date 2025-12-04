// ======================================================================
// 1. IMPORTS & CONFIGURATION
// ======================================================================
require("dotenv").config();
const express = require("express");
const fs = require('fs');
const path = require('path');
const cors = require('cors');
const bodyParser = require('body-parser');
const multer = require('multer');
const axios = require('axios');
const jwt = require('jsonwebtoken');
const FormData = require('form-data');
const { exec, spawn } = require('child_process');
const { GoogleGenerativeAI } = require('@google/generative-ai');

// --- Database & Config ---
const connectDB = require('./config/db');

// --- Middleware ---
const { protect } = require("./middleware/authMiddleware.js");

// --- Models ---
const User = require("./models/User");
const UserDetails = require("./models/userDetails"); // Replaced duplicate 'calorieGoal'
const FoodLog = require("./models/foodLog");
const WaterLog = require("./models/waterLog");
const PendingUser = require('./models/pendingUser.js');

// --- Routes ---
const authRoutes = require('./routes/authRoutes');
const userRoutes = require('./routes/userRoutes');
const userDetailsRoutes = require('./routes/userDetailsRoutes');
const activityRoutes = require('./routes/activityRoutes');
const rewardRoutes = require('./routes/rewardRoutes');
const foodLogRoutes = require('./routes/foodLogRoutes');
const progressRoutes = require('./routes/progressRoutes.js');
const webRoutes = require('./routes/webRoutes.js');
const complaintRoutes = require('./routes/complaintRoutes.js');
const mealPlanRoutes = require("./routes/mealPlanRoutes.js");

// --- App Initialization ---
const app = express();
const PORT = process.env.PORT || 5000;
const ai = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

// --- Cloudinary Configuration ---
const { v2: cloudinary } = require('cloudinary');

cloudinary.config({ 
    cloud_name: 'dztldh7o2', 
    api_key: '977541723819117', 
    // ⚠️ IMPORTANT: Use process.env for the secret in production!
    api_secret: process.env.CLOUDINARY_API_SECRET || '<your_api_secret>' 
});

// connect to Database
connectDB();

// ======================================================================
// 2. MIDDLEWARE & UPLOAD CONFIG
// ======================================================================

// --- Multer Configuration ---
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    if (!fs.existsSync("uploads")) {
      fs.mkdirSync("uploads");
    }
    cb(null, "uploads/");
  },
  filename: (req, file, cb) => {
    cb(null, `${Date.now()}-${file.originalname}`);
  },
});

const upload = multer({
  storage: storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB limit
});

// --- Enhanced Logging ---
app.use((req, res, next) => {
  console.log(`\n➡️  Request Received: ${req.method} ${req.originalUrl}`);
  console.log(`   Host: ${req.hostname}`);
  next();
});

// --- Standard Middleware ---
app.use(bodyParser.json());
app.use(cors());
app.use("/uploads", express.static(path.join(__dirname, "uploads")));

// ======================================================================
// 3. ROUTES API
// ======================================================================

app.use("/api/auth", authRoutes);
app.use("/api/users", userRoutes);
app.use("/api/user-details", userDetailsRoutes);
app.use("/api/activities", activityRoutes);
app.use("/api/mealplan", mealPlanRoutes);
app.use("/api/foodlog", foodLogRoutes);
app.use("/api/rewards", rewardRoutes);
app.use("/api/progress", progressRoutes);
app.use("/api/web", webRoutes);
app.use("/api/complaints", complaintRoutes);

// ======================================================================
// 4. CUSTOM ENDPOINTS
// ======================================================================


// --- AI Content Generation (Real-Time Database Data) ---
app.post("/api/predict", protect, upload.single("image"), async (req, res) => {
  if (!req.file) {
    return res.status(400).json({ success: false, message: "No image uploaded" });
  }

  const localFilePath = path.resolve(req.file.path);
  let cloudinaryUrl = "";

  // Set headers for streaming response
  res.setHeader('Content-Type', 'application/x-ndjson');
  res.setHeader('Transfer-Encoding', 'chunked');

  try {
    // 2. Upload to Cloudinary
    console.log("☁️ Uploading to Cloudinary...");
    
    // We run User Context fetch and Cloudinary Upload in parallel to save time
    const [userDetails, uploadResult] = await Promise.all([
       UserDetails.findOne({ user: req.userId }).lean(),
       cloudinary.uploader.upload(localFilePath, {
          folder: "nutriwise_food_logs", // Optional: organize folders
          public_id: `user_${req.userId}_${Date.now()}`, // Unique ID
          transformation: [
             { width: 800, crop: "limit" }, // Optional: Resize to save bandwidth
             { quality: "auto" }
          ]
       })
    ]);

    cloudinaryUrl = uploadResult.secure_url;
    console.log(`✅ Uploaded to Cloudinary: ${cloudinaryUrl}`);

    // 3. Send the Cloudinary URL to Frontend IMMEDIATELY
    const imageResponse = JSON.stringify({ 
        type: "uploaded_image", 
        url: cloudinaryUrl 
    });
    res.write(imageResponse + "\n");

    // --- Prepare User Context for Python ---
    let healthConditions = "{}";
    let remainingCalories = "2000";

    if (userDetails) {
      healthConditions = JSON.stringify(userDetails.healthConcerns || {});
      const todayStart = new Date();
      todayStart.setHours(0, 0, 0, 0);
      const todayLogs = await FoodLog.find({ user: req.userId, date: { $gte: todayStart } });
      const consumed = todayLogs.reduce((sum, item) => sum + (item.nutrients?.calories || 0), 0);
      const goal = userDetails.caloriesGoal || 2000;
      remainingCalories = String(Math.max(0, goal - consumed));
    }

    // 4. Run Python Script
    // Note: We use 'localFilePath' here because it's faster for Python to read 
    // from disk than downloading the Cloudinary URL.
    const scriptPath = path.join(__dirname, "predict.py");
    console.log(`🚀 Spawning python: ${scriptPath} ${localFilePath}`);
    
    const pythonProcess = spawn('python', [scriptPath, localFilePath, healthConditions, remainingCalories]);

    pythonProcess.stdout.on('data', (data) => {
      console.log(`📤 Stream chunk: ${data}`);
      res.write(data);
    });

    pythonProcess.stderr.on('data', (data) => {
      console.error(`⚠️ Python stderr: ${data}`);
    });

    pythonProcess.on('close', (code) => {
      console.log(`🏁 Python process exited with code ${code}`);
      
      // 5. Cleanup Local File
      // Since the image is safe in Cloudinary, we can delete the local temp file
      fs.unlink(localFilePath, (err) => {
        if (err) console.error("Error deleting temp file:", err);
        else console.log("🧹 Local temp file cleaned up");
      });
      
      res.end();
    });

  } catch (error) {
    console.error("❌ Error in process:", error);
    // If upload fails, we should still try to close the connection gracefully-ish
    // or send an error chunk if the stream is open.
    res.write(JSON.stringify({ type: "error", message: "Image processing failed" }) + "\n");
    res.end();
  }
});

// --- Nutrition Data Analysis (AI) ---
const nutritionSchema = {
  type: "object",
  properties: {
    food_name: { type: "string" },
    category: { type: "string" },
    calories: { type: "string" },
    protein: { type: "string" },
    carbs: { type: "string" },
    fat: { type: "string" },
    fiber: { type: "string" },
    sugar: { type: "string" },
    sodium: { type: "string" },
    cholesterol: { type: "string" },
    enoughData: { type: "boolean" },
  },
  required: ["food_name", "calories", "protein", "carbs", "fat", "enoughData"],
};

app.post("/api/get-nutrition-data", async (req, res) => {
  const { name, description } = req.body;

  if (!name || !description) {
    return res.status(400).json({ error: "Missing 'name' or 'description' in request body." });
  }

  const systemInstruction = `
    You are an expert Nutritional Analyst AI.
    Analyze the provided meal's name and description and generate a structured JSON object.
    Include all nutrients with correct units (e.g., "15 grams", "250 kcal").
    Be sure to include calories.
    Also include a boolean field "enoughData": true if the provided data is sufficient to predict the nutrition accurately, otherwise false.
  `;

  const nutritionQuery = `Food Name: ${name}\nDescription: ${description}`;
  console.log("Analyzing Food:", name);

  try {
    const model = ai.getGenerativeModel({
      model: "gemini-2.0-flash", // Ensure you have access to this model version
      systemInstruction,
    });

    const generationConfig = {
      responseMimeType: "application/json",
      responseSchema: nutritionSchema,
    };

    const result = await model.generateContent({
      contents: [{ role: "user", parts: [{ text: nutritionQuery }] }],
      generationConfig,
    });

    const responseText = result.response?.text();
    if (!responseText) throw new Error("Empty AI response");

    const nutritionData = JSON.parse(responseText);
    console.log("AI Response (Parsed):", nutritionData);
    res.json(nutritionData);
  } catch (error) {
    console.error("Error analyzing meal with AI:", error);
    res.status(500).json({
      error: "AI request failed to generate structured nutrition data.",
      details: error.message || "Unknown API error",
    });
  }
});

// --- User Profile Summary ---
app.get("/api/user/profile-summary", protect, async (req, res) => {
  const userId = req.userId;
  console.log(`➡️  Request Received: GET /api/user/profile-summary for User ID: ${userId}`);

  try {
    const USER = await User.findOne({ _id: userId }).select("email");
    const user = await UserDetails.findOne({ user: userId })
      .select("userName caloriesGoal currentWeight targetWeight height waterGoal healthConcerns startWeight")
      .lean();

    if (!user) {
      return res.status(404).json({ success: false, message: "User profile not found." });
    }

    // Fetch Today's Water
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const waterLog = await WaterLog.findOne({ user: userId, date: today });
    const currentWater = waterLog ? waterLog.amount : 0;
    const caloriesGoal = user.caloriesGoal || 2000;

    res.status(200).json({
      notification: true,
      email: USER.email,
      healthConditions: user.healthConcerns,
      success: true,
      userName: user.userName,
      caloriesConsumed: 2000, // TODO: Aggregate from FoodLog
      caloriesGoal: caloriesGoal,
      currentWeight: user.currentWeight,
      targetWeight: user.targetWeight,
      startWeight: user.startWeight,
      height: user.height,
      carbs: 9,
      protein: 9,
      fat: 9,
      steps: 3000,
      waterGoal: user.waterGoal ?? 2000,
      waterConsumed: currentWater,
      stepGoal: 10000,
    });
  } catch (err) {
    console.error(`   ❌ Error fetching profile summary: ${err.message}`);
    res.status(500).json({ success: false, message: "Failed to fetch user profile summary." });
  }
});

// ======================================================================
// 5. PYTHON INTEGRATION ENDPOINTS
// ======================================================================

// --- Prediction (Spawns Python) ---
app.post("/api/predict", protect, upload.single("image"), async (req, res) => {
  if (!req.file) {
    return res.status(400).json({ success: false, message: "No image uploaded" });
  }

  // Fetch User Context
  let healthConditions = "{}";
  let remainingCalories = "2000";

  try {
    const userDetails = await UserDetails.findOne({ user: req.userId }).lean();
    if (userDetails) {
      healthConditions = JSON.stringify(userDetails.healthConcerns || {});
      
      const todayStart = new Date();
      todayStart.setHours(0, 0, 0, 0);
      const todayLogs = await FoodLog.find({ user: req.userId, date: { $gte: todayStart } });
      const consumed = todayLogs.reduce((sum, item) => sum + (item.nutrients?.calories || 0), 0);
      const goal = userDetails.caloriesGoal || 2000;
      remainingCalories = String(Math.max(0, goal - consumed));
      
      console.log(`ℹ️ User Context - Remaining Cal: ${remainingCalories}, Health: ${healthConditions}`);
    }
  } catch (err) {
    console.error("⚠️ Error fetching user context for prediction:", err);
  }

  const imagePath = path.resolve(req.file.path);
  const scriptPath = path.join(__dirname, "predict.py");

  console.log(`🚀 Spawning python: ${scriptPath} ${imagePath}`);
  const pythonProcess = spawn('python', [scriptPath, imagePath, healthConditions, remainingCalories]);

  res.setHeader('Content-Type', 'application/x-ndjson');
  res.setHeader('Transfer-Encoding', 'chunked');

  pythonProcess.stdout.on('data', (data) => {
    console.log(`📤 Stream chunk: ${data}`);
    res.write(data);
  });

  pythonProcess.stderr.on('data', (data) => {
    console.error(`⚠️ Python stderr: ${data}`);
  });

  pythonProcess.on('close', (code) => {
    console.log(`🏁 Python process exited with code ${code}`);
    fs.unlink(imagePath, (err) => {
      if (err) console.error("Error deleting temp file:", err);
    });
    res.end();
  });
});

// --- Ingredient Detection ---
app.post("/api/detect-ingredients", upload.single("image"), (req, res) => {
  if (!req.file) return res.status(400).json({ success: false, message: "No image uploaded." });

  const imagePath = path.resolve(req.file.path);
  const pythonScriptPath = path.join(__dirname, "recipe_gernate.py");

  if (!fs.existsSync(pythonScriptPath)) {
    fs.unlinkSync(imagePath);
    return res.status(500).json({ success: false, message: "Server configuration error: Processing script not found." });
  }

  exec(`python "${pythonScriptPath}" "${imagePath}"`, { timeout: 30000 }, (error, stdout, stderr) => {
    if (error) {
      console.error("Python script execution failed:", error);
      if (error.code === "ETIMEDOUT") return res.status(408).json({ success: false, message: "Processing timeout." });
      return res.status(500).json({ success: false, message: "Failed to process image." });
    }

    if (stderr) console.warn("Python script stderr:", stderr);

    try {
      if (!stdout || stdout.trim() === "") throw new Error("No output received");
      const detectionResult = JSON.parse(stdout);
      
      if (detectionResult.error) {
        return res.status(500).json({ success: false, message: `Ingredient detection error: ${detectionResult.error}` });
      }

      console.log("Successfully detected ingredients.");
      res.status(200).header("Content-Type", "application/json").send(stdout);
    } catch (parseError) {
      console.error("Failed to parse detection result:", parseError);
      return res.status(500).json({ success: false, message: "Failed to process detection results." });
    }
  });
});

// --- Product Lookup ---
app.post("/api/food/products", protect, async (req, res) => {
  const { productName } = req.body;
  const userId = req.userId;

  console.log(`🔍 [DEBUG] /api/food/products called for: ${productName}`);

  if (!productName) {
    return res.status(400).json({ success: false, message: "Product name is required for lookup." });
  }

  try {
    const userDetails = await UserDetails.findOne({ user: userId });
    
    const userProfileData = {
      conditions: userDetails?.healthConcerns || {},
      restrictions: userDetails?.restrictions || {},
      calorie_limit_kcal_100g: userDetails?.options?.maxCalories || 500,
      input_name: productName,
    };

    const pythonScriptPath = path.join(__dirname, "food_lookup.py");
    const tempInputPath = path.join(__dirname, `temp_input_${Date.now()}.json`);

    fs.writeFileSync(tempInputPath, JSON.stringify(userProfileData));
    const command = `python "${pythonScriptPath}" "${tempInputPath}"`;

    console.log(`🚀 [PYTHON] Starting Python execution...`);
    exec(command, { maxBuffer: 1024 * 1024 * 5 }, (error, stdout, stderr) => {
      
      // Clean up temp file
      if (fs.existsSync(tempInputPath)) {
        fs.unlink(tempInputPath, () => {});
      }

      if (stderr) console.warn(`⚠️ [PYTHON WARNINGS]: ${stderr}`);
      if (error) {
        console.error(`❌ [PYTHON ERROR]:`, error);
        return res.status(500).json({ success: false, message: "Script execution failed" });
      }

      try {
        if (!stdout || stdout.trim() === "") throw new Error("Empty output");
        
        const pythonOutput = JSON.parse(stdout);
        
        const mappedProducts = (pythonOutput.products || []).map((p) => ({
          product_name: p.name,
          brands: p.brand,
          image_url: p.image_url,
          nutrients: p.nutrients,
        }));

        console.log(`📤 [RESPONSE] Sending ${mappedProducts.length} products`);
        res.status(200).json({ success: true, products: mappedProducts });
      } catch (parseError) {
        console.error(`❌ [PARSE ERROR]: ${parseError.message}`);
        res.status(500).json({ success: false, message: "Invalid response from script.", rawOutput: stdout.substring(0, 500) });
      }
    });

  } catch (error) {
    console.error("❌ [ROUTE ERROR] /api/food/products failed:", error);
    res.status(500).json({ success: false, message: "Internal server error." });
  }
});

// --- Upload & Scan Product ---
app.post("/upload", upload.single("image"), protect, async (req, res) => {
  console.log(`⚙️  Processing: /upload (Scanner) for User ${req.userId}.`);

  if (!req.file) return res.status(400).json({ success: false, message: "No image uploaded." });

  const imagePath = path.resolve(req.file.path);
  const pythonScriptPath = path.join(__dirname, "extract_product.py");
  let tempInputPath;

  try {
    const userDetails = await UserDetails.findOne({ user: req.userId }).select("healthConcerns restrictions").lean();
    const userProfileData = {
      image_path: imagePath,
      user_id: req.userId,
      conditions: userDetails?.healthConcerns || {},
      restrictions: userDetails?.restrictions || {},
    };

    tempInputPath = path.join(__dirname, `temp_scan_input_${Date.now()}.json`);
    fs.writeFileSync(tempInputPath, JSON.stringify(userProfileData));

    const command = `python "${pythonScriptPath}" "${tempInputPath}"`;
    
    exec(command, { timeout: 150000 }, (error, stdout, stderr) => {
      // Cleanup
      fs.unlink(imagePath, () => {});
      if (tempInputPath && fs.existsSync(tempInputPath)) fs.unlink(tempInputPath, () => {});

      if (error) {
        console.error("❌ /upload: Python error:", error);
        return res.status(error.code === "ETIMEDOUT" ? 408 : 500).json({ 
          success: false, 
          message: error.code === "ETIMEDOUT" ? "Processing timeout." : "Failed to process image." 
        });
      }

      if (stderr) console.warn("⚠️ /upload stderr:", stderr.substring(0, 100));

      try {
        if (!stdout || stdout.trim() === "") throw new Error("No output");
        const detectionResult = JSON.parse(stdout);

        if (detectionResult.error) {
          return res.status(500).json({ success: false, message: `Scanner error: ${detectionResult.error}` });
        }

        console.log("🎉 Scan successful.");
        res.status(200).json(detectionResult);
      } catch (parseError) {
        res.status(500).json({ success: false, message: "Invalid response from image processing." });
      }
    });
  } catch (dbError) {
    console.error("❌ /upload: DB Error:", dbError);
    if (req.file && fs.existsSync(imagePath)) fs.unlink(imagePath, () => {});
    res.status(500).json({ success: false, message: "Internal server error." });
  }
});

// --- Internal: Fetch User Conditions (For Python Script) ---
app.get("/api/user-details/conditions/:userId", async (req, res) => {
  const { userId } = req.params;
  try {
    const userDetails = await UserDetails.findOne({ user: userId }).select("healthConcerns restrictions").lean();
    if (!userDetails) return res.status(404).json({ success: false, message: "User details not found." });

    res.status(200).json({
      success: true,
      conditions: userDetails.healthConcerns || {},
      preferences: userDetails.restrictions || {},
    });
  } catch (err) {
    res.status(500).json({ success: false, message: "Failed to fetch user data." });
  }
});

// --- Profile Data (Conditions, Prefs, Styles) ---
app.get("/api/user-details/my-profile", protect, async (req, res) => {
  try {
    const userDetails = await UserDetails.findOne({ user: req.userId })
      .select("healthConcerns restrictions eatingStyles selectedSubGoals selectedHabits")
      .lean();

    if (!userDetails) return res.status(404).json({ success: false, message: "Profile not found." });

    res.status(200).json({
      success: true,
      healthConcerns: userDetails.healthConcerns || {},
      restrictions: userDetails.restrictions || {},
      eatingStyles: userDetails.eatingStyles || {},
      subGoals: userDetails.selectedSubGoals || [],
      habits: userDetails.selectedHabits || [],
    });
  } catch (err) {
    res.status(500).json({ success: false, message: "Failed to fetch user profile." });
  }
});

// --- Search Factory Products (OpenFoodFacts) ---
app.get("/api/search_factory_products", async (req, res) => {
  const { query } = req.query;

  if (!query || query.trim().length === 0) {
    return res.status(400).json({ success: false, message: "Search query is required." });
  }

  const offUrl = `https://world.openfoodfacts.org/cgi/search.pl`;

  try {
    const response = await axios.get(offUrl, {
      params: {
        search_terms: query,
        search_simple: 1,
        action: "process",
        json: 1,
        fields: "product_name,brands,nutriments,image_url",
        page_size: 30,
      },
      headers: { "User-Agent": "CravingsSearchApp - NodeServer - v1.0" },
      timeout: 100000,
    });

    const factoryProducts = (response.data.products || [])
      .map((product) => ({
        name: product.product_name,
        brand: product.brands,
        nutrients: product.nutriments,
        image_url: product.image_url,
      }))
      .filter((p) => p.name && p.brand && p.image_url);

    res.status(200).json({ success: true, products: factoryProducts });
  } catch (error) {
    const status = error.code === "ECONNABORTED" || error.response?.status === 408 ? 504 : 500;
    res.status(status).json({ success: false, error: "Failed to retrieve factory products." });
  }
});

// ======================================================================
// 6. ERROR HANDLER & STARTUP
// ======================================================================

app.use((err, req, res, next) => {
  console.error(`\n🔥 Global Error Handler: ${err.stack}`);
  res.status(500).json({
    success: false,
    message: "Internal server error",
    error: err.message,
  });
});

app.listen(PORT, "0.0.0.0", () => {
  console.log(`\n=================================================`);
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`=================================================`);
});