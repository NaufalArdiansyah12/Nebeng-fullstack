// testServer.js - Jalankan untuk test apakah server berjalan
async function testServer() {
  console.log('🔍 Testing server connection...\n');

  // Test 1: Health check
  try {
    console.log('1️⃣  Testing health endpoint: http://localhost:3001/api/health');
    const healthResponse = await fetch('http://localhost:3001/api/health');
    const healthData = await healthResponse.json();
    console.log('✅ Health check:', healthData);
  } catch (error) {
    console.error('❌ Health check failed:', error.message);
    console.log('⚠️  Server mungkin tidak berjalan di port 3001!\n');
    return;
  }

  // Test 2: Login dengan kredensial yang salah (untuk test endpoint)
  try {
    console.log('\n2️⃣  Testing login endpoint: http://localhost:3001/api/auth/login');
    const loginResponse = await fetch('http://localhost:3001/api/auth/login', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        email: 'test@test.com',
        password: 'wrongpassword'
      }),
    });
    const loginData = await loginResponse.json();
    console.log('✅ Login endpoint response:', loginData);
    console.log('(Expected: error message karena kredensial salah)');
  } catch (error) {
    console.error('❌ Login endpoint failed:', error.message);
  }

  console.log('\n✅ Server test completed!');
}

testServer();