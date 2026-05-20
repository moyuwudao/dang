#!/bin/bash
# 畅记云管理后台文件上传脚本
# 在阿里云控制台的云助手中执行

echo "=========================================="
echo "  畅记云管理后台部署脚本"
echo "=========================================="
echo ""

# 1. 检查文件是否已上传
if [ ! -d "/var/www/html/admin" ]; then
    echo "📁 检查目录..."
    sudo mkdir -p /var/www/html/admin
    sudo chown -R www-data:www-data /var/www/html/admin
    echo "✅ 目录准备完成"
fi

# 2. 如果文件上传提示
echo ""
echo "=========================================="
echo "  📤 请上传文件到 /var/www/html/admin 目录"
echo ""
echo "  上传方式:"
echo "  1. 使用 WinSCP 连接服务器后，从 D:\\trae_projects\\dang\\admin\\out\\ 上传"
echo "  2. 或使用 rsync 命令同步"
echo "  3. 或使用其他 SCP 工具"
echo ""
echo "  本地文件路径: D:\\trae_projects\\dang\\admin\\out"
echo "=========================================="
echo ""

# 3. 设置正确的权限
echo "🔐 设置文件权限..."
sudo chown -R www-data:www-data /var/www/html/admin
sudo find /var/www/html/admin -type f -exec chmod 644 {} \;
sudo find /var/www/html/admin -type d -exec chmod 755 {} \;
echo "✅ 权限设置完成"

# 4. 验证部署
echo ""
echo "🔍 验证部署..."
sleep 2
STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/login.html 2>/dev/null || echo "000")

echo ""
echo "=========================================="
if [ "$STATUS" = "200" ]; then
    echo "  🎉 部署成功!"
    echo "  📍 访问地址: http://101.133.238.249/login.html"
    echo ""
    echo "  🔐 测试账号: 13811112222"
    echo "  🔐 测试密码: Test123456"
else
    echo "  ⚠️ 请先上传文件后再访问"
    echo "  📍 预期状态码: 200"
    echo "  📍 实际状态码: $STATUS"
fi
echo "=========================================="
