const http = require('http');

console.log('=== 测试 Monitor API ===\n');

const loginData = JSON.stringify({
  phone: '18682092379',
  password: 'Hu123456'
});

const loginOptions = {
  hostname: '101.133.238.249',
  port: 80,
  path: '/api/v1/auth/login',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(loginData)
  }
};

const loginReq = http.request(loginOptions, (loginRes) => {
  let loginBody = '';
  loginRes.on('data', (chunk) => {
    loginBody += chunk;
  });
  
  loginRes.on('end', () => {
    const loginJson = JSON.parse(loginBody);
    const token = loginJson.data.accessToken;
    console.log('✅ 登录成功\n');
    
    // 测试 monitor API
    testAPI('/api/v1/monitor/system', token, '系统信息');
    testAPI('/api/v1/monitor/services', token, '服务状态');
  });
});

loginReq.write(loginData);
loginReq.end();

function testAPI(path, token, name) {
  const options = {
    hostname: '101.133.238.249',
    port: 80,
    path: path,
    method: 'GET',
    headers: {
      'Authorization': 'Bearer ' + token
    }
  };
  
  const req = http.request(options, (res) => {
    let body = '';
    res.on('data', (chunk) => {
      body += chunk;
    });
    
    res.on('end', () => {
      console.log(`=== ${name} (${path}) ===`);
      console.log(`状态码: ${res.statusCode}`);
      console.log(`响应体: ${body}`);
      console.log('');
      
      try {
        const json = JSON.parse(body);
        console.log('解析后的 JSON:', JSON.stringify(json, null, 2));
      } catch (e) {
        console.log('解析失败:', e.message);
      }
      console.log('');
    });
  });
  
  req.on('error', (e) => {
    console.log(`❌ ${name}: ${e.message}\n`);
  });
  
  req.end();
}
