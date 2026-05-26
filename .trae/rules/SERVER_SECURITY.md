---
alwaysApply: false
globs: admin/**, server/**
description: 服务器安全防护 - 网络安全、API安全、安全审计清单
---

# SERVER_SECURITY.md - 服务器安全防护

> **部署规范** → 详见 [SERVER_DEPLOY.md](SERVER_DEPLOY.md)
> **安全红线** → 详见 [RED_LINES.md](RED_LINES.md)

---

## 一、网络安全

| 层级 | 措施 | 状态 |
|-----|------|------|
| 阿里云安全组 | 限制SSH端口IP白名单 | ⚠️ 待配置 |
| UFW防火墙 | 仅开放22/80/443 | ✅ 已启用 |
| Fail2ban | 3次失败封禁1小时 | ✅ 已启用 |
| SSH | 禁用root登录 | ✅ 已配置 |
| Nginx | 基础认证 + Token | ✅ 已配置 |

---

## 二、API安全

| 措施 | 说明 | 状态 |
|-----|------|------|
| JWT认证 | 访问令牌 + 刷新令牌 | ✅ 已启用 |
| 密码加密 | bcrypt哈希存储 | ✅ 已启用 |
| 输入验证 | class-validator验证 | ✅ 已启用 |
| 速率限制 | 待配置 | ⚠️ 待配置 |
| HTTPS | 待配置SSL证书 | ⚠️ 待配置 |

---

## 三、安全审计清单

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

## 四、安全事件响应

### 检测入侵
```bash
sudo fail2ban-client set sshd banip <IP>
sudo grep <IP> /var/log/auth.log
sudo grep <IP> /var/log/nginx/access.log
```

### 确认入侵后
1. 立即修改所有密码
2. 检查文件完整性：`sudo find /etc -type f -mtime -1`
3. 审查用户权限和 SSH 配置
4. 通知 Walle

---

## 更新记录

| 日期 | 更新内容 |
|-----|---------|
| 2026-05-21 | 从 SERVER_DEPLOY.md 拆分，独立为 SERVER_SECURITY.md |
