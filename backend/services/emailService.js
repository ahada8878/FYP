// services/emailService.js (Using Nodemailer example)

const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
    // Configure your email service here (e.g., Gmail, SendGrid SMTP, etc.)
    service: 'Gmail', // Example
    auth: {
        user: 'YOUR_EMAIL@gmail.com',
        pass: 'YOUR_EMAIL_PASSWORD_OR_APP_KEY' 
    }
});

const sendVerificationEmail = async (toEmail, otpCode) => {
    const mailOptions = {
        from: 'YOUR_EMAIL@gmail.com',
        to: toEmail,
        subject: 'Your Foodie Club Verification Code',
        html: `
            <h1>Welcome to Foodie Club!</h1>
            <p>Use the following code to complete your registration. This code is valid for 5 minutes:</p>
            <h2 style="color: #FF5733;">${otpCode}</h2>
            <p>If you did not request this, please ignore this email.</p>
        `,
    };

    try {
        await transporter.sendMail(mailOptions);
        console.log('Verification email sent successfully to', toEmail);
    } catch (error) {
        console.error('Nodemailer Error:', error);
        throw new Error('Failed to send verification email.');
    }
};

module.exports = { sendVerificationEmail };