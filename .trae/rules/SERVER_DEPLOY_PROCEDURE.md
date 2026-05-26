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

## 更新记录

| 日期 | 更新内容 |
|-----|---------|
| 2026-05-25 | 安全修复：systemctl 加 --no-pager；psql/pg_dump 加 statement_timeout；redis-cli 加 --no-auth-warning；curl 加超时 |
| 2026-05-21 | 从 SERVER_DEPLOY.md 拆分，独立为 SERVER_DEPLOY_PROCEDURE.md |
