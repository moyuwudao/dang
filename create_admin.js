const bcrypt = require('bcryptjs');
const { Pool } = require('pg');

const pool = new Pool({
  host: 'localhost',
  port: 5432,
  database: 'appdb',
  user: 'appuser',
  password: 'AppUser123456'
});

async function createAdmin() {
  const phone = '18682092379';
  const password = 'Hu123456';
  const hash = await bcrypt.hash(password, 12);
  
  console.log('正在创建管理员账户...');
  console.log('手机号:', phone);
  console.log('密码:', password);
  
  // 检查用户是否已存在
  const checkQuery = 'SELECT id FROM users WHERE phone = $1';
  const checkResult = await pool.query(checkQuery, [phone]);
  
  if (checkResult.rows.length > 0) {
    console.log('用户已存在，更新密码...');
    const updateQuery = 'UPDATE users SET "passwordHash" = $1, role = $2, status = $3 WHERE phone = $4';
    await pool.query(updateQuery, [hash, 'admin', 'active', phone]);
  } else {
    console.log('创建新用户...');
    const insertQuery = 'INSERT INTO users (phone, "passwordHash", role, status, nickname) VALUES ($1, $2, $3, $4, $5)';
    await pool.query(insertQuery, [phone, hash, 'admin', 'active', '管理员']);
  }
  
  // 验证创建结果
  const verifyQuery = 'SELECT id, phone, role, status FROM users WHERE phone = $1';
  const verifyResult = await pool.query(verifyQuery, [phone]);
  
  if (verifyResult.rows.length > 0) {
    console.log('\n✅ 管理员账户创建/更新成功！');
    console.log('用户信息:');
    console.log(verifyResult.rows[0]);
  }
  
  await pool.end();
}

createAdmin().catch(err => {
  console.error('错误:', err);
  process.exit(1);
});
