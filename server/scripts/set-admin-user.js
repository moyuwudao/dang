/**
 * 设置管理员用户脚本
 * 用法: node scripts/set-admin-user.js
 * 
 * 将指定手机号的用户角色设置为 admin
 */
const { DataSource } = require('typeorm');

const ADMIN_PHONE = '18682092379';

const AppDataSource = new DataSource({
  type: 'postgres',
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '5432'),
  username: process.env.DB_USER || 'appuser',
  password: process.env.DB_PASSWORD || 'AppUser123456',
  database: process.env.DB_NAME || 'appdb',
});

async function main() {
  await AppDataSource.initialize();
  console.log('数据库连接成功');

  const result = await AppDataSource.query(
    `UPDATE users SET role = 'admin' WHERE phone = $1 RETURNING id, phone, nickname, role`,
    [ADMIN_PHONE],
  );

  if (result.length === 0) {
    console.log(`未找到手机号为 ${ADMIN_PHONE} 的用户，请先注册该账号`);
  } else {
    console.log(`已将 ${ADMIN_PHONE} 设置为管理员:`);
    console.log(JSON.stringify(result[0], null, 2));
  }

  await AppDataSource.destroy();
}

main().catch((err) => {
  console.error('执行失败:', err);
  process.exit(1);
});
