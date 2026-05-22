const bcrypt = require('bcryptjs');
const { Pool } = require('pg');

const pool = new Pool({
  host: 'localhost',
  port: 5432,
  database: 'appdb',
  user: 'appuser',
  password: 'AppUser123456'
});

async function main() {
  const phone = '18682092379';
  const password = 'Hu123456';
  
  console.log('检查用户是否存在...');
  const checkQuery = { text: 'SELECT id FROM users WHERE phone = $1', values: [phone] };
  const checkResult = await pool.query(checkQuery);
  
  if (checkResult.rows.length > 0) {
    console.log('用户已存在，更新密码和角色...');
    const hash = await bcrypt.hash(password, 12);
    const updateQuery = {
      text: 'UPDATE users SET "passwordHash" = $1, role = $2, status = $3 WHERE phone = $4',
      values: [hash, 'admin', 'active', phone]
    };
    await pool.query(updateQuery);
  } else {
    console.log('创建新用户...');
    const hash = await bcrypt.hash(password, 12);
    const insertQuery = {
      text: 'INSERT INTO users (phone, "passwordHash", role, status, nickname) VALUES ($1, $2, $3, $4, $5)',
      values: [phone, hash, 'admin', 'active', '管理员']
    };
    await pool.query(insertQuery);
  }
  
  console.log('验证结果...');
  const verifyQuery = { text: 'SELECT id, phone, role, status FROM users WHERE phone = $1', values: [phone] };
  const verifyResult = await pool.query(verifyQuery);
  
  console.log('\n✅ 完成！');
  console.log('用户信息:', verifyResult.rows[0]);
  
  await pool.end();
}

main().catch(err => {
  console.error('错误:', err);
  process.exit(1);
});
