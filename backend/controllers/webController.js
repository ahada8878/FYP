const User = require('../models/User');
const UserDetails = require('../models/userDetails');
const MealPlan = require('../models/MealPlan');
// Add these imports to the top of webController.js
const Admin = require('../models/Admin');
const AdminVerification = require('../models/AdminVerification');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const nodemailer = require('nodemailer');

const generateToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET, { expiresIn: '30d' });
};

// --- Helper: Send Email (Professional HTML Template) ---
const sendVerificationEmail = async (email, otp) => {
  // Configure your email service
  const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
      user: process.env.EMAIL_USER, // Your email
      pass: process.env.EMAIL_PASS  // Your email app password
    }
  });

  // Professional HTML Template for NutriWise
  const htmlTemplate = `
    <div style="font-family: 'Helvetica Neue', Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 0; background-color: #f9f9f9;">
      <div style="background-color: #ffffff; padding: 40px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); border-top: 4px solid #10B981;">
        
        <div style="text-align: center; margin-bottom: 30px;">
          <h1 style="color: #064E3B; margin: 0; font-size: 28px; letter-spacing: -0.5px;">NutriWise</h1>
          <p style="color: #6B7280; margin: 5px 0 0; font-size: 14px; text-transform: uppercase; letter-spacing: 1px;">Admin Dashboard Security</p>
        </div>

        <div style="color: #374151; line-height: 1.6; font-size: 16px;">
          <p>Hello,</p>
          <p>We received a request to verify your identity for the NutriWise Admin Panel. Please use the One-Time Password (OTP) below to complete your request.</p>
          
          <div style="background-color: #ECFDF5; border: 1px dashed #10B981; border-radius: 6px; padding: 20px; text-align: center; margin: 30px 0;">
            <span style="display: block; font-size: 12px; color: #059669; margin-bottom: 5px; text-transform: uppercase;">Your Verification Code</span>
            <span style="font-family: monospace; font-size: 32px; font-weight: bold; color: #047857; letter-spacing: 8px;">${otp}</span>
          </div>

          <p style="font-size: 14px; color: #6B7280;">This code is valid for <strong>10 minutes</strong>. If you did not request this code, please ignore this email or contact support immediately.</p>
        </div>

        <div style="margin-top: 40px; padding-top: 20px; border-top: 1px solid #E5E7EB; text-align: center; font-size: 12px; color: #9CA3AF;">
          <p>&copy; ${new Date().getFullYear()} NutriWise App. All rights reserved.</p>
          <p>This is an automated message, please do not reply.</p>
        </div>
      </div>
    </div>
  `;

  const mailOptions = {
    from: `"NutriWise Support" <${process.env.EMAIL_USER}>`, // Professional Sender Name
    to: email,
    subject: '🔐 Verify Your NutriWise Account', // Professional Subject
    html: htmlTemplate // Using HTML body
  };

  await transporter.sendMail(mailOptions);
};

const signupInit = async (req, res) => {
  const { firstName, lastName, email, password } = req.body;

  try {
    // 1. Check if Admin already exists
    const userExists = await Admin.findOne({ email });
    if (userExists) {
      return res.status(400).json({ message: 'User already exists' });
    }

    // 2. Generate OTP (6 digits)
    const otp = Math.floor(100000 + Math.random() * 900000).toString();

    // 3. Store temp data and OTP
    // ⚠️ CHANGE: We DO NOT hash the password here. 
    // We let the Admin model handle hashing when saving the final user.
    
    // Remove previous OTPs for this email
    await AdminVerification.deleteMany({ email });

    await AdminVerification.create({
      email,
      otp,
      tempUserData: {
        firstName,
        lastName,
        email,
        password: password // Store plain text (will be hashed upon verification)
      }
    });

    // 4. Send Email
    await sendVerificationEmail(email, otp);

    res.json({ message: 'Verification email sent' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error during signup' });
  }
};

const verifyAndCreate = async (req, res) => {
  const { email, otp } = req.body;

  try {
    const record = await AdminVerification.findOne({ email, otp });

    if (!record) {
      return res.status(400).json({ message: 'Invalid or expired code' });
    }

    const { firstName, lastName, password } = record.tempUserData;

    // ⚠️ CHANGE: Create Admin normally. 
    // The pre('save') hook in Admin.js will detect the new password and hash it automatically.
    const admin = new Admin({
      firstName,
      lastName,
      email,
      password: password, // Pass the plain password
      isVerified: true
    });
    
    await admin.save(); // <--- Hashing happens right here automatically

    // Delete verification record
    await AdminVerification.deleteMany({ email });

    // Generate Token
    const token = generateToken(admin._id);

    res.status(201).json({
      _id: admin._id,
      firstName: admin.firstName,
      lastName: admin.lastName,
      email: admin.email,
      token
    });

  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Verification failed' });
  }
};

// ======================================================================
// AUTH 3: LOGIN
// ======================================================================
const loginAdmin = async (req, res) => {
  const { email, password } = req.body;

  try {
    const admin = await Admin.findOne({ email });

    if (admin && (await admin.matchPassword(password))) {
      res.json({
        _id: admin._id,
        firstName: admin.firstName,
        lastName: admin.lastName,
        email: admin.email,
        token: generateToken(admin._id)
      });
    } else {
      res.status(401).json({ message: 'Invalid email or password' });
    }
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// ======================================================================
// AUTH 4: GET CURRENT ADMIN PROFILE (Protected Route)
// ======================================================================
const getAdminProfile = async (req, res) => {
  try {
    // req.admin is set by middleware
    const admin = await Admin.findById(req.admin._id).select('-password');
    if (admin) {
      res.json(admin);
    } else {
      res.status(404).json({ message: 'User not found' });
    }
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const updateProfileInit = async (req, res) => {
  const { firstName, lastName, email } = req.body;
  const adminId = req.admin._id; // From middleware

  try {
    const admin = await Admin.findById(adminId);
    
    // 1. Update Name immediately
    admin.firstName = firstName || admin.firstName;
    admin.lastName = lastName || admin.lastName;

    // 2. Check if email is changing
    if (email && email !== admin.email) {
      // Check if new email is taken
      const emailExists = await Admin.findOne({ email });
      if (emailExists) {
        return res.status(400).json({ message: 'Email already in use by another admin.' });
      }

      // Generate OTP for new email
      const otp = Math.floor(100000 + Math.random() * 900000).toString();

      // Store temp verification
      await AdminVerification.deleteMany({ email });
      await AdminVerification.create({
        email,
        otp,
        tempUserData: { adminId } // Store ID to know who is updating
      });

      await sendVerificationEmail(email, otp);
      
      // Save name changes, but NOT email yet
      await admin.save();
      
      return res.json({ 
        message: 'Profile updated. Verification code sent to new email.', 
        verifyEmail: true 
      });
    }

    // If email didn't change, just save
    await admin.save();
    res.json({ 
      message: 'Profile updated successfully', 
      verifyEmail: false,
      admin: {
        firstName: admin.firstName,
        lastName: admin.lastName,
        email: admin.email
      }
    });

  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// ======================================================================
// SETTINGS 2: VERIFY NEW EMAIL
// ======================================================================
const verifyNewEmail = async (req, res) => {
  const { email, otp } = req.body;
  const adminId = req.admin._id;

  try {
    const record = await AdminVerification.findOne({ email, otp });
    
    if (!record || record.tempUserData.adminId.toString() !== adminId.toString()) {
      return res.status(400).json({ message: 'Invalid or expired code' });
    }

    // Update Admin Email
    const admin = await Admin.findById(adminId);
    admin.email = email;
    await admin.save();

    await AdminVerification.deleteMany({ email });

    res.json({ 
      message: 'Email updated successfully',
      email: admin.email
    });

  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// ======================================================================
// SETTINGS 3: CHANGE PASSWORD
// ======================================================================
const changePassword = async (req, res) => {
  const { oldPassword, newPassword } = req.body;
  const adminId = req.admin._id;

  try {
    const admin = await Admin.findById(adminId);

    // 1. Verify Old Password
    const isMatch = await admin.matchPassword(oldPassword);
    if (!isMatch) {
      return res.status(400).json({ message: 'Incorrect old password' });
    }

    // 2. Set New Password (pre-save hook will hash it)
    admin.password = newPassword;
    await admin.save();

    res.json({ message: 'Password changed successfully' });

  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const getDashboardStats = async (req, res) => {
  try {
    const [userCount, mealPlanCount] = await Promise.all([
      User.countDocuments(),
      MealPlan.countDocuments()
    ]);

    res.json({
      totalUsers: userCount,
      totalMealPlans: mealPlanCount
    });
  } catch (error) {
    console.error("Error fetching dashboard stats:", error);
    res.status(500).json({ message: "Server error fetching stats" });
  }
};

const cleanupOrphans = async (req, res) => {
  try {
    // 1. Get all UserDetails
    const allDetails = await UserDetails.find();
    let deletedCount = 0;

    // 2. Check each one
    for (const detail of allDetails) {
      // Check if the linked User exists
      const linkedUser = await User.findById(detail.user);
      
      if (!linkedUser) {
        // If no user found, delete this orphan record
        await UserDetails.findByIdAndDelete(detail._id);
        deletedCount++;
      }
    }

    res.json({ 
      success: true, 
      message: `Cleanup complete. Deleted ${deletedCount} orphan records.`,
      remaining: allDetails.length - deletedCount
    });

  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// ======================================================================
// 2. DIET DISTRIBUTION (Pie Chart)
// ======================================================================
const getDietDistribution = async (req, res) => {
  try {
    const data = await UserDetails.aggregate([
      { $project: { styles: { $objectToArray: "$eatingStyles" } } },
      { $unwind: "$styles" },
      { $match: { "styles.v": true } },
      { $group: { _id: "$styles.k", count: { $sum: 1 } } },
      { $project: { name: "$_id", value: "$count", _id: 0 } },
      { $sort: { value: -1 } }
    ]);
    res.json(data);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// ======================================================================
// 3. GOAL DISTRIBUTION (Bar Chart)
// ======================================================================
const getGoalDistribution = async (req, res) => {
  try {
    const data = await UserDetails.aggregate([
      { $unwind: "$selectedSubGoals" },
      { $group: { _id: "$selectedSubGoals", count: { $sum: 1 } } },
      { $project: { name: "$_id", value: "$count", _id: 0 } },
      { $sort: { value: -1 } },
      { $limit: 10 }
    ]);
    res.json(data);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// ======================================================================
// 4. ALLERGY FREQUENCY (Bar Chart)
// ======================================================================
const getAllergyFrequency = async (req, res) => {
  try {
    const data = await UserDetails.aggregate([
      { $project: { concerns: { $objectToArray: "$healthConcerns" } } },
      { $unwind: "$concerns" },
      { $match: { "concerns.v": true } },
      { $group: { _id: "$concerns.k", count: { $sum: 1 } } },
      { $project: { name: "$_id", value: "$count", _id: 0 } },
      { $sort: { value: -1 } }
    ]);
    res.json(data);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// ======================================================================
// 5. USER GROWTH (Line Chart)
// ======================================================================
const getUserGrowth = async (req, res) => {
  try {
    const data = await User.aggregate([
      {
        $group: {
          _id: { $dateToString: { format: "%Y-%m-%d", date: "$createdAt" } },
          count: { $sum: 1 }
        }
      },
      { $sort: { _id: 1 } }
    ]);
    
    const formattedData = data.map(item => ({
      name: item._id,
      value: item.count
    }));
    
    res.json(formattedData);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const getAllUsers = async (req, res) => {
  try {
    // 1. Fetch data using .lean() to get Plain JavaScript Objects
    const details = await UserDetails.find()
      .populate('user', 'email')
      .select('healthConcerns selectedSubGoals user')
      .lean();

    const formattedUsers = details.map(detail => {
      if (!detail.user) return null;
      
      // 2. Get Goal
      let goal = 'General Health';
      if (detail.selectedSubGoals && detail.selectedSubGoals.length > 0) {
        goal = detail.selectedSubGoals[0];
      }

      // 3. Process Health Concerns
      let activeConcerns = [];
      if (detail.healthConcerns) {
        activeConcerns = Object.entries(detail.healthConcerns)
          .filter(([key, value]) => value === true || value === 'true') 
          .map(([key]) => key.charAt(0).toUpperCase() + key.slice(1));
      }
      
      const healthString = activeConcerns.length > 0 ? activeConcerns.join(', ') : 'None';

      return {
        id: detail.user._id,
        email: detail.user.email,
        healthConcerns: healthString,
        goal: goal
      };
    }).filter(u => u !== null);

    res.json(formattedUsers);
  } catch (error) {
    console.error("Error getting users:", error);
    res.status(500).json({ message: error.message });
  }
};

// ======================================================================
// 7. DELETE USER
// ======================================================================
const deleteUser = async (req, res) => {
  try {
    const userId = req.params.id;

    await User.findByIdAndDelete(userId);
    await UserDetails.findOneAndDelete({ user: userId });
    await MealPlan.deleteMany({ userId: userId });

    res.json({ message: 'User deleted successfully' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// ======================================================================
// 8. USER BMI DISTRIBUTION (Robust JS Version)
// ======================================================================
const getUserBMIStats = async (req, res) => {
  try {
    const users = await UserDetails.find()
      .select('height currentWeight')
      .lean();

    console.log(`[BMI Stats] Processing ${users.length} user records...`);

    const stats = {
      Underweight: 0,
      Healthy: 0,
      Overweight: 0,
      Obese: 0
    };

    let validCount = 0;

    users.forEach(user => {
      const parseValue = (val) => {
        if (!val) return 0;
        const str = String(val).replace(/[^0-9.]/g, '');
        return parseFloat(str) || 0;
      };

      const heightCm = parseValue(user.height);
      const weightKg = parseValue(user.currentWeight);

      if (heightCm > 0 && weightKg > 0) {
        const heightM = heightCm / 100;
        const bmi = weightKg / (heightM * heightM);

        if (bmi < 18.5) stats.Underweight++;
        else if (bmi < 25) stats.Healthy++;
        else if (bmi < 30) stats.Overweight++;
        else stats.Obese++;

        validCount++;
      }
    });

    console.log(`[BMI Stats] Calculated ${validCount} valid BMIs.`);

    const graphData = [
      { name: "Underweight", value: stats.Underweight },
      { name: "Healthy", value: stats.Healthy },
      { name: "Overweight", value: stats.Overweight },
      { name: "Obese", value: stats.Obese }
    ];

    res.json(graphData);

  } catch (error) {
    console.error("Error calculating BMI stats:", error);
    res.status(500).json({ message: error.message });
  }
};

const forgotPasswordInit = async (req, res) => {
  const { email } = req.body;

  try {
    const admin = await Admin.findOne({ email });
    if (!admin) {
      return res.status(404).json({ message: 'User does not exist' });
    }

    const otp = Math.floor(100000 + Math.random() * 900000).toString();

    await AdminVerification.deleteMany({ email });
    await AdminVerification.create({
      email,
      otp,
      tempUserData: { type: 'RESET_PASSWORD' }
    });

    await sendVerificationEmail(email, otp);

    res.json({ message: 'Verification code sent to your email' });

  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

const verifyResetOtp = async (req, res) => {
  const { email, otp } = req.body;

  try {
    const record = await AdminVerification.findOne({ email, otp });
    
    if (!record) {
      return res.status(400).json({ message: 'Invalid or expired code' });
    }

    res.json({ message: 'Code verified successfully' });

  } catch (error) {
    res.status(500).json({ message: 'Server error' });
  }
};

const resetPassword = async (req, res) => {
  const { email, otp, newPassword } = req.body;

  try {
    const record = await AdminVerification.findOne({ email, otp });
    if (!record) {
      return res.status(400).json({ message: 'Invalid code. Please try again.' });
    }

    const admin = await Admin.findOne({ email });
    if (!admin) {
      return res.status(404).json({ message: 'User not found' });
    }

    admin.password = newPassword;
    await admin.save();

    await AdminVerification.deleteMany({ email });

    res.json({ message: 'Password reset successfully' });

  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

module.exports = {
  getDashboardStats,
  getDietDistribution,
  getGoalDistribution,
  getAllergyFrequency,
  getUserGrowth,
  getAllUsers,
  deleteUser,
  getUserBMIStats,
  cleanupOrphans,
  signupInit,
  verifyAndCreate,
  loginAdmin,
  getAdminProfile,
  updateProfileInit,
  verifyNewEmail,
  changePassword,
  forgotPasswordInit,
  verifyResetOtp,
  resetPassword
};