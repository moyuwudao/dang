# 服务器目录结构存档

> **服务器**: 101.133.238.249 (changji)
> **SSH Host**: changji
> **实际用户**: admin
> **实际 HOME**: /home/admin/
> **最后更新**: 2026-06-02
> **用途**: 避免反复搜索服务器目录结构

---

## ⚠️ 重要纠正（2026-06-01）

**之前的文档错误**：
- ❌ 错误假设用户是 `mayn`，路径是 `/home/mayn/`
- ❌ 错误假设 API 部署目录是 `/opt/changji-cloud/api/`
- ❌ 错误假设编译输出路径是 `dist/src/main.js`

**实际服务器情况**（已通过 SSH 确认）：
- ✅ 实际用户是 `admin`
- ✅ 实际 HOME 是 `/home/admin/`
- ✅ API 项目代码在 `/home/admin/dang/server/`
- ✅ 编译输出路径是 `dist/main.js`（不是 `dist/src/main.js`）
- ✅ `/opt/changji-cloud/` 目录**不存在**
- ✅ `/home/mayn/` 目录**不存在**

---

## 一、后端部署目录

### `/home/admin/dang/server/`（NestJS 后端项目根目录）

```
/home/admin/dang/server/
├── src/                    # NestJS 源代码
│   ├── admin/              # 管理后台模块
│   ├── ai/                 # AI 服务模块
│   ├── auth/               # 认证模块
│   ├── subscription/       # 订阅/计费模块
│   ├── redis/              # Redis 模块
│   ├── monitor/            # 监控模块
│   ├── payment/            # 支付模块
│   ├── plan/               # 套餐模块
│   └── main.ts             # 应用入口
├── dist/                   # 编译输出（nest build 生成）
│   ├── main.js             # PM2 启动入口 ✅ 正确路径
│   ├── main.d.ts
│   ├── main.js.map
│   ├── app.module.js
│   ├── admin/
│   ├── ai/
│   ├── auth/
│   ├── subscription/
│   └── ...
├── node_modules/           # npm 依赖
├── package.json            # 项目配置
├── tsconfig.json           # TypeScript 配置
│   └── outDir: "./dist"    # 编译输出到 dist/ 根目录
├── .env                    # 环境变量（需手动创建）
└── ecosystem.config.js     # PM2 配置（可选）
```

### 关键文件路径

| 文件/目录 | 实际路径 | 用途 |
|-----------|---------|------|
| 源代码 | `/home/admin/dang/server/src/` | NestJS 源代码 |
| 编译输出 | `/home/admin/dang/server/dist/main.js` | PM2 启动入口 ✅ |
| 错误路径 | `/home/admin/dang/server/dist/src/main.js` | ❌ 不存在！ |
| 依赖 | `/home/admin/dang/server/node_modules/` | npm 依赖 |
| 环境变量 | `/home/admin/dang/server/.env` | DB/Redis 密码等 |
| 项目配置 | `/home/admin/dang/server/package.json` | npm 配置 |
| TS 配置 | `/home/admin/dang/server/tsconfig.json` | outDir: "./dist" |

---

## 二、管理后台目录

### `/home/admin/dang/admin/`（Next.js 管理后台源码）

```
/home/admin/dang/admin/
├── pages/                  # Next.js 页面
├── services/               # API 调用层
├── node_modules/           # npm 依赖
└── package.json            # 项目配置
```

### `/home/admin/admin-sync/`（管理后台部署目录）

```
/home/admin/admin-sync/
├── out/                    # 静态构建输出
├── node_modules/           # npm 依赖
└── package.json            # 项目配置
```

---

## 三、Flutter 项目目录

### `/home/admin/dang/`（Flutter + 后端完整项目）

```
/home/admin/dang/
├── android/                # Android 平台代码
├── assets/                 # 资源文件
├── ios/                    # iOS 平台代码
├── lib/                    # Flutter 主代码
├── server/                 # NestJS 后端（见上文）
├── admin/                  # Next.js 管理后台源码
├── test/                   # 测试代码
├── web/                    # Web 平台
└── pubspec.yaml            # Flutter 配置
```

---

## 四、PM2 配置

### PM2 主目录

```
/home/admin/.pm2/
├── logs/                   # 日志目录
│   ├── changji-api-out.log # 标准输出日志
│   └── changji-api-error.log # 错误日志
├── dump.pm2               # 进程快照
└── pm2.log                # PM2 主日志
```

### 正确的 PM2 启动命令

```bash
# 进入项目目录
cd /home/admin/dang/server

# 启动/重启服务
npx pm2 start dist/main.js --name changji-api  # ✅ 正确路径
npx pm2 save

# 查看状态
npx pm2 status
npx pm2 logs changji-api --lines 20 --nostream
```

### ❌ 错误的 PM2 启动命令

```bash
# 错误路径！dist/src/main.js 不存在
npx pm2 start dist/src/main.js --name changji-api  # ❌ 错误！
```

---

## 五、Nginx 静态文件目录

### `/var/www/html/admin/`（管理后台部署路径）

```bash
# 部署管理后台
sudo rm -rf /var/www/html/admin
sudo cp -r /home/admin/admin-sync/out /var/www/html/admin
sudo chown -R www-data:www-data /var/www/html/admin
sudo systemctl reload nginx
```

---

## 六、数据库连接

### PostgreSQL

```bash
# 连接数据库
PGOPTIONS="-c statement_timeout=30000" sudo -u postgres psql -d appdb -c "SELECT 1;"

# 连接字符串
postgresql://appuser:AppUser123456@localhost:5432/appdb
```

### Redis

```bash
# 连接 Redis
redis-cli -a Redis123456 --no-auth-warning PING
```

---

## 七、部署检查清单

```bash
# 1. 确认在正确的目录
cd /home/admin/dang/server
pwd  # 应输出 /home/admin/dang/server

# 2. 确认 tsconfig.json 存在
ls tsconfig.json  # 应存在

# 3. 确认 package.json 存在
ls package.json  # 应存在

# 4. 构建
npm run build

# 5. 确认编译输出（重要！路径是 dist/main.js，不是 dist/src/main.js）
ls dist/main.js  # 应存在
ls dist/src/main.js  # 应不存在（如果存在说明配置有问题）

# 6. 重启服务（使用正确路径）
npx pm2 restart changji-api
# 或重新启动
npx pm2 delete changji-api
npx pm2 start dist/main.js --name changji-api  # ✅ 正确路径
npx pm2 save

# 7. 验证
npx pm2 status
curl -s http://localhost:3000/api/v1/health
```

---

## 八、常见错误预防

### 错误1：路径错误
- ❌ `/home/mayn/dang/server/` → 目录不存在
- ❌ `/opt/changji-cloud/api/` → 目录不存在
- ✅ `/home/admin/dang/server/` → 正确路径

### 错误2：用户错误
- ❌ 假设用户是 `mayn`
- ✅ 实际用户是 `admin`

### 错误3：编译输出路径
- ❌ `dist/src/main.js` → 错误（NestJS 输出到 `dist/main.js`）
- ✅ `dist/main.js` → 正确

### 错误4：tsconfig.json 配置
```json
{
  "compilerOptions": {
    "outDir": "./dist",  // 输出到 dist/ 根目录
    // 不是 "./dist/src"
  }
}
```

---

## 九、SSH 连接信息

```bash
# SSH Config（C:\Users\Mayn\.ssh\config）
Host changji
    HostName 101.133.238.249
    User admin              # 实际用户是 admin
    Port 22
    IdentityFile ~/.ssh/id_ed25519
    StrictHostKeyChecking accept-new
    ConnectTimeout 30
```

---

## 更新记录

| 日期 | 版本 | 更新内容 |
|-----|------|---------|
| 2026-06-02 | v3.1 | 确认：后端项目路径 `/home/admin/dang/server/`（无嵌套）；PM2 重启正常 |
| 2026-06-01 | v3.0 | **最终纠正**：实际用户是 admin；实际路径是 /home/admin/；编译输出路径是 dist/main.js 不是 dist/src/main.js |
| 2026-06-01 | v2.1 | 纠正：实际用户是 mayn 不是 admin（后被证明错误） |
| 2026-06-01 | v2.0 | 初始版本（含错误路径） |
