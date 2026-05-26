const http = require('http');

const postData = JSON.stringify({
  phone: '13800138001',
  password: 'ChangJi@2026#Admin!'
});

const options = {
  hostname: '101.133.238.249',
  port: 80,
  path: '/api/v1/auth/login',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(postData)
  }
};

const req = http.request(options, (res) => {
  console.log(`状态码: ${res.statusCode}`);
  console.log(`响应头: ${JSON.stringify(res.headers)}`);
  
  let body = '';
  res.on('data', (chunk) => {
    body += chunk;
  });
  
  res.on('end', () => {
    console.log('响应体:');
    try {
      const json = JSON.parse(body);
      console.log(JSON.stringify(json, null, 2));
      
      if (json.data && json.data.accessToken) {
        console.log('\n=== 测试管理员API ===');
        testAdminAPI(json.data.accessToken);
      }
    } catch (e) {
      console.log(body);
    }
  });
});

req.on('error', (e) => {
  console.error(`请求遇到问题: ${e.message}`);
});

req.write(postData);
req.end();

function testAdminAPI(token) {
  const options2 = {
    hostname: '101.133.238.249',
    port: 80,
    path: '/api/v1/admin/stats',
    method: 'GET',
    headers: {
      'Authorization': 'Bearer ' + token
    }
  };

  const req2 = http.request(options2, (res) => {
    console.log(`\n管理员API状态码: ${res.statusCode}`);
    
    let body = '';
    res.on('data', (chunk) => {
      body += chunk;
    });
    
    res.on('end', () => {
      try {
        const json = JSON.parse(body);
        console.log(JSON.stringify(json, null, 2));
      } catch (e) {
        console.log(body);
      }
    });
  });

  req2.on('error', (e) => {
    console.error(`管理员API请求遇到问题: ${e.message}`);
  });

  req2.end();
}
