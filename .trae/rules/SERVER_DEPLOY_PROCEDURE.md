---
alwaysApply: false
globs: admin/**, server/**
description: 服务器部署流程 - 标准部署步骤、权限管理、版本控制、回滚机制
---

# SERVER_DEPLOY_PROCEDURE.md - 服务器部署流程

> **部署规范** → 详见 [SERVER_DEPLOY.md](SERVER_DEPLOY.md)
> **安全防护** → 详见 [SERVER_SECURITY.md](SERVER_SECURITY.md)
> **运维规范** → 详见 [SERVER_OPS.md](SERVER_OPS.md)

---

## 一、部署前检查清单

```
□ 确认服务器IP可访问: ping 101.133.238.249
□ 确认拥有root或sudo权限
□ 确认阿里云安全组规则已配置
□ 备份当前系统状态（如为升级部署）
```

---

## 二、标准部署流程

### 阶段一：系统初始化

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y vim wget curl net-tools htop iotop unzip git
sudo useradd -m -s /bin/bash admin
sudo usermod -aG sudo admin
sudo usermod -aG docker admin
```

SSH 安全配置（`/etc/ssh/sshd_config`）：
```
PermitRootLogin no
PasswordAuthentication yes
PubkeyAuthentication yes
MaxAuthTries 3
MaxSessions 2
AllowUsers admin
```
```bash
sudo systemctl restart sshd
```

### 阶段二：安全加固

```bash
sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable

sudo apt install -y fail2ban
sudo apt install -y unattended-upgrades
```

### 阶段三：基础服务部署

```bash
sudo apt install -y docker.io
sudo systemctl enable docker && sudo systemctl start docker

sudo apt install -y nginx
sudo systemctl enable nginx && sudo systemctl start nginx

sudo apt install -y certbot python3-certbot-nginx

sudo apt install -y chrony
sudo systemctl enable chrony
```

### 阶段四：性能优化

```bash
# /etc/sysctl.conf
net.ipv4.tcp_max_tw_buckets = 6000
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 30
vm.swappiness = 10
fs.file-max = 655360

# /etc/security/limits.conf
* soft nofile 65536
* hard nofile 65536

sudo sysctl -p
```

### 阶段五：应用环境部署

```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo bash -
sudo apt install -y nodejs
sudo npm install -g pm2

sudo apt install -y postgresql postgresql-contrib
sudo systemctl enable postgresql && sudo systemctl start postgresql
sudo -u postgres psql -c "CREATE USER appuser WITH PASSWORD 'AppUser123456' CREATEDB;"
sudo -u postgres psql -c "CREATE DATABASE appdb OWNER appuser;"

sudo apt install -y redis-server
# /etc/redis/redis.conf: supervised systemd, requirepass Redis123456
sudo systemctl enable redis-server && sudo systemctl restart redis-server
```

### 阶段六：部署 Server Agent

```bash
sudo pip3 install flask
sudo mkdir -p /opt/server-agent
sudo cp server-agent.py /opt/server-agent/
sudo chmod +x /opt/server-agent/server-agent.py
sudo cp server-agent.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable server-agent && sudo systemctl start server-agent

sudo cp agent-nginx.conf /etc/nginx/sites-available/agent
sudo ln -sf /etc/nginx/sites-available/agent /etc/nginx/sites-enabled/agent
sudo apt install -y apache2-utils
sudo htpasswd -c /etc/nginx/.htpasswd admin
sudo nginx -t && sudo systemctl restart nginx
```

### 阶段七：部署畅记云 API 服务

```bash
sudo mkdir -p /opt/changji-cloud/api
cd /opt/changji-cloud/api
npm install && npm install @nestjs/jwt && npm run build
```

环境变量（`/opt/changji-cloud/api/.env`）：
```
NODE_ENV=production
PORT=3000
API_PREFIX=/api/v1
DB_HOST=localhost
DB_PORT=5432
DB_NAME=appdb
DB_USER=appuser
DB_PASSWORD=AppUser123456
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASS=Redis123456
JWT_SECRET=changji-secret-key-2026-change-in-production
JWT_ACCESS_EXPIRATION=15m
JWT_REFRESH_EXPIRATION=7d
```

PM2 配置（`ecosystem.json`）：
```json
{
  "apps": [{
    "name": "changji-api",
    "script": "./dist/main.js",
    "instances": 1,
    "exec_mode": "fork",
    "env": { "NODE_ENV": "production" },
    "log_file": "/var/log/changji-api.log",
    "error_file": "/var/log/changji-api-error.log",
    "out_file": "/var/log/changji-api-out.log",
    "max_memory_restart": "512M",
    "restart_delay": 3000,
    "max_restarts": 5,
    "min_uptime": "10s"
  }]
}
```

```bash
sudo touch /var/log/changji-api.log /var/log/changji-api-error.log /var/log/changji-api-out.log
sudo chown admin:admin /var/log/changji-api*.log
pm2 start ecosystem.json && pm2 save && pm2 startup
```

Nginx 反向代理（`/etc/nginx/sites-available/api`）：
```nginx
server {
    listen 80;
    server_name 101.133.238.249;
    location /api/ {
        proxy_pass http://127.0.0.1:3000/api/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    location / { return 404; }
}
```
```bash
sudo ln -sf /etc/nginx/sites-available/api /etc/nginx/sites-enabled/api
sudo nginx -t && sudo systemctl restart nginx
```

### 阶段八：备份策略

```bash
sudo mkdir -p /backup/scripts /backup/data
```

备份脚本（`/backup/scripts/backup-db.sh`）：
```bash
#!/bin/bash
BACKUP_DIR="/backup/data"
DATE=$(date +%Y%m%d_%H%M%S)
PGOPTIONS="-c statement_timeout=600000" sudo -u postgres pg_dump appdb > "$BACKUP_DIR/appdb_$DATE.sql"
redis-cli -a Redis123456 --no-auth-warning BGSAVE
sleep 2
cp /var/lib/redis/dump.rdb "$BACKUP_DIR/redis_$DATE.rdb"
find $BACKUP_DIR -mtime +7 -delete
```

```bash
crontab -e
# 0 2 * * * /backup/scripts/backup-db.sh
```

### 部署后验证

```bash
sudo systemctl --no-pager status ssh nginx docker postgresql redis-server fail2ban unattended-upgrades chrony
sudo ufw status verbose
sudo docker --version && sudo docker run hello-world
curl --connect-timeout 5 --max-time 10 -I http://localhost
node --version && npm --version
pm2 status
psql --version && PGOPTIONS="-c statement_timeout=10000" sudo -u postgres psql -c "\l"
redis-cli -a Redis123456 --no-auth-warning PING
curl --connect-timeout 5 --max-time 10 http://127.0.0.1:8848/health
curl --connect-timeout 5 --max-time 10 http://127.0.0.1:3000/api/v1/health
sudo ss -tlnp
```

---

## 三、权限管理

| 用户 | 权限 | 用途 |
|-----|------|------|
| root | 全部 | 系统管理（禁止SSH登录） |
| admin | sudo | 日常管理（主要操作账户） |
| www-data | 服务 | Nginx运行用户 |
| postgres | 服务 | PostgreSQL运行用户 |
| redis | 服务 | Redis运行用户 |
| server-agent | root | Agent服务运行用户 |

SSH 访问规范：
```
✅ 必须使用admin账户登录
✅ 推荐使用SSH密钥认证
❌ 禁止使用root直接登录
❌ 禁止密码认证（配置密钥后）
❌ 禁止共享账户
```

---

## 四、版本控制

| 软件 | 当前版本 | 更新策略 |
|-----|---------|---------|
| Docker | 29.1.3 | 安全更新（每周检查） |
| Nginx | 1.18.0 | 安全更新（每周检查） |
| Ubuntu | 22.04.5 | LTS版本（每季度） |
| Node.js | 24.14.1 | LTS安全更新（每月） |
| PostgreSQL | 14.22 | 安全更新（每月） |
| Redis | 6.0.16 | 安全更新（每月） |
| PM2 | 5.4.0 | 安全更新（每月） |
| NestJS API | 1.0.0 | 功能更新（按需） |

配置变更规范：
```bash
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak.$(date +%Y%m%d)
echo "$(date): 修改sshd_config" >> /var/log/config-changes.log
```

---

## 五、回滚机制

### 配置文件回滚
```bash
sudo cp /etc/ssh/sshd_config.bak.20260520 /etc/ssh/sshd_config
sudo systemctl restart sshd
```

### 服务回滚
```bash
pm2 stop changji-api
cd /opt/changji-cloud/api && git checkout <previous-tag>
npm install && npm run build
pm2 start ecosystem.json
```

### 数据库回滚
```bash
sudo -u postgres psql -d appdb < /backup/data/appdb_20260520_020000.sql
sudo systemctl stop redis-server
cp /backup/data/redis_20260520_020000.rdb /var/lib/redis/dump.rdb
sudo systemctl start redis-server
```

### 紧急回滚流程
```
1. 停止相关服务
2. 恢复配置文件备份
3. 重启服务验证
4. 记录回滚原因到 /var/log/rollback.log
```

---

## 六、后端代码部署标准流程（2026-06-03 沉淀）

> **目的**：把 2026-06-03 修复流程固化为标准，**所有后续后端代码修改必须按此顺序执行**。
> 
> **前置必查**：
> - [SERVER_STATUS.md](../docs/SERVER_STATUS.md) - 服务器当前状态
> - [.env 规范](BUILD.md#-env-与-processenv-规范部署必修) - 环境变量配置要求
> - [SERVER_DEPLOY.md 问题9](SERVER_DEPLOY.md#问题9后端反复重启redis-noauth--ioredis-unhandled-error-event) - 反复重启根因

### 阶段一：本地代码修改与测试

```bash
# 在 Windows 端编辑 server/src/ 下的代码
# 写代码时注意：
#   - 所有 ioredis 客户端必须有 password fallback 和 error 事件监听器
#   - 涉及 .env 字段的代码，必须同时确认 .env 实际存在且包含该字段
#   - 涉及 NestJS Module 注入新 Repository，必须同步 forFeature 列表
```

### 阶段二：提交到 git

```bash
git -C d:/trae_projects/dang add server/
git -C d:/trae_projects/dang commit -m "fix: 简短描述（含根本原因）"
git -C d:/trae_projects/dang push origin master
```

### 阶段三：服务器 pull + build

```bash
wsl -d dang bash -c 'ssh -o ConnectTimeout=10 -o ServerAliveInterval=5 -o ServerAliveCountMax=2 changji "
  set -e
  cd /home/admin/dang
  git pull origin master 2>&1 | tail -5
  cd server
  npm run build 2>&1 | tail -5
  ls -la dist/admin/admin.module.js  # 验证编译产物
"'
```

### 阶段四：检查并修复 .env

```bash
# 必查项：服务器 .env 必须存在且包含关键字段
wsl -d dang bash -c 'ssh -o ConnectTimeout=10 changji "
  ls -la /home/admin/dang/server/.env
  [ -f /home/admin/dang/server/.env ] || cp /opt/changji-cloud/api/.env /home/admin/dang/server/.env
  grep -E \"^REDIS_PASSWORD|^DB_PASSWORD|^JWT_SECRET\" /home/admin/dang/server/.env
"'
```

### 阶段五：重启 pm2

```bash
wsl -d dang bash -c 'ssh -o ConnectTimeout=10 changji "
  pm2 delete all 2>&1 | tail -3
  cd /home/admin/dang/server
  pm2 start dist/main.js --name changji-api --cwd /home/admin/dang/server 2>&1 | tail -5
  pm2 save 2>&1 | tail -3
"'
```

### 阶段六：稳定性和功能验证

```bash
# 等待 30-60 秒，看重启次数是否为 0
wsl -d dang bash -c 'ssh -o ConnectTimeout=10 changji "
  pm2 flush  # 清空历史日志
  sleep 30
  pm2 jlist 2>&1 | python3 -c \"
import json,sys
for p in json.load(sys.stdin):
  if p[\\\"name\\\"]==\\\"changji-api\\\":
    print(f\\\"重启次数: {p[\\\"pm2_env\\\"][\\\"restart_time\\\"]} 状态: {p[\\\"pm2_env\\\"][\\\"status\\\"]} 内存: {p[\\\"monit\\\"][\\\"memory\\\"]/1024/1024:.1f}MB\\\")
\"
  pm2 logs changji-api --lines 30 --nostream --err 2>&1 | tail -10  # 应该无 NOAUTH/Error
"'

# 测试核心 API
wsl -d dang bash -c 'curl -s --max-time 10 -X POST http://101.133.238.249/api/v1/auth/send-sms-code -H "Content-Type: application/json" -d "{\"phone\":\"13912345678\"}"'
```

### 完整检查清单

- [ ] **阶段二**：commit 信息描述根本原因，**不只是症状**
- [ ] **阶段三**：`dist/main.js` 编译成功且 mtime > 当前时间
- [ ] **阶段四**：`.env` 存在，**包含** `REDIS_PASSWORD=Redis123456`（必查）
- [ ] **阶段五**：pm2 restart_time = 0 持续 30 秒以上
- [ ] **阶段六**：核心 API 正常返回（非 5xx，非 NOAUTH 错误）

### 异常对照

后端部署失败时按 [SERVER_DEPLOY.md 问题集](SERVER_DEPLOY.md#七常见问题与解决方案) 排查：
- **问题9**（最重要）：后端反复重启（Redis NOAUTH + ioredis error event + .env 路径）
- **问题8**：数据库表结构变更后实体类未同步
- **问题10**：WSL 端 SSH 密钥缺失（无法远程操作）

---

## 更新记录

| 日期 | 更新内容 |
|-----|---------|
| 2026-06-03 | **新增"六、后端代码部署标准流程"**：6 阶段（本地开发→commit→服务器 pull→检查 .env→pm2 restart→稳定验证）+ 完整检查清单 + 异常对照。把 2026-06-03 修复流程（Redis NOAUTH + AdminModule 502）固化为标准 |
| 2026-05-25 | 安全修复：systemctl 加 --no-pager；psql/pg_dump 加 statement_timeout；redis-cli 加 --no-auth-warning；curl 加超时 |
| 2026-05-21 | 从 SERVER_DEPLOY.md 拆分，独立为 SERVER_DEPLOY_PROCEDURE.md |
