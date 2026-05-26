const http = require('http');

const data = JSON.stringify({
  phone: '13800138001',
  password: 'ChangJi@2026#Admin!'
});

const options = {
  hostname: '127.0.0.1',
  port: 3000,
  path: '/api/v1/auth/login',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(data)
  }
};

const req = http.request(options, (res) => {
  let body = '';
  res.on('data', (chunk) => body += chunk);
  res.on('end', () => {
    console.log('Status:', res.statusCode);
    console.log('Response:', body);
    
    if (res.statusCode === 200 || res.statusCode === 201) {
      const result = JSON.parse(body);
      if (result.data && result.data.accessToken) {
        console.log('\n--- Testing Admin API with token ---');
        testAdminAPI(result.data.accessToken);
      }
    }
  });
});

req.on('error', (e) => console.error('Error:', e.message));
req.write(data);
req.end();

function testAdminAPI(token) {
  const options2 = {
    hostname: '127.0.0.1',
    port: 3000,
    path: '/api/v1/admin/stats',
    method: 'GET',
    headers: {
      'Authorization': 'Bearer ' + token
    }
  };
  
  const req2 = http.request(options2, (res) => {
    let body = '';
    res.on('data', (chunk) => body += chunk);
    res.on('end', () => {
      console.log('Admin API Status:', res.statusCode);
      console.log('Admin API Response:', body);
    });
  });
  req2.on('error', (e) => console.error('Admin API Error:', e.message));
  req2.end();
}