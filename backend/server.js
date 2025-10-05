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
// const axios = require('axios'); // REMOVED: No longer needed for recipe finding 
const fs = require('fs');
require('dotenv').config();

const app = express();

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
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

// Middleware
app.use(bodyParser.json());
app.use(cors());
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Connect to Database
connectDB();

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/meals', mealRoutes);
app.use('/api/user-details', userDetailsRoutes);

// --- ORIGINAL IMAGE PREDICTION ENDPOINT (REMAINS UNCHANGED) ---
app.post('/api/predict', upload.single('image'), (req, res) => {
  if (!req.file) {
    return res.status(400).json({ success: false, message: 'No image uploaded' });
  }

  const imagePath = path.resolve(req.file.path);
  
  // This part still calls your original 'predict.py' or can be modified as needed
  exec(`python ${path.join(__dirname, 'predict.py')} ${imagePath}`, 
    (error, stdout, stderr) => {
      if (error) {
        console.error(`Prediction error: ${error.message}`);
        return res.status(500).json({ 
          success: false, 
          message: 'Prediction failed',
          error: error.message
        });
      }
      if (stderr) {
        console.error(`Prediction stderr: ${stderr}`);
      }
      
      res.send(stdout.trim().replace(/^"|"$/g, ''));
      console.log(`Prediction result: ${stdout.trim()}`);
    }
  );
});


// --- NEW INGREDIENT DETECTION ENDPOINT (REMAINS AS THE ONLY RECIPE-RELATED BACKEND LOGIC) ---
app.post('/api/detect-ingredients', upload.single('image'), (req, res) => {
    if (!req.file) {
        return res.status(400).json({ success: false, message: 'No image uploaded.' });
    }
    
    const imagePath = path.resolve(req.file.path);
    
    // Validate that the file actually exists
    if (!fs.existsSync(imagePath)) {
        return res.status(400).json({ success: false, message: 'Uploaded file not found.' });
    }

    const pythonScriptPath = path.join(__dirname, 'recipe_gernate.py');
    
    // Validate that the Python script exists
    if (!fs.existsSync(pythonScriptPath)) {
        // Clean up the uploaded file
        fs.unlinkSync(imagePath);
        return res.status(500).json({ 
            success: false, 
            message: 'Server configuration error: Processing script not found.' 
        });
    }

    // Set a timeout for the model execution
    exec(`python "${pythonScriptPath}" "${imagePath}"`, { timeout: 30000 },
        (error, stdout, stderr) => {
            // Note: Cleanup logic has been commented out in the original, keeping it that way,
            // but in a production environment, file cleanup is critical.
            
            // Handle execution errors
            if (error) {
                console.error('Python script execution failed:', error);
                
                if (error.code === 'ETIMEDOUT' || error.signal === 'SIGTERM') {
                    return res.status(408).json({ 
                        success: false, 
                        message: 'Processing timeout. Please try again with a smaller image.' 
                    });
                }
                
                // Try to check if Python script printed an error JSON before failing
                try {
                  const errorOutput = JSON.parse(stdout);
                  if (errorOutput.error) {
                      return res.status(500).json({ success: false, message: `Ingredient detection error: ${errorOutput.error}` });
                  }
                } catch (e) {
                  // Ignore parse error, use generic message below
                }
                
                return res.status(500).json({ 
                    success: false, 
                    message: 'Failed to process image. Please try again.' 
                });
            }

            // Log stderr for debugging (non-fatal)
            if (stderr) {
                console.warn('Python script stderr:', stderr);
            }

            try {
                // Check if stdout is empty
                if (!stdout || stdout.trim() === '') {
                    throw new Error('No output received from processing script');
                }

                const detectionResult = JSON.parse(stdout);
                
                // Check for error reported via JSON in stdout (from recipe_gernate.py)
                if (detectionResult.error) {
                    return res.status(500).json({ success: false, message: `Ingredient detection error: ${detectionResult.error}` });
                }

                // Validate the structure of the detection result
                if (!detectionResult || typeof detectionResult !== 'object' || !detectionResult.detections) {
                    throw new Error('Invalid detection result format or missing detections field');
                }

                console.log('Successfully detected ingredients.');
                // Directly send the JSON output from the Python script.
                // Set the content type to ensure the client parses it as JSON.
                res.status(200).header('Content-Type', 'application/json').send(stdout);
                
            } catch (parseError) {
                console.error('Failed to parse detection result:', parseError);
                console.error('Raw stdout:', stdout);
                
                if (parseError instanceof SyntaxError) {
                    return res.status(500).json({ 
                        success: false, 
                        message: 'Invalid response from image processing service. Check Python script output.' 
                    });
                }
                
                return res.status(500).json({ 
                    success: false, 
                    message: 'Failed to process detection results.' 
                });
            }
        }
    );
});

// --- REMOVED: /api/find-recipes endpoint is removed as requested to shift logic to Flutter ---
/*
app.post('/api/find-recipes', async (req, res) => {
    // ... logic removed ...
});
*/


// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ 
    success: false, 
    message: 'Internal server error',
    error: err.message 
  });
});

const PORT = process.env.PORT || 5000;

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Original prediction endpoint: POST /api/predict`);
  console.log(`Ingredient detection endpoint: POST /api/detect-ingredients`);
  // Note: /api/find-recipes is now handled by the Flutter client.
});