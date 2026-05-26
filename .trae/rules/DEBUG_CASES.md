---
alwaysApply: false
description: 错误案例集锦 - 记录项目中遇到的典型问题及解决方案
---

# DEBUG_CASES.md - 错误案例集锦

## 目录

| 序号 | 问题类型 | 严重程度 | 状态 |
|-----|---------|---------|------|
| 1 | 按钮点击无响应 | 高 | ✅ 已解决 |
| 2 | 重定向次数过多 | 高 | ✅ 已解决 |
| 3 | Nginx 配置错误 | 中 | ✅ 已解决 |
| 4 | Playwright 安装失败 | 中 | ✅ 已解决 |

---

## 案例 1：按钮点击无响应

**问题描述**：
- 管理员后台页面加载正常，但按钮点击无任何反应
- 无痕模式下同样无法响应
- 控制台显示 accessibility 警告（`aria-label`）

**错误日志**：
```
If you do not provide a visible label, you must specify an aria-label or aria-labelledby attribute for accessibility
```

**排查过程**：
1. ✅ 检查前端按钮代码 - 点击事件绑定正确
2. ✅ 验证 API 连接 - API 正常工作
3. ✅ 检查 Nginx 配置 - 配置正确
4. ❌ **发现问题**：前端配置了 `trailingSlash: true`，但服务器部署的是旧版本代码

**根本原因**：
- 代码版本不一致：本地代码配置了带斜杠的路由，但服务器上仍是旧版本
- 缓存问题：浏览器缓存了过期的 JavaScript 代码

**解决方案**：
1. 更新服务器代码：`git pull && npm run build && cp -r out/* /var/www/html/admin/`
2. 更新 Nginx 配置支持带斜杠的 URL
3. 添加 `Cache-Control: no-cache` 头

**验证方式**：
```bash
npx playwright test --timeout=60000  # Playwright 测试全部通过
```

**经验教训**：
- 部署前确认配置文件与代码版本一致
- 部署后清除缓存或添加缓存控制头
- 使用自动化测试验证功能

---

## 案例 2：重定向次数过多（ERR_TOO_MANY_REDIRECTS）

**问题描述**：
- 访问 `http://101.133.238.249` 时浏览器报错
- 显示 "将您重定向的次数过多"

**错误日志**：
```
ERR_TOO_MANY_REDIRECTS
```

**排查过程**：
1. 检查 Nginx 配置中的 `try_files` 指令
2. 发现 `index.html` 包含 meta refresh 重定向到 `/login`
3. `try_files` 配置错误导致循环重定向

**根本原因**：
- Nginx 的 `try_files` 指令配置错误
- `index.html` 包含 `<meta http-equiv="refresh" content="0; url=/login">`
- 形成 `/ → index.html → /login → index.html → /login...` 的循环

**解决方案**：
```nginx
location / {
    try_files $uri $uri/ $uri.html /index.html;
    add_header Cache-Control no-cache;
}
```

**经验教训**：
- 配置 Nginx 时仔细检查 `try_files` 逻辑
- 避免在静态 HTML 中使用 meta refresh 进行重定向
- 使用 JavaScript 路由或服务器端重定向代替

---

## 案例 3：Nginx 配置语法错误

**问题描述**：
- Nginx 无法启动或重载
- 配置文件测试失败

**错误日志**：
```
nginx: [emerg] invalid number of arguments in "proxy_set_header" directive
```

**排查过程**：
1. 检查 `/etc/nginx/sites-available/admin`
2. 发现 `proxy_set_header` 指令参数格式错误

**根本原因**：
- `proxy_set_header` 指令的引号使用不当
- 例如：`proxy_set_header Host $host;` 正确，`proxy_set_header Host "$host";` 可能出错

**解决方案**：
```nginx
# 正确配置
location /api/ {
    proxy_pass http://127.0.0.1:3000;
}
```

**验证方式**：
```bash
# 修改 Nginx 配置后，先执行 nginx -t 验证再 reload
nginx -t  # 测试配置文件
systemctl reload nginx  # 重载配置
```

**经验教训**：
- 修改配置后使用 `nginx -t` 验证
- 保持配置简洁，只添加必要的指令

---

## 案例 4：Playwright 浏览器安装失败

**问题描述**：
- 在本地环境安装 Playwright 时权限不足
- 无法创建缓存目录

**错误日志**：
```
EPERM: operation not permitted, mkdir 'C:\Users\Mayn\AppData\Local\ms-playwright'
```

**排查过程**：
1. 检查目录权限
2. 发现 Trae sandbox 限制无法在本地创建目录

**解决方案**：
- 通过 MCP SSH 连接到服务器，在服务器环境中安装和运行 Playwright
- 使用服务器端的 Node.js 环境执行测试

**验证方式**：
```bash
# 在服务器上运行
cd /home/admin/dang/admin
npx playwright install
npx playwright test --timeout=60000
```

**经验教训**：
- 了解开发环境的限制
- 利用服务器环境进行测试
- 使用 MCP 工具连接远程服务器

---

## 案例分类总结

### 前端相关问题

| 问题 | 常见原因 | 预防措施 |
|-----|---------|---------|
| 按钮无响应 | 代码版本不一致、缓存 | 部署后清除缓存 |
| 路由错误 | 配置与代码不匹配 | 确认配置一致性 |
| JavaScript 错误 | 语法错误、依赖问题 | 构建前运行 lint |

### 服务器相关问题

| 问题 | 常见原因 | 预防措施 |
|-----|---------|---------|
| 重定向循环 | Nginx 配置错误 | 配置后测试验证 |
| 配置语法错误 | 指令格式错误 | 使用 `nginx -t` 验证 |
| API 连接失败 | 端口未开放、服务未启动 | 检查防火墙和服务状态 |

### 测试相关问题

| 问题 | 常见原因 | 预防措施 |
|-----|---------|---------|
| Playwright 安装失败 | 权限限制 | 使用服务器环境 |
| 测试用例失败 | 页面元素变化 | 更新选择器 |
| 测试超时 | 网络延迟、页面加载慢 | 增加超时时间 |

---

## 更新记录

| 日期 | 案例 | 更新内容 |
|-----|------|---------|
| 2026-05-25 | - | 安全修复：playwright 测试加 --timeout=60000；nginx reload 前加 nginx -t 验证 |
| 2026-05-23 | 案例 1-4 | 初始版本 |

---

*本文件记录项目中遇到的典型错误案例，便于快速定位和解决类似问题。*
