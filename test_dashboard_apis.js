const http = require('http');

console.log('=== 测试 Dashboard 登录后调用的 API ===\n');

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
    
    // 按顺序测试 Dashboard 页面可能调用的 API
    testAPI('/api/v1/admin/stats', token, '统计信息');
    
    // 延迟一下再测试其他 API，模拟前端加载顺序
    setTimeout(() => {
      testAPI('/api/v1/admin/plans', token, '套餐列表');
      testAPI('/api/v1/admin/users', token, '用户列表');
      testAPI('/api/v1/api-key/admin/list', token, 'API Keys');
    }, 500);
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
        console.log('解析后的 JSON:');
        console.log(`  code: ${json.code}`);
        console.log(`  message: ${json.message}`);
        console.log(`  data 类型: ${typeof json.data}`);
        if (json.data) {
          console.log(`  data 内容: ${JSON.stringify(json.data)}`);
        }
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
