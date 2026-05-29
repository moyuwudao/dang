---
alwaysApply: false
globs: admin/**, server/**
description: 阿里云ECS服务器部署规范 - 101.133.238.249 标准化操作指导
---

# SERVER_DEPLOY.md - 服务器部署规范

## 概述

本文档定义阿里云ECS服务器（101.133.238.249）的部署标准规范。

**适用范围**：所有对该服务器的部署、配置、维护操作
**服务器IP**：101.133.238.249（公网）/ 172.24.29.151（内网）
**操作系统**：Ubuntu 22.04.5 LTS
**文档版本**：v1.8

> **MCP 连接** → 详见 `aliyun-servers` MCP（mcp-server-ssh）
> **安全红线** → 详见 [RED_LINES.md](RED_LINES.md)
> **构建规则** → 详见 [BUILD.md](BUILD.md)

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

#### 密码登录（备用方式）
```bash
# ⚠️ 仅手动使用（交互式登录，AI 执行会永久阻塞）
ssh admin@101.133.238.249

# ✅ AI/脚本使用（远程执行单条命令，30 秒超时）
ssh -o ConnectTimeout=10 admin@101.133.238.249 "具体命令"
```

#### 密钥登录（推荐 ✅ 已配置）
```powershell
# ⚠️ 仅手动使用（交互式登录，AI 执行会永久阻塞）
ssh -i $env:USERPROFILE\.ssh\id_ed25519 admin@101.133.238.249
ssh changji

# ✅ AI/脚本使用（远程执行命令）
ssh -o ConnectTimeout=10 changji "具体命令"
```

SSH Config（`C:\Users\Mayn\.ssh\config`）：
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
# ⚠️ 仅手动使用（交互式 psql，AI 执行会永久阻塞）
sudo -u postgres psql -d appdb

# ✅ AI/脚本使用（非交互式 SQL，30 秒超时）
PGOPTIONS="-c statement_timeout=30000" sudo -u postgres psql -d appdb -c "SELECT 1;"

# 连接字符串（代码中使用）
postgresql://appuser:AppUser123456@localhost:5432/appdb
```

#### Redis
```bash
# ⚠️ 仅手动使用（交互式 redis-cli，AI 执行会永久阻塞）
redis-cli -a Redis123456

# ✅ AI/脚本使用（非交互式命令）
redis-cli -a Redis123456 --no-auth-warning PING
redis-cli -a Redis123456 --no-auth-warning INFO
```

#### Server Agent
```bash
curl --connect-timeout 5 --max-time 10 http://127.0.0.1:8848/health
curl --connect-timeout 5 --max-time 10 -H "X-Agent-Token: changji-agent-2026" http://127.0.0.1:8848/info
```

#### Nginx 反向代理
```bash
curl --connect-timeout 5 --max-time 10 -u admin:Agent@2026 \
  -H "X-Agent-Token: changji-agent-2026" \
  http://101.133.238.249/agent/info
```

#### 畅记云 API
```bash
curl --connect-timeout 5 --max-time 10 http://101.133.238.249/api/v1/health
```

### 2.4 连接安全规范

```
✅ 必须使用 admin 账户连接
✅ 推荐使用 SSH 密钥认证
✅ 生产环境禁止密码登录
❌ 禁止使用 root 直接登录
❌ 禁止共享账户密码
```

### 2.5 代码存放规范（强制）

```
❌ 禁止将项目代码放置在 /root/ 目录下
❌ 禁止将构建产物、日志、配置文件放在 root 用户目录
✅ 所有项目代码必须存放在 /home/admin/ 目录下
✅ 文件权限必须设置为 admin:admin
```

**为什么重要**：
- root 目录下的代码在系统更新或安全审计时可能被清除
- 不利于团队协作和权限管理
- 违反最小权限原则

**正确示例**：
```bash
# ✅ 正确：代码在 admin 用户目录
cd /home/admin/dang
git pull origin master
npm run build
pm2 restart changji-api

# ❌ 错误：代码在 root 目录
cd /root/dang        # 禁止！
sudo git pull        # 禁止！
```

**迁移方法**（如已有代码在 /root/ 下）：
```bash
# 1. 复制代码到 admin 目录
sudo cp -r /root/dang /home/admin/dang
sudo chown -R admin:admin /home/admin/dang

# 2. 更新 PM2 配置
pm2 delete changji-api
pm2 start /home/admin/dang/server/dist/main.js --name changji-api
pm2 save

# 3. 更新部署脚本
sed -i 's|/root/dang|/home/admin/dang|g' /home/admin/dang/deploy_backend.sh

# 4. 删除 root 下的代码（确认迁移成功后）
sudo rm -rf /root/dang
```

---

## 三、已知问题与解决方案

### 问题1：NestJS模块依赖错误
**现象**：`Nest can't resolve dependencies of the JwtAuthGuard`
**解决**：在 `auth.module.ts` 中导出 `JwtModule`：`exports: [AuthService, JwtModule]`

### 问题2：Nginx代理路径错误
**现象**：API请求返回404
**解决**：`proxy_pass http://127.0.0.1:3000/api/;` 注意末尾的 `/`

### 问题3：环境变量名不匹配
**现象**：数据库连接失败
**解决**：统一使用 `DB_PASSWORD` 作为环境变量名

### 问题4：登录返回401
**现象**：注册用户成功，但登录返回401
**解决**：重新创建测试用户或重置密码

### 问题5：Admin 后台页面样式不生效（纯 HTML 无样式）
**现象**：
- 浏览器打开后台页面（如 `/dashboard`、`/subscriptions`），显示为纯文字，无任何样式
- 页面布局错乱，所有元素堆叠在一起
- HTML 源码中有 Tailwind class 名称（如 `bg-white`、`text-gray-900`），但浏览器完全不渲染样式
- 多个浏览器、手机、无痕模式均无法正常显示

**实际案例（2026-05-21）**
优化后台 UI 后部署到服务器，用户反馈"所有设备看到的都是最简陋的原始版本"。排查发现：

```
服务器上 /var/www/html/admin/_next/static/css/ 目录不存在
curl http://127.0.0.1/_next/static/css/ → 404 Not Found
```

**根本原因**：项目缺少 Tailwind CSS 入口文件
- ❌ 没有 `admin/styles/globals.css`（Tailwind `@tailwind` 指令）
- ❌ 没有 `admin/pages/_app.tsx`（导入 CSS 的入口）
- Next.js 构建时不会生成独立的 CSS 文件（`_next/static/css/xxx.css`）
- HTML 中引用了 CSS 文件路径，但文件不存在 → 所有样式丢失

**解决方案**：

1. 创建 Tailwind CSS 入口文件 `admin/styles/globals.css`：
```css
@tailwind base;
@tailwind components;
@tailwind utilities;
```

2. 创建 Next.js App 入口 `admin/pages/_app.tsx`：
```tsx
import '@/styles/globals.css';
import type { AppProps } from 'next/app';

export default function App({ Component, pageProps }: AppProps) {
  return <Component {...pageProps} />;
}
```

3. 重新构建并部署：
```bash
cd admin && npm run build
# 确认输出包含 css/xxx.css 行：
# ├ css/8297752048ca8b96.css    25.5 kB
git add . && git commit -m "fix: add tailwind entry files" && git push
# 服务器执行
cd /home/admin/dang && git pull origin master
sudo rm -rf /var/www/html/admin/_next
sudo cp -r admin/out/* /var/www/html/admin/
sudo chown -R www-data:www-data /var/www/html/admin
sudo systemctl reload nginx
```

**验证方法**：
```bash
# 1. 确认 CSS 文件存在
ls /var/www/html/admin/_next/static/css/
# 应输出: 8297752048ca8b96.css

# 2. 确认 CSS 可访问
curl -sI http://127.0.0.1/_next/static/css/8297752048ca8b96.css | head -3
# 应输出: HTTP/1.1 200 OK, Content-Type: text/css

# 3. 浏览器检查 Network 面板，确认 CSS 文件加载状态为 200
```

### 问题6：Nginx 缓存导致旧版本页面无法更新
**现象**：
- 代码已更新并重新部署到服务器
- 服务器本地 curl 返回新版本内容
- 但浏览器仍显示旧版本页面
- 清除浏览器缓存、使用无痕模式、换电脑/手机均无效

**实际案例（2026-05-21）**
优化后台 UI 后多次部署，服务器文件已确认是新版本（`grep bg-gradient` 返回 0），但用户多端均看到旧版。

**根本原因**：Nginx 配置未给 HTML 文件设置缓存控制头，浏览器可能通过中间代理或 CDN 缓存了旧版本。

**解决方案**：修改 Nginx 配置，给 HTML 页面添加 no-cache 头：
```nginx
server {
    listen 80;
    server_name _;
    root /var/www/html/admin;
    index index.html;

    location / {
        try_files $uri $uri/ $uri.html /index.html;
        # 关键：HTML 页面禁止缓存
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header Pragma "no-cache";
        add_header Expires "0";
    }

    location /_next/ {
        # JS/CSS 资源可以长期缓存（文件名带 hash）
        expires 1y;
        add_header Cache-Control "public, immutable";
        try_files $uri $uri/ =404;
    }

    location /api/ {
        proxy_pass http://127.0.0.1:3000;
        ...
    }
}
```

**注意**：
- HTML 用 `no-cache`：每次请求都向服务器验证
- `_next/` 资源用长期缓存：Next.js 生成的文件名含 hash，内容变化时文件名也变
- 不要给 `location /` 设置 `expires` 或 `Cache-Control: public`

**快速诊断方法**：
```bash
# 对比服务器本地和外部访问的内容是否一致
# 服务器本地（应为新版本）
ssh admin@101.133.238.249 "curl -s http://127.0.0.1/subscriptions | grep -o bg-gradient | wc -l"

# 外部访问（对比结果）
curl -s http://101.133.238.249/subscriptions | grep -o bg-gradient | wc -l
# 如果两者一致且均为 0，说明服务器正确，问题在客户端缓存层
```

---

## 四、部署后验证（使用 MCP 工具）

### 4.1 Chrome DevTools MCP — 浏览器视觉验证

部署完成后，使用 Chrome DevTools MCP 验证 admin 面板功能正常：

```
1. 打开 admin 面板
   mcp_Chrome_DevTools_MCP_navigate_page(type="url", url="http://101.133.238.249/admin/dashboard")

2. 截图保存部署后状态
   mcp_Chrome_DevTools_MCP_take_screenshot(fullPage=true)

3. 获取页面快照，验证关键元素存在
   mcp_Chrome_DevTools_MCP_take_snapshot()

4. 检查控制台错误
   mcp_Chrome_DevTools_MCP_list_console_messages(types=["error"])

5. 验证 API 请求正常
   mcp_Chrome_DevTools_MCP_list_network_requests(resourceTypes=["xhr", "fetch"])
```

> **详细 SOP** → 详见 [PLAYWRIGHT_E2E.md](PLAYWRIGHT_E2E.md)

### 4.2 GitHub MCP — 代码与发布管理

| 操作 | MCP 工具 | 说明 |
|------|---------|------|
| 创建部署分支 | `mcp_GitHub_create_branch` | 从 main 创建 `deploy/YYYYMMDD` 分支 |
| 提交代码变更 | `mcp_GitHub_push_files` | 批量推送部署相关文件 |
| 创建 PR | `mcp_GitHub_create_pull_request` | 创建部署 PR 供审查 |
| 查看部署历史 | `mcp_GitHub_list_commits` | 查看最近的部署提交 |

---

## 五、相关文档

| 文档 | 用途 |
|-----|------|
| [SERVER_DEPLOY_PROCEDURE.md](SERVER_DEPLOY_PROCEDURE.md) | 标准部署流程、权限管理、回滚机制 |
| [SERVER_SECURITY.md](SERVER_SECURITY.md) | 网络安全、API安全、安全审计 |
| [SERVER_OPS.md](SERVER_OPS.md) | 日常检查、日志管理、应急响应 |
| [SERVER_API.md](SERVER_API.md) | 畅记云 API 接口说明 |
| [../docs/SERVER_STATUS.md](../docs/SERVER_STATUS.md) | 当前服务器部署状态报告 |
| [RED_LINES.md](RED_LINES.md) | 通用安全红线 |
| [BUILD.md](BUILD.md) | APK构建规则 |
| [API_DESIGN.md](API_DESIGN.md) | API设计规范 |

---

## 更新记录

| 日期 | 版本 | 更新内容 |
|-----|------|---------|
| 2026-05-25 | v1.9 | 安全修复：交互式 SSH/psql/redis-cli 加"仅手动使用"标注并提供 AI 安全替代；curl 命令加 --connect-timeout/--max-time |
| 2026-05-21 | v1.7 | 新增 CASE-005：Admin 后台 Tailwind CSS 样式不生效；新增 CASE-006：Nginx 缓存导致旧版本页面无法更新 |
| 2026-05-21 | v1.6 | 拆分优化：部署流程→SERVER_DEPLOY_PROCEDURE.md，安全→SERVER_SECURITY.md，运维→SERVER_OPS.md，API→SERVER_API.md |
| 2026-05-20 | v1.5 | 新增服务器连接方式章节 |
| 2026-05-20 | v1.2 | 新增服务器连接方式 |
| 2026-05-19 | v1.1 | 新增 Node.js/PostgreSQL/Redis |
| 2026-05-20 | v1.0 | 初始版本 |
