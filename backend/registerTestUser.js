// registerTestUser.js
const axios = require('axios');

const BASE_URL = 'http://localhost:5000/api/auth'; // Change IP if testing on real device

async function registerUser() {
  try {
    const response = await axios.post(`${BASE_URL}/register`, {
      email: 'test@example.com',
      password: 'testpassword'
    });
    console.log('✅ User Registered:', response.data);
  } catch (error) {
    if (error.response) {
      console.error('❌ Registration Failed:', error.response.data);
    } else {
      console.error('❌ Error:', error.message);
    }
  }
}

registerUser();
// Run this script with Node.js to register a test user 