const express = require("express");
const bodyParser = require("body-parser");
const cors = require("cors");
const multer = require("multer");
const path = require("path");
const { exec } = require("child_process");
const connectDB = require("./config/db");
const fs = require("fs");
const jwt = require("jsonwebtoken");
const axios = require("axios");
const FormData = require("form-data");
require("dotenv").config();
const { GoogleGenerativeAI } = require("@google/generative-ai");

// --- Import Models ---
const User = require("./models/User");
const UserDetails = require("./models/userDetails");
const PendingUser = require("./models/pendingUser.js");
const WaterLog = require("./models/waterLog"); 

// --- Import Routes ---
const userRoutes = require("./routes/userRoutes");
const authRoutes = require("./routes/authRoutes");
const userDetailsRoutes = require("./routes/userDetailsRoutes");
const activityRoutes = require("./routes/activityRoutes");
const rewardRoutes = require("./routes/rewardRoutes");
const foodLogRoutes = require("./routes/foodLogRoutes");
const progressRoutes = require("./routes/progressRoutes.js");
const mealPlanRoutes = require("./routes/mealPlanRoutes.js");
const webRoutes = require('./routes/webRoutes'); // Admin Panel Routes
const complaintRoutes = require('./routes/complaintRoutes'); // Complaints Routes

const { protect } = require("./middleware/authMiddleware.js");

// Initialize AI
const ai = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

const app = express();

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

// --- Middleware ---
app.use((req, res, next) => {
  console.log(`\n➡️  Request Received: ${req.method} ${req.originalUrl}`);
  next();
});

app.use(bodyParser.json());
app.use(cors());
app.use("/uploads", express.static(path.join(__dirname, "uploads")));

// Connect to Database
connectDB();

// ======================================================================
// 🚀 APP ROUTES
// ======================================================================
app.use("/api/auth", authRoutes);
app.use("/api/users", userRoutes);
app.use("/api/user-details", userDetailsRoutes);
app.use("/api/activities", activityRoutes);
app.use("/api/mealplan", mealPlanRoutes);
app.use("/api/foodlog", foodLogRoutes);
app.use("/api/rewards", rewardRoutes);
app.use("/api/progress", progressRoutes);
app.use('/api/web', webRoutes); // Admin Web Routes
app.use('/api/complaints', complaintRoutes); // ✅ Complaints Routes

// ======================================================================
// 🤖 AI & PYTHON ENDPOINTS
// ======================================================================

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

app.post("/api/get_last_7days_steps", async (req, res) => {
  const steps = [2000, 3000, 1000, 10000, 9000, 6000, 9000, 7000];
  const minLength = 7;
  let responseSteps;
  let okData;

  if (steps.length >= minLength) {
    responseSteps = steps.slice(-minLength);
    okData = true;
  } else {
    responseSteps = steps;
    okData = false;
  }

  res.send({ OkData: okData, steps: responseSteps });
});

app.post('/api/generate-ai-content', async (req, res) => {
  const userData = {
    averageCalories : 100,
    averageSugar: 12, averageFats: 3, averageCholesterol: 21,     
    averageCarbs: 25, averageProtein: 5, averageCaloriesBurned: 50,  
    currentHealthCondition: ["Hypertension","Sugar"] 
  };

  const userPrompt = `
    Based on the following data, predict possible future health risks:
    - Average Calories Intake: ${userData.averageCalories} kcal
    - Average Blood Sugar: ${userData.averageSugar} mg/dL
    - Average Cholesterol: ${userData.averageCholesterol} mg/dL
    - Average Fats: ${userData.averageFats} g
    - Average Carbs: ${userData.averageCarbs} g
    - Average Protein: ${userData.averageProtein} g
    - Average Calories Burned Per Day: ${userData.averageCaloriesBurned} kcal
    - Current Health Condition: ${userData.currentHealthCondition}
    
    Only predict the following conditions: 
    'Hypertension', 'High Cholesterol', 'Obesity', 'Diabetes', 'Heart Disease', 'Arthritis', 'Asthma'.
    Please return the information as a JSON object.
  `;

  try {
    const model = ai.getGenerativeModel({ model: "gemini-2.0-flash" });
    const result = await model.generateContent(userPrompt);
    res.json(result.response.text());
  } catch (error) {
    res.status(500).send('AI request failed');
  }
});

app.post("/api/get-nutrition-data", async (req, res) => {
  const { name, description } = req.body;
  if (!name || !description) return res.status(400).json({ error: "Missing name/desc" });

  const systemInstruction = `You are an expert Nutritional Analyst AI. Analyze the meal and generate JSON with nutrients.`;
  
  try {
    const model = ai.getGenerativeModel({ model: "gemini-2.0-flash", systemInstruction });
    const result = await model.generateContent({
      contents: [{ role: "user", parts: [{ text: `Food Name: ${name}\nDescription: ${description}` }] }],
      generationConfig: { responseMimeType: "application/json", responseSchema: nutritionSchema },
    });
    res.json(JSON.parse(result.response.text()));
  } catch (error) {
    res.status(500).json({ error: "AI request failed." });
  }
});

app.get("/api/user/profile-summary", protect, async (req, res) => {
  const userId = req.userId;
  try {
    const USER = await User.findOne({ _id: userId }).select("email");
    const user = await UserDetails.findOne({ user: userId }).lean();

    if (!user) return res.status(404).json({ success: false, message: "User profile not found." });

    const today = new Date(); today.setHours(0, 0, 0, 0);
    const waterLog = await WaterLog.findOne({ user: userId, date: today });

    res.status(200).json({
      notification: true,
      email: USER.email,
      healthConditions: user.healthConcerns,
      success: true,
      userName: user.userName,
      caloriesGoal: user.caloriesGoal || 2000,
      currentWeight: user.currentWeight,
      targetWeight: user.targetWeight,
      startWeight: user.startWeight,
      height: user.height,
      waterGoal: user.waterGoal ?? 2000,
      waterConsumed: waterLog ? waterLog.amount : 0,
    });
  } catch (err) {
    res.status(500).json({ success: false, message: "Failed to fetch profile." });
  }
});

app.post("/api/predict", upload.single("image"), (req, res) => {
  if (!req.file) return res.status(400).json({ success: false, message: "No image uploaded" });
  const imagePath = path.resolve(req.file.path);
  exec(`python ${path.join(__dirname, "predict.py")} ${imagePath}`, (error, stdout) => {
      if (error) return res.status(500).json({ success: false, message: "Prediction failed" });
      res.send(stdout.trim().replace(/^"|"$/g, ""));
  });
});

app.post("/api/detect-ingredients", upload.single("image"), (req, res) => {
  if (!req.file) return res.status(400).json({ success: false, message: "No image uploaded." });
  const imagePath = path.resolve(req.file.path);
  const pythonScriptPath = path.join(__dirname, "recipe_gernate.py");
  
  if (!fs.existsSync(pythonScriptPath)) {
    fs.unlinkSync(imagePath);
    return res.status(500).json({ success: false, message: "Script not found." });
  }

  exec(`python "${pythonScriptPath}" "${imagePath}"`, { timeout: 30000 }, (error, stdout) => {
      if (error) return res.status(500).json({ success: false, message: "Failed to process image." });
      res.status(200).header("Content-Type", "application/json").send(stdout);
  });
});

app.post("/api/food/products", protect, async (req, res) => {
  const { productName } = req.body;
  if (!productName) return res.status(400).json({ success: false, message: "Product name required." });

  try {
    const userDetails = await UserDetails.findOne({ user: req.userId });
    const userProfileData = {
      conditions: userDetails?.healthConcerns || {},
      restrictions: userDetails?.restrictions || {},
      calorie_limit_kcal_100g: userDetails?.options?.maxCalories || 500, 
      input_name: productName,
    };

    const pythonScriptPath = path.join(__dirname, "food_lookup.py");
    const tempInputPath = path.join(__dirname, `temp_input_${Date.now()}.json`);
    fs.writeFileSync(tempInputPath, JSON.stringify(userProfileData));

    exec(`python "${pythonScriptPath}" "${tempInputPath}"`, { maxBuffer: 1024 * 1024 * 5 }, (error, stdout) => {
      if (fs.existsSync(tempInputPath)) fs.unlinkSync(tempInputPath);
      if (error) return res.status(500).json({ success: false, message: 'Safety check failed.' });
      
      try {
        const pythonOutput = JSON.parse(stdout);
        res.status(200).json({ success: true, products: pythonOutput.products || [] });
      } catch (e) {
        res.status(500).json({ success: false, message: "Invalid script response." });
      }
    });
  } catch (error) {
    res.status(500).json({ success: false, message: "Server error." });
  }
});

app.post("/upload", upload.single("image"), protect, async (req, res) => {
  if (!req.file) return res.status(400).json({ success: false, message: "No image uploaded." });
  const imagePath = path.resolve(req.file.path);
  const pythonScriptPath = path.join(__dirname, "extract_product.py");
  const tempInputPath = path.join(__dirname, `temp_scan_input_${Date.now()}.json`);

  try {
    const userDetails = await UserDetails.findOne({ user: req.userId }).select("healthConcerns restrictions").lean();
    fs.writeFileSync(tempInputPath, JSON.stringify({
      image_path: imagePath,
      user_id: req.userId,
      conditions: userDetails?.healthConcerns || {},
      restrictions: userDetails?.restrictions || {},
    }));

    exec(`python "${pythonScriptPath}" "${tempInputPath}"`, { timeout: 150000 }, (error, stdout) => {
        fs.unlink(imagePath, () => {});
        if (fs.existsSync(tempInputPath)) fs.unlinkSync(tempInputPath);
        if (error) return res.status(500).json({ success: false, message: "Processing failed." });
        try {
          res.status(200).json(JSON.parse(stdout));
        } catch (e) {
          res.status(500).json({ success: false, message: "Invalid JSON response." });
        }
    });
  } catch (dbError) {
    if (req.file) fs.unlink(imagePath, () => {});
    res.status(500).json({ success: false, message: "Internal server error." });
  }
});

app.get("/api/user-details/conditions/:userId", async (req, res) => {
  try {
    const userDetails = await UserDetails.findOne({ user: req.params.userId }).select("healthConcerns restrictions").lean();
    if (!userDetails) return res.status(404).json({ success: false });
    res.status(200).json({ success: true, conditions: userDetails.healthConcerns, preferences: userDetails.restrictions });
  } catch (err) {
    res.status(500).json({ success: false });
  }
});

app.get("/api/user-details/my-profile", protect, async (req, res) => {
  try {
    const userDetails = await UserDetails.findOne({ user: req.userId }).lean();
    if (!userDetails) return res.status(404).json({ success: false });
    res.status(200).json({
      success: true,
      healthConcerns: userDetails.healthConcerns || {},
      restrictions: userDetails.restrictions || {},
      eatingStyles: userDetails.eatingStyles || {},
      subGoals: userDetails.selectedSubGoals || [],
      habits: userDetails.selectedHabits || [],
    });
  } catch (err) {
    res.status(500).json({ success: false });
  }
});

app.get("/api/search_factory_products", async (req, res) => {
  if (!req.query.query) return res.status(400).json({ success: false });
  try {
    const response = await axios.get(`https://world.openfoodfacts.org/cgi/search.pl`, {
      params: { search_terms: req.query.query, search_simple: 1, action: "process", json: 1, fields: "product_name,brands,nutriments,image_url", page_size: 30 },
      timeout: 100000,
    });
    res.status(200).json({ success: true, products: response.data.products || [] });
  } catch (error) {
    res.status(500).json({ success: false });
  }
});

app.use((err, req, res, next) => {
  console.error(`\n🔥 Global Error Handler: ${err.stack}`);
  res.status(500).json({ success: false, message: "Internal server error", error: err.message });
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, "0.0.0.0", () => {
  console.log(`\n=================================================`);
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`=================================================`);
});