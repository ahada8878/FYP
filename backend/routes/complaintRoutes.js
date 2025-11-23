const express = require('express');
const router = express.Router();
const complaintController = require('../controllers/complaintController');
const authMiddleware = require('../middleware/authMiddleware');


router.post('/create', authMiddleware.protect, complaintController.createComplaint);

// Admin Routes
router.get('/', complaintController.getAllComplaints);
router.patch('/:id/status', complaintController.updateComplaintStatus);

module.exports = router;