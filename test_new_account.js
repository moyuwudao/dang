const http = require('http');

// 1. 注册用户
console.log('正在注册新用户...');
const registerData = JSON.stringify({
  phone: '18682092379',
  password: 'Hu123456',
  smsCode: '123456'
});

const registerOptions = {
  hostname: '101.133.238.249',
  port: 80,
  path: '/api/v1/auth/register',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(registerData)
  }
};

const registerReq = http.request(registerOptions, (registerRes) => {
  let registerBody = '';
  registerRes.on('data', (chunk) => {
    registerBody += chunk;
  });
  
  registerRes.on('end', () => {
    console.log(`注册响应状态码: ${registerRes.statusCode}`);
    try {
      const registerJson = JSON.parse(registerBody);
      console.log('注册响应:', JSON.stringify(registerJson, null, 2));
      
      if (registerJson.code === 200 || registerRes.statusCode === 201) {
        console.log('\n✅ 用户注册成功！现在需要更新角色为管理员');
        
        // 登录获取 token
        testLogin();
      }
    } catch (e) {
      console.log('注册响应:', registerBody);
      testLogin();
    }
  });
});

registerReq.on('error', (e) => {
  console.error(`注册请求遇到问题: ${e.message}`);
});

registerReq.write(registerData);
registerReq.end();

function testLogin() {
  console.log('\n\n=== 测试新账户登录 ===');
  const testLoginData = JSON.stringify({
    phone: '18682092379',
    password: 'Hu123456'
  });
  
  const testLoginOptions = {
    hostname: '101.133.238.249',
    port: 80,
    path: '/api/v1/auth/login',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(testLoginData)
    }
  };
  
  const testLoginReq = http.request(testLoginOptions, (testLoginRes) => {
    let testLoginBody = '';
    testLoginRes.on('data', (chunk) => {
      testLoginBody += chunk;
    });
    
    testLoginRes.on('end', () => {
      try {
        const testLoginJson = JSON.parse(testLoginBody);
        console.log('登录响应:', JSON.stringify(testLoginJson, null, 2));
        
        if (testLoginJson.code === 200 || testLoginRes.statusCode === 201) {
          console.log('\n✅ 登录成功！');
          
          if (testLoginJson.data && testLoginJson.data.accessToken) {
            console.log('\n用户信息:', testLoginJson.data.user);
            testAdminAPI(testLoginJson.data.accessToken);
          }
        }
      } catch (e) {
        console.log('登录响应:', testLoginBody);
      }
    });
  });
  
  testLoginReq.on('error', (e) => {
    console.error(`登录请求遇到问题: ${e.message}`);
  });
  
  testLoginReq.write(testLoginData);
  testLoginReq.end();
}

function testAdminAPI(token) {
  console.log('\n\n=== 测试管理员API ===');
  
  const testAdminOptions = {
    hostname: '101.133.238.249',
    port: 80,
    path: '/api/v1/admin/stats',
    method: 'GET',
    headers: {
      'Authorization': 'Bearer ' + token
    }
  };
  
  const testAdminReq = http.request(testAdminOptions, (testAdminRes) => {
    let testAdminBody = '';
    testAdminRes.on('data', (chunk) => {
      testAdminBody += chunk;
    });
    
    testAdminRes.on('end', () => {
      try {
        const testAdminJson = JSON.parse(testAdminBody);
        console.log('管理员API响应:', JSON.stringify(testAdminJson, null, 2));
        
        if (testAdminRes.statusCode === 200) {
          console.log('\n🎉 管理员权限验证成功！');
        }
      } catch (e) {
        console.log('管理员API响应:', testAdminBody);
      }
    });
  });
  
  testAdminReq.on('error', (e) => {
    console.error(`管理员API请求遇到问题: ${e.message}`);
  });
  
  testAdminReq.end();
}
