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
| 5 | PM2 路径不匹配 | 高 | ✅ 已解决 |
| 6 | 数据库表结构变更未同步 | 中 | ✅ 已解决 |
| 7 | SSH 路径解析错误 | 中 | ✅ 已解决 |
| 8 | API Key 分配不均问题 | 高 | ✅ 已解决 |
| 9 | rsync --delete 误删 WSL 端签名配置 | 高 | ✅ 已解决 |
| 10 | PowerShell 把 `$(date ...)` 误解析为 `$(Get-Date ...)` | 中 | ✅ 已解决 |
| 11 | TypeORM 实体 snake_case 与 DB camelCase schema 不匹配 | 高 | ✅ 已解决 |
| 12 | Admin passwordHash 字段 hash 写入截断（bcrypt 12 轮应 60 字符） | 中 | ⚠️ 临时解决 |
| 13 | WSL 端 `/mnt/d/` 文件缓存延迟（write 后立即执行报 No such file） | 低 | ✅ 已识别 |

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

## 案例 5：编译后代码路径与 PM2 配置不匹配（MODULE_NOT_FOUND）

**问题描述**：
- 后端代码修改后编译部署，服务无法启动
- PM2 状态显示 `errored`，重启次数不断增加
- 浏览器访问 API 返回 `Internal server error` 或无法连接

**错误日志**：
```
Error: Cannot find module '/opt/changji-cloud/api/dist/main.js'
    at Module._resolveFilename (node:internal/modules/cjs/loader:1207:15)
    code: 'MODULE_NOT_FOUND',
```

**排查过程**：
1. ✅ 检查 PM2 状态 - 显示 `errored`，PID 为 0
2. ✅ 查看 PM2 错误日志 - 发现 `MODULE_NOT_FOUND` 错误
3. ✅ 检查 PM2 配置的 script path - `/opt/changji-cloud/api/dist/main.js`
4. ❌ **发现问题**：实际编译后的文件在 `/home/admin/dang/server/dist/src/main.js`
5. ❌ **根本原因**：NestJS 编译输出目录结构为 `dist/src/main.js`，但 PM2 配置指向 `dist/main.js`

**根本原因**：
- NestJS 的 `tsconfig.json` 中 `outDir` 为 `./dist`，但实际编译后入口文件位于 `dist/src/main.js`
- PM2 启动配置中的 `script` 路径与实际编译输出路径不一致
- 之前通过 `rsync` 同步代码时，没有创建正确的符号链接或调整 PM2 配置

**解决方案**：

**方案 A：创建符号链接（推荐，快速修复）**
```bash
# 创建符号链接，让 dist/main.js 指向实际的 dist/src/main.js
ln -sf /opt/changji-cloud/api/dist/src/main.js /opt/changji-cloud/api/dist/main.js

# 重启服务
pm2 restart changji-api
```

**方案 B：修改 PM2 配置（长期解决）**
```bash
# 查看当前 PM2 配置
pm2 describe changji-api | grep "script path"

# 删除旧配置
pm2 delete changji-api

# 使用正确的路径重新启动
pm2 start /opt/changji-cloud/api/dist/src/main.js --name changji-api
pm2 save
```

**方案 C：修改 NestJS 配置（调整输出结构）**
```json
// tsconfig.json 中添加
{
  "compilerOptions": {
    "outDir": "./dist",
    "rootDir": "./src"
  }
}
// 或在 nest-cli.json 中配置入口
```

**验证方式**：
```bash
# 1. 确认文件存在
ls -la /opt/changji-cloud/api/dist/main.js
# 应输出：lrwxrwxrwx ... /opt/changji-cloud/api/dist/main.js -> /opt/changji-cloud/api/dist/src/main.js

# 2. 确认服务状态
pm2 status changji-api
# 应显示：online，PID 不为 0，uptime 正常增长

# 3. 测试 API
curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api/v1/admin/billing-standards
# 应返回：401（需要认证，说明服务正常）

# 4. 检查端口监听
ss -tlnp | grep 3000
# 应显示：LISTEN 0 511 0.0.0.0:3000 ... users:(("node",pid=xxx,fd=xx))
```

**经验教训**：
- 部署前必须确认编译输出路径与 PM2 配置路径一致
- 修改后端代码后，不仅要编译，还要验证编译输出结构
- 使用 `pm2 describe` 查看实际配置的 script path
- 建立部署检查清单：编译 → 验证输出 → 同步 → 重启 → 验证状态

**预防措施**：
```bash
# 部署前检查清单
echo "=== 部署前检查 ==="
echo "1. 编译输出路径:"
ls -la /home/admin/dang/server/dist/src/main.js 2>/dev/null || echo "❌ 编译输出不存在"
echo "2. PM2 配置路径:"
pm2 describe changji-api | grep "script path" || echo "❌ PM2 配置不存在"
echo "3. 目标路径:"
ls -la /opt/changji-cloud/api/dist/main.js 2>/dev/null || echo "❌ 目标路径不存在"
```

---

## 案例 6：数据库表结构变更后实体类未同步（Unknown column）

**问题描述**：
- 修改数据库表结构（如添加/删除/重命名列）后，后端服务报错
- API 返回 `Internal server error`
- 错误日志显示 `Unknown column 'xxx' in 'field list'`

**错误日志**：
```
QueryFailedError: column "base_price_cents" does not exist
    at PostgresQueryRunner.query (...)
```

**排查过程**：
1. ✅ 检查数据库表结构 - 发现列名已变更（如 `base_price_cents` → `base_price_yuan`）
2. ✅ 检查 TypeORM 实体类 - 发现实体类字段名未同步更新
3. ❌ **根本原因**：数据库表结构通过 SQL 脚本修改，但 TypeORM 实体类未同步更新

**根本原因**：
- 数据库表结构变更和实体类变更没有同步进行
- TypeORM 尝试查询不存在的列名
- 前后端数据模型不一致

**解决方案**：

**步骤 1：同步修改实体类**
```typescript
// billing-standard.entity.ts
// 修改前
@Column({ name: 'base_price_cents', type: 'int', nullable: true })
basePriceCents: number;

// 修改后
@Column({ name: 'base_price_yuan', type: 'decimal', precision: 10, scale: 4, nullable: true })
basePriceYuan: number;

@Column({ name: 'output_price_yuan', type: 'decimal', precision: 10, scale: 4, nullable: true })
outputPriceYuan: number;
```

**步骤 2：同步修改前端接口**
```typescript
// 前端接口定义
interface BillingStandard {
  // 修改前
  basePriceCents?: number;
  
  // 修改后
  basePriceYuan?: number;
  outputPriceYuan?: number;
}
```

**步骤 3：重新编译并部署**
```bash
cd /home/admin/dang/server
npm run build
rsync -avz --delete dist/ /opt/changji-cloud/api/dist/
pm2 restart changji-api
```

**验证方式**：
```bash
# 1. 确认数据库表结构
echo "\d billing_standards" | sudo -u postgres psql -d appdb

# 2. 确认实体类字段名与数据库一致
grep -n "base_price" /home/admin/dang/server/src/subscription/entities/billing-standard.entity.ts

# 3. 测试 API
curl -s http://localhost:3000/api/v1/admin/billing-standards -H "Authorization: Bearer xxx"
```

**经验教训**：
- 数据库表结构变更必须同步修改 TypeORM 实体类
- 实体类字段名必须与数据库列名一致（通过 `@Column({ name: 'xxx' })` 映射）
- 修改实体类后必须重新编译后端代码
- 建立数据库变更检查清单：SQL 脚本 → 实体类 → DTO → 前端接口

---

## 案例 7：服务器路径反复错误（SSH 输出解析问题）

**问题描述**：
- 通过 SSH 执行 `ls -la /home/admin/dang/dang/server/` 时，输出被错误解析
- 实际输出为 `dang`、`diagnose.sh`、`package-lock.json`（三个文件），但被误认为目录包含这些文件
- 导致反复假设路径是 `/home/admin/dang/dang/server/`（嵌套 dang），实际正确路径是 `/home/admin/dang/server/`

**错误日志**：
```
# SSH 实际输出
dang
diagnose.sh
package-lock.json

# 错误理解：认为 /home/admin/dang/dang/server/ 目录下有三个文件
# 正确理解：/home/admin/dang/ 目录下有 dang/、diagnose.sh、package-lock.json
```

**排查过程**：
1. ❌ 多次执行 `ls -la /home/admin/dang/dang/server/`，输出始终只有三个文件名，未意识到路径错误
2. ❌ 反复尝试不同方式解析输出，陷入循环
3. ✅ 用户直接登录服务器执行 `ls -la /home/admin/dang/dang/server/`，返回 `No such file or directory`
4. ✅ 确认正确路径是 `/home/admin/dang/server/`

**根本原因**：
- SSH 命令 `ls -la /home/admin/dang/dang/server/` 实际执行的是 `ls -la /home/admin/dang/`（因为 `/dang/server` 不存在，shell 自动回退）
- 或者：SSH 会话的当前目录是 `/home/admin/dang/server/`，执行 `ls` 时路径被忽略
- 输出被误解析为目录内容，而非错误信息

**解决方案**：
```bash
# 正确做法：用户直接在服务器上执行命令验证路径
admin@server:~/dang/server$ ls -la /home/admin/dang/dang/server/
ls: cannot access '/home/admin/dang/dang/server/': No such file or directory

# 确认正确路径
admin@server:~/dang/server$ ls -la /home/admin/dang/server/
# 正常输出 src/、dist/、package.json 等
```

**经验教训**：
- SSH 远程命令的输出可能被 shell 环境、当前工作目录影响
- 当输出与预期不符时，优先让用户直接在服务器上执行命令验证
- 避免在路径不确定时反复执行相同命令
- 建立路径确认机制：先 `pwd` + `ls` 确认当前位置，再执行目标命令

**预防措施**：
```bash
# 路径确认清单
echo "当前目录: $(pwd)"
echo "目标路径是否存在: $(ls -d /目标路径 2>/dev/null && echo '存在' || echo '不存在')"
```

---

## 案例 8：API Key 分配不均导致访问受限

**问题描述**：
- 多用户访问时，所有用户被分配到同一个 API Key
- 该 Key 的日配额快速耗尽，后续用户无法使用 AI 服务
- 每次请求都查询数据库，无缓存机制

**错误日志**：
```typescript
// 原代码问题
private async assignNewKey(userId: string) {
  const availableKey = await this.apiKeyRepository.findOne({
    where: { status: ApiKeyStatus.ACTIVE },
  });
  // 所有用户都拿到同一个 Key（数据库第一个活跃 Key）
}
```

**根本原因**：
- `findOne` 默认按主键排序，总是返回第一个活跃 Key
- 无负载均衡逻辑
- 无 Redis 缓存，每次请求都查数据库

**解决方案**：
1. 实现加权轮询算法（使用率 40% + 健康度 30% + 响应时间 20% + 配额余量 10%）
2. 添加 Redis 三层缓存（用户分配、活跃 Key 列表、实时使用量）
3. 配额预检和并发负载控制

**验证方式**：
```bash
# 1. 检查 Redis 缓存
redis-cli -a Redis123456 --no-auth-warning KEYS "api:*"

# 2. 查看多个用户的分配情况
# 通过 admin 后台查看 API Key 使用统计
```

**经验教训**：
- 多用户共享资源时必须实现负载均衡
- 缓存可以显著减少数据库压力并提高响应速度
- 配额预检可以避免将用户分配到已耗尽的 Key

---

## 案例 9：rsync --delete 误删 WSL 端签名配置

**问题描述**：
- 构建 APK 前已通过 `wsl bash` 在 `/home/mayn/dang/android/key.properties` 创建签名配置文件
- 紧接着执行 `rsync -av --delete /mnt/d/trae_projects/dang/android/ /home/mayn/dang/android/` 同步代码
- 同步后 key.properties 消失，APK 构建报 `Cannot read keyAlias from key.properties`

**错误日志**：
```
FAILURE: Build failed with an exception.
* What went wrong:
Execution failed for task ':app:validateSigningConfigRelease'.
> Cannot read keyAlias from key.properties
```
或：
```
> A failure occurred while executing com.android.build.gradle.tasks.PackageAndroidArtifact$IncrementalSplitterRunnable
> Key file not set for signing config release
```

**根本原因**：
- `key.properties` 包含签名密钥密码，**必须在 `.gitignore` 中**（不应进入 Git 仓库）
- Windows 端 `d:\trae_projects\dang\android\` 中**没有** key.properties（git 忽略）
- `rsync --delete` 的语义是"目标端与源端保持完全一致"——源端没有的文件，目标端有也会被删除
- 因此 WSL 端刚刚写入的 key.properties 被 rsync 当作"多余文件"删除

**排查过程**：
1. ✅ 检查 `local.properties` 和 `build.gradle.kts` —— 配置逻辑正确
2. ✅ 检查签名文件 `/home/mayn/.android/signing/changji.jks` —— 存在
3. ❌ **发现问题**：`/home/mayn/dang/android/key.properties` 不存在（被 rsync 删除）
4. ✅ 复现：写入 key.properties → rsync → 文件消失

**解决方案**：
**方案 A（推荐，最简单）**：rsync 同步完成后再写入 key.properties

```bash
# 1. 先 rsync 同步代码（会自动删除 WSL 端多余文件）
wsl -d dang bash -c 'rsync -av --delete /mnt/d/trae_projects/dang/android/ /home/mayn/dang/android/ --exclude=".gradle" --exclude="build"'

# 2. rsync 之后再写入签名配置
wsl -d dang bash -c 'cat > /home/mayn/dang/android/key.properties << EOF
storePassword=123456
keyPassword=123456
keyAlias=changji
storeFile=/home/mayn/.android/signing/changji.jks
EOF'
```

**方案 B**：rsync 加 `--exclude` 保护 WSL 端独有文件

```bash
rsync -av --delete --exclude="key.properties" --exclude=".gradle" --exclude="build" \
  /mnt/d/trae_projects/dang/android/ /home/mayn/dang/android/
```

**方案 C**：把 key.properties 纳入 WSL 项目的 `.gitignore` 同步黑名单

```bash
# 在 WSL 端 android/.gitignore 末尾追加（已经存在）
echo "key.properties" >> /home/mayn/dang/android/.gitignore
```

**验证方式**：
```bash
# 1. 确认 key.properties 存在
wsl -d dang bash -c "ls -la /home/mayn/dang/android/key.properties"

# 2. 确认内容正确
wsl -d dang bash -c "cat /home/mayn/dang/android/key.properties"

# 3. 构建成功
wsl -d dang bash -c "cd /home/mayn/dang && flutter build apk --release"
```

**经验教训**：
- `rsync --delete` 是"双向对齐"工具，目标端任何不在源端的文件都会被删除
- **敏感/本地配置文件**（key.properties、.env、local.properties）必须放在 rsync 之后写入
- 如果 WSL 端需要长期保留某些文件，rsync 时必须用 `--exclude` 保护
- **危险组合**：用 `rsync --delete` 同步时，**先写敏感文件 → 再 rsync = 必丢**
- 推荐流程：先 rsync 同步代码 → 再写 WSL 端独有的配置 → 再构建

---

## 案例 10：PowerShell 把 `$(date ...)` 误解析为 `$(Get-Date ...)`

**问题描述**：
- 在 PowerShell 终端执行：`wsl -d dang bash -c "TS=\$(date +%Y%m%d_%H%M); ..."`
- 预期：WSL bash 展开 `$(date ...)` 为时间戳字符串
- 实际：PowerShell 提前把 `$(date +%Y%m%d_%H%M)` 当作 PowerShell 表达式 `$(Get-Date +%Y%m%d_%H%M)` 执行
- 结果：报 `Get-Date: 无法将值 "+%Y%m%d_%H%M" 转换为类型 "System.DateTime"`
- 后续的 WSL bash 命令也被破坏（双引号未闭合）：`/bin/bash: -c: line 1: unexpected EOF`

**错误日志**：
```
Get-Date : 无法绑定参数"Date"。无法将值"+%Y%m%d_%H%M"转换为类型"System.DateTime"。错误:"该字符串未被识别为有效的 DateTime。"
所在位置 行:1 字符: 37
+ & { wsl -d dang bash -c "TS=\$(date +%Y%m%d_%H%M); TARGET=\"changji_app_\${TS}.apk\"; ...
+                                     ~~~~~~~~~~~~
    + CategoryInfo          : InvalidArgument: (:) [Get-Date], ParameterBindingException
    + FullyQualifiedErrorId : CannotConvertArgumentNoMessage,Microsoft.PowerShell.Commands.GetDateCommand

/bin/bash: -c: line 1: unexpected EOF while looking for matching `'"'
```

**根本原因**：
- PowerShell 的 `$(...)` 是**子表达式运算符**，会在命令解析阶段先求值
- 当用户期望 `$(...)` 透传给 WSL bash 时，PowerShell 已经把它当 PowerShell 表达式执行了
- 嵌套的双引号在 PowerShell 中还会触发二次解析，进一步破坏命令字符串
- 这次错误的连锁反应：PowerShell 解析 → 报错 → WSL 收到残缺命令 → 报 EOF 错误

**排查过程**：
1. ❌ 第一次尝试：双引号包裹 + 内嵌 `$(date ...)` → PowerShell 提前解析
2. ❌ 第二次尝试：单引号包裹整个 wsl 命令 → trae-sandbox 仍可能解析 `$`
3. ✅ **最终方案**：把逻辑写进 WSL 内的 `.sh` 脚本，再 `bash xxx.sh`

**解决方案**：
**方案 A（最稳，推荐）**：Write 工具写脚本到 Windows 端，WSL 读取并执行

```powershell
# 1. Write 写脚本到 Windows 端
# 文件：d:\trae_projects\dang\tmp_copy_apk.sh
# 内容：
#   #!/bin/bash
#   TS=$(date +%Y%m%d_%H%M)
#   TARGET="changji_app_${TS}.apk"
#   cp /home/mayn/dang/build/app/outputs/flutter-apk/app-release.apk "/mnt/d/trae_projects/dang/${TARGET}"

# 2. WSL 执行脚本
wsl -d dang bash -c 'bash /mnt/d/trae_projects/dang/tmp_copy_apk.sh'

# 3. 用完删除临时脚本
Remove-Item "d:\trae_projects\dang\tmp_copy_apk.sh"
```

**方案 B**：PowerShell 用反引号 ` ` ` 转义所有 `$`

```powershell
wsl -d dang bash -c "TS=`$(date +%Y%m%d_%H%M); TARGET=`"changji_app_`${TS}.apk`"; cp ... /mnt/d/.../`${TARGET}"
# ❌ 极容易写错，不推荐
```

**方案 C**：用 `Invoke-Expression` 显式标记 PowerShell 边界

```powershell
$cmd = 'TS=$(date +%Y%m%d_%H%M); TARGET="changji_app_${TS}.apk"; cp /home/mayn/dang/build/app/outputs/flutter-apk/app-release.apk "/mnt/d/trae_projects/dang/${TARGET}"'
wsl -d dang bash -c $cmd
# ✅ 变量在 PowerShell 端不展开，但写起来繁琐
```

**验证方式**：
```bash
# 1. 确认 APK 复制成功，文件名带时间戳
ls -la /mnt/d/trae_projects/dang/changji_app_*.apk | tail -3

# 2. 确认 PowerShell 端可见
Get-ChildItem "d:\trae_projects\dang\changji_app_*.apk" | Sort-Object LastWriteTime -Descending | Select-Object -First 3 Name, Length, LastWriteTime

# 3. 确认时间戳与预期时间一致
Get-Item "d:\trae_projects\dang\changji_app_20260602_2255.apk" | Select-Object Name, Length, LastWriteTime, CreationTime
```

**经验教训**：
- **PowerShell 的 `$(...)` 不是字符串，它会先被解析**——绝不能期望它透传给 WSL
- **任何含 `$`、`"`、`(`、`)` 的复杂命令**，优先用 Write+脚本方案
- **trae-sandbox + PowerShell + wsl + bash -c** 组合是 4 层解析，**任何一层都可能在错误的位置解释元字符**
- WSL bash 内的 `$(date ...)` 本身完全正常，问题 100% 出在 PowerShell 提前介入
- **铁律**：跨 PowerShell → WSL bash 传命令，要么用方案 A（脚本文件），要么用方案 C（变量传递），绝不直接在命令行嵌套引号
- 简单场景下可以试 `wsl -d dang bash -c '...'`（外层单引号），但只能处理无 `$` 嵌入的情况

---

## 更新记录

| 日期 | 案例 | 更新内容 |
|-----|------|---------|
| 2026-06-02 | 案例 9-10 | 新增：rsync --delete 误删 WSL 端签名配置（key.properties）、PowerShell 把 `$(date ...)` 误解析为 `$(Get-Date ...)` |
| 2026-06-04 | 案例 11-13 | 新增：TypeORM 实体 snake_case 与 DB camelCase schema 不匹配（导致分配套餐 500）、Admin passwordHash 字段 hash 写入截断（临时解决）、WSL 端 `/mnt/d/` 文件缓存延迟 |
| 2026-06-02 | 案例 7-8 | 新增：SSH 路径解析错误、API Key 分配不均问题 |
| 2026-05-30 | 案例 5-6 | 新增：PM2 路径不匹配问题、数据库表结构变更同步问题 |
| 2026-05-25 | - | 安全修复：playwright 测试加 --timeout=60000；nginx reload 前加 nginx -t 验证 |
| 2026-05-23 | 案例 1-4 | 初始版本 |

---

*本文件记录项目中遇到的典型错误案例，便于快速定位和解决类似问题。*

---

## 案例 11：TypeORM 实体 snake_case 与 DB camelCase schema 不匹配（导致 500 错误）

**问题描述**：
- 阿里云 ECS 后端，调用 `/api/v1/admin/users/:userId/subscribe` 分配套餐接口返回 500
- 错误日志：`column s.user_id does not exist`
- 同样导致 `/api/v1/admin/users` 列表接口 500

**错误日志**：
```
[Nest] ERROR [ExceptionsHandler] QueryFailedError: column s.user_id does not exist
    at AdminService.getUsers (.../admin.service.ts:72:3)
    at AdminService.assignPlanToUser (.../admin.service.ts:343:13)
```

**根本原因**：
- `subscriptions` 表实际列名是 camelCase：`userId`, `planId`, `startedAt`, `expiresAt`, `totalQuota`, `usedQuota`
- TypeORM 实体 `Subscription` 的 `@Column` 全部用了 snake_case `name: 'user_id'` 等
- TypeORM 0.2.x 在 SELECT/INSERT/UPDATE 时会按 `name` 指定的列名生成 SQL
- 但 DB 中不存在 `user_id` 列，只有 `userId`，导致所有订阅相关的写入/读取失败
- **影响面**：所有 subscription 写入/读取、含 subscriptions 关联的查询（如 getUsers）

**关键诊断**：
```sql
-- 1. 看 DB 实际列名
\d subscriptions
-- 输出：userId, planId, startedAt, expiresAt, totalQuota, usedQuota
--        （不是 user_id, plan_id 等 snake_case）

-- 2. 实体 vs DB 不一致
-- 实体：@Column({ name: 'user_id' }) userId: string
-- DB：userId  (camelCase)
```

**解决方案**：
1. 修正 TypeORM 实体，与 DB 实际列名一致：
```typescript
// 修改前
@Column({ name: 'user_id' }) userId: string;
@Column({ name: 'plan_id' }) planId: string;
@Column({ name: 'token_quota', default: 0 }) tokenQuota: number;
@Column({ name: 'used_tokens', default: 0 }) usedTokens: number;
@Column({ name: 'balance_tokens', default: 0 }) balanceTokens: number;
@Column({ name: 'started_at', type: 'timestamp' }) startedAt: Date;
@Column({ name: 'expires_at', type: 'timestamp' }) expiresAt: Date;

// 修改后（去除 name 映射，typeorm 默认用属性名）
@Column() userId: string;
@Column() planId: string;
@Column({ default: 0 }) totalQuota: number;  // 重命名 tokenQuota→totalQuota
@Column({ default: 0 }) usedQuota: number;    // 重命名 usedTokens→usedQuota
// 移除 balanceTokens（DB 无此列，实际在 user_token_balances 表）
@Column({ type: 'timestamp' }) startedAt: Date;
@Column({ type: 'timestamp' }) expiresAt: Date;
```

2. 同步修复所有 service 中引用旧字段名的代码：
- `admin.service.ts` `assignPlanToUser`：`tokenQuota` → `totalQuota`, `usedTokens` → `usedQuota`, 移除 `balanceTokens`
- `subscription.service.ts` `assignSubscription` 和 trial 路径：同上
- 注意：API 响应字段名可保持 `tokenQuota/usedTokens` 不变以兼容前端，只改实体内部字段名

**预防措施**：
- ⚠️ 创建新实体时先用 `\d <table>` 确认 DB 实际列名
- ⚠️ 不要假设列名就是 snake_case，**必须以 DB 实际为准**
- ⚠️ TypeORM 0.2.x `name` 是用来映射不同命名风格的，**必须与 DB 严格一致**
- ⚠️ 任何含 `leftJoinAndSelect` + `@ManyToOne` 的查询，列名错就会 500

**影响文件**：
- [subscription.entity.ts](server/src/subscription/entities/subscription.entity.ts) - 实体字段重命名
- [admin.service.ts](server/src/admin/admin.service.ts) - 字段引用同步
- [subscription.service.ts](server/src/subscription/subscription.service.ts) - 字段引用同步

**部署验证**：
- 编译产物含 `Subscription.prototype, "userId"`, `"totalQuota"`, `"usedQuota"`
- pm2 状态=online, 重启=0
- API 验证：分配套餐 HTTP 201, 返回 userPhone + totalQuota 字段

---

## 案例 12：Admin passwordHash 字段 hash 写入截断（临时解决）

**问题描述**：
- 重置 admin 密码后，登录仍然 401
- DB 中 passwordHash 长度只有 43 字符，但 bcrypt 12 轮 hash 应为 60 字符
- 后续 bcrypt.compareSync 失败

**根本原因**：
- typeorm 0.2 的 `@Column()` 不指定长度时，默认 VARCHAR(255)
- 但实际写入时某种原因被截断到 43 字符（具体原因未完全确认）
- 可能是 typeorm 0.2 旧版本 bug 或 PG 客户端字符串长度限制

**临时解决方案**：
- 用 pg 客户端直连，绕过 typeorm：
```javascript
const r = await client.query({
  text: 'UPDATE users SET "passwordHash" = $1 WHERE role = $2 RETURNING phone, LENGTH("passwordHash")',
  values: [hash, 'admin']
});
```
- 这样 hash 完整 60 字符写入成功

**永久方案**（待实施）：
- 在 User 实体中显式指定 `length: 255` 或改为 `@Column('text')`
- 或者用 `@Column('text')` 完全无长度限制
- 添加定期检查：所有 user 的 passwordHash 长度都应该是 60

**预防**：
- ⚠️ 任何 bcrypt/crypt hash 字段，TypeORM 实体必须用 `@Column('text')` 或 `@Column({ length: 255 })`
- ⚠️ 重置密码后必须验证 `LENGTH(passwordHash) = 60`，否则登录会失败

---

## 案例 13：WSL 端 `/mnt/d/` 文件缓存延迟

**问题描述**：
- WSL bash 中刚 Write 的脚本，立即执行 `bash /mnt/d/.../xxx.sh` 报 "No such file or directory"
- 但 `ls -la` 能看到文件
- 几秒后再执行又正常

**根本原因**：
- WSL 的 9P 文件系统（WSLDrvFS）有元数据缓存
- 跨系统写入（Windows → WSL）后，WSL 端 metadata 更新有延迟
- 表现为：文件存在但 bash 看不到

**解决方案**：
- 执行前加 `sleep 1~3` 等待
- 或在 wsl bash 中执行 `sync` 强制同步
- 或在 PowerShell 端用 `cmd /c` 调用

**预防**：
- ⚠️ 涉及 `/mnt/d/` 路径的脚本执行时，前面加 `sleep 2`
- ⚠️ 复杂命令链需要脚本化的，必须分步 sleep 等待

---

*本文件记录项目中遇到的典型错误案例，便于快速定位和解决类似问题。*
