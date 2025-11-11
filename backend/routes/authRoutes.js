const express = require('express');
const router = express.Router();
const User = require('../models/User'); // Your permanent User model
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const axios = require('axios');
const authMiddleware = require('../middleware/authMiddleware'); // For authenticated routes
require('dotenv').config();
const PendingUser = require('../models/pendingUser'); // Temporary OTP storage
const nodemailer = require('nodemailer');

// -------------------------------------------------------------------------
// ⚡️ EMAIL SENDING LOGIC (Helper Functions)
// -------------------------------------------------------------------------

// NOTE: Using hardcoded credentials as requested for immediate testing. 
// HIGHLY recommended to switch back to process.env in production.
const HARDCODED_USER = "undercovermysteries0@gmail.com"; 
const HARDCODED_PASS = "xpes oojs mvvh rlem"; 

/**
 * Sends a verification email for either registration, email update, or password reset.
 * @param {string} email - The recipient email address.
 * @param {string} otp - The 6-digit OTP code.
 * @param {string} type - 'register', 'update', or 'reset' to customize the email content.
 */
const sendEmail = async (email, otp, type = 'register') => {
    // 1. Create Transporter (reused for all emails)
    const transporter = nodemailer.createTransport({
        service: 'gmail',
        auth: {
            user: HARDCODED_USER, 
            pass: HARDCODED_PASS, 
        },
    });

    let subject, welcomeMessage;

    if (type === 'update') {
        subject = 'Email Change Verification Code';
        welcomeMessage = `
            <h2 style="color: #333;">Confirm Your Email Change</h2>
            <p>You requested to change your email address. Please use the code below to complete the update:</p>
        `;
    } else if (type === 'reset') { // <<< LOGIC FOR PASSWORD RESET
        subject = 'Password Reset Verification Code';
        welcomeMessage = `
            <h2 style="color: #333;">Password Reset Request</h2>
            <p>You requested a password reset. Please use the code below to verify your identity and set a new password:</p>
        `;
    } else { // default to 'register'
        subject = 'Your Account Verification Code';
        welcomeMessage = `
            <h2 style="color: #333;">Welcome to the Foodie Club!</h2>
            <p>Thank yourself for registering. Please use the following code to verify your account:</p>
        `;
    }

    // 2. Define the email content
    const mailOptions = {
        from: `Nutriwise Support <${HARDCODED_USER}>`,
        to: email,
        subject: subject,
        html: `
            <div style="font-family: Arial, sans-serif; padding: 20px; border: 1px solid #ddd; border-radius: 10px; text-align: center;">
                ${welcomeMessage}
                <div style="background-color: #f0f0f0; padding: 15px; border-radius: 8px; margin: 20px 0;">
                    <strong style="font-size: 24px; color: #ff5722;">${otp}</strong>
                </div>
                <p style="font-size: 14px; color: #888;">This code is valid for 5 minutes.</p>
                <p>If you did not request this, please ignore this email.</p>
            </div>
        `,
    };

    // 3. Send the email
    try {
        const info = await transporter.sendMail(mailOptions);
        console.log(`✅ Email sent: ${info.response} to ${email}`);
        return true;
    } catch (error) {
        console.error("❌ Nodemailer failed to send email:", error.message);
        throw new Error('Failed to send verification email. Please check server logs.'); 
    }
};

// Helper function for registration route compatibility
const sendVerificationEmail = (email, otp) => sendEmail(email, otp, 'register');


// =========================================================================
// 1. REGISTRATION ROUTES (EXISTING)
// =========================================================================

// POST /api/auth/send-otp
router.post('/send-otp', async (req, res) => {
    const { email, password } = req.body;
    
    if (!email || !password) {
        return res.status(400).json({ message: 'Email and password are required.' });
    }

    try {
        // 2. Check if user already exists in permanent database
        let user = await User.findOne({ email }).select('email').lean();
        if (user) {
            return res.status(400).json({ message: 'User already exists' });
        }

        // 3. Generate OTP (Password is stored as plain-text in PendingUser)

        const otp = Math.floor(100000 + Math.random() * 900000).toString(); // 6-digit OTP
        const otpExpires = new Date(Date.now() + 5 * 60 * 1000); // 5 minutes from now

        // 4. Save/Update to PendingUser
        await PendingUser.findOneAndUpdate(
            { email },
            {
                password: password, // Store plain password here
                otp,
                otpExpires,
            },
            { upsert: true, new: true, runValidators: true }
        );

        // 5. Send OTP Email
        await sendVerificationEmail(email, otp);

        console.log(`✅ OTP sent and PendingUser created for: ${email}`);
        res.status(200).json({ message: 'Verification code sent to email.' });

    } catch (err) {
        console.error('Send OTP server error:', err.message);
        res.status(500).json({ message: 'Server error during OTP request' });
    }
});

// POST /api/auth/verify-otp
router.post('/verify-otp', async (req, res) => {
    const { email, otp } = req.body;

    if (!email || !otp) {
        return res.status(400).json({ message: 'Email and OTP are required.' });
    }

    try {
        // 1. Find and validate PendingUser record
        const pendingUser = await PendingUser.findOne({ email });

        if (!pendingUser) {
            return res.status(400).json({ message: 'Verification record not found. Please re-register.' });
        }

        // Check if OTP has expired
        if (pendingUser.otpExpires < Date.now()) {
            await pendingUser.deleteOne();
            return res.status(400).json({ message: 'OTP has expired. Please request a new one.' });
        }

        // Check if OTP matches
        if (pendingUser.otp !== otp) {
            return res.status(400).json({ message: 'Invalid verification code.' });
        }

        // 2. Create new user in permanent database
        let user = new User({ 
            email: pendingUser.email, 
            password: pendingUser.password // Pass the plain-text value
        });
        await user.save(); // Hashing is done automatically by UserSchema.pre('save')

        // 3. Spoonacular connect logic
        try {
            const spoonacularRes = await axios.post(
                `https://api.spoonacular.com/users/connect`,
                { username: user.id },
                { params: { apiKey: process.env.SPOONACULAR_API_KEY } }
            );
            user.spoonacular = {
                username: spoonacularRes.data.username,
                hash: spoonacularRes.data.hash
            };
            // Note: Since no password field is modified, this save does not re-hash.
            await user.save(); 
            console.log(`✅ Spoonacular connected for new user: ${user.email}`);
        } catch (spoonErr) {
            console.error("Spoonacular connect failed:", spoonErr.response?.data || spoonErr.message);
        }

        // 4. Delete the temporary PendingUser record
        await pendingUser.deleteOne();

        // 5. Generate and return JWT
        const payload = {
            user: { id: user.id },
        };

        jwt.sign(
            payload,
            process.env.JWT_SECRET,
            { expiresIn: '30d' },
            (err, token) => {
                if (err) throw err;
                res.status(201).json({
                    message: "User registered, verified, & connected to Spoonacular",
                    token,
                    email: user.email,
                    userId: user.id, 
                });
            }
        );

    } catch (err) {
        console.error('Verify OTP server error:', err.message);
        if (err.code && err.code === 11000) {
           return res.status(400).json({ message: 'User already exists (Duplicate key error)' });
        }
        res.status(500).json({ message: 'Server error during verification' });
    }
});


// =========================================================================
// 2. EMAIL UPDATE ROUTES (Authenticated) (EXISTING)
// =========================================================================

// POST /api/auth/send-update-otp
router.post('/send-update-otp', authMiddleware.protect, async (req, res) => {
    const currentUserId = req.user.id; 
    const { newEmail } = req.body;

    if (!newEmail) {
        return res.status(400).json({ message: 'New email address is required.' });
    }

    try {
        // 1. Check if the new email is already in use by a DIFFERENT user
        const existingUser = await User.findOne({ email: newEmail }).select('_id').lean();
        if (existingUser && existingUser._id.toString() !== currentUserId) {
            return res.status(400).json({ message: 'This email is already registered to another account.' });
        }

        // 2. Generate OTP
        const otp = Math.floor(100000 + Math.random() * 900000).toString(); // 6-digit OTP
        const otpExpires = new Date(Date.now() + 5 * 60 * 1000); // 5 minutes

        // 3. Save/Update pending change record using the newEmail as the key
        await PendingUser.findOneAndUpdate(
            { email: newEmail }, 
            {
                email: newEmail, 
                otp: otp,
                otpExpires: otpExpires,
            },
            { upsert: true, new: true, runValidators: false } 
        );

        // 4. Send OTP Email to the NEW email address
        await sendEmail(newEmail, otp, 'update');

        console.log(`✅ Update OTP sent and PendingUser record created for user: ${currentUserId}`);
        res.status(200).json({ message: 'Verification code sent to the new email.' });

    } catch (err) {
        console.error('Send Update OTP server error:', err.message);
        res.status(500).json({ message: 'Server error during OTP request' });
    }
});

// POST /api/auth/verify-update-email
router.post('/verify-update-email', authMiddleware.protect, async (req, res) => {
    const currentUserId = req.user.id; 
    const { otp, newEmail } = req.body; 

    if (!otp || !newEmail) {
        return res.status(400).json({ message: 'OTP and new email are required.' });
    }

    try {
        // 1. Find and validate the pending record by the newEmail
        const pendingRecord = await PendingUser.findOne({ email: newEmail }); 
        
        if (!pendingRecord) {
            return res.status(400).json({ message: 'No pending email change request found for this email.' });
        }
        
        // 2. Check if OTP has expired
        if (pendingRecord.otpExpires < Date.now()) {
            await pendingRecord.deleteOne();
            return res.status(400).json({ message: 'OTP has expired. Please request a new code.' });
        }

        // 3. Check if OTP matches
        if (pendingRecord.otp !== otp) {
            return res.status(400).json({ message: 'Invalid verification code.' });
        }

        // 4. Verification successful: Update the permanent User record
        const updatedUser = await User.findByIdAndUpdate(
            currentUserId,
            { email: pendingRecord.email }, // This uses the verified new email
            { new: true, runValidators: false, select: 'email' } 
        );

        if (!updatedUser) {
            return res.status(404).json({ message: 'User not found for update.' });
        }

        // 5. Delete the temporary PendingUser record
        await pendingRecord.deleteOne();
        
        console.log(`✅ User ${currentUserId} email updated to: ${updatedUser.email}`);
        res.status(200).json({
            message: "Email successfully updated.",
            newEmail: updatedUser.email
        });

    } catch (err) {
        console.error('Verify Email Update server error:', err.message);
        res.status(500).json({ message: 'Server error during email update verification' });
    }
});

// POST /api/auth/change-password
router.post('/change-password',authMiddleware.protect, async (req, res) => {
    const { oldPassword, newPassword } = req.body;

    console.log("kkkkkkkkkkkkkkkkkkkkkklllllllllllllllll")
    console.log(oldPassword);
    console.log(newPassword);


    if (!oldPassword || !newPassword) {
        return res.status(400).json({ 
            message: 'Please provide both the current and new passwords.' 
        });
    }
    
    // Basic validation for new password strength (optional, but recommended)
    if (newPassword.length < 6) {
        return res.status(400).json({ 
            message: 'New password must be at least 6 characters long.' 
        });
    }

    try {
        // 1. Find the user based on the ID attached by the 'protect' middleware
        // FIX: Use req.user.id for consistency with other authenticated routes
        const user = await User.findById(req.user.id); 

        if (!user) {
            return res.status(404).json({ message: 'User not found.' });
        }

        // 2. Securely compare the current plaintext password with the stored hash
        console.log(user.password);
        const isMatch = await bcrypt.compare(oldPassword, user.password);
        
        // Removed explicit hashing logic (const salt = ..., const hashedPassword = ...)
        // as this is handled by the Mongoose User model's pre('save') hook.
        
        if (!isMatch) {
            return res.status(401).json({ message: 'Incorrect current password.' });
        }
        
        // 3. Update the user's password field with the PLAIN new password.
        // The Mongoose pre('save') hook will automatically hash this on the next line.
        user.password = newPassword;

        // 4. Save the updated user document
        await user.save();

        res.json({ message: 'Password updated successfully.' });

    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error during password change.' });
    }
});


// =========================================================================
// 3. LOGIN & DELETE ROUTES (EXISTING)
// =========================================================================

// POST /api/auth/login
router.post('/login', async (req, res) => {
    const { email, password } = req.body;
    try {
        const user = await User.findOne({ email });
        if (!user) {
            return res.status(400).json({ message: 'Invalid credentials' });
        }
        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) {
            return res.status(400).json({ message: 'Invalid credentials' });
        }
        
        const payload = {
            user: {
                id: user.id,
            },
        };
        jwt.sign(
            payload,
            process.env.JWT_SECRET,
            { expiresIn: '5h' },
            (err, token) => {
                if (err) throw err;
                res.status(200).json({
                    token,
                    user: user.id, // CRITICAL: user ID for client-side storage
                    email: user.email,
                });
            }
        );
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server error');
    }
});

// DELETE /api/auth/delete
router.delete('/delete', authMiddleware.protect, async (req, res) => {
    try {
        const userId = req.user.id; 
        
        const user = await User.findById(userId);

        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }
        
        // You could add logic here to delete the user from Spoonacular
        
        await user.deleteOne();
        res.status(200).json({ message: 'Account deleted successfully' });

    } catch (err) {
        console.error(`Error deleting account for user ${req.user?.id}: ${err.message}`);
        res.status(500).send('Server error during account deletion.');
    }
});

// =========================================================================
// 4. PASSWORD RESET & USER INFO ROUTES (NEW)
// =========================================================================

// POST /api/auth/forgot-password // Corrected route to match Dart client's sendPasswordResetOtp URL
// Initiates the password reset process by sending an OTP to the user's email.
router.post('/forgot-password', async (req, res) => {
    const { email } = req.body;

    if (!email) {
        return res.status(400).json({ message: 'Email address is required.' });
    }

    try {
        // 1. Check if user exists in permanent database
        const user = await User.findOne({ email }).select('email').lean();
        if (!user) {
            // Use 404 or 200/202 to prevent email enumeration (here using 404 for clarity)
            return res.status(404).json({ message: 'User not found with this email address.' });
        }

        // 2. Generate OTP
        const otp = Math.floor(100000 + Math.random() * 900000).toString();
        const otpExpires = new Date(Date.now() + 5 * 60 * 1000); // 5 minutes

        // 3. Save/Update to PendingUser (without storing a password)
        await PendingUser.findOneAndUpdate(
            { email },
            {
                otp,
                otpExpires,
                password: undefined // Explicitly remove/omit password for this flow
            },
            { upsert: true, new: true, runValidators: true }
        );

        // 4. Send OTP Email for password reset
        await sendEmail(email, otp, 'reset');

        console.log(`✅ Password Reset OTP sent and PendingUser created for: ${email}`);
        res.status(200).json({ message: 'Verification code sent to email to reset password.' });

    } catch (err) {
        console.error('Forgot Password Send OTP server error:', err.message);
        res.status(500).json({ message: 'Server error during password reset OTP request' });
    }
});

// POST /api/auth/reset-password // Corrected route to match Dart client's resetPassword URL
// Performs the final password reset using email, OTP, and the new password in a single step 
// (combining the client's verify and reset calls into one, based on the original server logic).
router.post('/reset-password', async (req, res) => {
    const { email, otp, newPassword } = req.body;

    // NOTE: The Dart client's resetPassword method only sends email and newPassword,
    // so this combined endpoint will require the client to be updated to send the OTP too, 
    // OR the Dart client's intermediate verifyPasswordResetOtp must be removed.
    // Assuming the client will be updated to send all three for this route.
    if (!email || !otp || !newPassword) {
        return res.status(400).json({ message: 'Email, OTP, and new password are required.' });
    }

    if (newPassword.length < 6) {
        return res.status(400).json({ message: 'New password must be at least 6 characters long.' });
    }

    try {
        // 1. Find and validate PendingUser record
        const pendingUser = await PendingUser.findOne({ email });

        if (!pendingUser) {
            return res.status(400).json({ message: 'Password reset request not found. Please request again.' });
        }

        // Check if OTP has expired
        if (pendingUser.otpExpires < Date.now()) {
            await pendingUser.deleteOne();
            return res.status(400).json({ message: 'OTP has expired. Please request a new one.' });
        }

        // Check if OTP matches
        if (pendingUser.otp !== otp) {
            return res.status(400).json({ message: 'Invalid verification code.' });
        }

        // 2. Verification successful: Find and update the permanent User
        const user = await User.findOne({ email });

        if (!user) {
            return res.status(404).json({ message: 'User not found in permanent database.' });
        }

        // 3. Update and hash the new password
        user.password = newPassword;
        await user.save(); // Hashing is done automatically by UserSchema.pre('save')

        // 4. Delete the temporary PendingUser record
        await pendingUser.deleteOne();

        console.log(`✅ User ${email} password successfully reset.`);
        res.status(200).json({ message: "Password successfully reset. You can now log in." });

    } catch (err) {
        console.error('Reset Password server error:', err.message);
        res.status(500).json({ message: 'Server error during password reset' });
    }
});

// GET /api/auth/me
// Matches Dart client's fetchUserDetails
// Retrieves the current authenticated user's details (excluding the password hash).
router.get('/me', authMiddleware.protect, async (req, res) => {
    try {
        // Find user by ID attached by authMiddleware and select all fields EXCEPT password
        const user = await User.findById(req.user.id).select('-password');

        if (!user) {
            return res.status(404).json({ message: 'User not found.' });
        }

        // Return the user data
        res.status(200).json(user);

    } catch (err) {
        console.error('GET /me server error:', err.message);
        res.status(500).json({ message: 'Server error fetching user details' });
    }
});


module.exports = router;