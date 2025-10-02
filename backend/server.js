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

// --- ORIGINAL IMAGE PREDICTION ENDPOINT (UNCHANGED) ---
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


// --- ✨ NEW RECIPE GENERATION ENDPOINT ---
// This new endpoint is specifically for generating recipes from an image.
app.post('/api/generate-recipe', upload.single('image'), (req, res) => {
    if (!req.file) {
        return res.status(400).json({ success: false, message: 'No image uploaded for recipe generation.' });
    }

    const imagePath = path.resolve(req.file.path);

    // This command executes the recipe generation script
    exec(`python ${path.join(__dirname, 'recipe_gernate.py')} ${imagePath}`,
        (error, stdout, stderr) => {
            if (error) {
                console.error(`Recipe script execution error: ${error.message}`);
                return res.status(500).json({
                    success: false,
                    message: 'Recipe generation failed.',
                    error: error.message
                });
            }
            if (stderr) {
                console.error(`Recipe script stderr: ${stderr}`);
                // Note: Python libraries sometimes print warnings to stderr, so we don't exit here.
            }

            // The Python script should output a clean JSON string. We parse it here.
            try {
                const recipes = JSON.parse(stdout);
                console.log('Successfully generated recipes.');
                res.status(200).json({ success: true, data: recipes });
            } catch (e) {
                console.error('Error parsing python script output:', e);
                console.error('Raw stdout from python:', stdout); // Log the raw output for debugging
                res.status(500).json({ success: false, message: 'Failed to parse recipe data from script.' });
            }
        }
    );
});


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
  console.log(`New recipe endpoint: POST /api/generate-recipe`);
});