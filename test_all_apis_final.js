const http = require('http');

console.log('=== 测试所有 API 返回格式 ===\n');

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
    console.log('✅ 登录成功');
    console.log('Token 获取成功\n');
    
    // 测试所有 API
    const apis = [
      { path: '/api/v1/admin/stats', name: '统计信息' },
      { path: '/api/v1/admin/plans', name: '套餐列表' },
      { path: '/api/v1/admin/users', name: '用户列表' },
      { path: '/api/v1/admin/subscriptions', name: '订阅列表' },
      { path: '/api/v1/admin/recharge-records', name: '充值记录' },
      { path: '/api/v1/admin/charts/user-growth?days=7', name: '用户增长' },
      { path: '/api/v1/admin/charts/revenue-trend?days=7', name: '收入趋势' },
      { path: '/api/v1/api-key/admin/list', name: 'API Keys' },
      { path: '/api/v1/monitor/system', name: '系统监控' },
      { path: '/api/v1/monitor/services', name: '服务状态' },
      { path: '/api/v1/auth/me', name: '用户信息' },
      { path: '/api/v1/subscription/plans', name: '订阅套餐' },
      { path: '/api/v1/subscription/balance', name: '用户余额' },
    ];
    
    apis.forEach((api, index) => {
      setTimeout(() => {
        testAPI(api.path, api.name, token);
      }, index * 100);
    });
  });
});

loginReq.write(loginData);
loginReq.end();

function testAPI(path, name, token) {
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
      
      try {
        const json = JSON.parse(body);
        const hasCode = 'code' in json;
        const hasMessage = 'message' in json;
        const hasData = 'data' in json;
        
        if (hasCode && hasMessage && hasData) {
          console.log('✅ 返回格式正确: {code, message, data}');
        } else {
          console.log('❌ 返回格式不正确');
          console.log('  code:', hasCode ? '存在' : '缺失');
          console.log('  message:', hasMessage ? '存在' : '缺失');
          console.log('  data:', hasData ? '存在' : '缺失');
        }
        
        console.log('');
      } catch (e) {
        console.log('❌ 解析失败:', e.message);
        console.log('');
      }
    });
  });
  
  req.on('error', (e) => {
    console.log(`❌ ${name}: ${e.message}\n`);
  });
  
  req.end();
}
