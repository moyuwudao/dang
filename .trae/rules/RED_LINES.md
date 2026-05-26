---
alwaysApply: true
description: 安全红线规则 - 绝对不能碰的区域和操作
---

# RED_LINES.md - 安全红线

## 核心理念

这份文档列出**绝对不能做**的事情。
这些红线不是为了限制，而是保护：
- 保护你的数据安全
- 保护你的账号安全
- 保护产品不被意外破坏

---

## 🔴 绝对红线（Zero Tolerance）

### 1. 密钥和凭证

**绝对不能做**：
- ❌ 读取或暴露 API 密钥
- ❌ 提交密钥到 git 仓库
- ❌ 在任何文件中硬编码密钥
- ❌ 在对话中透露密钥内容

**包含但不限于**：
- AI API 密钥（如阿里云、通义千问）
- Android 签名密钥
- WebDAV 密码
- 任何第三方服务的凭证

**正确做法**：
- 密钥必须放在 `secrets.env` 或 `.env` 文件中
- 这些文件必须在 `.gitignore` 中
- 代码中通过环境变量读取
- Flutter 特定：使用 `flutter_secure_storage` 存储运行时令牌

### Flutter 特定安全

**绝对不能做**：
- ❌ 在代码中硬编码 API 密钥（`const apiKey = 'xxx'`）
- ❌ 使用 `SharedPreferences` 存储明文敏感数据
- ❌ 在日志中打印 token、密码等敏感信息
- ❌ 使用 HTTP（必须使用 HTTPS）
- ❌ 未验证深链 URL 直接导航

**正确做法**：
- ✅ 使用 `String.fromEnvironment('API_KEY')` 编译时配置
- ✅ 使用 `flutter_secure_storage` 存储认证令牌
- ✅ 使用 `print` 替代方案（logger 包）且不包含敏感数据
- ✅ Android 配置 `network_security_config.xml` 禁止明文流量
- ✅ iOS 配置 `NSAppTransportSecurity` 禁止任意加载
- ✅ 深链验证 scheme、host、path 后才导航

---

### 2. 用户数据

**绝对不能做**：
- ❌ 删除用户数据（除非用户明确要求）
- ❌ 修改用户数据（除非用户明确要求）
- ❌ 导出用户数据给第三方
- ❌ 在日志中记录敏感用户信息

**用户数据包括**：
- 录音文件
- 转录文本
- 笔记内容
- AI 分析结果
- 设置偏好

---

### 3. 生产配置

**绝对不能做**：
- ❌ 修改生产环境的 API 地址
- ❌ 更改生产数据库连接
- ❌ 调整生产环境的权限设置
- ❌ 关闭安全验证

**什么是"生产"**：
- 用户实际使用的版本
- 发布到应用商店的 APK

---

### 4. Git 敏感操作

**绝对不能做**：
- ❌ 强制 push（`git push --force`）
- ❌ 删除远程分支
- ❌ 修改 git 历史
- ❌ 在未经确认的情况下合并冲突

**如果必须做**：
- 必须先问 Walle
- 解释风险
- 确认备份

---

### 5. 终端命令执行（强制上限 + 超时自动终止）

#### 5.1 禁止的无限等待命令

**绝对不能用的命令**：
- ❌ `pm2 logs` **不加 `--nostream`** → 会进入流式监听，永不退出
- ❌ `tail -f` / `tailf` → 持续监听文件变化，永不退出
- ❌ `adb logcat` **不加 `-d`** → 持续输出日志流，永不退出
- ❌ `flutter logs` / `flutter run` → 前台持续运行，永不退出
- ❌ `npm run dev` / `npm start` → 开发服务器前台运行，永不退出
- ❌ `dart run build_runner watch` → 文件监听模式，永不退出
- ❌ 交互式 shell（`psql`、`redis-cli`、`ssh` 不加命令）→ 等待输入，永不退出
- ❌ `journalctl` / `systemctl status` **不加分页禁用** → 可能触发 `less` 分页器

**正确替代**：
```
❌ pm2 logs changji-api --lines 100
✅ pm2 logs changji-api --lines 100 --nostream

❌ tail -f /var/log/nginx/access.log
✅ tail -n 100 /var/log/nginx/access.log

❌ adb logcat | grep -i flutter
✅ adb logcat -d | grep -i flutter

❌ sudo -u postgres psql -d appdb
✅ sudo -u postgres psql -d appdb -c "SELECT 1;"

❌ redis-cli -a xxx
✅ redis-cli -a xxx --no-auth-warning PING

❌ ssh changji
✅ ssh changji "具体命令"
```

#### 5.2 命令超时要求

**所有终端命令必须考虑超时**：

| 命令类型 | 默认超时 | 示例 |
|---------|---------|------|
| SSH 远程命令 | **30 秒** | `ssh -o ConnectTimeout=10 changji "cmd"` |
| 日志查看（`pm2 logs --nostream`） | **10 秒** | 快速完成，几乎不需要超时 |
| 数据库只读查询 | **30 秒** | `PGOPTIONS="-c statement_timeout=30000" psql -c "SELECT..."` |
| 数据库 DDL（ALTER TABLE 等） | **60 秒** | `PGOPTIONS="-c statement_timeout=60000" psql -c "ALTER TABLE..."` |
| API 调用（curl） | **10 秒** | `curl --connect-timeout 5 --max-time 10 http://...` |
| 文件同步（rsync） | **60 秒** | `rsync --timeout=60 -av ...` |
| 依赖安装（pub get/npm install） | **120 秒** | `timeout 120 flutter pub get` |
| APK 构建 | **20 分钟** | `timeout 1200 flutter build apk --release` |
| 测试运行 | **10 分钟** | `timeout 600 flutter test --coverage` |
| Hook 命令 | **60 秒** | `timeout 60 dart format .` |

#### 5.3 命令超时自动恢复（不需要等确认）

**当命令超时或卡住时**：
1. ✅ **自动调用 `CheckCommandStatus`** 轮询状态（最多 3 次，间隔 5 秒）
2. ✅ **超时 60 秒后自动 `StopCommand`** → 不需要等 Walle 确认
3. ✅ **自动重试 1 次**（修正参数后），仍失败则报告
4. ✅ **只读操作（日志查看、状态查询、数据读取）超时后不需要确认，直接自动处理**

**只读操作超时不需要确认的理由**：
- 日志查看（`pm2 logs --nostream`、`tail`、`journalctl`）→ 纯粹的信息查询
- 状态查询（`systemctl status`、`pm2 status`、`df -h`、`free -h`）→ 只读
- 数据库查询（SELECT）→ 只读，有 statement_timeout 保护
- 这些操作**不会修改任何数据**，卡住了直接终止重试即可

#### 5.4 重试上限与模式识别

**绝对不能做**：
- ❌ 同一个命令失败后用不同方式反复重试超过 **2 次**
- ❌ 在命令失败后不检查原因就自动换方案重试
- ❌ 对生产环境（服务器、数据库）执行未验证的命令
- ❌ 用同一种方式（仅改变格式/转义/引号）反复重试 —— 这不是"重试"，这是机械重复

**模式识别规则（关键防重复机制）**：

当出现以下任意情况时，**不视为"值得重试"**，必须立即停止并切换方案：
| 识别信号 | 含义 | 正确行为 |
|---------|------|---------|
| 重试后得到与上次**完全相同的错误输出** | 改格式没解决问题 | **立即停止，换思路** |
| 错误信息包含引号/转义相关关键词 | 环境限制，非代码问题 | **切换传输方案**，不继续调引号 |
| 连续 2 次输出"PowerShell 引号问题"等同类描述 | 环境根本限制 | **立即换方案**，不再用 `cat << 'EOF'` |
| 分析后发现原因与上次相同 | 方案本身有问题 | **换方案**，不继续打补丁 |
| "尝试了方案 A，不行" → 用方案 A 的不同写法再试 | 这不是方案 B | **换真正的方案 B** |

**环境限制 vs 代码错误的区分**：

```
错误输出 → 分析是哪种问题？
  ↓
环境限制？
  ├→ PowerShell 引号/转义问题
  ├→ heredoc 在 SSH 中截断
  ├→ Windows 路径与 Linux 路径混用
  ├→ 文件编码/换行符差异
  └→ 正确行为：**立即切换传输方案**，不重试同方式
  ↓
代码/逻辑错误？
  ├→ SQL 语法错误
  ├→ 依赖冲突
  ├→ 类型不匹配
  └→ 正确行为：**修复代码后重试 1 次**
```

#### 5.5 PowerShell + SSH 跨环境规则（强制执行）

**核心原则**：在 Windows PowerShell 终端**禁止直接通过 SSH 传递多行代码或 heredoc**。必须使用 WSL bash 作为中转。

**为什么必须这样做**：
- PowerShell 的引号和转义规则与 bash 完全不同
- heredoc（`cat << 'EOF'`）在 PowerShell SSH 中必然断裂
- 不要试图"调试引号格式" —— 这是环境根本限制，换了也没用
- WSL 已配置且 bash 完美支持所有 bash 语法

**绝对不能做**：
- ❌ 直接 `ssh changji "cat << 'EOF' ... EOF"` —— heredoc 必然断裂
- ❌ 在 SSH 命令中嵌套多层引号（单引号套双引号套单引号）
- ❌ 用 `python3 -c '...'` 在 SSH 中传递多行 Python 代码
- ❌ 用 `printf` 拼接多行内容到 SSH 远程文件
- ❌ 试图通过"换一种引号格式"来解决引号问题
- ❌ 不要在输出中说"PowerShell 转义太复杂了" —— 已经有解决方案了

**正确替代方案（按优先级）**：

```
方案 1（首选，一行搞定）：WSL bash 代理 SSH —— 解决一切引号问题

  # 多行代码直接传（bash 正确解析 heredoc）
  wsl bash -c "ssh changji 'cat > /tmp/fix.py << EOF
  这里写任意多行 Python/SQL/Shell 代码
  不需要任何转义
  引号、变量、换行符全部正确传递
  EOF
  python3 /tmp/fix.py'"

  # 单行命令也推荐用 wsl bash，避免引号意外
  wsl bash -c "ssh changji '《任何 bash 命令》'"

方案 2（备选）：Write 工具写本地文件 → WSL rsync 到服务器 → WSL SSH 执行
  1. Write file: d:\trae_projects\dang\tmp\fix.py
  2. wsl bash -c "rsync -av /mnt/d/trae_projects/dang/tmp/ changji:/tmp/"
  3. wsl bash -c "ssh changji 'python3 /tmp/fix.py'"

方案 3（代码同步场景）：GitHub MCP 推送 → SSH git pull
  1. GitHub MCP push_files → 推送到仓库
  2. ssh changji "cd /path && git pull"
```

**一句话记忆**：
> 任何需要引号、多行代码、heredoc 的 SSH 操作 → 统一用 `wsl bash -c "ssh changji '...'"`。不再讨论 PowerShell 引号问题。


#### 5.6 重试判断标准（完整版）

```
命令执行
  ↓
成功？ → 完成
  ↓ 卡住（60 秒无响应）
自动 StopCommand → 分析原因
  ↓ 原因是环境限制（引号/转义）
切换传输方案（Write+scp 或 GitHub MCP），不重试原方式
  ↓ 原因是代码错误
修正重试（仅 1 次）
  ↓ 仍卡住/仍失败
自动 StopCommand → 报告 Walle
  ↓ 失败
分析错误输出
  ↓
错误与上次完全相同？ → **这不是新问题，立即停止，换方案**
  ↓
能确定原因？ → 修复后重试（仅 1 次）
  ↓ 不能确定
立即停止，报告给 Walle
  ↓
第 1 次重试后仍失败？
  ↓ 是
立即停止，报告给 Walle，不再尝试
```

---

### 6. APK 构建（强制要求）

**绝对不能做**：
- ❌ 未经 Walle 同意，在 Windows 本地直接构建 APK
- ❌ 在本地下载或安装 Android SDK/NDK 等构建工具
- ❌ 尝试在本地配置 Flutter 构建环境

**强制要求**：
- ✅ **必须在 WSL 环境构建** - 所有 APK 构建必须在 WSL 实例 `dang` 中进行
- ✅ **WSL 环境已配置完成** - 包含 Flutter SDK、Android SDK、签名密钥
- ✅ **优先使用现有环境** - 不要重复下载或配置

> **唯一构建规则源** → 详见 [BUILD.md](BUILD.md)

**绝对红线**：任何情况下都不允许跳过 WSL 在本地构建！

---

## 🟢 自由区域（可以直接做）

这些可以放心做，不需要每次都问：

- ✅ 修改 UI 样式（颜色、间距、字体）
- ✅ 修改现有页面的布局
- ✅ 添加/修改现有功能的文案
- ✅ 修改 Flutter 资源文件（图片、图标）
- ✅ 调整动画效果
- ✅ 修改 `lib/features/` 下的页面代码
- ✅ 在 `lib/` 下添加新文件

---

## 🟠🟡 高风险和警告操作

> **完整高风险操作规范** → 详见 [HIGH_RISK_OPS.md](HIGH_RISK_OPS.md)

| 颜色 | 含义 | 行动 |
|-----|------|------|
| 🔴 红 | 绝对不能做 | 绝对不做，零容忍 |
| 🟠 橙 | 高风险小心 | 先问，等确认 |
| 🟡 黄 | 先问再做 | 解释后确认 |
| 🟢 绿 | 放心做 | 直接做 |

---

## 如果不确定

**规则很简单**：

> 如果你不确定某个操作是否安全 → 先问 Walle

**问的模板**：
```
[确认] 我想___，这会不会影响___？
```

---

## 意外触发了红线怎么办

### 密钥暴露了
1. 立即告诉 Walle
2. 一起商量是否需要更换密钥
3. 从对话历史中清除

### 误删了文件
1. 立即告诉 Walle
2. 检查是否在 git 中还有记录
3. 商量恢复方案

### push 出了问题
1. 立即停止操作
2. 告诉 Walle 发生了什么
3. 不要继续尝试修复，等 Walle 指示

---

*触犯红线不是错误，隐瞒才是。*
*如果不小心触犯了，立即告诉我，我们一起处理。*

---

## 更新记录

| 日期 | 更新内容 |
|-----|---------|
| 2026-05-25 | 重大更新：第5节全面改写，新增5.1禁止无限等待命令、5.2命令超时要求、5.3超时自动恢复（免确认）、5.4重试上限 |
| 2026-05-21 | 拆分优化：高风险/警告操作→HIGH_RISK_OPS.md |
| 2026-05-17 | 初始版本 |
