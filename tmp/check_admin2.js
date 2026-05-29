const { Client } = require('pg');

const client = new Client({
  host: 'localhost',
  port: 5432,
  user: 'appuser',
  password: 'AppUser123456',
  database: 'appdb'
});

client.connect().then(async () => {
  const res = await client.query('SELECT phone, role FROM admin_users');
  console.log(JSON.stringify(res.rows));
  await client.end();
}).catch(err => {
  console.error('Error:', err.message);
  process.exit(1);
});
