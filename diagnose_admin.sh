#!/bin/bash
# 诊断管理后台部署问题

echo "=== 1. 检查文件是否存在 ==="
ls -la /var/www/html/admin/ | head -20
echo ""

echo "=== 2. 检查文件数量 ==="
find /var/www/html/admin -type f | wc -l
echo ""

echo "=== 3. 检查login.html是否存在 ==="
ls -la /var/www/html/admin/login.html 2>&1
echo ""

echo "=== 4. 检查静态资源目录 ==="
ls -la /var/www/html/admin/_next/static/ 2>&1 | head -10
echo ""

echo "=== 5. 检查Nginx配置 ==="
cat /etc/nginx/sites-enabled/admin
echo ""

echo "=== 6. 检查Nginx状态 ==="
sudo systemctl status nginx | head -10
echo ""

echo "=== 7. 测试本地访问 ==="
curl -s -o /dev/null -w "HTTP状态码: %{http_code}\n" http://127.0.0.1/login.html
curl -s -o /dev/null -w "HTTP状态码: %{http_code}\n" http://127.0.0.1/admin/login.html
echo ""

echo "=== 8. 检查Git仓库是否正确 ==="
if [ -d "~/dang" ]; then
    cd ~/dang
    echo "admin/out目录内容："
    ls -la admin/out/ | head -10
fi
