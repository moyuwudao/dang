---
alwaysApply: false
description: 阿里云ECS服务器部署规范 - 101.133.238.249 标准化操作指导
---

# SERVER_DEPLOY.md - 服务器部署规范

## 概述

本文档定义阿里云ECS服务器（101.133.238.249）的部署标准规范。

**适用范围**：所有对该服务器的部署、配置、维护操作
**服务器IP**：101.133.238.249（公网）/ 172.24.29.151（内网）
**操作系统**：Ubuntu 22.04.5 LTS
**文档版本**：v1.4

> **安全红线** → 详见 [RED_LINES.md](RED_LINES.md)
> **构建红线** → 详见 [BUILD_RED_LINES.md](BUILD_RED_LINES.md)

---

## 一、环境配置

### 1.1 服务器规格

| 项目 | 配置 |
|-----|------|
| CPU | 2核 |
| 内存 | 1.6GB |
| 磁盘 | 40GB SSD |
| 架构 | x86_64 |

### 1.2 网络端口

| 端口 | 协议 | 用途 | 状态 |
|-----|------|------|------|
| 22 | TCP | SSH远程管理 | ✅ 开放 |
| 80 | TCP | HTTP | ✅ 开放 |
| 443 | TCP | HTTPS | ✅ 开放 |
| 3000 | TCP | API服务（本地） | ✅ 运行中 |
| 5432 | TCP | PostgreSQL（本地） | ✅ 运行中 |
| 6379 | TCP | Redis（本地） | ✅ 运行中 |
| 8848 | TCP | Server Agent（本地） | ✅ 运行中 |

### 1.3 必需软件

| 软件 | 版本 | 用途 |
|-----|------|------|
| Docker | 29.1.3 | 容器化平台 |
| Nginx | 1.18.0 | Web服务器/反向代理 |
| Fail2ban | 0.11.2 | 防暴力破解 |
| UFW | 0.36.1 | 防火墙管理 |
| Certbot | 1.21.0 | SSL证书管理 |
| Chrony | 4.2 | 时间同步 |
| Node.js | 24.14.1 | JavaScript运行时 |
| PostgreSQL | 14.22 | 关系型数据库 |
| Redis | 6.0.16 | 缓存/消息队列 |
| Server Agent | 1.0.0 | 服务器管理Agent |
| PM2 | 5.4.0 | Node.js进程管理 |
| NestJS API | 1.0.0 | 畅记云服务API |

---

## 二、服务器连接方式

### 2.1 SSH连接信息

| 项目 | 配置 |
|-----|------|
| 连接地址 | 101.133.238.249 |
| 连接端口 | 22 |
| 管理用户 | admin |
| 连接协议 | SSH |

### 2.2 连接方式

#### 方式一：密码登录（备用方式）

```bash
# Linux/Mac 终端
ssh admin@101.133.238.249

# Windows (PowerShell)
ssh admin@101.133.238.249
```

**注意**：密码登录仅在密钥登录不可用时使用

#### 方式二：密钥登录（推荐 ✅ 已配置）

**本地配置**（Windows PowerShell）：
```powershell
# 1. 确认私钥存在
ls $env:USERPROFILE\.ssh\id_ed25519

# 2. 使用密钥连接
ssh -i $env:USERPROFILE\.ssh\id_ed25519 admin@101.133.238.249

# 3. 或使用配置别名
ssh changji
```

**服务器配置**（已完成的配置）：
```bash
# 公钥已添加到 /home/admin/.ssh/authorized_keys
# SSH配置：PasswordAuthentication yes + PubkeyAuthentication yes
# 防火墙：ufw allow 22/tcp
```

**SSH Config 配置**（`C:\Users\Mayn\.ssh\config`）：
```bash
Host changji
    HostName 101.133.238.249
    User admin
    Port 22
    IdentityFile ~/.ssh/id_ed25519
    StrictHostKeyChecking accept-new
    ConnectTimeout 30
```

### 2.3 服务连接方式

#### PostgreSQL

```bash
# 本地连接
sudo -u postgres psql -d appdb

# 连接字符串格式
postgresql://appuser:AppUser123456@localhost:5432/appdb
```

#### Redis

```bash
# 本地连接（带密码）
redis-cli -a Redis123456
```

#### Server Agent

```bash
# 本地访问（无需认证）
curl http://127.0.0.1:8848/health

# 本地访问（需要Token）
curl -H "X-Agent-Token: changji-agent-2026" http://127.0.0.1:8848/info
```

#### Nginx 反向代理

```bash
# 远程访问（需要基础认证 + Token）
curl -u admin:Agent@2026 \
  -H "X-Agent-Token: changji-agent-2026" \
  http://101.133.238.249/agent/info
```

#### 畅记云 API 服务

```bash
# 健康检查
curl http://101.133.238.249/api/v1/health

# 用户注册
curl -X POST http://101.133.238.249/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"phone":"13800138000","password":"test123456","smsCode":"123456"}'

# 用户登录
curl -X POST http://101.133.238.249/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"phone":"13800138000","password":"test123456"}'

# 获取用户信息（需要 Token）
curl http://101.133.238.249/api/v1/auth/profile \
  -H "Authorization: Bearer <token>"
```

#### API 服务

```bash
# 本地访问
http://127.0.0.1:3000/api/v1/health

# 通过Nginx反向代理访问
http://101.133.238.249/api/v1/health
```

### 2.4 SSH 配置进展记录

#### 配置历史

| 日期 | 操作 | 状态 |
|-----|------|------|
| 2026-05-20 | 初始配置：生成 ed25519 密钥对 | ✅ 完成 |
| 2026-05-20 | 添加公钥到服务器 authorized_keys | ✅ 完成 |
| 2026-05-20 | 配置 SSH Config 别名 `changji` | ✅ 完成 |
| 2026-05-20 | 测试密码登录成功 | ✅ 完成 |
| 2026-05-20 | 配置 Nginx 反向代理 | ✅ 完成 |
| 2026-05-21 | 服务器恢复后重新验证 SSH 连接 | ✅ 完成 |
| 2026-05-21 | 密码登录可用，密钥登录待验证 | ⚠️ 待完成 |

#### 已知问题与解决

**问题1：SSH 连接超时**
- 现象：`Connection timed out`
- 原因：阿里云安全组或网络问题
- 解决：检查安全组规则，确认 22 端口开放

**问题2：密钥认证失败**
- 现象：`Permission denied (publickey)`
- 原因：公钥未正确添加到服务器
- 解决：手动添加公钥到 `~/.ssh/authorized_keys`

**问题3：服务器无法连接**
- 现象：云助手和 SSH 都无法连接
- 原因：SSH 配置错误或系统问题
- 解决：通过阿里云控制台重置实例密码，重启服务器

#### 当前配置状态

**服务器端：**
```bash
# SSH 服务状态
sudo systemctl status sshd  # active (running)

# 关键配置
Port 22
PermitRootLogin no
PasswordAuthentication yes
PubkeyAuthentication yes

# 防火墙
sudo ufw status  # 22/tcp ALLOW
```

**本地端：**
```powershell
# SSH Config (C:\Users\Mayn\.ssh\config)
Host changji
    HostName 101.133.238.249
    User admin
    Port 22
    IdentityFile ~/.ssh/id_ed25519
    StrictHostKeyChecking accept-new
```

### 2.5 连接安全规范

```
✅ 必须使用 admin 账户连接
✅ 推荐使用 SSH 密钥认证
✅ 生产环境禁止密码登录
❌ 禁止使用 root 直接登录
❌ 禁止共享账户密码
```

---

## 三、部署流程

### 3.1 部署前检查清单

```
□ 确认服务器IP可访问: ping 101.133.238.249
□ 确认拥有root或sudo权限
□ 确认阿里云安全组规则已配置
□ 备份当前系统状态（如为升级部署）
```

### 3.2 标准部署流程

#### 阶段一：系统初始化

```bash
# 1. 系统更新
sudo apt update && sudo apt upgrade -y

# 2. 安装基础工具
sudo apt install -y vim wget curl net-tools htop iotop unzip git

# 3. 创建管理用户
sudo useradd -m -s /bin/bash admin
sudo usermod -aG sudo admin
sudo usermod -aG docker admin

# 4. 配置SSH安全（编辑 /etc/ssh/sshd_config）
PermitRootLogin no
PasswordAuthentication yes
PubkeyAuthentication yes
MaxAuthTries 3
MaxSessions 2
AllowUsers admin

# 5. 重启SSH
sudo systemctl restart sshd
```

#### 阶段二：安全加固

```bash
# 1. 配置防火墙
sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable

# 2. 安装配置Fail2ban
sudo apt install -y fail2ban
# SSH: 3次失败封禁1小时

# 3. 配置自动安全更新
sudo apt install -y unattended-upgrades
```

#### 阶段三：基础服务部署

```bash
# 1. 安装Docker
sudo apt install -y docker.io
sudo systemctl enable docker
sudo systemctl start docker

# 2. 安装Nginx
sudo apt install -y nginx
sudo systemctl enable nginx
sudo systemctl start nginx

# 3. 安装Certbot
sudo apt install -y certbot python3-certbot-nginx

# 4. 配置时间同步
sudo apt install -y chrony
sudo systemctl enable chrony
```

#### 阶段四：性能优化

```bash
# 编辑 /etc/sysctl.conf
net.ipv4.tcp_max_tw_buckets = 6000
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 30
vm.swappiness = 10
fs.file-max = 655360

# 编辑 /etc/security/limits.conf
* soft nofile 65536
* hard nofile 65536

# 应用配置
sudo sysctl -p
```

#### 阶段五：应用环境部署

```bash
# 1. 安装 Node.js
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo bash -
sudo apt install -y nodejs

# 2. 安装 PM2
sudo npm install -g pm2

# 3. 安装 PostgreSQL
sudo apt install -y postgresql postgresql-contrib
sudo systemctl enable postgresql
sudo systemctl start postgresql

# 4. 创建数据库用户
sudo -u postgres psql -c "CREATE USER appuser WITH PASSWORD 'AppUser123456' CREATEDB;"
sudo -u postgres psql -c "CREATE DATABASE appdb OWNER appuser;"

# 5. 安装 Redis
sudo apt install -y redis-server
# 配置 /etc/redis/redis.conf
# - supervised systemd
# - requirepass Redis123456
sudo systemctl enable redis-server
sudo systemctl restart redis-server
```

#### 阶段六：部署 Server Agent

```bash
# 1. 安装 Python 依赖
sudo pip3 install flask

# 2. 创建 Agent 目录
sudo mkdir -p /opt/server-agent

# 3. 部署 Agent 文件
sudo cp server-agent.py /opt/server-agent/
sudo chmod +x /opt/server-agent/server-agent.py

# 4. 部署 Systemd 服务
sudo cp server-agent.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable server-agent
sudo systemctl start server-agent

# 5. 配置 Nginx 反向代理
sudo cp agent-nginx.conf /etc/nginx/sites-available/agent
sudo ln -sf /etc/nginx/sites-available/agent /etc/nginx/sites-enabled/agent

# 6. 创建基础认证
sudo apt install -y apache2-utils
sudo htpasswd -c /etc/nginx/.htpasswd admin

# 7. 测试并重载 Nginx
sudo nginx -t
sudo systemctl restart nginx
```

#### 阶段七：部署畅记云 API 服务

```bash
# 1. 创建应用目录
sudo mkdir -p /opt/changji-cloud/api
cd /opt/changji-cloud/api

# 2. 上传应用代码（通过 SCP 或 Git）
# 代码结构：
# /opt/changji-cloud/api/
#   ├── src/              # 源代码
#   ├── dist/             # 编译输出
#   ├── package.json      # 依赖配置
#   ├── ecosystem.json    # PM2 配置
#   └── .env              # 环境变量

# 3. 安装依赖
npm install

# 4. 安装额外依赖
npm install @nestjs/jwt

# 5. 构建应用
npm run build

# 6. 配置环境变量（/opt/changji-cloud/api/.env）
cat > .env << 'EOF'
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
EOF

# 7. 配置 PM2（/opt/changji-cloud/api/ecosystem.json）
cat > ecosystem.json << 'EOF'
{
  "apps": [{
    "name": "changji-api",
    "script": "./dist/main.js",
    "instances": 1,
    "exec_mode": "fork",
    "env": {
      "NODE_ENV": "production"
    },
    "log_file": "/var/log/changji-api.log",
    "error_file": "/var/log/changji-api-error.log",
    "out_file": "/var/log/changji-api-out.log",
    "max_memory_restart": "512M",
    "restart_delay": 3000,
    "max_restarts": 5,
    "min_uptime": "10s"
  }]
}
EOF

# 8. 创建日志文件
sudo touch /var/log/changji-api.log /var/log/changji-api-error.log /var/log/changji-api-out.log
sudo chown admin:admin /var/log/changji-api*.log

# 9. 启动服务
pm2 start ecosystem.json
pm2 save
pm2 startup

# 10. 配置 Nginx 反向代理（/etc/nginx/sites-available/api）
cat > /etc/nginx/sites-available/api << 'EOF'
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

    location / {
        return 404;
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/api /etc/nginx/sites-enabled/api
sudo nginx -t
sudo systemctl restart nginx
```

#### 阶段八：备份策略

```bash
# 创建备份目录
sudo mkdir -p /backup/scripts /backup/data

# 创建数据库备份脚本 /backup/scripts/backup-db.sh
#!/bin/bash
BACKUP_DIR="/backup/data"
DATE=$(date +%Y%m%d_%H%M%S)

# 备份 PostgreSQL
sudo -u postgres pg_dump appdb > "$BACKUP_DIR/appdb_$DATE.sql"

# 备份 Redis
redis-cli -a Redis123456 BGSAVE
sleep 2
cp /var/lib/redis/dump.rdb "$BACKUP_DIR/redis_$DATE.rdb"

# 清理7天前的备份
find $BACKUP_DIR -mtime +7 -delete
```

# 设置定时任务
crontab -e
# 添加：0 2 * * * /backup/scripts/backup-db.sh
```

### 3.3 部署后验证

```bash
# 检查所有服务状态
sudo systemctl status ssh nginx docker postgresql redis-server fail2ban unattended-upgrades chrony

# 检查防火墙
sudo ufw status verbose

# 检查Docker
sudo docker --version
sudo docker run hello-world

# 检查Nginx
curl -I http://localhost

# 检查Node.js
node --version
npm --version

# 检查PM2
pm2 status

# 检查PostgreSQL
psql --version
sudo -u postgres psql -c "\l"

# 检查Redis
redis-server --version
redis-cli -a Redis123456 ping

# 检查Agent
curl http://127.0.0.1:8848/health
curl -H "X-Agent-Token: changji-agent-2026" http://127.0.0.1:8848/info

# 检查API服务
curl http://127.0.0.1:3000/api/v1/health
curl http://101.133.238.249/api/v1/health

# 检查Nginx反向代理
curl -u admin:Agent@2026 -H "X-Agent-Token: changji-agent-2026" http://101.133.238.249/agent/info

# 检查端口监听
sudo ss -tlnp
```

---

## 四、权限管理

### 4.1 用户账户体系

| 用户 | 权限 | 用途 |
|-----|------|------|
| root | 全部 | 系统管理（禁止SSH登录） |
| admin | sudo | 日常管理（主要操作账户） |
| www-data | 服务 | Nginx运行用户 |
| postgres | 服务 | PostgreSQL运行用户 |
| redis | 服务 | Redis运行用户 |
| server-agent | root | Agent服务运行用户 |

### 4.2 SSH访问规范

```
✅ 必须使用admin账户登录
✅ 推荐使用SSH密钥认证
❌ 禁止使用root直接登录
❌ 禁止密码认证（配置密钥后）
❌ 禁止共享账户
```

---

## 五、版本控制

### 5.1 软件版本管理

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

### 5.2 配置版本控制

```bash
# 修改前必须备份
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak.$(date +%Y%m%d)

# 记录变更
echo "$(date): 修改sshd_config" >> /var/log/config-changes.log
```

### 5.3 部署版本标记

```bash
echo "部署版本: v1.0.0" > /etc/deploy-version
echo "部署时间: $(date)" >> /etc/deploy-version
```

---

## 六、回滚机制

### 6.1 配置文件回滚

```bash
# 回滚SSH配置
sudo cp /etc/ssh/sshd_config.bak.20260520 /etc/ssh/sshd_config
sudo systemctl restart sshd

# 回滚Nginx配置
sudo cp /etc/nginx/sites-available/api.bak.20260520 /etc/nginx/sites-available/api
sudo nginx -t
sudo systemctl restart nginx
```

### 6.2 服务回滚

```bash
# API服务回滚
pm2 stop changji-api
# 恢复上一版本代码
cd /opt/changji-cloud/api && git checkout <previous-tag>
npm install && npm run build
pm2 start ecosystem.json

# Nginx配置回滚
sudo nginx -t
sudo systemctl restart nginx
```

### 6.3 数据库回滚

```bash
# 从备份恢复PostgreSQL
sudo -u postgres psql -d appdb < /backup/data/appdb_20260520_020000.sql

# 从备份恢复Redis
sudo systemctl stop redis-server
cp /backup/data/redis_20260520_020000.rdb /var/lib/redis/dump.rdb
sudo systemctl start redis-server
```

### 6.4 系统级回滚

```bash
# 使用备份恢复
sudo tar -xzf /backup/data/20260520_020000.tar.gz -C /

# 或使用阿里云快照回滚（控制台操作）
```

### 6.5 紧急回滚流程

```
1. 停止相关服务
2. 恢复配置文件备份
3. 重启服务验证
4. 记录回滚原因到 /var/log/rollback.log
```

---

## 七、安全防护

### 7.1 网络安全

| 层级 | 措施 | 状态 |
|-----|------|------|
| 阿里云安全组 | 限制SSH端口IP白名单 | ⚠️ 待配置 |
| UFW防火墙 | 仅开放22/80/443 | ✅ 已启用 |
| Fail2ban | 3次失败封禁1小时 | ✅ 已启用 |
| SSH | 禁用root登录 | ✅ 已配置 |
| Nginx | 基础认证 + Token | ✅ 已配置 |

### 7.2 API安全

| 措施 | 说明 | 状态 |
|-----|------|------|
| JWT认证 | 访问令牌 + 刷新令牌 | ✅ 已启用 |
| 密码加密 | bcrypt哈希存储 | ✅ 已启用 |
| 输入验证 | class-validator验证 | ✅ 已启用 |
| 速率限制 | 待配置 | ⚠️ 待配置 |
| HTTPS | 待配置SSL证书 | ⚠️ 待配置 |

### 7.3 安全审计清单

```
□ 每月检查登录日志
□ 每月检查Fail2ban封禁记录
□ 每月检查API访问日志
□ 每季度更新所有软件
□ 每季度轮换SSH密钥
□ 每半年审查用户权限
□ 每年更换数据库密码
```

---

## 八、运维规范

### 8.1 日常检查命令

```bash
# 每日检查
sudo systemctl status ssh nginx docker postgresql redis-server fail2ban
sudo df -h
sudo free -h
pm2 status

# 每周检查
sudo apt list --upgradable
sudo ufw status verbose
sudo fail2ban-client status sshd
sudo -u postgres psql -c "SELECT count(*) FROM pg_stat_activity;"
redis-cli -a Redis123456 info stats

# 每月检查
sudo cat /var/log/auth.log | grep "Failed password"
pm2 logs changji-api --lines 100
```

### 8.2 日志管理

| 日志文件 | 内容 | 保留周期 |
|---------|------|---------|
| /var/log/auth.log | 认证日志 | 30天 |
| /var/log/syslog | 系统日志 | 30天 |
| /var/log/nginx/access.log | Nginx访问 | 7天 |
| /var/log/nginx/error.log | Nginx错误 | 30天 |
| /var/log/nginx/agent-access.log | Agent访问日志 | 7天 |
| /var/log/nginx/agent-error.log | Agent错误日志 | 30天 |
| /var/log/postgresql/postgresql-14-main.log | PostgreSQL日志 | 30天 |
| /var/log/redis/redis-server.log | Redis日志 | 30天 |
| /var/log/server-agent.log | Agent服务日志 | 30天 |
| /var/log/changji-api.log | API服务日志 | 30天 |
| /var/log/changji-api-error.log | API错误日志 | 30天 |
| /var/log/changji-api-out.log | API输出日志 | 30天 |

### 8.3 应急响应

#### 服务宕机

```bash
# 1. 检查服务状态
sudo systemctl status <service>

# 2. 查看错误日志
sudo journalctl -u <service> -n 50

# 3. 尝试重启
sudo systemctl restart <service>

# 4. 如无法恢复，回滚配置
```

#### API服务异常

```bash
# 1. 检查PM2状态
pm2 status

# 2. 查看API日志
pm2 logs changji-api --lines 50

# 3. 检查错误日志
cat /var/log/changji-api-error.log | tail -50

# 4. 重启API服务
pm2 restart changji-api

# 5. 检查Nginx配置
sudo nginx -t
sudo systemctl restart nginx
```

#### 安全事件

```bash
# 1. 封禁可疑IP
sudo fail2ban-client set sshd banip <IP>

# 2. 检查入侵痕迹
sudo grep <IP> /var/log/auth.log

# 3. 检查API异常访问
sudo grep <IP> /var/log/nginx/access.log

# 4. 如确认入侵，立即修改所有密码
# 5. 检查文件完整性
sudo find /etc -type f -mtime -1
```

#### 磁盘空间不足

```bash
# 检查磁盘使用
sudo df -h

# 清理Docker
sudo docker system prune -a

# 清理日志
sudo journalctl --vacuum-time=7d

# 清理旧备份
sudo find /backup/data -mtime +7 -delete

# 清理PostgreSQL日志
sudo find /var/log/postgresql -name "*.log" -mtime +7 -delete

# 清理Redis日志
sudo find /var/log/redis -name "*.log" -mtime +7 -delete

# 清理API日志
sudo find /var/log/changji-api*.log -mtime +7 -delete
```

---

## 九、已知问题与解决方案

### 问题1：NestJS模块依赖错误

**现象**：`Nest can't resolve dependencies of the JwtAuthGuard`

**原因**：`JwtAuthGuard` 依赖 `JwtService`，但模块未正确导入/导出

**解决**：
1. 在 `auth.module.ts` 中导出 `JwtModule`：`exports: [AuthService, JwtModule]`
2. 在使用 `JwtAuthGuard` 的模块中导入 `AuthModule`

### 问题2：Nginx代理路径错误

**现象**：API请求返回404或路径不匹配

**原因**：`proxy_pass` 路径配置错误，导致 `/api` 前缀丢失

**解决**：
```nginx
location /api/ {
    proxy_pass http://127.0.0.1:3000/api/;  # 注意末尾的 /
}
```

### 问题3：环境变量名不匹配

**现象**：数据库连接失败

**原因**：使用 `DB_PASS` 但代码期望 `DB_PASSWORD`

**解决**：统一使用 `DB_PASSWORD` 作为环境变量名

### 问题4：登录返回401

**现象**：注册用户成功，但登录返回401

**原因**：测试用户密码哈希可能有问题

**解决**：重新创建测试用户或重置密码

---

## 十、相关文档

| 文档 | 用途 |
|-----|------|
| [SERVER_STATUS.md](SERVER_STATUS.md) | 当前服务器部署状态报告 |
| [RED_LINES.md](RED_LINES.md) | 通用安全红线 |
| [BUILD_RED_LINES.md](BUILD_RED_LINES.md) | APK构建红线 |
| [API_DESIGN.md](API_DESIGN.md) | API设计规范 |

---

## 十一、畅记云 API 接口说明

### 11.1 基础信息

- **Base URL**: `http://101.133.238.249/api/v1`
- **认证方式**: JWT Bearer Token
- **数据格式**: JSON

### 11.2 认证接口

#### 用户注册
```
POST /auth/register
Content-Type: application/json

{
  "phone": "13800138000",
  "password": "test123456",
  "smsCode": "123456"
}

Response:
{
  "code": 200,
  "message": "success",
  "data": {
    "accessToken": "eyJhbGc...",
    "refreshToken": "eyJhb..."
  }
}
```

#### 用户登录
```
POST /auth/login
Content-Type: application/json

{
  "phone": "13800138000",
  "password": "test123456"
}

Response:
{
  "code": 200,
  "message": "success",
  "data": {
    "accessToken": "eyJhbGc...",
    "refreshToken": "eyJhb..."
  }
}
```

#### 获取用户信息
```
GET /auth/profile
Authorization: Bearer <accessToken>

Response:
{
  "code": 200,
  "message": "success",
  "data": {
    "id": "uuid",
    "phone": "13800138000"
  }
}
```

### 11.3 订阅管理接口

#### 获取当前订阅
```
GET /subscription
Authorization: Bearer <accessToken>

Response:
{
  "code": 200,
  "message": "success",
  "data": {
    "planId": "free",
    "planName": "免费版",
    "status": "active",
    "expiresAt": null,
    "totalQuota": 30,
    "usedQuota": 0,
    "remainingQuota": 30
  }
}
```

#### 创建订阅
```
POST /subscription
Authorization: Bearer <accessToken>
Content-Type: application/json

{
  "planId": "basic"
}

Response:
{
  "code": 200,
  "message": "订阅创建成功",
  "data": { ... }
}
```

#### 获取套餐列表
```
GET /subscription/plans

Response:
{
  "code": 200,
  "message": "success",
  "data": [
    {
      "id": "free",
      "name": "免费版",
      "description": "免费体验套餐",
      "priceCents": 0,
      "durationDays": 30,
      "quotaType": "minutes",
      "quotaValue": 30
    },
    {
      "id": "basic",
      "name": "基础版",
      "description": "基础功能套餐",
      "priceCents": 9900,
      "durationDays": 30,
      "quotaType": "minutes",
      "quotaValue": 300
    }
  ]
}
```

#### 使用配额
```
POST /subscription/quota/use
Authorization: Bearer <accessToken>
Content-Type: application/json

{
  "amount": 5
}

Response:
{
  "code": 200,
  "message": "配额使用成功",
  "data": {
    "planId": "free",
    "usedQuota": 5,
    "remainingQuota": 25
  }
}
```

#### 创建套餐（管理员）
```
POST /subscription/plans
Authorization: Bearer <accessToken>
Content-Type: application/json

{
  "id": "premium",
  "name": "高级版",
  "description": "高级功能套餐",
  "priceCents": 19900,
  "durationDays": 30,
  "quotaType": "minutes",
  "quotaValue": 500
}
```

### 11.4 API Key 分发接口

#### 获取分配的 API Key
```
GET /api-key
Authorization: Bearer <accessToken>

Response:
{
  "code": 200,
  "message": "success",
  "data": {
    "provider": "qwen",
    "apiKey": "sk-xxxxx",
    "model": "qwen-max",
    "rateLimitPerMin": 60,
    "expiresAt": "2026-05-21T10:30:00.000Z"
  }
}
```

#### 刷新 API Key
```
POST /api-key/refresh
Authorization: Bearer <accessToken>

Response:
{
  "code": 200,
  "message": "success",
  "data": {
    "provider": "qwen",
    "apiKey": "sk-yyyyy",
    "model": "qwen-max",
    "rateLimitPerMin": 60,
    "expiresAt": "2026-05-21T10:30:00.000Z"
  }
}
```

#### 获取 API Key 列表（管理员）
```
GET /api-key/admin/list
Authorization: Bearer <accessToken>

Response:
{
  "code": 200,
  "message": "success",
  "data": [
    {
      "id": "uuid",
      "provider": "qwen",
      "model": "qwen-max",
      "isActive": true,
      "rateLimitPerMin": 60,
      "createdAt": "2026-05-20T10:00:00.000Z"
    }
  ]
}
```

#### 创建 API Key（管理员）
```
POST /api-key/admin/create
Authorization: Bearer <accessToken>
Content-Type: application/json

{
  "provider": "qwen",
  "apiKey": "sk-xxxxx",
  "model": "qwen-max",
  "rateLimitPerMin": 60
}

Response:
{
  "code": 200,
  "message": "API Key 创建成功",
  "data": {
    "id": "uuid",
    "provider": "qwen",
    "model": "qwen-max",
    "isActive": true
  }
}
```

#### 删除 API Key（管理员）
```
DELETE /api-key/admin/:id
Authorization: Bearer <accessToken>

Response:
{
  "code": 200,
  "message": "API Key 删除成功"
}
```

### 11.5 使用流程

1. 用户注册/登录获取 JWT Token
2. 用户查看套餐信息并创建订阅
3. 用户调用 API Key 接口获取 AI 服务密钥
4. 用户使用获取的 API Key 调用 AI 服务
5. 系统自动扣除用户配额

---

## 十二、部署步骤

### 12.1 本地开发部署

```bash
# 1. 进入 server 目录
cd server

# 2. 安装依赖
npm install

# 3. 配置环境变量
cp .env.example .env
# 编辑 .env 文件，填写数据库等配置

# 4. 启动开发服务器
npm run start:dev
```

### 12.2 生产环境部署

```bash
# 1. 上传代码到服务器
# 使用提供的 deploy-server.ps1 脚本，或手动上传

# 2. 服务器上执行
ssh admin@101.133.238.249
cd /opt/changji-cloud/api

# 3. 初始化数据库（首次部署）
# 连接 PostgreSQL 并执行 seed-data.sql

# 4. 启动服务
pm2 start ecosystem.json
pm2 save

# 5. 检查服务状态
pm2 status
pm2 logs changji-api
```

### 12.3 数据库初始化

```bash
# 连接数据库
sudo -u postgres psql -d appdb

# 执行种子数据
\i /opt/changji-cloud/api/seed-data.sql

# 或直接从本地执行
cat server/seed-data.sql | ssh admin@101.133.238.249 "sudo -u postgres psql -d appdb"
```

---

## 更新记录

| 日期 | 版本 | 更新内容 |
|-----|------|---------|
| 2026-05-20 | v1.0 | 初始版本，整合部署规则文档 |
| 2026-05-20 | v1.1 | 新增Node.js/PostgreSQL/Redis部署规范 |
| 2026-05-20 | v1.2 | 新增服务器连接方式章节 |
| 2026-05-20 | v1.3 | 新增Server Agent和Nginx反向代理配置 |
| 2026-05-20 | v1.4 | 新增畅记云API服务部署、PM2配置、已知问题与解决方案 |
| 2026-05-20 | v1.5 | 新增订阅管理、API Key分发、完整API文档 |