
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
  const phone1 = '13800138001';
  const phone2 = '18682092379';
  const password = 'Hu123456';
  
  console.log('=== 更新用户为管理员 ===');
  
  for (const phone of [phone1, phone2]) {
    console.log('\n检查用户:', phone);
    
    const checkQuery = 'SELECT id FROM users WHERE phone = $1';
    const checkResult = await pool.query(checkQuery, [phone]);
    
    if (checkResult.rows.length > 0) {
      console.log('用户存在，更新为管理员...');
      const hash = await bcrypt.hash(password, 12);
      const updateQuery = 'UPDATE users SET "passwordHash" = $1, role = $2, status = $3 WHERE phone = $4';
      await pool.query(updateQuery, [hash, 'admin', 'active', phone]);
    } else {
      console.log('创建新用户...');
      const hash = await bcrypt.hash(password, 12);
      const insertQuery = 'INSERT INTO users (phone, "passwordHash", role, status, nickname) VALUES ($1, $2, $3, $4, $5)';
      await pool.query(insertQuery, [phone, hash, 'admin', 'active', '管理员']);
    }
    
    const verifyQuery = 'SELECT id, phone, role, status FROM users WHERE phone = $1';
    const verifyResult = await pool.query(verifyQuery, [phone]);
    
    console.log('✅ 用户信息:', verifyResult.rows[0]);
  }
  
  console.log('\n\n🎉 完成！');
  console.log('可用账户：');
  console.log('  账户1: 13800138001 / Hu123456');
  console.log('  账户2: 18682092379 / Hu123456');
  console.log('\n请使用上述任一账户登录管理后台');
  
  await pool.end();
}

main().catch(err => {
  console.error('错误:', err);
  process.exit(1);
});
