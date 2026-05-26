const http = require('http');

// 先登录获取 token
console.log('=== 1. 登录获取 token ===');
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
    
    // 测试所有 Admin API
    testAPI('/api/v1/admin/stats', token, '统计信息');
    testAPI('/api/v1/admin/plans', token, '套餐列表');
    testAPI('/api/v1/admin/users', token, '用户列表');
    testAPI('/api/v1/admin/subscriptions', token, '订阅列表');
    testAPI('/api/v1/admin/recharge-records', token, '充值记录');
    testAPI('/api/v1/admin/charts/user-growth?days=7', token, '用户增长');
    testAPI('/api/v1/admin/charts/revenue-trend?days=7', token, '收入趋势');
    testAPI('/api/v1/api-key/admin/list', token, 'API Keys');
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
      try {
        const json = JSON.parse(body);
        if (res.statusCode === 200) {
          console.log(`✅ ${name}: OK`);
          console.log(`   响应: ${JSON.stringify(json).substring(0, 100)}...`);
        } else {
          console.log(`❌ ${name}: ${res.statusCode}`);
          console.log(`   响应: ${JSON.stringify(json)}`);
        }
      } catch (e) {
        console.log(`❌ ${name}: 解析错误`);
        console.log(`   响应: ${body}`);
      }
      console.log('');
    });
  });
  
  req.on('error', (e) => {
    console.log(`❌ ${name}: ${e.message}\n`);
  });
  
  req.end();
}
