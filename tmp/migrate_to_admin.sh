#!/bin/bash
set -e

echo "=== 服务器代码迁移脚本 ==="
echo "将代码从 /root/dang 迁移到 /home/admin/dang"
echo ""

# 1. 检查当前状态
echo "1. 检查当前目录状态..."
echo "  /root/dang 存在?"
if [ -d "/root/dang" ]; then
    echo "  ✓ 存在"
    ls -la /root/dang | head -5
else
    echo "  ✗ 不存在"
fi

echo "  /home/admin/dang 存在?"
if [ -d "/home/admin/dang" ]; then
    echo "  ✓ 存在"
else
    echo "  ✗ 不存在，将创建"
fi

echo "  /opt/changji-cloud/api 存在?"
if [ -d "/opt/changji-cloud/api" ]; then
    echo "  ✓ 存在"
    ls -la /opt/changji-cloud/api | head -5
else
    echo "  ✗ 不存在"
fi

echo ""
echo "2. 复制代码到 /home/admin/dang..."
if [ -d "/root/dang" ]; then
    sudo cp -r /root/dang /home/admin/dang
    sudo chown -R admin:admin /home/admin/dang
    echo "  ✓ 复制完成"
else
    echo "  ✗ /root/dang 不存在，无法复制"
    exit 1
fi

echo ""
echo "3. 更新 deploy_backend.sh..."
cat > /home/admin/dang/deploy_backend.sh << 'EOF'
#!/bin/bash
set -e

echo "=== 拉取最新代码 ==="
cd /home/admin/dang
git pull origin master

echo "=== 重新构建后端 ==="
cd server
npm install
npm run build

echo "=== 同步构建产物到 /opt/changji-cloud/api ==="
rsync -av --delete dist/ /opt/changji-cloud/api/dist/
rsync -av --delete node_modules/ /opt/changji-cloud/api/node_modules/
cp package.json /opt/changji-cloud/api/

echo "=== 重启服务 ==="
pm2 restart changji-api

echo "=== 检查服务状态 ==="
pm2 status changji-api

echo "=== 完成 ==="
EOF
chmod +x /home/admin/dang/deploy_backend.sh
chown admin:admin /home/admin/dang/deploy_backend.sh
echo "  ✓ 更新完成"

echo ""
echo "4. 检查 PM2 配置..."
pm2 show changji-api | grep -E "script path|exec cwd" || echo "  PM2 配置获取失败"

echo ""
echo "=== 迁移完成 ==="
echo "请确认以下事项："
echo "1. /home/admin/dang/ 下是否有完整的代码"
echo "2. 文件权限是否正确 (admin:admin)"
echo "3. 是否需要更新 PM2 配置指向新路径"
echo ""
echo "下一步："
echo "  cd /home/admin/dang"
echo "  git pull origin master"
echo "  cd server && npm install && npm run build"
echo "  pm2 restart changji-api"
