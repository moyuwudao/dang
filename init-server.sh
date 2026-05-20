#!/bin/bash
# =============================================================================
# 阿里云 ECS Ubuntu 20.04 服务器初始化脚本
# 服务器: 101.133.238.249
# 生成时间: 2026-05-19
# =============================================================================

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# =============================================================================
# 1. 系统更新
# =============================================================================
log_info "开始系统更新..."
apt update && apt upgrade -y
apt install -y vim wget curl net-tools htop iotop unzip git
log_info "系统更新完成"

# =============================================================================
# 2. 创建管理用户
# =============================================================================
log_info "创建管理用户..."
USERNAME="admin"
USER_PASSWORD="Admin@123456!"

if id "$USERNAME" &>/dev/null; then
    log_warn "用户 $USERNAME 已存在，跳过创建"
else
    useradd -m -s /bin/bash "$USERNAME"
    echo "$USERNAME:$USER_PASSWORD" | chpasswd
    usermod -aG sudo "$USERNAME"
    log_info "用户 $USERNAME 创建完成，密码: $USER_PASSWORD"
fi

# =============================================================================
# 3. 配置 SSH 安全
# =============================================================================
log_info "配置 SSH 安全..."

# 备份原配置
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak.$(date +%Y%m%d)

# 生成新的 SSH 配置
cat > /etc/ssh/sshd_config << 'EOF'
# SSH 安全配置
Port 22
ListenAddress 0.0.0.0

# 认证配置
PermitRootLogin no
PasswordAuthentication yes
PubkeyAuthentication yes
PermitEmptyPasswords no
ChallengeResponseAuthentication no

# 安全限制
MaxAuthTries 3
MaxSessions 2
LoginGraceTime 30
ClientAliveInterval 300
ClientAliveCountMax 2

# 协议版本
Protocol 2

# 密钥算法
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key

# 允许的用户
AllowUsers admin root

# 其他配置
UsePAM yes
X11Forwarding no
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server
EOF

# 重启 SSH 服务
systemctl restart sshd
log_info "SSH 配置完成"

# =============================================================================
# 4. 配置防火墙 (UFW)
# =============================================================================
log_info "配置防火墙..."

# 重置 UFW
ufw --force reset

# 默认策略
ufw default deny incoming
ufw default allow outgoing

# 允许 SSH
ufw allow 22/tcp

# 允许 HTTP/HTTPS
ufw allow 80/tcp
ufw allow 443/tcp

# 启用 UFW
echo "y" | ufw enable

log_info "防火墙配置完成"
ufw status verbose

# =============================================================================
# 5. 安装 Docker 和 Docker Compose
# =============================================================================
log_info "安装 Docker..."

# 卸载旧版本
apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

# 安装依赖
apt install -y ca-certificates gnupg lsb-release

# 添加 Docker GPG 密钥
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# 添加 Docker 仓库
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# 安装 Docker
apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# 启动 Docker
systemctl enable docker
systemctl start docker

# 将 admin 用户添加到 docker 组
usermod -aG docker admin

# 安装 Docker Compose v2
DOCKER_CONFIG=${DOCKER_CONFIG:-/usr/local/lib/docker}
mkdir -p $DOCKER_CONFIG/cli-plugins
curl -SL https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-linux-x86_64 -o $DOCKER_CONFIG/cli-plugins/docker-compose
chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose

# 创建软链接
ln -sf $DOCKER_CONFIG/cli-plugins/docker-compose /usr/local/bin/docker-compose

log_info "Docker 安装完成"
docker --version
docker compose version

# =============================================================================
# 6. 系统性能优化
# =============================================================================
log_info "优化系统性能..."

# 备份原配置
cp /etc/sysctl.conf /etc/sysctl.conf.bak.$(date +%Y%m%d)

# 内核参数优化
cat >> /etc/sysctl.conf << 'EOF'

# 网络性能优化
net.ipv4.tcp_max_tw_buckets = 6000
net.ipv4.tcp_sack = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_rmem = 4096 87380 4194304
net.ipv4.tcp_wmem = 4096 16384 4194304
net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.netdev_max_backlog = 65536
net.ipv4.tcp_max_orphans = 3276800
net.ipv4.tcp_max_syn_backlog = 65536
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 2
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_mem = 94500000 915000000 927000000
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.ip_local_port_range = 1024 65535

# 虚拟内存优化
vm.swappiness = 10
vm.dirty_ratio = 40
vm.dirty_background_ratio = 10

# 文件系统优化
fs.file-max = 655360
fs.nr_open = 655360
EOF

# 应用配置
sysctl -p

# 文件描述符限制
cat >> /etc/security/limits.conf << 'EOF'

# 文件描述符限制
* soft nofile 65536
* hard nofile 65536
* soft nproc 65536
* hard nproc 65536
root soft nofile 65536
root hard nofile 65536
EOF

# PAM 配置
sed -i 's/# session    required   pam_limits.so/session    required   pam_limits.so/' /etc/pam.d/common-session
sed -i 's/# session    required   pam_limits.so/session    required   pam_limits.so/' /etc/pam.d/common-session-noninteractive

log_info "性能优化完成"

# =============================================================================
# 7. 安装 Fail2ban (防暴力破解)
# =============================================================================
log_info "安装 Fail2ban..."

apt install -y fail2ban

# 配置 Fail2ban
cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3
backend = systemd

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
EOF

systemctl enable fail2ban
systemctl start fail2ban

log_info "Fail2ban 安装完成"

# =============================================================================
# 8. 配置自动安全更新
# =============================================================================
log_info "配置自动安全更新..."

apt install -y unattended-upgrades

cat > /etc/apt/apt.conf.d/50unattended-upgrades << 'EOF'
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
    "${distro_id}ESMApps:${distro_codename}-apps-security";
    "${distro_id}ESM:${distro_codename}-infra-security";
};

Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::InstallOnShutdown "false";
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
EOF

cat > /etc/apt/apt.conf.d/20auto-upgrades << 'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF

systemctl enable unattended-upgrades
systemctl start unattended-upgrades

log_info "自动安全更新配置完成"

# =============================================================================
# 9. 配置 NTP 时间同步
# =============================================================================
log_info "配置时间同步..."

apt install -y chrony

systemctl enable chrony
systemctl start chrony

log_info "时间同步配置完成"

# =============================================================================
# 10. 配置日志轮转
# =============================================================================
log_info "配置日志轮转..."

cat > /etc/logrotate.d/custom-logs << 'EOF'
/var/log/custom/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 0644 root root
    sharedscripts
    postrotate
        /bin/kill -HUP $(cat /var/run/rsyslogd.pid 2> /dev/null) 2> /dev/null || true
    endscript
}
EOF

log_info "日志轮转配置完成"

# =============================================================================
# 11. 创建备份策略
# =============================================================================
log_info "创建备份策略..."

mkdir -p /backup/scripts
mkdir -p /backup/data

# 创建备份脚本
cat > /backup/scripts/backup.sh << 'EOF'
#!/bin/bash

BACKUP_DIR="/backup/data/$(date +%Y%m%d_%H%M%S)"
LOG_FILE="/backup/backup.log"
RETENTION_DAYS=7

# 创建备份目录
mkdir -p "$BACKUP_DIR"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] 开始备份..." >> "$LOG_FILE"

# 备份重要配置
cp -r /etc/nginx "$BACKUP_DIR/" 2>/dev/null || true
cp -r /etc/ssh "$BACKUP_DIR/" 2>/dev/null || true
cp -r /etc/docker "$BACKUP_DIR/" 2>/dev/null || true
cp /etc/sysctl.conf "$BACKUP_DIR/" 2>/dev/null || true
cp /etc/ssh/sshd_config "$BACKUP_DIR/" 2>/dev/null || true

# 备份用户数据
cp -r /home "$BACKUP_DIR/" 2>/dev/null || true

# 备份 Docker 数据
cp -r /var/lib/docker/volumes "$BACKUP_DIR/" 2>/dev/null || true

# 创建备份信息
cat > "$BACKUP_DIR/backup-info.txt" << EOL
备份时间: $(date '+%Y-%m-%d %H:%M:%S')
主机名: $(hostname)
IP地址: $(hostname -I | awk '{print $1}')
系统版本: $(lsb_release -ds)
EOL

# 压缩备份
cd /backup/data
tar -czf "$(basename $BACKUP_DIR).tar.gz" "$(basename $BACKUP_DIR)"
rm -rf "$BACKUP_DIR"

# 清理旧备份
find /backup/data -name "*.tar.gz" -mtime +$RETENTION_DAYS -delete

echo "[$(date '+%Y-%m-%d %H:%M:%S')] 备份完成: $(basename $BACKUP_DIR).tar.gz" >> "$LOG_FILE"
EOF

chmod +x /backup/scripts/backup.sh

# 添加定时任务 (每天凌晨 2 点执行)
(crontab -l 2>/dev/null || true; echo "0 2 * * * /backup/scripts/backup.sh") | crontab -

log_info "备份策略创建完成"

# =============================================================================
# 12. 安装常用工具
# =============================================================================
log_info "安装常用工具..."

apt install -y \
    nginx \
    certbot \
    python3-certbot-nginx \
    mysql-client \
    redis-tools \
    jq \
    tree \
    ncdu \
    tmux \
    htop

# 配置 Nginx
systemctl enable nginx
systemctl start nginx

log_info "常用工具安装完成"

# =============================================================================
# 13. 清理系统
# =============================================================================
log_info "清理系统..."

apt autoremove -y
apt autoclean

# 清理旧内核
dpkg -l 'linux-*' | sed '/^ii/!d;/'"$(uname -r | sed "s/\(.*\)-\([^0-9]\+\)/\1/")"/d;s/^[^ ]* [^ ]* \([^ ]*\).*/\1/;/[0-9]/!d' | xargs -r apt autoremove -y 2>/dev/null || true

log_info "系统清理完成"

# =============================================================================
# 14. 生成部署报告
# =============================================================================
log_info "生成部署报告..."

REPORT_FILE="/root/server-init-report.txt"
cat > "$REPORT_FILE" << EOF
===============================================================================
阿里云 ECS Ubuntu 20.04 服务器初始化部署报告
服务器: 101.133.238.249
部署时间: $(date '+%Y-%m-%d %H:%M:%S')
===============================================================================

## 1. 系统信息
- 主机名: $(hostname)
- 操作系统: $(lsb_release -ds)
- 内核版本: $(uname -r)
- IP地址: $(hostname -I | awk '{print $1}')

## 2. 用户账户
- 管理用户: admin
- 管理密码: Admin@123456!
- 用户组: sudo, docker

## 3. SSH 配置
- 端口: 22
- Root登录: 已禁用
- 密码认证: 已启用（建议后续配置密钥认证）
- 配置文件: /etc/ssh/sshd_config

## 4. 防火墙状态
$(ufw status numbered)

## 5. 已安装软件
- Docker: $(docker --version 2>/dev/null || echo '未安装')
- Docker Compose: $(docker compose version 2>/dev/null || echo '未安装')
- Nginx: $(nginx -v 2>&1 || echo '未安装')
- Fail2ban: $(fail2ban-client status 2>/dev/null | head -1 || echo '未安装')

## 6. 备份策略
- 备份目录: /backup/data
- 备份脚本: /backup/scripts/backup.sh
- 执行时间: 每天凌晨 2:00
- 保留周期: 7 天

## 7. 自动更新
- 安全更新: 已启用
- 更新检查: 每天
- 配置目录: /etc/apt/apt.conf.d/

## 8. 重要文件备份
- SSH配置备份: /etc/ssh/sshd_config.bak.*
- 系统参数备份: /etc/sysctl.conf.bak.*

===============================================================================
## 后续建议
===============================================================================

1. 【重要】配置 SSH 密钥认证并禁用密码登录
   - 生成密钥对: ssh-keygen -t ed25519 -C "your_email@example.com"
   - 上传公钥: ssh-copy-id admin@101.133.238.249
   - 禁用密码登录: 修改 /etc/ssh/sshd_config 中 PasswordAuthentication no

2. 【重要】修改默认密码
   - admin 用户密码当前为: Admin@123456!
   - 建议立即修改: passwd admin

3. 配置阿里云安全组
   - 确保端口 22, 80, 443 已开放
   - 建议限制 SSH 端口仅允许你的 IP 访问

4. 配置域名和 SSL
   - 使用 certbot 申请免费 SSL 证书
   - 配置 Nginx 反向代理

5. 监控告警
   - 建议安装 Prometheus + Grafana 监控
   - 或配置阿里云云监控

===============================================================================
EOF

cat "$REPORT_FILE"

log_info "========================================"
log_info "服务器初始化完成！"
log_info "========================================"
log_info "部署报告已保存到: $REPORT_FILE"
log_info "请查看上方报告了解详细信息"
log_warn "【重要】请立即修改 admin 用户密码！"
log_warn "【重要】建议配置 SSH 密钥认证！"
log_info "========================================"