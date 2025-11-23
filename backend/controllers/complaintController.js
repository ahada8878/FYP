const Complaint = require('../models/Complaint');

// 1. Create Complaint (For Flutter App)
const createComplaint = async (req, res) => {
  try {
    const { email, subject, message } = req.body;
    
    // Extract User ID from the Token (set by auth middleware)
    // We check both req.userId and req.user._id to handle different middleware styles
    const userId = req.userId || (req.user && req.user._id);

    if (!userId) {
        return res.status(401).json({ success: false, message: 'User not authenticated.' });
    }

    if (!email || !subject || !message) {
      return res.status(400).json({ 
        success: false, 
        message: 'Please provide email, subject, and message.' 
      });
    }

    const newComplaint = new Complaint({
      user: userId,
      email,
      subject,
      message,
      status: 'UNRESOLVED'
    });

    await newComplaint.save();

    res.status(201).json({
      success: true,
      message: 'Complaint registered successfully.'
    });

  } catch (error) {
    console.error("Error creating complaint:", error);
    res.status(500).json({ success: false, message: 'Server error.' });
  }
};

// 2. Get All Complaints (For Admin Panel)
const getAllComplaints = async (req, res) => {
  try {
    const complaints = await Complaint.find()
      .sort({ createdAt: -1 })
      .populate('user', 'name email'); 
    res.json(complaints);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// 3. Update Status (For Admin Panel)
const updateComplaintStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    const complaint = await Complaint.findByIdAndUpdate(
      id,
      { status },
      { new: true }
    );

    if (!complaint) {
      return res.status(404).json({ message: 'Complaint not found' });
    }

    res.json({ success: true, complaint });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

module.exports = {
  createComplaint,
  getAllComplaints,
  updateComplaintStatus
};