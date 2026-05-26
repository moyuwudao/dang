const http = require('http');

console.log('=== 检查登录和 token ===\n');

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
    console.log(`登录响应状态码: ${loginRes.statusCode}`);
    console.log(`登录响应: ${loginBody}`);
    
    try {
      const loginJson = JSON.parse(loginBody);
      console.log('\n解析后的响应:');
      console.log(`  code: ${loginJson.code}`);
      console.log(`  message: ${loginJson.message}`);
      console.log(`  data.accessToken: ${loginJson.data?.accessToken ? '存在 (' + loginJson.data.accessToken.length + ' 字符)' : '缺失'}`);
      console.log(`  data.user:`, loginJson.data?.user);
      
      if (loginJson.data?.accessToken) {
        console.log('\n=== 测试用新 token 访问 /auth/me ===');
        
        const options = {
          hostname: '101.133.238.249',
          port: 80,
          path: '/api/v1/auth/me',
          method: 'GET',
          headers: {
            'Authorization': 'Bearer ' + loginJson.data.accessToken
          }
        };
        
        http.request(options, (res) => {
          let body = '';
          res.on('data', (chunk) => body += chunk);
          res.on('end', () => {
            console.log(`状态码: ${res.statusCode}`);
            console.log(`响应: ${body}`);
          });
        }).end();
      }
    } catch (e) {
      console.log('解析失败:', e.message);
    }
  });
});

loginReq.on('error', (e) => {
  console.error(`登录请求失败: ${e.message}`);
});

loginReq.write(loginData);
loginReq.end();
