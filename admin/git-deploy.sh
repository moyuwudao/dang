#!/bin/bash
# Git部署管理后台到服务器

# 进入项目目录
cd ~/dang || {
    echo "项目目录不存在，克隆仓库..."
    git clone https://github.com/moyuwudao/dang.git ~/dang
    cd ~/dang
}

# 拉取最新代码
echo "拉取最新代码..."
git pull origin master

# 复制管理后台到nginx目录
echo "部署管理后台..."
sudo cp -r admin/out/* /var/www/html/admin/

# 设置权限
sudo chown -R www-data:www-data /var/www/html/admin
sudo chmod -R 755 /var/www/html/admin

# 重新加载nginx
sudo nginx -t && sudo systemctl reload nginx

echo ""
echo "✅ 管理后台部署完成！"
echo "📱 登录地址: http://101.133.238.249/login.html"
echo ""
echo "🔐 测试账号："
echo "   手机号: 13811112222"
echo "   密码:   Test123456"
echo ""
