#!/bin/bash
# 诊断管理后台部署问题

echo "=========================================="
echo "  管理后台部署诊断"
echo "=========================================="
echo ""

echo "1️⃣ 检查源文件（Git仓库中）:"
if [ -d "~/dang/admin/out" ]; then
    echo "✅ admin/out 目录存在"
    ls -la ~/dang/admin/out/ | head -10
else
    echo "❌ admin/out 目录不存在"
fi
echo ""

echo "2️⃣ 检查目标目录:"
ls -la /var/www/html/admin/ | head -10
echo ""

echo "3️⃣ 检查文件数量:"
echo "源文件数量: $(find ~/dang/admin/out -type f 2>/dev/null | wc -l)"
echo "目标文件数量: $(find /var/www/html/admin -type f 2>/dev/null | wc -l)"
echo ""

echo "4️⃣ 测试具体文件:"
curl -s -o /dev/null -w "/login.html: %{http_code}\n" http://localhost/login.html
curl -s -o /dev/null -w "/index.html: %{http_code}\n" http://localhost/index.html
echo ""

echo "5️⃣ 检查 Nginx root 配置:"
grep -A5 "root" /etc/nginx/sites-enabled/admin 2>/dev/null || echo "配置文件未找到"
echo ""

echo "6️⃣ 测试文件内容是否为空:"
wc -l /var/www/html/admin/login.html 2>/dev/null || echo "文件不存在"
echo ""
