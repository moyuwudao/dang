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
**文档版本**：v1.2

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

#### 方式一：密码登录（当前方式）

```bash
# Linux/Mac 终端
ssh admin@101.133.238.249

# Windows (PowerShell)
ssh admin@101.133.238.249
```

#### 方式二：密钥登录（推荐）

```bash
# 1. 生成密钥对（本地执行）
ssh-keygen -t ed25519 -C "your_email@example.com"

# 2. 上传公钥到服务器
ssh-copy-id admin@101.133.238.249

# 3. 使用密钥登录
ssh admin@101.133.238.249
```

### 2.3 数据库连接方式

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

### 2.4 连接安全规范

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

#### 阶段三：服务部署

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

# 2. 安装 PostgreSQL
sudo apt install -y postgresql postgresql-contrib
sudo systemctl enable postgresql
sudo systemctl start postgresql

# 3. 创建数据库用户
sudo -u postgres psql -c "CREATE USER appuser WITH PASSWORD 'AppUser123456' CREATEDB;"
sudo -u postgres psql -c "CREATE DATABASE appdb OWNER appuser;"

# 4. 安装 Redis
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

#### 阶段七：备份策略

```bash
# 创建备份目录
sudo mkdir -p /backup/scripts /backup/data

# 创建备份脚本 /backup/scripts/backup.sh
# 设置定时任务
crontab -e
# 添加：0 2 * * * /backup/scripts/backup.sh
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

# 检查PostgreSQL
psql --version
sudo -u postgres psql -c "\l"

# 检查Redis
redis-server --version
redis-cli ping

# 检查Agent
curl http://127.0.0.1:8848/health
curl -H "X-Agent-Token: changji-agent-2026" http://127.0.0.1:8848/info

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
```

### 6.2 服务回滚

```bash
# Docker容器回滚
docker ps -a
docker stop <container>
docker start <previous_container>

# Nginx配置回滚
sudo nginx -t
sudo systemctl restart nginx
```

### 6.3 系统级回滚

```bash
# 使用备份恢复
sudo tar -xzf /backup/data/20260520_020000.tar.gz -C /

# 或使用阿里云快照回滚（控制台操作）
```

### 6.4 紧急回滚流程

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

### 7.2 安全审计清单

```
□ 每月检查登录日志
□ 每月检查Fail2ban封禁记录
□ 每季度更新所有软件
□ 每季度轮换SSH密钥
□ 每半年审查用户权限
```

---

## 八、运维规范

### 8.1 日常检查命令

```bash
# 每日检查
sudo systemctl status ssh nginx docker postgresql redis-server fail2ban
sudo df -h
sudo free -h

# 每周检查
sudo apt list --upgradable
sudo ufw status verbose
sudo fail2ban-client status sshd
sudo -u postgres psql -c "SELECT count(*) FROM pg_stat_activity;"
redis-cli info stats
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

#### 安全事件

```bash
# 1. 封禁可疑IP
sudo fail2ban-client set sshd banip <IP>

# 2. 检查入侵痕迹
sudo grep <IP> /var/log/auth.log

# 3. 如确认入侵，立即修改所有密码
# 4. 检查文件完整性
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
```

---

## 八、相关文档

| 文档 | 用途 |
|-----|------|
| [SERVER_STATUS.md](SERVER_STATUS.md) | 当前服务器部署状态报告 |
| [RED_LINES.md](RED_LINES.md) | 通用安全红线 |
| [BUILD_RED_LINES.md](BUILD_RED_LINES.md) | APK构建红线 |

---

## 更新记录

| 日期 | 版本 | 更新内容 |
|-----|------|---------|
| 2026-05-20 | v1.0 | 初始版本，整合部署规则文档 |
| 2026-05-20 | v1.1 | 新增Node.js/PostgreSQL/Redis部署规范 |
| 2026-05-20 | v1.2 | 新增服务器连接方式章节 |
| 2026-05-20 | v1.3 | 新增Server Agent和Nginx反向代理配置 |
