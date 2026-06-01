module.exports = {
  apps: [{
    name: 'changji-api',
    script: './dist/src/main.js',
    cwd: '/opt/changji-cloud/api',
    env: {
      NODE_ENV: 'production',
      REDIS_HOST: 'localhost',
      REDIS_PORT: 6379,
      REDIS_PASSWORD: 'Redis123456',
    },
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '500M',
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    error_file: '/home/admin/.pm2/logs/changji-api-error.log',
    out_file: '/home/admin/.pm2/logs/changji-api-out.log',
  }],
};
