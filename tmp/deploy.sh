#!/bin/bash
set -e

echo "=== 开始部署后端服务 ==="

cd /home/admin/dang

echo "1. 拉取最新代码..."
git pull origin master

echo "2. 查找 NestJS 项目目录..."
SERVER_DIR=$(find /home/admin/dang -name "main.ts" -path "*/src/*" | head -1 | xargs dirname | xargs dirname)
echo "找到服务端目录: $SERVER_DIR"

cd "$SERVER_DIR"

echo "3. 安装依赖..."
npm install

echo "4. 构建..."
npm run build

echo "5. 重启 PM2 服务..."
pm2 restart changji-api || pm2 start dist/main.js --name changji-api
pm2 save

echo "=== 部署完成 ==="
