#!/bin/bash
# 畅记云管理后台部署脚本
# 在阿里云 ECS 服务器上执行

echo "=========================================="
echo "  畅记云管理后台部署脚本"
echo "=========================================="
echo ""

# 1. 创建目录
echo "📁 创建目录..."
sudo mkdir -p /var/www/html/admin
sudo chown -R www-data:www-data /var/www/html/admin
echo "✅ 目录创建完成"

# 2. 配置 Nginx
echo ""
echo "⚙️ 配置 Nginx..."
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

# 启用配置
sudo ln -sf /etc/nginx/sites-available/admin /etc/nginx/sites-enabled/admin
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl reload nginx
echo "✅ Nginx 配置完成"

# 3. 提示文件上传
echo ""
echo "=========================================="
echo "  请将管理后台文件上传到:"
echo "  /var/www/html/admin/"
echo ""
echo "  Windows 本地文件位置:"
echo "  D:\\trae_projects\\dang\\admin\\out\\"
echo ""
echo "  上传方式:"
echo "  - 使用 WinSCP 连接后上传"
echo "  - 或使用 rsync 命令同步"
echo "=========================================="

# 4. 验证部署
echo ""
echo "🔍 验证部署..."
sleep 2
STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/login.html 2>/dev/null || echo "000")

if [ "$STATUS" = "200" ]; then
    echo "✅ 部署成功!"
    echo ""
    echo "=========================================="
    echo "  🎉 部署完成!"
    echo "  📍 访问地址: http://101.133.238.249/login.html"
    echo "=========================================="
else
    echo "⚠️ 请先上传文件后再访问"
    echo "📍 预期状态码: 200"
    echo "📍 实际状态码: $STATUS"
fi
