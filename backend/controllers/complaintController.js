const Complaint = require('../models/Complaint');
const nodemailer = require('nodemailer');

// --- Helper: Send Resolution Email ---
const sendResolutionEmail = async (email, subject) => {
  console.log(`📧 [Email Service] Sending resolution email to: ${email}`);

  if (!process.env.EMAIL_USER || !process.env.EMAIL_PASS) {
    console.error(`❌ Missing EMAIL credentials in .env`);
    return;
  }

  try {
    const transporter = nodemailer.createTransport({
      service: 'gmail',
      auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS
      }
    });

    await transporter.sendMail({
      from: `"NutriWise Support" <${process.env.EMAIL_USER}>`,
      to: email,
      subject: '✅ Complaint Resolved - NutriWise',
      html: `
        <div style="font-family: Arial, sans-serif; padding: 20px;">
          <h2 style="color: #10B981;">Complaint Resolved</h2>
          <p>Hello,</p>
          <p>We are writing to inform you that your complaint regarding <strong>"${subject}"</strong> has been reviewed and resolved.</p>
          <p>Thank you for your patience.</p>
          <br>
          <p style="color: #6B7280; font-size: 12px;">NutriWise Support Team</p>
        </div>
      `
    });
    console.log(`✅ Email sent successfully.`);
  } catch (error) {
    console.error("❌ Failed to send email:", error);
  }
};

// 1. Create Complaint
const createComplaint = async (req, res) => {
  try {
    const { email, subject, message } = req.body;
    const userId = req.userId || (req.user && req.user._id);

    if (!userId || !email || !subject || !message) {
        return res.status(400).json({ success: false, message: 'Missing required fields' });
    }

    const newComplaint = new Complaint({
      user: userId,
      email,
      subject,
      message,
      status: 'UNRESOLVED'
    });

    await newComplaint.save();
    res.status(201).json({ success: true, message: 'Complaint submitted.' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// 2. Get All Complaints
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

// 3. Update Status
const updateComplaintStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    const complaint = await Complaint.findByIdAndUpdate(
      id,
      { status },
      { new: true }
    );

    if (!complaint) return res.status(404).json({ message: 'Complaint not found' });

    // Trigger email only on Resolve
    if (status === 'RESOLVED') {
      sendResolutionEmail(complaint.email, complaint.subject);
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