const express = require('express');
const router = express.Router();
const webController = require('../controllers/webController');
const { protectAdmin } = require('../middleware/adminAuthMiddleware');

// Dashboard Overview
router.get('/stats', webController.getDashboardStats); // Returns { totalUsers, totalMealPlans }
router.get('/diets', webController.getDietDistribution);
router.get('/goals', webController.getGoalDistribution);
router.get('/allergies', webController.getAllergyFrequency);

// Analytics Page
router.get('/user-growth', webController.getUserGrowth);
router.get('/users-list', webController.getAllUsers);
router.delete('/users/:id', webController.deleteUser);
router.get('/bmi-distribution', webController.getUserBMIStats);
router.delete('/cleanup', webController.cleanupOrphans);
router.post('/signup-init', webController.signupInit);
router.post('/signup-verify', webController.verifyAndCreate);
router.post('/login', webController.loginAdmin);
router.get('/profile', protectAdmin, webController.getAdminProfile);
router.put('/settings/profile', protectAdmin, webController.updateProfileInit);
router.post('/settings/verify-email', protectAdmin, webController.verifyNewEmail);
router.put('/settings/password', protectAdmin, webController.changePassword);
router.post('/forgot-password-init', webController.forgotPasswordInit);
router.post('/forgot-password-verify', webController.verifyResetOtp);
router.post('/reset-password', webController.resetPassword);

module.exports = router;