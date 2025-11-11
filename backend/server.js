const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const multer = require('multer');
const path = require('path');
const { exec } = require('child_process');
const connectDB = require('./config/db');
const userRoutes = require('./routes/userRoutes');
const authRoutes = require('./routes/authRoutes');
const mealRoutes = require('./routes/mealRoutes');
const userDetailsRoutes = require('./routes/userDetailsRoutes');
const activityRoutes = require('./routes/activityRoutes');
const rewardRoutes = require('./routes/rewardRoutes');
const fs = require('fs');
const jwt = require('jsonwebtoken');
const axios = require('axios'); 
const PendingUser = require('./models/pendingUser.js'); // <--- ADD THIS LINE
const FormData = require('form-data'); 
require('dotenv').config();

const { GoogleGenerativeAI } = require('@google/generative-ai');
const ai = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);




// Mongoose Models
const User = require('./models/User'); 
const UserDetails = require('./models/userDetails'); 
const mealPlanRoutes = require("./routes/mealPlanRoutes.js");
const calorieGoal = require('./models/userDetails');
const progressRoutes = require('./routes/progressRoutes.js');

const { protect } = require('./middleware/authMiddleware.js');


const app = express();

// --- Multer Configuration for File Uploads ---
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        if (!fs.existsSync('uploads')) {
            fs.mkdirSync('uploads');
        }
        cb(null, 'uploads/');
    },
    filename: (req, file, cb) => {
        cb(null, `${Date.now()}-${file.originalname}`);
    }
});

const upload = multer({
    storage: storage,
    limits: { fileSize: 5 * 1024 * 1024 } // 5MB limit
});

// --- Enhanced Logging Middleware ---
app.use((req, res, next) => {
    console.log(`\n➡️  Request Received: ${req.method} ${req.originalUrl}`);
    console.log(`   Host: ${req.hostname}`);
    next();
});

// --- Standard Middleware ---
app.use(bodyParser.json());
app.use(cors());
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Connect to Database
connectDB();



// --- Application Routes ---
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/meals', mealRoutes);
app.use('/api/user-details', userDetailsRoutes);
app.use('/api/activities', activityRoutes);
app.use('/api/rewards', rewardRoutes);
app.use("/api/mealplan", mealPlanRoutes);
app.use("/api/progress", progressRoutes);






app.post('/api/get_last_7days_steps', async (req, res) => {
    // Mock data for demonstration
    // If steps.length is 8, it should return the last 7 (3000 to 7000) and OkData: true.
    const steps = [2000, 3000, 1000, 10000, 9000, 6000, 9000, 7000];

    // Example if steps.length < 7:
    // const steps = [4000, 5000, 6000]; 

    const minLength = 7;
    let responseSteps;
    let okData;

    if (steps.length >= minLength) {
        // If 7 or more values exist, get only the last 7 days (values)
        // steps.slice(-7) returns the last 7 elements of the array.
        responseSteps = steps.slice(-minLength);
        okData = true;
    } else {
        // If less than 7 values exist, return the entire array as is
        responseSteps = steps;
        okData = false;
    }

    // Send the structured JSON response
    res.send({
        "OkData": okData,
        "steps": responseSteps
    });
});


app.post('/api/generate-ai-content', async (req, res) => {
//   const userId = req.body.userId;  

  const userData = {
    averageCalories : 100,
    averageSugar: 12,           
    averageFats: 3,             
    averageCholesterol: 21,     
    averageCarbs: 25,           
    averageProtein: 5,          
    averageCaloriesBurned: 50,  
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
    Please provide the likelihood of each condition and actionable recommendations for improving health.

    Please return the following information as a JSON object only:
    {
    "profile": {
        "Health Conditions": 
        "Average Calories": 
        "Average Blood Sugar":
        "Average Cholesterol":
        "Average Fats":
        "Average Carbs":
        "Average Protein":
        "Average Calories Burned":
    
    }

    "health_risks": {
        "Hypertension": "(low,medium,high,very high)",
        "Diabetes": "(low,medium,high,very high)",
        "Obesity": "(low,medium,high,very high)",
        ...
        ...
    },
    "consumption":{
        "sugar": (low,medium,high,very high),
        "fat": (low,medium,high,very high),
        ...
        ...
    
    }
    "recommendations": ["recommendation1(within 15 words)", "recommendation2(within 15 words)", "recommendation3(within 15 words); "recommendation4(within 15 words); "recommendation5(within 15 words)"]
    }
  `;

  console.log("Prompt:", userPrompt); // Debugging to check the prompt

  try {
    const model = ai.getGenerativeModel({ model: "gemini-2.5-flash" });
    const result = await model.generateContent(userPrompt);

    const responseText = result.response.text();
    console.log("AI Response:", responseText);



    res.json(responseText);

  } catch (error) {
    console.error("Error:", error);
    res.status(500).send('AI request failed');
  }
});



// --- ADDED: New route to get user's name and calorie goal ---
app.get('/api/user/profile-summary', protect, async (req, res) => {
    const userId = req.userId;
    console.log(`➡️  Request Received: GET /api/user/profile-summary for User ID: ${userId}`);
 
    try {

        const USER = await User.findOne({_id: userId}).select('email');
        // Fetch user's name and calorie goal from the UserDetails collection
        const user = await UserDetails.findOne({ user: userId })
            .select('userName caloriesGoal currentWeight targetWeight height waterGoal') // Fetch both fields
            .lean();
        
        if (!user) {
            console.log(`   ❌ User details not found for ID: ${userId}`);
            return res.status(404).json({ success: false, message: 'User profile not found.' });
        }


        const caloriesGoal = user.caloriesGoal || 2000; 

        console.log(`   ✅ Successfully fetched data: Name='${user.userName}', Calories=${caloriesGoal},   ${user.waterGoal}`);
         
        res.status(200).json({
            email: USER.email,
            success: true,
            userName: user.userName,
            caloriesConsumed: 2000,
            caloriesGoal: caloriesGoal,
            currentWeight: user.currentWeight,
            targetWeight: user.targetWeight,
            startWeight: user.startWeight|| "160 kg",
            height: user.height,
            carbs: 9,
            protein: 9,
            fat: 9,
            steps:3000,
            waterGoal: user.waterGoal ?? 1500,
            waterConsumed: 250,
            stepGoal: 10000
        });

    } catch (err) {
        console.error(`   ❌ Error fetching profile summary for User ID ${userId}: ${err.message}`);
        res.status(500).json({ 
            success: false, 
            message: 'Failed to fetch user profile summary.' 
        });
    }
});

// --- REPLACE your /api/predict route with this ---
app.post('/api/predict', upload.single('image'), async (req, res) => {
  if (!req.file) {
    return res.status(400).json({ success: false, message: 'No image uploaded' });
  }

  const imagePath = path.resolve(req.file.path);
  const spoonacularUrl = 'https://api.spoonacular.com/food/images/classify';
  
  const form = new FormData();
  
  // ✅ FIX: The API expects the field name to be 'file', not 'image'
  form.append('file', fs.createReadStream(imagePath));

  try {
    const response = await axios.post(
      spoonacularUrl,
      form,
      {
        headers: {
          ...form.getHeaders(),
          'x-api-key': process.env.SPOONACULAR_API_KEY,
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36'
        },
        decompress: true
      }
    );

    if (response.data && response.data.category) {
      // Send back the category name, matching your old script's output
      res.send(JSON.stringify(response.data.category));
    } else {
      res.send(JSON.stringify("Could not classify food."));
    }

  } catch (error) {
    // ✅ FIX: Improved error logging
    if (error.response) {
      console.error('Spoonacular Error Status:', error.response.status);
      // This will now print the JSON object with the error message
      console.error('Spoonacular Error Data:', error.response.data); 
    } else {
      console.error('Spoonacular Error Message:', error.message);
    }

    return res.status(500).json({
      success: false,
      message: 'Prediction failed',
      // Send the specific Spoonacular error message to the app if available
      error: error.response ? error.response.data.message : 'Server error'
    });
  } finally {
    // Clean up the uploaded file
    fs.unlink(imagePath, (err) => {
      if (err) console.error('Error deleting temp image file:', err);
    });
  }
});



// // --- NEW INGREDIENT DETECTION ENDPOINT (REMAINS AS THE ONLY RECIPE-RELATED BACKEND LOGIC) ---
// app.post('/api/detect-ingredients', upload.single('image'), (req, res) => {
//     if (!req.file) {
//         return res.status(400).json({ success: false, message: 'No image uploaded.' });
//     }
    
//     const imagePath = path.resolve(req.file.path);
    
//     // Validate that the file actually exists
//     if (!fs.existsSync(imagePath)) {
//         return res.status(400).json({ success: false, message: 'Uploaded file not found.' });
//     }

//     const pythonScriptPath = path.join(__dirname, 'recipe_gernate.py');
    
//     // Validate that the Python script exists
//     if (!fs.existsSync(pythonScriptPath)) {
//         // Clean up the uploaded file
//         fs.unlinkSync(imagePath);
//         return res.status(500).json({ 
//             success: false, 
//             message: 'Server configuration error: Processing script not found.' 
//         });
//     }

//     // Set a timeout for the model execution
//     exec(`python "${pythonScriptPath}" "${imagePath}"`, { timeout: 30000 },
//         (error, stdout, stderr) => {
//             // Note: Cleanup logic has been commented out in the original, keeping it that way,
//             // but in a production environment, file cleanup is critical.
            
//             // Handle execution errors
//             if (error) {
//                 console.error('Python script execution failed:', error);
                
//                 if (error.code === 'ETIMEDOUT' || error.signal === 'SIGTERM') {
//                     return res.status(408).json({ 
//                         success: false, 
//                         message: 'Processing timeout. Please try again with a smaller image.' 
//                     });
//                 }
                
//                 // Try to check if Python script printed an error JSON before failing
//                 try {
//                   const errorOutput = JSON.parse(stdout);
//                   if (errorOutput.error) {
//                       return res.status(500).json({ success: false, message: `Ingredient detection error: ${errorOutput.error}` });
//                   }
//                 } catch (e) {
//                   // Ignore parse error, use generic message below
//                 }
                
//                 return res.status(500).json({ 
//                     success: false, 
//                     message: 'Failed to process image. Please try again.' 
//                 });
//             }

//             // Log stderr for debugging (non-fatal)
//             if (stderr) {
//                 console.warn('Python script stderr:', stderr);
//             }

//             try {
//                 // Check if stdout is empty
//                 if (!stdout || stdout.trim() === '') {
//                     throw new Error('No output received from processing script');
//                 }

//                 const detectionResult = JSON.parse(stdout);
                
//                 // Check for error reported via JSON in stdout (from recipe_gernate.py)
//                 if (detectionResult.error) {
//                     return res.status(500).json({ success: false, message: `Ingredient detection error: ${detectionResult.error}` });
//                 }

//                 // Validate the structure of the detection result
//                 if (!detectionResult || typeof detectionResult !== 'object' || !detectionResult.detections) {
//                     throw new Error('Invalid detection result format or missing detections field');
//                 }

//                 console.log('Successfully detected ingredients.');
//                 // Directly send the JSON output from the Python script.
//                 // Set the content type to ensure the client parses it as JSON.
//                 res.status(200).header('Content-Type', 'application/json').send(stdout);
                
//             } catch (parseError) {
//                 console.error('Failed to parse detection result:', parseError);
//                 console.error('Raw stdout:', stdout);
                
//                 if (parseError instanceof SyntaxError) {
//                     return res.status(500).json({ 
//                         success: false, 
//                         message: 'Invalid response from image processing service. Check Python script output.' 
//                     });
//                 }
                
//                 return res.status(500).json({ 
//                     success: false, 
//                     message: 'Failed to process detection results.' 
//                 });
//             }
//         }
//     );
// });

// ======================================================================
// 🚫 DISABLED INGREDIENT DETECTION ENDPOINT - Returns Feature Disabled
// ======================================================================  


app.post('/api/detect-ingredients', upload.single('image'), (req, res) => {
    // Clean up the uploaded file immediately
    if (req.file) {
        fs.unlink(req.file.path, (err) => {
            if (err) console.error("Error deleting temp file:", err);
        });
    }

    // Return a "feature disabled" error
    res.status(503).json({ 
        success: false, 
        message: 'This feature is temporarily disabled.' 
    });
});



// ======================================================================
// ✅ CRITICAL FIX: PRODUCT LOOKUP ROUTE - Executes food_lookup.py
// ======================================================================
app.post('/api/food/products', protect, async (req, res) => {
    const { productName } = req.body;
    const userId = req.userId;

    console.log(`🔍 [DEBUG] /api/food/products called for: ${productName}`);
    console.log(`🔍 [DEBUG] User ID: ${userId}`);

    if (!productName) {
        return res.status(400).json({ success: false, message: 'Product name is required for lookup.' });
    }

    try {
        // 1. Fetch User's Health Profile
        console.log(`🔍 [DEBUG] Fetching user details from database...`);
        const userDetails = await UserDetails.findOne({ user: userId });
        console.log(`🔍 [DEBUG] User details found:`, !!userDetails);
        
        // Construct the profile data
        const userProfileData = {
            conditions: userDetails?.healthConcerns || {},
            restrictions: userDetails?.restrictions || {},
            calorie_limit_kcal_100g: userDetails?.options?.maxCalories || 500, 
            input_name: productName,
        };

        console.log(`🔍 [DEBUG] Data for Python:`, JSON.stringify(userProfileData, null, 2));

        // 2. Prepare for Python Execution
        const pythonScriptPath = path.join(__dirname, 'food_lookup.py');
        const tempInputPath = path.join(__dirname, `temp_input_${Date.now()}.json`);

        console.log(`🔍 [DEBUG] Python script path: ${pythonScriptPath}`);
        console.log(`🔍 [DEBUG] Temp file path: ${tempInputPath}`);
        console.log(`🔍 [DEBUG] Checking if Python script exists: ${fs.existsSync(pythonScriptPath)}`);

        // Write input to temporary file
        fs.writeFileSync(tempInputPath, JSON.stringify(userProfileData));
        console.log(`🔍 [DEBUG] Temp file created successfully`);

        const command = `python "${pythonScriptPath}" "${tempInputPath}"`;
        console.log(`🔍 [DEBUG] Command to execute: ${command}`);

        // 3. Execute Python Script
        console.log(`🚀 [PYTHON] Starting Python execution...`);
        
        exec(command, { maxBuffer: 1024 * 1024 * 5 }, (error, stdout, stderr) => {
            console.log(`🔍 [PYTHON] Execution completed - cleaning up temp file`);
            
            // Clean up temp file
            if (fs.existsSync(tempInputPath)) {
                fs.unlink(tempInputPath, (unlinkErr) => {
                    if (unlinkErr) console.error('❌ Error deleting temp file:', unlinkErr);
                    else console.log('✅ Temp file deleted');
                });
            }

            console.log(`🔍 [PYTHON] stdout length: ${stdout?.length || 0}`);
            console.log(`🔍 [PYTHON] stderr length: ${stderr?.length || 0}`);
            console.log(`🔍 [PYTHON] stdout: ${stdout}`);
            console.log(`🔍 [PYTHON] stderr: ${stderr}`);
            console.log(`🔍 [PYTHON] error:`, error);

            if (error) {
                console.error(`❌ [PYTHON ERROR] Code: ${error.code}, Signal: ${error.signal}`);
                console.error(`❌ [PYTHON ERROR] Message: ${error.message}`);
                return res.status(500).json({ 
                    success: false, 
                    message: 'Product safety check failed due to script error.',
                    errorDetail: stderr || error.message
                });
            }

            if (stderr) {
                console.warn(`⚠️ [PYTHON WARNINGS]: ${stderr}`);
            }

            try {
                if (!stdout || stdout.trim() === '') {
                    throw new Error('Python script returned empty output');
                }

                console.log(`🔍 [PYTHON] Parsing JSON output...`);
                const pythonOutput = JSON.parse(stdout);
                console.log(`✅ [PYTHON] Successfully parsed JSON output`);

                // Check products
                if (pythonOutput.products && pythonOutput.products.length > 0) {
                    console.log(`🎉 [SUCCESS] Found ${pythonOutput.products.length} products`);
                    pythonOutput.products.forEach((product, index) => {
                        console.log(`   📦 Product ${index + 1}: ${product.name} by ${product.brand}`);
                    });
                } else {
                    console.log(`❌ [NO PRODUCTS] Python returned:`, pythonOutput);
                }

                // Map products
                const mappedProducts = (pythonOutput.products || []).map(p => ({
                    product_name: p.name,
                    brands: p.brand,
                    image_url: p.image_url,
                    nutrients: p.nutrients
                }));

                console.log(`📤 [RESPONSE] Sending ${mappedProducts.length} products to client`);
                res.status(200).json({ success: true, products: mappedProducts });

            } catch (parseError) {
                console.error(`❌ [PARSE ERROR] Failed to parse Python output: ${parseError.message}`);
                console.error(`❌ [RAW STDOUT]: ${stdout}`);
                return res.status(500).json({ 
                    success: false, 
                    message: 'Invalid response from safety check script.',
                    rawOutput: stdout.substring(0, 500)
                });
            }
        });

    } catch (error) {
        console.error("❌ [ROUTE ERROR] /api/food/products failed:", error);
        res.status(500).json({ success: false, message: 'Internal server error during profile lookup.' });
    }
});


// 🚀 MAIN SCANNER ENDPOINT (Protected)
app.post('/upload', upload.single('image'), protect, (req, res) => {
    console.log(`   ⚙️  Processing: /upload (Scanner) started for User ${req.userId}.`);
    if (!req.file) {
        return res.status(400).json({ success: false, message: 'No image uploaded.' });
    }

    const imagePath = path.resolve(req.file.path);
    const pythonScriptPath = path.join(__dirname, 'extract_product.py');
    const userId = req.userId;

    console.log(`   📂 File saved temporarily: ${imagePath}`);

    // Command structure ensures userId is passed to python script for internal lookup
    const command = `python "${pythonScriptPath}" "${imagePath}" "${userId}"`;
    console.log(`   🐍 Executing Python script: ${command}`);
 
    exec(command, { timeout: 90000 },
        (error, stdout, stderr) => {
            fs.unlink(imagePath, (err) => {
                if (err) console.error('Error deleting file:', err);
            });
 
            if (error) {
                if (error.code === 'ETIMEDOUT') {
                    return res.status(408).json({ success: false, message: 'Processing timeout. Please try again.' });
                }
                console.error('   ❌ /upload: Python script execution error:', error);
                return res.status(500).json({ success: false, message: 'Failed to process image due to server error.' });
            }

            if (stderr) {
                console.warn('   ⚠️ /upload: Python script stderr output:', stderr.substring(0, 100) + '...');
            }

            try {
                if (!stdout || stdout.trim() === '') {
                    throw new Error('No output received from processing script');
                }

                const detectionResult = JSON.parse(stdout);

                if (detectionResult.error) {
                    return res.status(500).json({ success: false, message: `Scanner error: ${detectionResult.error}` });
                }

                res.status(200).json(detectionResult);

            } catch (parseError) {
                return res.status(500).json({
                    success: false,
                    message: 'Invalid response from image processing service.'
                });
            }
        }
    );
});


// 🏥 INTERNAL ENDPOINT: Fetch User Conditions for Python Scanner 
// (Called by the Python script using req.userId passed via the command line)
app.get('/api/user-details/conditions/:userId', async (req, res) => {
    const { userId } = req.params; 
    console.log(`   ⚙️  Internal API: Fetching details for User ID: ${userId}`);

    try {
        const userDetails = await UserDetails.findOne({ user: userId }) 
            .select('healthConcerns restrictions')
            .lean(); 
        
        if (!userDetails) {
            return res.status(404).json({ success: false, message: 'User details not found. Profile setup incomplete.' });
        }

        const conditions = userDetails.healthConcerns || {}; 
        const preferences = userDetails.restrictions || {}; 
        
        console.log(`   ✅ Internal API: Data fetched. Conditions keys: ${Object.keys(conditions).length}`);
        
        res.status(200).json({
            success: true,
            conditions: conditions, 
            preferences: preferences
        });

    } catch (err) {
        console.error(`   ❌ Internal API DB Error (ID: ${userId}): ${err.message}`);
        res.status(500).json({ 
            success: false, 
            message: 'Failed to fetch user data from database. Check server logs.' 
        });
    }
});


// 🆕 NEW PROTECTED ENDPOINT: Fetch Full User Profile (Conditions, Preferences, Styles)
// Called by the Flutter App on load to get data for filtering
app.get('/api/user-details/my-profile', protect, async (req, res) => {
    const userId = req.userId; 
    console.log(`   ⚙️  External API: Fetching full profile for authenticated User ID: ${userId}`);

    try {
        // Fetch all fields relevant to filtering/display
        const userDetails = await UserDetails.findOne({ user: userId }) 
            .select('healthConcerns restrictions eatingStyles selectedSubGoals selectedHabits') 
            .lean(); 
        
        if (!userDetails) {
            console.log(`   ⚠️ External API: User details not found for User ID ${userId}.`);
            return res.status(404).json({ success: false, message: 'User profile not found. Please complete your profile setup.' });
        }

        console.log(`   ✅ External API: Profile data fetched successfully.`);
        
        // Return all relevant data
        res.status(200).json({
            success: true,
            healthConcerns: userDetails.healthConcerns || {},
            restrictions: userDetails.restrictions || {},
            eatingStyles: userDetails.eatingStyles || {},
            subGoals: userDetails.selectedSubGoals || [],
            habits: userDetails.selectedHabits || [],
        });

    } catch (err) {
        console.error(`   ❌ External API DB Error (ID: ${userId}): ${err.message}`);
        res.status(500).json({ 
            success: false, 
            message: 'Failed to fetch user profile data from database.' 
        });
    }
});


// 3. FACTORY PRODUCT SEARCH ENDPOINT (Public)
app.get('/api/search_factory_products', async (req, res) => {
    const { query } = req.query;

    if (!query || query.trim().length === 0) {
        return res.status(400).json({ success: false, message: 'Search query is required.' });
    }

    const offUrl = `https://world.openfoodfacts.org/cgi/search.pl`;

    try {
        const response = await axios.get(offUrl, {
            params: {
                search_terms: query, search_simple: 1, action: 'process', json: 1,
                fields: 'product_name,brands,nutriments,image_url', page_size: 30,
            },
            headers: { 'User-Agent': 'CravingsSearchApp - NodeServer - v1.0' },
            timeout: 100000
        });

        const factoryProducts = (response.data.products || [])
            .map(product => ({
                name: product.product_name,
                brand: product.brands,
                nutrients: product.nutriments,
                image_url: product.image_url,
            }))
            .filter(p => p.name && p.brand && p.image_url);

        res.status(200).json({ success: true, products: factoryProducts });

    } catch (error) {
        const status = (error.code === 'ECONNABORTED' || error.response?.status === 408) ? 504 : 500;
        res.status(status).json({ success: false, error: 'Failed to retrieve factory products from external source.' });
    }
});


// --- Error handling middleware ---
app.use((err, req, res, next) => {
    console.error(`\n🔥 Global Error Handler: ${err.stack}`);
    res.status(500).json({ success: false, message: 'Internal server error', error: err.message });
});

const PORT = process.env.PORT || 5000;

app.listen(PORT, '0.0.0.0', () => {
    console.log(`\n=================================================`);
    console.log(`🚀 Server running on port ${PORT}`);
    console.log(`=================================================`);
});