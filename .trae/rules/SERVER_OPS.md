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

## 零、后端健康检查决策树（强制遵循）

> **目标**：校验后端是否正常时，**秒级返回结果**，绝不卡住等待日志输出。

### 决策流程（优先级自上而下）

```
需要校验后端状态？
  ↓
第1步：能用 aliyun-servers MCP 吗？（方案二 - 优先）
  ├→ ✅ ssh_exec — 远程执行命令（内置超时，最稳定）
  ├→ ✅ ssh_system_info — 获取服务器整体状态
  ├→ ✅ sftp_read — 读取远程日志文件（非流式）
  └→ MCP 可用 → 直接用，跳过 SSH 命令行
  ↓
第2步：用"查状态"代替"看日志"（方案三 - 核心原则）
  ├→ ✅ pm2 status changji-api — 看进程是否在运行（秒级）
  ├→ ✅ curl --connect-timeout 5 --max-time 10 http://localhost:3000/health — HTTP 健康检查
  ├→ ✅ systemctl --no-pager status nginx — 看服务状态
  └→ ❌ 绝不先用 pm2 logs — 日志是排查工具，不是检查工具
  ↓
第3步：必须看日志时（仅在状态异常后，排查问题）
  ├→ ✅ pm2 logs changji-api --lines 50 --nostream — 固定行数，非流式
  ├→ ✅ tail -n 50 /var/log/changji-api-error.log — 固定行数
  └→ ❌ tail -f /var/log/xxx — 禁止流式监听
  ↓
第4步：必须用 SSH 命令行时（方案一 - 兜底）
  └→ ✅ 强制加超时参数：ssh -o ConnectTimeout=10 -o ServerAliveInterval=5 -o ServerAliveCountMax=2 changji "cmd"
```

### 为什么这样设计？

| 问题 | 旧做法 | 新做法 | 效果 |
|------|--------|--------|------|
| SSH 连接卡住 | `ssh changji "pm2 logs"` 无超时 | 优先 MCP / SSH 强制超时 | 10 秒内知道连不上 |
| 日志命令永不退出 | `pm2 logs` 进入流式监听 | `pm2 status` + `--nostream` | 秒级返回 |
| 无效等待 | 等日志输出判断正常 | HTTP 健康检查 / PM2 状态 | 直接拿到结果 |
| 重复执行 | 失败后反复重试 SSH | MCP 内置超时 + 自动切换 | 最多 1 次重试 |

---

## ⚠️ 执行前确认

**所有涉及服务器的命令执行前必须**：
1. 说明要执行的命令和目的
2. 如果是修改性操作（重启、改配置、清理等）→ 等用户确认后再执行
3. 如果是只读操作（查看状态、日志）→ 可直接执行
4. 命令失败时按 RED_LINES.md 重试上限执行（最多重试 1 次）
5. **优先使用 aliyun-servers MCP**，只有当 MCP 不可用时才用 SSH 命令行（且必须带超时参数）

---

## 一、日常检查命令

### 每日检查（只读，可直接执行）

**优先使用 MCP**：
```
mcp_aliyun_servers_ssh_exec(command="pm2 status")
mcp_aliyun_servers_ssh_system_info()
```

**SSH 命令行（兜底，必须带超时参数）**：
```bash
ssh -o ConnectTimeout=10 -o ServerAliveInterval=5 -o ServerAliveCountMax=2 changji "sudo systemctl --no-pager status ssh nginx docker postgresql redis-server fail2ban"
ssh -o ConnectTimeout=10 -o ServerAliveInterval=5 -o ServerAliveCountMax=2 changji "sudo df -h"
ssh -o ConnectTimeout=10 -o ServerAliveInterval=5 -o ServerAliveCountMax=2 changji "sudo free -h"
ssh -o ConnectTimeout=10 -o ServerAliveInterval=5 -o ServerAliveCountMax=2 changji "pm2 status"
```

### 每周检查

**优先使用 MCP**：
```
mcp_aliyun_servers_ssh_exec(command="sudo apt list --upgradable")
mcp_aliyun_servers_ssh_exec(command="sudo ufw status verbose")
mcp_aliyun_servers_ssh_exec(command="sudo fail2ban-client status sshd")
mcp_aliyun_servers_ssh_exec(command="PGOPTIONS='-c statement_timeout=10000' sudo -u postgres psql -c 'SELECT count(*) FROM pg_stat_activity;'")
mcp_aliyun_servers_ssh_exec(command="redis-cli -a Redis123456 --no-auth-warning INFO stats")
```

**SSH 命令行（兜底，必须带超时参数）**：
```bash
ssh -o ConnectTimeout=10 -o ServerAliveInterval=5 -o ServerAliveCountMax=2 changji "sudo apt list --upgradable"
ssh -o ConnectTimeout=10 -o ServerAliveInterval=5 -o ServerAliveCountMax=2 changji "sudo ufw status verbose"
ssh -o ConnectTimeout=10 -o ServerAliveInterval=5 -o ServerAliveCountMax=2 changji "sudo fail2ban-client status sshd"
ssh -o ConnectTimeout=10 -o ServerAliveInterval=5 -o ServerAliveCountMax=2 changji "PGOPTIONS='-c statement_timeout=10000' sudo -u postgres psql -c 'SELECT count(*) FROM pg_stat_activity;'"
ssh -o ConnectTimeout=10 -o ServerAliveInterval=5 -o ServerAliveCountMax=2 changji "redis-cli -a Redis123456 --no-auth-warning INFO stats"
```

### 每月检查

**优先使用 MCP**：
```
mcp_aliyun_servers_ssh_exec(command="sudo cat /var/log/auth.log | grep 'Failed password'")
mcp_aliyun_servers_ssh_exec(command="pm2 logs changji-api --nostream --lines 100")
```

**SSH 命令行（兜底，必须带超时参数）**：
```bash
ssh -o ConnectTimeout=10 -o ServerAliveInterval=5 -o ServerAliveCountMax=2 changji "sudo cat /var/log/auth.log | grep 'Failed password'"
ssh -o ConnectTimeout=10 -o ServerAliveInterval=5 -o ServerAliveCountMax=2 changji "pm2 logs changji-api --nostream --lines 100"
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

**优先使用 MCP**：
```
mcp_aliyun_servers_ssh_exec(command="sudo systemctl status <service>")
mcp_aliyun_servers_ssh_exec(command="sudo journalctl -u <service> -n 50")
```

**SSH 命令行（兜底，必须带超时参数）**：
```bash
ssh -o ConnectTimeout=10 -o ServerAliveInterval=5 -o ServerAliveCountMax=2 changji "sudo systemctl status <service>"
ssh -o ConnectTimeout=10 -o ServerAliveInterval=5 -o ServerAliveCountMax=2 changji "sudo journalctl -u <service> -n 50"
```

**重启命令（需用户确认后执行）**：
```bash
ssh -o ConnectTimeout=10 -o ServerAliveInterval=5 -o ServerAliveCountMax=2 changji "sudo systemctl restart <service>"
```

### API服务异常

**优先使用 MCP**：
```
# 第1步：查状态（秒级返回）
mcp_aliyun_servers_ssh_exec(command="pm2 status")

# 第2步：状态异常时，查看错误日志（固定行数）
mcp_aliyun_servers_ssh_exec(command="pm2 logs changji-api --nostream --lines 50")
mcp_aliyun_servers_sftp_read(remote_path="/var/log/changji-api-error.log")

# 第3步：必要时重启（需用户确认）
mcp_aliyun_servers_ssh_exec(command="pm2 restart changji-api")
```

**SSH 命令行（兜底，必须带超时参数）**：
```bash
# 第1步：查状态（绝不先看日志）
ssh -o ConnectTimeout=10 -o ServerAliveInterval=5 -o ServerAliveCountMax=2 changji "pm2 status"

# 第2步：状态异常时，看固定行数日志
ssh -o ConnectTimeout=10 -o ServerAliveInterval=5 -o ServerAliveCountMax=2 changji "pm2 logs changji-api --nostream --lines 50"
ssh -o ConnectTimeout=10 -o ServerAliveInterval=5 -o ServerAliveCountMax=2 changji "tail -n 50 /var/log/changji-api-error.log"

# 第3步：重启（需用户确认后执行）
ssh -o ConnectTimeout=10 -o ServerAliveInterval=5 -o ServerAliveCountMax=2 changji "pm2 restart changji-api"
ssh -o ConnectTimeout=10 -o ServerAliveInterval=5 -o ServerAliveCountMax=2 changji "sudo nginx -t && sudo systemctl restart nginx"
```

### 磁盘空间不足

**优先使用 MCP**：
```
mcp_aliyun_servers_ssh_exec(command="sudo df -h")
mcp_aliyun_servers_ssh_exec(command="sudo docker system prune -a -f")
mcp_aliyun_servers_ssh_exec(command="sudo journalctl --vacuum-time=7d")
mcp_aliyun_servers_ssh_exec(command="sudo find /backup/data -mtime +7 -delete")
mcp_aliyun_servers_ssh_exec(command="sudo find /var/log/postgresql -name '*.log' -mtime +7 -delete")
mcp_aliyun_servers_ssh_exec(command="sudo find /var/log/redis -name '*.log' -mtime +7 -delete")
mcp_aliyun_servers_ssh_exec(command="sudo find /var/log/changji-api*.log -mtime +7 -delete")
```

**SSH 命令行（兜底，必须带超时参数）**：
```bash
ssh -o ConnectTimeout=10 -o ServerAliveInterval=5 -o ServerAliveCountMax=2 changji "sudo df -h"
ssh -o ConnectTimeout=10 -o ServerAliveInterval=5 -o ServerAliveCountMax=2 changji "sudo docker system prune -a -f"
ssh -o ConnectTimeout=10 -o ServerAliveInterval=5 -o ServerAliveCountMax=2 changji "sudo journalctl --vacuum-time=7d"
ssh -o ConnectTimeout=10 -o ServerAliveInterval=5 -o ServerAliveCountMax=2 changji "sudo find /backup/data -mtime +7 -delete"
ssh -o ConnectTimeout=10 -o ServerAliveInterval=5 -o ServerAliveCountMax=2 changji "sudo find /var/log/postgresql -name '*.log' -mtime +7 -delete"
ssh -o ConnectTimeout=10 -o ServerAliveInterval=5 -o ServerAliveCountMax=2 changji "sudo find /var/log/redis -name '*.log' -mtime +7 -delete"
ssh -o ConnectTimeout=10 -o ServerAliveInterval=5 -o ServerAliveCountMax=2 changji "sudo find /var/log/changji-api*.log -mtime +7 -delete"
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
| 2026-05-28 | **重大更新**：新增"后端健康检查决策树"（零节），强制优先使用 aliyun-servers MCP → 查状态代替看日志 → SSH 超时参数兜底的三级策略；所有命令示例同步更新为双模式（MCP 优先 + SSH 兜底带超时参数） |
| 2026-05-25 | 安全修复：pm2 logs 加 --nostream；systemctl 加 --no-pager；psql 加 statement_timeout；redis-cli 加 --no-auth-warning；cat 管道优化为 tail -n；新增运维后 Chrome DevTools MCP 验证 |
| 2026-05-21 | 从 SERVER_DEPLOY.md 拆分，独立为 SERVER_OPS.md |
