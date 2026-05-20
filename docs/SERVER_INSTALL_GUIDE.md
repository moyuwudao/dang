# 畅记云服务 - Node.js + PostgreSQL + Redis 安装指南

> 目标服务器：101.133.238.249 (Ubuntu 22.04.5 LTS)
> 适用：2核1.6G内存 / 40G SSD
> 安装内容：Node.js 20 + PostgreSQL 16 + Redis 7 + PM2

---

## 一、安装前检查

### 1.1 SSH 登录服务器

```bash
# 使用 admin 账户登录
ssh admin@101.133.238.249

# 输入密码后进入
```

### 1.2 检查当前资源

```bash
# 查看内存
free -h

# 查看磁盘
df -h

# 查看现有服务
sudo systemctl status docker nginx
```

**预期输出**：
- 内存：1.6G，可用 > 1G
- 磁盘：40G，可用 > 34G
- Docker：active
- Nginx：active

---

## 二、安装 Node.js 20

### 2.1 安装步骤

```bash
# 1. 下载 NodeSource 安装脚本
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -

# 2. 安装 Node.js 和 npm
sudo apt-get install -y nodejs

# 3. 验证安装
node --version    # 应输出 v20.x.x
npm --version     # 应输出 10.x.x

# 4. 安装 PM2（进程管理器）
sudo npm install -g pm2

# 5. 验证 PM2
pm2 --version
```

### 2.2 配置 npm（可选，加速国内下载）

```bash
# 配置淘宝镜像（国内服务器推荐）
npm config set registry https://registry.npmmirror.com

# 验证
npm config get registry
```

### 2.3 内存优化配置

```bash
# 配置 Node.js 内存限制（1.6G 内存环境）
echo 'export NODE_OPTIONS="--max-old-space-size=1024"' >> ~/.bashrc
source ~/.bashrc
```

---

## 三、安装 PostgreSQL 16

### 3.1 安装步骤

```bash
# 1. 添加 PostgreSQL 官方仓库
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'

# 2. 导入签名密钥
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

# 3. 更新包列表
sudo apt-get update

# 4. 安装 PostgreSQL 16
sudo apt-get install -y postgresql-16 postgresql-client-16

# 5. 验证安装
psql --version    # 应输出 psql (PostgreSQL) 16.x

# 6. 启动并设置开机自启
sudo systemctl start postgresql
sudo systemctl enable postgresql

# 7. 检查状态
sudo systemctl status postgresql
```

### 3.2 配置 PostgreSQL（低内存优化）

```bash
# 编辑配置文件
sudo nano /etc/postgresql/16/main/postgresql.conf
```

**修改以下配置**（1.6G 内存优化）：

```conf
# 内存配置
shared_buffers = 256MB          # 默认 128MB，提高到 256MB
effective_cache_size = 512MB    # 默认 4GB，降低到 512MB
maintenance_work_mem = 64MB     # 默认 64MB，保持
work_mem = 4MB                  # 默认 4MB，保持

# 连接配置
max_connections = 50            # 默认 100，降低到 50

# WAL 配置
wal_buffers = 16MB              # 自动调整
checkpoint_completion_target = 0.9

# 日志配置
logging_collector = on
log_directory = 'log'
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'
log_rotation_age = 1d
log_rotation_size = 100MB

# 性能配置
random_page_cost = 1.1
effective_io_concurrency = 200
```

### 3.3 创建数据库和用户

```bash
# 切换到 postgres 用户
sudo -u postgres psql
```

在 psql 中执行：

```sql
-- 创建数据库用户
CREATE USER changji WITH PASSWORD 'changji_db_password_2024';

-- 创建数据库
CREATE DATABASE changji OWNER changji;

-- 授予权限
GRANT ALL PRIVILEGES ON DATABASE changji TO changji;

-- 退出
\q
```

### 3.4 配置远程访问（仅本地，不开放公网）

```bash
# 编辑 pg_hba.conf
sudo nano /etc/postgresql/16/main/pg_hba.conf
```

确保有以下行：

```conf
# 本地连接使用密码验证
local   all             all                                     scram-sha-256
host    all             all             127.0.0.1/32            scram-sha-256
host    all             all             ::1/128                 scram-sha-256
```

```bash
# 重启 PostgreSQL
sudo systemctl restart postgresql
```

### 3.5 测试连接

```bash
# 测试本地连接
psql -h localhost -U changji -d changji

# 输入密码：changji_db_password_2024

# 测试查询
SELECT version();
\q
```

---

## 四、安装 Redis 7

### 4.1 安装步骤

```bash
# 1. 安装 Redis
sudo apt-get install -y redis-server

# 2. 验证安装
redis-cli --version    # 应输出 redis-cli 7.x.x

# 3. 启动并设置开机自启
sudo systemctl start redis-server
sudo systemctl enable redis-server

# 4. 检查状态
sudo systemctl status redis-server
```

### 4.2 配置 Redis（低内存 + 安全）

```bash
# 编辑配置文件
sudo nano /etc/redis/redis.conf
```

**修改以下配置**：

```conf
# 绑定仅本地（不开放公网）
bind 127.0.0.1

# 启用密码认证
requirepass changji_redis_password_2024

# 内存限制（1.6G 内存环境）
maxmemory 128mb
maxmemory-policy allkeys-lru

# 持久化配置
save 900 1
save 300 10
save 60 10000

# 日志配置
loglevel notice
logfile /var/log/redis/redis-server.log

# 禁用危险命令（可选）
rename-command FLUSHALL ""
rename-command FLUSHDB ""
```

```bash
# 创建日志目录
sudo mkdir -p /var/log/redis
sudo chown redis:redis /var/log/redis

# 重启 Redis
sudo systemctl restart redis-server
```

### 4.3 测试连接

```bash
# 连接 Redis
redis-cli

# 认证
AUTH changji_redis_password_2024

# 测试
SET test_key "hello"
GET test_key
DEL test_key

# 退出
EXIT
```

---

## 五、创建项目目录结构

### 5.1 创建目录

```bash
# 创建项目根目录
sudo mkdir -p /opt/changji-cloud
sudo chown admin:admin /opt/changji-cloud

# 创建子目录
cd /opt/changji-cloud
mkdir -p api logs backup

# 目录结构
# /opt/changji-cloud/
# ├── api/           # NestJS 项目代码
# ├── logs/          # 应用日志
# ├── backup/        # 备份文件
# └── docker-compose.yml  # 容器编排（如使用 Docker）
```

---

## 六、配置防火墙

### 6.1 更新 UFW 规则

```bash
# 查看当前规则
sudo ufw status verbose

# PostgreSQL 和 Redis 仅本地访问，不需要开放端口
# 确认 80/443/22 已开放即可

# 如果需要开放其他端口（如 3000 用于测试）
# sudo ufw allow 3000/tcp
```

**注意**：生产环境不要直接暴露 3000 端口，通过 Nginx 反向代理。

---

## 七、验证安装

### 7.1 验证所有服务

```bash
# 创建验证脚本
cat > /opt/changji-cloud/verify.sh << 'EOF'
#!/bin/bash
echo "=========================================="
echo "  畅记云服务 - 安装验证"
echo "=========================================="
echo ""

echo "[1] Node.js 版本:"
node --version

echo ""
echo "[2] NPM 版本:"
npm --version

echo ""
echo "[3] PM2 版本:"
pm2 --version

echo ""
echo "[4] PostgreSQL 版本:"
psql --version

echo ""
echo "[5] PostgreSQL 服务状态:"
sudo systemctl is-active postgresql

echo ""
echo "[6] Redis 版本:"
redis-cli --version

echo ""
echo "[7] Redis 服务状态:"
sudo systemctl is-active redis-server

echo ""
echo "[8] 内存使用:"
free -h

echo ""
echo "[9] 磁盘使用:"
df -h

echo ""
echo "[10] 端口监听:"
sudo ss -tlnp | grep -E ':(22|80|443|5432|6379)'

echo ""
echo "=========================================="
echo "  验证完成"
echo "=========================================="
EOF

chmod +x /opt/changji-cloud/verify.sh

# 执行验证
/opt/changji-cloud/verify.sh
```

### 7.2 预期输出

```
==========================================
  畅记云服务 - 安装验证
==========================================

[1] Node.js 版本:
v20.x.x

[2] NPM 版本:
10.x.x

[3] PM2 版本:
5.x.x

[4] PostgreSQL 版本:
psql (PostgreSQL) 16.x

[5] PostgreSQL 服务状态:
active

[6] Redis 版本:
redis-cli 7.x.x

[7] Redis 服务状态:
active

[8] 内存使用:
              total        used        free      shared  buff/cache   available
Mem:          1.6Gi       xxxMi       xxxMi       x.xMi       xxxMi       x.xGi
Swap:            0B          0B          0B

[9] 磁盘使用:
Filesystem      Size  Used Avail Use% Mounted on
/dev/vda1        40G  x.xG   34G  x% /

[10] 端口监听:
LISTEN 0  128  0.0.0.0:22     ...
LISTEN 0  128  0.0.0.0:80     ...
LISTEN 0  128  0.0.0.0:443    ...
LISTEN 0  128  127.0.0.1:5432 ...
LISTEN 0  128  127.0.0.1:6379 ...

==========================================
  验证完成
==========================================
```

---

## 八、环境变量配置

### 8.1 创建环境变量文件

```bash
# 创建环境变量文件
cat > /opt/changji-cloud/.env << 'EOF'
# 数据库配置
DB_HOST=localhost
DB_PORT=5432
DB_NAME=changji
DB_USER=changji
DB_PASSWORD=changji_db_password_2024

# Redis 配置
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=changji_redis_password_2024

# JWT 配置（生产环境必须修改！）
JWT_SECRET=changji_jwt_secret_change_me_in_production
JWT_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=7d

# 应用配置
NODE_ENV=production
PORT=3000
API_PREFIX=/api/v1

# 阿里云短信配置（按需填写）
SMS_ACCESS_KEY_ID=
SMS_ACCESS_KEY_SECRET=
SMS_SIGN_NAME=
SMS_TEMPLATE_CODE=

# 支付配置（按需填写）
WECHAT_MCH_ID=
WECHAT_API_KEY=
WECHAT_APP_ID=
ALIPAY_APP_ID=
ALIPAY_PRIVATE_KEY=
ALIPAY_PUBLIC_KEY=
EOF

# 设置权限
chmod 600 /opt/changji-cloud/.env
```

**⚠️ 安全提醒**：
- 生产环境必须修改 `JWT_SECRET` 为随机强密码
- `.env` 文件权限设置为 600（仅所有者可读写）
- 不要将 `.env` 提交到 Git

---

## 九、一键安装脚本

### 9.1 完整安装脚本

如果需要一键安装，创建以下脚本：

```bash
cat > /opt/changji-cloud/install-all.sh << 'EOF'
#!/bin/bash
set -e

echo "=========================================="
echo "  畅记云服务 - 一键安装"
echo "=========================================="

# 1. 更新系统
echo "[1/6] 更新系统..."
sudo apt-get update && sudo apt-get upgrade -y

# 2. 安装 Node.js
echo "[2/6] 安装 Node.js 20..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs
sudo npm install -g pm2

# 3. 安装 PostgreSQL
echo "[3/6] 安装 PostgreSQL 16..."
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get update
sudo apt-get install -y postgresql-16 postgresql-client-16
sudo systemctl start postgresql
sudo systemctl enable postgresql

# 4. 安装 Redis
echo "[4/6] 安装 Redis..."
sudo apt-get install -y redis-server
sudo systemctl start redis-server
sudo systemctl enable redis-server

# 5. 配置数据库
echo "[5/6] 配置数据库..."
sudo -u postgres psql -c "CREATE USER changji WITH PASSWORD 'changji_db_password_2024';"
sudo -u postgres psql -c "CREATE DATABASE changji OWNER changji;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE changji TO changji;"

# 6. 验证安装
echo "[6/6] 验证安装..."
node --version
psql --version
redis-cli --version

echo ""
echo "=========================================="
echo "  安装完成！"
echo "=========================================="
echo ""
echo "请执行以下操作："
echo "1. 修改 /opt/changji-cloud/.env 中的 JWT_SECRET"
echo "2. 配置 PostgreSQL 和 Redis 的密码"
echo "3. 重启所有服务"
echo ""
EOF

chmod +x /opt/changji-cloud/install-all.sh
```

---

## 十、常见问题

### Q1: 内存不足怎么办？

```bash
# 创建 Swap 文件（如果还没有）
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

### Q2: PostgreSQL 启动失败？

```bash
# 查看日志
sudo journalctl -u postgresql -n 50

# 检查配置语法
sudo -u postgres pg_ctlcluster 16 main configtest
```

### Q3: Redis 连接失败？

```bash
# 检查 Redis 状态
sudo systemctl status redis-server

# 检查日志
sudo tail -f /var/log/redis/redis-server.log

# 测试连接
redis-cli ping
```

### Q4: Node.js 版本不对？

```bash
# 卸载旧版本
sudo apt-get remove nodejs npm

# 清理缓存
sudo rm -rf /usr/local/bin/node
sudo rm -rf /usr/local/bin/npm

# 重新安装
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs
```

---

## 十一、下一步

安装完成后，继续：

1. **部署 NestJS 后端服务**
   - 上传代码到 `/opt/changji-cloud/api/`
   - 运行 `npm install && npm run build`
   - 使用 PM2 启动服务

2. **配置 Nginx 反向代理**
   - 配置 SSL 证书
   - 设置反向代理到 localhost:3000

3. **客户端对接**
   - 配置 API 基础地址
   - 实现登录/订阅/Key 获取逻辑

---

*文档版本：v1.0*
*更新日期：2026-05-13*
*状态：待执行*
