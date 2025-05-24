const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const connectDB = require('./config/db');
const userRoutes = require('./routes/userRoutes');
require('dotenv').config();

const authRoutes = require('./routes/authRoutes');

const app = express();

// Middleware
app.use(bodyParser.json());
app.use(cors());

// Connect to Database
connectDB();

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);

const PORT = process.env.PORT || 5000;

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`);
});