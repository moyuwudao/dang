# 畅记云服务部署脚本
# 需要先配置 SSH 免密登录，或使用密码方式

$SERVER_IP = "101.133.238.249"
$SERVER_USER = "admin"
$LOCAL_SERVER_DIR = "server"
$REMOTE_DIR = "/opt/changji-cloud/api"

Write-Host "=== 开始部署畅记云服务 ===" -ForegroundColor Green

# 1. 停止服务
Write-Host "`n1. 停止现有服务..." -ForegroundColor Yellow
ssh "${SERVER_USER}@${SERVER_IP}" "cd ${REMOTE_DIR} && pm2 stop changji-api 2>/dev/null || true"

# 2. 备份
Write-Host "`n2. 备份现有代码..." -ForegroundColor Yellow
$backupName = "backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
ssh "${SERVER_USER}@${SERVER_IP}" "cd ${REMOTE_DIR}/.. && cp -r api ${backupName} 2>/dev/null || true"

# 3. 上传代码
Write-Host "`n3. 上传新代码..." -ForegroundColor Yellow
$tempTar = "server_code.tar.gz"
cd $LOCAL_SERVER_DIR
tar -czf "../${tempTar}" --exclude=node_modules --exclude=.git --exclude=dist .
cd ..
scp $tempTar "${SERVER_USER}@${SERVER_IP}:/tmp/"
Remove-Item $tempTar

# 4. 解压和部署
Write-Host "`n4. 部署新代码..." -ForegroundColor Yellow
ssh "${SERVER_USER}@${SERVER_IP}" @"
cd ${REMOTE_DIR}
rm -rf * 2>/dev/null || true
tar -xzf /tmp/${tempTar} -C .
rm /tmp/${tempTar}

# 复制 .env 文件（如果不存在）
if [ ! -f .env ]; then
    cp .env.example .env
fi

# 安装依赖
npm install

# 构建
npm run build

# 重启服务
pm2 restart ecosystem.json || pm2 start ecosystem.json
pm2 save

# 显示状态
pm2 status
"@

Write-Host "`n=== 部署完成 ===" -ForegroundColor Green
Write-Host "请检查服务状态：ssh ${SERVER_USER}@${SERVER_IP} 'pm2 logs changji-api --lines 50'"
