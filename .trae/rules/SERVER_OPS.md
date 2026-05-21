---
alwaysApply: false
description: 服务器运维规范 - 日常检查、日志管理、应急响应
---

# SERVER_OPS.md - 服务器运维规范

> **部署规范** → 详见 [SERVER_DEPLOY.md](SERVER_DEPLOY.md)
> **安全防护** → 详见 [SERVER_SECURITY.md](SERVER_SECURITY.md)

---

## 一、日常检查命令

### 每日检查
```bash
sudo systemctl status ssh nginx docker postgresql redis-server fail2ban
sudo df -h
sudo free -h
pm2 status
```

### 每周检查
```bash
sudo apt list --upgradable
sudo ufw status verbose
sudo fail2ban-client status sshd
sudo -u postgres psql -c "SELECT count(*) FROM pg_stat_activity;"
redis-cli -a Redis123456 info stats
```

### 每月检查
```bash
sudo cat /var/log/auth.log | grep "Failed password"
pm2 logs changji-api --lines 100
```

---

## 二、日志管理

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

---

## 三、应急响应

### 服务宕机
```bash
sudo systemctl status <service>
sudo journalctl -u <service> -n 50
sudo systemctl restart <service>
```

### API服务异常
```bash
pm2 status
pm2 logs changji-api --lines 50
cat /var/log/changji-api-error.log | tail -50
pm2 restart changji-api
sudo nginx -t && sudo systemctl restart nginx
```

### 磁盘空间不足
```bash
sudo df -h
sudo docker system prune -a
sudo journalctl --vacuum-time=7d
sudo find /backup/data -mtime +7 -delete
sudo find /var/log/postgresql -name "*.log" -mtime +7 -delete
sudo find /var/log/redis -name "*.log" -mtime +7 -delete
sudo find /var/log/changji-api*.log -mtime +7 -delete
```

---

## 更新记录

| 日期 | 更新内容 |
|-----|---------|
| 2026-05-21 | 从 SERVER_DEPLOY.md 拆分，独立为 SERVER_OPS.md |
