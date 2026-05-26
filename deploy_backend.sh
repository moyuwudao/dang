#!/bin/bash

echo "=== 拉取最新代码 ==="
cd /root/dang
git pull

echo "=== 重新构建后端 ==="
cd server
npm run build

echo "=== 重启服务 ==="
pm2 restart changji-api

echo "=== 检查服务状态 ==="
pm2 status changji-api

echo "=== 完成 ==="
