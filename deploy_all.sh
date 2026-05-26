#!/bin/bash
# Git部署管理后台和后端API到服务器

# 进入项目目录
cd ~/dang || {
    echo "项目目录不存在，克隆仓库..."
    git clone https://github.com/moyuwudao/dang.git ~/dang
    cd ~/dang
}

# 拉取最新代码
echo "拉取最新代码..."
git pull origin master

# 1. 部署后端API
echo ""
echo "=========================================="
echo "  部署后端API..."
echo "=========================================="
cd ~/dang/server
npm install
npm run build
pm2 restart changji-api || pm2 start dist/main.js --name changji-api
echo "✅ 后端API部署完成"

# 2. 构建前端
echo ""
echo "=========================================="
echo "  构建前端..."
echo "=========================================="
cd ~/dang/admin
npm install
npm run build
echo "✅ 前端构建完成"

# 3. 部署管理后台到nginx
echo ""
echo "=========================================="
echo "  部署管理后台..."
echo "=========================================="
sudo cp -r ~/dang/admin/out/* /var/www/html/admin/

# 设置权限
sudo chown -R www-data:www-data /var/www/html/admin
sudo chmod -R 755 /var/www/html/admin

# 重新加载nginx
sudo nginx -t && sudo systemctl reload nginx

echo ""
echo "=========================================="
echo "  🎉 全部部署完成！"
echo "=========================================="
echo "📱 管理后台: http://101.133.238.249/login.html"
echo "🔧 API状态: http://101.133.238.249/api/v1/subscription/plans"
echo ""
