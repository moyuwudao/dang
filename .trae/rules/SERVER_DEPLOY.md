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
**文档版本**：v3.2

> **MCP 连接** → 详见 `aliyun-servers` MCP（mcp-server-ssh）
> **安全红线** → 详见 [RED_LINES.md](RED_LINES.md)
> **构建规则** → 详见 [BUILD.md](BUILD.md)
> **服务器目录结构** → 详见 [docs/SERVER_DIRECTORY.md](../docs/SERVER_DIRECTORY.md)（最新后端架构、部署路径、PM2状态）
> **后端管理系统完整架构** → 详见 [docs/BACKEND_ARCHITECTURE.md](../docs/BACKEND_ARCHITECTURE.md)（NestJS模块、数据库实体、AI路由策略）

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
| 管理用户 | admin（SSH Host 为 changji，实际登录用户是 admin） |
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
ssh changji  # 注意：SSH Config 中 User 是 admin

# ✅ AI/脚本使用（远程执行命令）
ssh -o ConnectTimeout=10 changji "具体命令"
```

SSH Config（`C:\Users\Mayn\.ssh\config`）：
```bash
Host changji
    HostName 101.133.238.249
    User admin              # 实际用户是 admin
    Port 22
    IdentityFile ~/.ssh/id_ed25519
    StrictHostKeyChecking accept-new
    ConnectTimeout 30
```

> **重要纠正（2026-06-01）**：SSH Host 名为 `changji`，实际登录用户是 `admin`。之前文档曾被错误地写成了 `mayn`，已通过 SSH 确认纠正。

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
❌ 禁止假设路径是 /home/mayn/（实际用户是 admin）
❌ 禁止假设路径是 /opt/changji-cloud/（该目录不存在）
✅ 所有项目代码必须存放在 /home/admin/ 目录下
✅ 文件权限必须设置为 admin:admin
```

**为什么重要**：
- root 目录下的代码在系统更新或安全审计时可能被清除
- 不利于团队协作和权限管理
- 违反最小权限原则
- 错误的路径假设会导致部署失败

**正确示例**：
```bash
# ✅ 正确：代码在 admin 用户目录
cd /home/admin/dang/server
git pull origin master
npm run build
npx pm2 restart changji-api

# ❌ 错误：代码在 mayn 目录（不存在）
cd /home/mayn/dang        # 禁止！目录不存在

# ❌ 错误：代码在 /opt/changji-cloud/（不存在）
cd /opt/changji-cloud/api  # 禁止！目录不存在
```

**实际服务器路径**（2026-06-01 最终确认）：
```bash
# NestJS 后端项目
/home/admin/dang/server/

# 管理后台
/home/admin/admin-sync/

# PM2 配置
/home/admin/.pm2/

# Nginx 静态文件
/var/www/html/admin/
```

---

## 三、部署前必读（SERVER_STATUS.md）

每次部署前，**必须**查阅 [docs/SERVER_STATUS.md](../docs/SERVER_STATUS.md)，确认以下内容：

| 检查项 | 说明 |
|--------|------|
| 当前服务状态 | PM2 状态、PID、内存、重启次数 |
| 上次部署记录 | 部署了哪些文件、构建是否成功 |
| 已知问题 | 哪些已修复、哪些待验证 |
| 架构变更 | API分配策略、缓存机制、计费逻辑等 |
| 部署检查清单 | 标准部署命令序列 |

> **规则**：部署前未查阅 SERVER_STATUS.md 导致的问题，视为部署流程违规。

---

## 四、已知问题与解决方案

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

### 问题7：编译后代码路径与 PM2 配置不匹配（MODULE_NOT_FOUND）
**现象**：
- 后端代码修改后编译部署，服务无法启动
- PM2 状态显示 `errored`，重启次数不断增加
- 浏览器访问 API 返回 `Internal server error`
- 错误日志：`Cannot find module '/opt/changji-cloud/api/dist/main.js'`

**根本原因**：
- NestJS 编译输出目录结构为 `dist/src/main.js`，但 PM2 配置指向 `dist/main.js`
- 代码同步后没有验证编译输出路径与 PM2 配置路径是否一致

**解决方案**：
1. 创建符号链接：`ln -sf /opt/changji-cloud/api/dist/src/main.js /opt/changji-cloud/api/dist/main.js`
2. 或修改 PM2 配置指向正确的路径：`pm2 start /opt/changji-cloud/api/dist/src/main.js --name changji-api`

**预防措施**：
```bash
# 部署前检查清单
echo "=== 部署前检查 ==="
echo "1. 编译输出路径:"
ls -la /home/admin/dang/server/dist/main.js 2>/dev/null || echo "❌ 编译输出不存在"
echo "2. PM2 配置路径:"
npx pm2 describe changji-api | grep "script path" || echo "❌ PM2 配置不存在"
echo "3. 检查 tsconfig.json:"
ls -la /home/admin/dang/server/tsconfig.json 2>/dev/null || echo "❌ tsconfig.json 不存在"
```

### 问题8：数据库表结构变更后实体类未同步（Unknown column）
**现象**：
- 修改数据库表结构后，后端服务报错
- API 返回 `Internal server error`
- 错误日志：`QueryFailedError: column "xxx" does not exist`

**根本原因**：
- 数据库表结构通过 SQL 脚本修改，但 TypeORM 实体类未同步更新
- 实体类字段名与数据库列名不一致

**解决方案**：
1. 同步修改 TypeORM 实体类（`@Column({ name: 'xxx' })`）
2. 同步修改前端接口定义
3. 重新编译并部署

**预防措施**：
```bash
# 数据库变更检查清单
# 1. 修改 SQL 脚本
# 2. 修改 TypeORM 实体类
# 3. 修改前端接口
# 4. 重新编译
# 5. 验证数据库表结构与实体类一致
echo "\d billing_standards" | sudo -u postgres psql -d appdb
grep -n "base_price" /home/admin/dang/server/src/subscription/entities/billing-standard.entity.ts
```

### 问题9：后端反复重启（Redis NOAUTH + ioredis unhandled error event）

> **关键案例（2026-06-03）**：服务重启 1472 次，pm2 status 显示 `restart_time: 1472`，`uptime: 0s`（一直在崩溃重启）。

**现象**：
- `pm2 status` 显示 `↺ 1472`（重启次数异常大）
- `uptime` 只有 0~几秒（秒崩）
- 错误日志重复出现 `Unhandled error event: ReplyError: NOAUTH Authentication required`
- 但 `redis-cli -a Redis123456 PING` 直接测试是 OK 的

**根本原因**（三个问题叠加）：

1. **`.env` 文件路径错误**：
   - 服务器只有 `/opt/changji-cloud/api/.env`（老路径）
   - 但 pm2 进程 `cwd` 是 `/home/admin/dang/server`
   - NestJS `ConfigModule` 找不到 .env → `ConfigService.get('REDIS_PASSWORD')` 返回 undefined
   - ⚠️ **重要**：`process.env.X` 也不读 .env（Node 默认行为）

2. **代码里直接用 `process.env.X` 没有 fallback**：
   ```typescript
   // auth.service.ts (错误)
   password: process.env.REDIS_PASSWORD || process.env.REDIS_PASS,  // password = undefined
   ```

3. **ioredis 'error' 事件没有监听器**：
   - EventEmitter 'error' 事件没有监听器时，Node 进程会**抛出未捕获异常并退出**
   - ioredis 客户端连接失败时 emit 'error' 事件
   - 后果：每次 Redis 调用 → 进程崩溃 → pm2 重启 → 再次崩溃 → 死循环

**完整解决方案**：

**A. 修复 `.env` 路径**：
```bash
ssh -o ConnectTimeout=10 changji 'cp /opt/changji-cloud/api/.env /home/admin/dang/server/.env'
```

**B. 修复代码（auth.service.ts）**：
```typescript
this.redisClient = new Redis({
  host: process.env.REDIS_HOST || 'localhost',
  port: parseInt(process.env.REDIS_PORT || '6379'),
  password: process.env.REDIS_PASSWORD || process.env.REDIS_PASS || 'Redis123456',  // ← fallback
});
// 必须监听 error 事件！
this.redisClient.on('error', (err) => {
  this.logger.warn(`Redis client error (non-fatal): ${err.message}`);
});
```

**C. 重启服务**：
```bash
ssh -o ConnectTimeout=10 changji 'pm2 delete all && pm2 start dist/main.js --name changji-api && pm2 save'
```

**D. 验证稳定**：
```bash
# 等待60秒，看重启次数是否仍为0
ssh -o ConnectTimeout=10 changji 'pm2 flush && sleep 60 && pm2 jlist | python3 -c "
import json,sys
for p in json.load(sys.stdin):
  if p[\"name\"]==\"changji-api\":
    print(f\"重启: {p[\"pm2_env\"][\"restart_time\"]} 状态: {p[\"pm2_env\"][\"status\"]}\")
"'
# 期望：重启 = 0，状态 = online
```

**预防清单（部署前必查）**：
- [ ] `ls -la /home/admin/dang/server/.env` 文件存在
- [ ] `.env` 中包含 `REDIS_PASSWORD=Redis123456`
- [ ] 所有 ioredis 客户端都有 `redisClient.on('error', ...)` 监听器
- [ ] `pm2 logs changji-api --err` 实时检查没有 NOAUTH / ECONNREFUSED

### 问题10：WSL 端 SSH 密钥缺失（远程运维中断）

> **关键案例（2026-06-03）**：在 WSL 实例 `dang` 中执行 `ssh changji` 命令时报 `permission denied (publickey)`。

**现象**：
- WSL 终端执行 `ssh changji` 失败
- 错误：`Permission denied (publickey)`
- Windows 端的 `id_ed25519` 存在但 WSL 端 `~/.ssh/` 目录不存在

**根本原因**：
- WSL 实例是新创建或被重置的，`~/.ssh/` 是空的
- Windows 端 `C:\Users\xxx\.ssh\` 已有密钥
- WSL 和 Windows 是两个文件系统，不共享 `.ssh/`

**解决方案**（一次性配置）：
```powershell
# 复制 Windows 端密钥到 WSL
wsl -d dang bash -c 'bash /mnt/d/trae_projects/dang/tmp/setup_wsl_ssh.sh'
```

或手动复制：
```bash
# 在 WSL 内执行
mkdir -p ~/.ssh
chmod 700 ~/.ssh
cp /mnt/c/Users/<Windows用户>/.ssh/id_ed25519 ~/.ssh/
cp /mnt/c/Users/<Windows用户>/.ssh/id_ed25519.pub ~/.ssh/
cp /mnt/c/Users/<Windows用户>/.ssh/config ~/.ssh/
cp /mnt/c/Users/<Windows用户>/.ssh/known_hosts ~/.ssh/
chmod 600 ~/.ssh/id_ed25519 ~/.ssh/config
chmod 644 ~/.ssh/id_ed25519.pub ~/.ssh/known_hosts
```

**权限强制要求**（Linux SSH 安全规范）：
| 文件 | 权限 |
|-----|------|
| `~/.ssh/` | `700` |
| `~/.ssh/id_ed25519` | `600` |
| `~/.ssh/config` | `600` |
| `~/.ssh/known_hosts` | `644` |

**详细规范** → 详见 [BUILD.md § WSL SSH 密钥配置](BUILD.md#-wsl-ssh-密钥配置远程操作前置条件)

---

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
# 服务器本地（应为新版本）
ssh changji "curl -s http://127.0.0.1/subscriptions | grep -o bg-gradient | wc -l"

# 外部访问（对比结果）
curl -s http://101.133.238.249/subscriptions | grep -o bg-gradient | wc -l
# 如果两者一致且均为 0，说明服务器正确，问题在客户端缓存层
```

---

## 五、部署后验证（使用 MCP 工具）

### 5.1 Chrome DevTools MCP — 浏览器视觉验证

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

### 5.2 GitHub MCP — 代码与发布管理

| 操作 | MCP 工具 | 说明 |
|------|---------|------|
| 创建部署分支 | `mcp_GitHub_create_branch` | 从 main 创建 `deploy/YYYYMMDD` 分支 |
| 提交代码变更 | `mcp_GitHub_push_files` | 批量推送部署相关文件 |
| 创建 PR | `mcp_GitHub_create_pull_request` | 创建部署 PR 供审查 |
| 查看部署历史 | `mcp_GitHub_list_commits` | 查看最近的部署提交 |

---

## 六、相关文档

| 文档 | 用途 |
|-----|------|
| [SERVER_DEPLOY_PROCEDURE.md](SERVER_DEPLOY_PROCEDURE.md) | 标准部署流程、权限管理、回滚机制 |
| [SERVER_SECURITY.md](SERVER_SECURITY.md) | 网络安全、API安全、安全审计 |
| [SERVER_OPS.md](SERVER_OPS.md) | 日常检查、日志管理、应急响应 |
| [SERVER_API.md](SERVER_API.md) | 畅记云 API 接口说明 |
| [../docs/SERVER_STATUS.md](../docs/SERVER_STATUS.md) | **服务器部署状态与架构记录**（部署前必读） |
| [../docs/BACKEND_ARCHITECTURE.md](../docs/BACKEND_ARCHITECTURE.md) | 后端管理系统完整架构（NestJS模块、数据库实体、AI路由策略） |
| [RED_LINES.md](RED_LINES.md) | 通用安全红线 |
| [BUILD.md](BUILD.md) | APK构建规则 |
| [API_DESIGN.md](API_DESIGN.md) | API设计规范 |

---

## 更新记录

| 日期 | 版本 | 更新内容 |
|-----|------|---------|
| 2026-06-03 | v3.2 | **新增问题9（核心）**：后端反复重启 1472 次的根因复盘（Redis NOAUTH + ioredis unhandled error + .env 路径错）含完整解决方案和预防清单；**新增问题10**：WSL 端 SSH 密钥缺失的标准化恢复流程；引用 [BUILD.md § WSL SSH 密钥配置](BUILD.md) 和 [.env 规范](BUILD.md#-env-与-processenv-规范部署必修) |
| 2026-06-02 | v3.1 | 新增"部署前必读"章节：强制要求部署前查阅 SERVER_STATUS.md；更新相关文档引用 |
| 2026-06-01 | v3.0 | **最终纠正**：实际用户是 admin（不是 mayn）；实际路径是 /home/admin/；编译输出路径是 dist/main.js（不是 dist/src/main.js）；更新所有路径引用 |
| 2026-06-01 | v2.1 | 纠正：实际用户是 mayn 不是 admin（后被证明错误） |
| 2026-05-30 | v2.0 | 新增问题7：编译后代码路径与 PM2 配置不匹配（MODULE_NOT_FOUND）；新增问题8：数据库表结构变更后实体类未同步（Unknown column）；增加部署前检查清单 |
| 2026-05-25 | v1.9 | 安全修复：交互式 SSH/psql/redis-cli 加"仅手动使用"标注并提供 AI 安全替代；curl 命令加 --connect-timeout/--max-time |
| 2026-05-21 | v1.7 | 新增 CASE-005：Admin 后台 Tailwind CSS 样式不生效；新增 CASE-006：Nginx 缓存导致旧版本页面无法更新 |
| 2026-05-21 | v1.6 | 拆分优化：部署流程→SERVER_DEPLOY_PROCEDURE.md，安全→SERVER_SECURITY.md，运维→SERVER_OPS.md，API→SERVER_API.md |
| 2026-05-20 | v1.5 | 新增服务器连接方式章节 |
| 2026-05-20 | v1.2 | 新增服务器连接方式 |
| 2026-05-19 | v1.1 | 新增 Node.js/PostgreSQL/Redis |
| 2026-05-20 | v1.0 | 初始版本 |
