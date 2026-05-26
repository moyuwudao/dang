const http = require('http');

console.log('=== 测试新账户登录 ===');
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
