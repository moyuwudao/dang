#!/bin/bash
# 完整重新部署管理后台脚本

echo "=========================================="
echo "  完整重新部署管理后台"
echo "=========================================="
echo ""

# 1. 进入项目目录
cd ~/dang || {
    echo "❌ 项目目录不存在，正在克隆..."
    git clone https://github.com/moyuwudao/dang.git ~/dang
    cd ~/dang
}
echo "✅ 进入项目目录: $(pwd)"

# 2. 拉取最新代码
echo ""
echo "📥 拉取最新代码..."
git pull origin master
echo "✅ 代码更新完成"

# 3. 清理旧文件
echo ""
echo "🗑️ 清理旧文件..."
sudo rm -rf /var/www/html/admin/*
echo "✅ 旧文件清理完成"

# 4. 复制新文件
echo ""
echo "📦 复制文件到 Nginx 目录..."
sudo cp -r admin/out/* /var/www/html/admin/
echo "✅ 文件复制完成"

# 5. 设置权限
echo ""
echo "🔐 设置文件权限..."
sudo chown -R www-data:www-data /var/www/html/admin
sudo find /var/www/html/admin -type f -exec chmod 644 {} \;
sudo find /var/www/html/admin -type d -exec chmod 755 {} \;
echo "✅ 权限设置完成"

# 6. 验证文件
echo ""
echo "🔍 验证文件复制..."
FILE_COUNT=$(find /var/www/html/admin -type f | wc -l)
echo "📊 复制了 $FILE_COUNT 个文件"

if [ -f "/var/www/html/admin/login.html" ]; then
    echo "✅ login.html 存在"
else
    echo "❌ login.html 不存在！"
fi

if [ -d "/var/www/html/admin/_next" ]; then
    echo "✅ _next 目录存在"
else
    echo "❌ _next 目录不存在！"
fi

# 7. 重新配置 Nginx
echo ""
echo "⚙️ 重新配置 Nginx..."
sudo tee /etc/nginx/sites-available/admin > /dev/null << 'EOF'
server {
    listen 80;
    server_name _;

    root /var/www/html/admin;
    index index.html;

    # 管理后台路由
    location / {
        try_files $uri $uri/ $uri.html /index.html;
    }

    # 静态资源缓存
    location /_next/ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        try_files $uri $uri/ =404;
    }

    # API 反向代理
    location /api/ {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
EOF

# 8. 测试并重载 Nginx
echo ""
echo "🔄 测试并重载 Nginx..."
sudo nginx -t
if [ $? -eq 0 ]; then
    sudo systemctl reload nginx
    echo "✅ Nginx 配置测试通过并重载"
else
    echo "❌ Nginx 配置有错误！"
fi

# 9. 最终测试
echo ""
echo "🧪 测试访问..."
echo ""
echo "本地测试:"
curl -s -o /dev/null -w "  /login.html 状态码: %{http_code}\n" http://localhost/login.html
curl -s -o /dev/null -w "  /dashboard.html 状态码: %{http_code}\n" http://localhost/dashboard.html
curl -s -o /dev/null -w "  /_next/ 状态码: %{http_code}\n" http://localhost/_next/

echo ""
echo "=========================================="
echo "  🎉 部署完成!"
echo "  📍 访问地址: http://101.133.238.249/login.html"
echo ""
echo "  🔐 测试账号:"
echo "     手机号: 13811112222"
echo "     密码:   Test123456"
echo "=========================================="
