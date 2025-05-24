// testRoutes.js
const axios = require('axios');

const BASE_URL = 'http://localhost:5000/api'; // Adjust if using different port or IP

async function testAuthRoute() {
  try {
    const res = await axios.post(`${BASE_URL}/auth/login`, {
      email: 'test@example.com',
      password: 'testpassword'
    });
    console.log('/auth/login ➤ SUCCESS:', res.data);
  } catch (err) {
    console.error('/auth/login ➤ ERROR:', err.response ? err.response.data : err.message);
  }
}

async function testUsersRoute() {
  try {
    const res = await axios.get(`${BASE_URL}/users`);
    console.log('/users ➤ SUCCESS:', res.data);
  } catch (err) {
    console.error('/users ➤ ERROR:', err.response ? err.response.data : err.message);
  }
}

async function runTests() {
  console.log('🔍 Testing backend routes...');
  await testAuthRoute();
  await testUsersRoute();
}

runTests();
// Run this script with Node.js to test the backend routes
// Ensure the server is running before executing this script