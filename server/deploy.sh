#!/bin/bash
# 畅记云服务 - 一键部署脚本
# 执行方式: bash deploy.sh

set -e

echo "=========================================="
echo "  畅记云服务 API - 一键部署"
echo "=========================================="

# 1. 备份当前状态
echo "[1/6] 备份当前状态..."
mkdir -p /backup/pre-deploy
if [ -d /opt/changji-cloud/api ]; then
    tar -czf /backup/pre-deploy/api-$(date +%Y%m%d-%H%M%S).tar.gz /opt/changji-cloud/api 2>/dev/null || true
fi

# 2. 拉取最新代码
echo "[2/6] 拉取最新代码..."
cd /opt/changji-cloud

if [ -d /opt/changji-cloud/api/.git ]; then
    cd /opt/changji-cloud/api
    git pull origin master
else
    rm -rf /opt/changji-cloud/api
    git clone https://github.com/moyuwudao/dang.git temp-repo
    cp -r temp-repo/server/* api/
    rm -rf temp-repo
fi

# 3. 创建环境变量
echo "[3/6] 配置环境变量..."
cd /opt/changji-cloud/api

cat > .env << 'EOF'
DB_HOST=localhost
DB_PORT=5432
DB_NAME=appdb
DB_USER=appuser
DB_PASSWORD=AppUser123456
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=Redis123456
JWT_SECRET=changji_jwt_secret_change_me_in_production
JWT_REFRESH_SECRET=changji_refresh_secret_change_me
NODE_ENV=production
PORT=3000
EOF

chmod 600 .env

# 4. 安装依赖
echo "[4/6] 安装依赖..."
npm install

# 5. 构建
echo "[5/6] 构建项目..."
npm run build

# 6. 启动服务
echo "[6/6] 启动服务..."
pm2 restart changji-api 2>/dev/null || pm2 start dist/main.js --name changji-api

# 保存 PM2 配置
pm2 save

echo ""
echo "=========================================="
echo "  部署完成！"
echo "=========================================="
echo ""
pm2 status
echo ""
echo "API 地址: http://localhost:3000/api/v1"
echo "健康检查: curl http://localhost:3000/api/v1/health"
