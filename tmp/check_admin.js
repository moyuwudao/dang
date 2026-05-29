const { DataSource } = require('typeorm');

const ds = new DataSource({
  type: 'postgres',
  host: 'localhost',
  port: 5432,
  username: 'changji',
  password: 'changji_db_pass_2026',
  database: 'changji_cloud',
  entities: ['dist/**/*.entity.js']
});

ds.initialize().then(async () => {
  const admins = await ds.query('SELECT phone, role FROM admin_users');
  console.log(JSON.stringify(admins));
  await ds.destroy();
}).catch(err => {
  console.error('Error:', err.message);
  process.exit(1);
});
