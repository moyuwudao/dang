const http = require('http');

// 1. 注册用户
console.log('=== 步骤1: 注册新用户 ===');
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
    try {
      const registerJson = JSON.parse(registerBody);
      console.log('注册响应:', JSON.stringify(registerJson, null, 2));
      
      if (registerJson.code === 200 || registerRes.statusCode === 201) {
        console.log('\n=== 用户注册成功！现在更新为管理员 ===');
        
        // 2. 更新用户角色为 admin
        updateUserRole();
      } else {
        console.log('\n=== 用户可能已存在，尝试直接登录并测试 ===');
        testLogin();
      }
    } catch (e) {
      console.log('注册响应:', registerBody);
    }
  });
});

registerReq.on('error', (e) => {
  console.error(`注册请求遇到问题: ${e.message}`);
});

registerReq.write(registerData);
registerReq.end();

function updateUserRole() {
  console.log('\n=== 步骤2: 登录获取 token ===');
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
      try {
        const loginJson = JSON.parse(loginBody);
        console.log('登录响应:', JSON.stringify(loginJson, null, 2));
        
        if (loginJson.code === 200 || loginRes.statusCode === 201) {
          console.log('\n=== 登录成功，用户信息:', loginJson.data.user);
          
          // 使用数据库脚本更新角色
          updateRoleViaDb();
        }
      } catch (e) {
        console.log('登录响应:', loginBody);
      }
    });
  });
  
  loginReq.on('error', (e) => {
    console.error(`登录请求遇到问题: ${e.message}`);
  });
  
  loginReq.write(loginData);
  loginReq.end();
}

function updateRoleViaDb() {
  console.log('\n=== 步骤3: 通过数据库更新角色 ===');
  // 直接运行 SQL 更新
  const { exec } = require('child_process');
  
  const updateRoleScript = `
const bcrypt = require('/home/admin/dang/server/node_modules/bcryptjs');
const { Pool } = require('/home/admin/dang/server/node_modules/pg');

const pool = new Pool({
  host: 'localhost',
  port: 5432,
  database: 'appdb',
  user: 'appuser',
  password: 'AppUser123456'
});

async function updateRole() {
  const phone = '18682092379';
  console.log('更新用户角色...');
  const query = 'UPDATE users SET role = $1 WHERE phone = $2';
  await pool.query(query, ['admin', phone]);
  
  const verifyQuery = 'SELECT id, phone, role, status FROM users WHERE phone = $1';
  const verifyResult = await pool.query(verifyQuery, [phone]);
  
  if (verifyResult.rows.length > 0) {
    console.log('✅ 更新成功！用户信息:', verifyResult.rows[0]);
  }
  
  await pool.end();
}

updateRole().catch(err => {
  console.error('错误:', err);
  process.exit(1);
});
`;
  
  console.log('脚本内容:', updateRoleScript);
  
  // 通过 SSH 运行脚本
  const fs = require('fs');
  fs.writeFileSync('/tmp/update_role.js', updateRoleScript);
  
  console.log('\n请在服务器上运行以下命令更新角色：');
  console.log('cd /home/admin/dang');
  console.log(`node -e "${updateRoleScript.replace(/"/g, '\\"')}"`);
  
  // 或者直接测试登录
  setTimeout(() => {
    testLogin();
  }, 1000);
}

function testLogin() {
  console.log('\n=== 测试新账户登录和管理员权限 ===');
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
        console.log('测试登录响应:', JSON.stringify(testLoginJson, null, 2));
        
        if (testLoginJson.code === 200 || testLoginRes.statusCode === 201) {
          console.log('\n=== 登录成功 ===');
          
          if (testLoginJson.data && testLoginJson.data.accessToken) {
            testAdminAPI(testLoginJson.data.accessToken);
          }
        }
      } catch (e) {
        console.log('测试登录响应:', testLoginBody);
      }
    });
  });
  
  testLoginReq.on('error', (e) => {
    console.error(`测试登录请求遇到问题: ${e.message}`);
  });
  
  testLoginReq.write(testLoginData);
  testLoginReq.end();
}

function testAdminAPI(token) {
  console.log('\n=== 测试管理员API ===');
  
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
