---
alwaysApply: false
globs: admin/**, server/**
description: 服务器运维规范 - 日常检查、日志管理、应急响应
---

# SERVER_OPS.md - 服务器运维规范

> **MCP 连接** → 详见 `aliyun-servers` MCP（mcp-server-ssh）
> **部署规范** → 详见 [SERVER_DEPLOY.md](SERVER_DEPLOY.md)
> **安全防护** → 详见 [SERVER_SECURITY.md](SERVER_SECURITY.md)

---

## ⚠️ 执行前确认

**所有涉及服务器的命令执行前必须**：
1. 说明要执行的命令和目的
2. 如果是修改性操作（重启、改配置、清理等）→ 等用户确认后再执行
3. 如果是只读操作（查看状态、日志）→ 可直接执行
4. 命令失败时按 RED_LINES.md 重试上限执行（最多重试 1 次）

---

## 一、日常检查命令

### 每日检查（只读，可直接执行）
```bash
sudo systemctl --no-pager status ssh nginx docker postgresql redis-server fail2ban
sudo df -h
sudo free -h
pm2 status
```

### 每周检查
```bash
sudo apt list --upgradable
sudo ufw status verbose
sudo fail2ban-client status sshd
PGOPTIONS="-c statement_timeout=10000" sudo -u postgres psql -c "SELECT count(*) FROM pg_stat_activity;"
redis-cli -a Redis123456 --no-auth-warning INFO stats
```

### 每月检查
```bash
sudo cat /var/log/auth.log | grep "Failed password"
pm2 logs changji-api --nostream --lines 100
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
pm2 logs changji-api --nostream --lines 50
tail -n 50 /var/log/changji-api-error.log
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

## 运维后验证（使用 Chrome DevTools MCP）

每次运维操作（重启、部署、配置变更）完成后，应使用 Chrome DevTools MCP 验证 admin 面板功能：

```
1. 打开 admin 面板
   mcp_Chrome_DevTools_MCP_navigate_page(type="url", url="http://101.133.238.249/admin/dashboard")

2. 截图确认页面正常渲染
   mcp_Chrome_DevTools_MCP_take_screenshot(fullPage=true)

3. 检查控制台无错误
   mcp_Chrome_DevTools_MCP_list_console_messages(types=["error"])
```

> **完整测试 SOP** → 详见 [PLAYWRIGHT_E2E.md](PLAYWRIGHT_E2E.md)

---

## 更新记录

| 日期 | 更新内容 |
|-----|---------|
| 2026-05-25 | 安全修复：pm2 logs 加 --nostream；systemctl 加 --no-pager；psql 加 statement_timeout；redis-cli 加 --no-auth-warning；cat 管道优化为 tail -n；新增运维后 Chrome DevTools MCP 验证 |
| 2026-05-21 | 从 SERVER_DEPLOY.md 拆分，独立为 SERVER_OPS.md |
