---
alwaysApply: false
globs: lib/**/*.dart
description: Flutter 开发调试规范 - 热重载、设备选择、日志查看等日常操作
---

# DEBUG.md - Flutter 开发调试规范

## 核心理念

Flutter 开发调试的效率取决于能否快速：
- 运行应用
- 查看日志
- 热重载修改
- 排查问题

---

## 环境要求

### WSL 环境

```bash
# 进入 WSL
wsl -d dang

# 设置环境变量
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
export PATH=/home/mayn/flutter/bin:/usr/bin:/bin:/usr/local/bin:$PATH
```

### Windows 环境

确保：
- Android 手机已开启开发者模式
- USB 调试已开启
- 数据线连接电脑

---

## 运行应用

### 连接设备查看

```bash
# 查看已连接设备
flutter devices

# 期望输出示例：
# Chrome
# Windows
# Android SDK built for x86 (emulator)
# Mi 9 (device)
```

### 运行 Debug 版本

⚠️ `flutter run` 是持续运行命令，不适合自动化脚本。需要手动 Ctrl+C 停止。

```bash
# ⚠️ 持续运行命令，不适合自动化脚本。需要手动 Ctrl+C 停止
# 选择设备运行
flutter run -d <device-id>

# 示例
flutter run -d Mi 9

# 或者直接运行，会选择第一个可用设备
flutter run
```

### 运行 Release 版本

⚠️ `flutter run --release` 是持续运行命令，不适合自动化脚本。需要手动 Ctrl+C 停止。

```bash
# ⚠️ 持续运行命令，不适合自动化脚本。需要手动 Ctrl+C 停止
flutter run --release
```

---

## 热重载（Hot Reload）

### 使用场景

修改了 UI、样式、简单逻辑时使用，不需要重启应用。

### 快捷键

| 环境 | 快捷键 |
|-----|--------|
| VS Code | `Ctrl + S`（保存时自动） |
| Android Studio | `Ctrl + \` |
| 命令行 | `r` |

### 命令行热重载

```bash
# 在 flutter run 运行时按 r
# 或者
flutter hotreload
```

### 热重启（Hot Restart）

修改了状态管理、initState、Provider 等时使用，会重置状态。

```bash
# 在 flutter run 运行时按 R（大写）
# 或者
flutter hotrestart
```

---

## 日志查看

### flutter logs

⚠️ 持续输出命令，自动化场景请使用 `adb logcat -d`

```bash
# 查看 Android 日志
flutter logs

# 指定设备
flutter logs -d <device-id>
```

### adb logcat（更详细）

```bash
# 进入 adb
adb shell

# 查看 Flutter 日志（dump 模式，输出后退出）
logcat -d -s flutter

# 查看所有日志（dump 模式，输出后退出）
logcat -d

# 过滤某个 tag
logcat -s myapp

# 清除日志
logcat -c
```

### VS Code

安装 Flutter 扩展后，调试控制台会显示日志。

---

## Debug 模式的特点

| 特点 | 说明 |
|-----|------|
| 断言开启 | Debug 模式会检查断言 |
| 调试信息 | 有额外的调试信息 |
| 性能优化关闭 | 性能不如 Release |
| 热重载支持 | 支持 Hot Reload |

---

## Release 模式测试

### 为什么重要

- Debug 模式下有些问题不会暴露
- 性能问题只在 Release 下明显
- 某些行为 Debug 和 Release 不同

### 构建 Release

```bash
# WSL 内
cd /home/mayn/dang/android
./gradlew assembleRelease --no-daemon
```

### 安装 Release APK

```bash
# 通过 flutter 安装（需要设备连接）
flutter install

# 或者手动安装 APK
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

---

## 常见问题排查

### 设备找不到

```bash
# 1. 检查设备
flutter devices

# 2. 重启 ADB
adb kill-server
adb start-server

# 3. 重新连接设备
```

### 应用崩溃

```bash
# 1. 查看日志
flutter logs

# 2. 用 adb 查看更详细的 crash 日志
adb logcat -d | grep -i crash
```

### 热重载不生效

```bash
# 1. 使用热重启
flutter hotrestart

# 2. 清理后重新运行
flutter clean
flutter pub get
flutter run
```

---

## 代码调试

### IDE 断点调试

VS Code 或 Android Studio 中：
1. 在代码行号左侧点击设置断点
2. `flutter run --debug`
3. 断点会触发，查看变量值

### print 调试

```dart
print('Debug: value = $value');

// 注意：生产代码删除 print
// 用 assert 或日志框架代替
```

### Debug Mode 专用代码

```dart
// 只在 Debug 模式运行
assert(() {
  print('Debug only: $debugInfo');
  return true;
}());
```

---

## 性能分析

### DevTools

```bash
flutter run --observatory
```

浏览器打开显示的 URL，查看：
- 性能 timeline
- 内存使用
- Widget 树

### APK 大小分析

```bash
flutter build apk --analyze-size
```

---

## 服务器端问题排查（Admin 后台）

> **优先使用 Chrome DevTools MCP** → 详见 [PLAYWRIGHT_E2E.md](PLAYWRIGHT_E2E.md)

### 使用 Chrome DevTools MCP 快速诊断

```
1. 打开 admin 面板并截图
   mcp_Chrome_DevTools_MCP_navigate_page(type="url", url="http://101.133.238.249/admin/dashboard")
   mcp_Chrome_DevTools_MCP_take_screenshot(fullPage=true)

2. 检查控制台错误
   mcp_Chrome_DevTools_MCP_list_console_messages(types=["error"])

3. 检查 API 请求是否正常
   mcp_Chrome_DevTools_MCP_list_network_requests(resourceTypes=["xhr", "fetch"])

4. 如果是按钮问题，按 PLAYWRIGHT_E2E.md 的按钮排查 SOP 执行
```

### 服务器端配置排查（传统方式）

1. **检查路由配置**
   ```bash
   # 查看 next.config.js
   cat admin/next.config.js
   ```
   - 确认 `trailingSlash: true` 配置
   - 确认部署的代码版本与配置一致

2. **检查 Nginx 配置**
   ```bash
   cat /etc/nginx/sites-available/admin
   ```
   - 确保配置支持带斜杠的 URL
   - 添加缓存控制头防止旧代码缓存

3. **验证 API 连接**
   ```bash
   curl --connect-timeout 5 --max-time 10 http://101.133.238.249/api/v1/auth/me
   ```

4. **使用 Playwright 测试验证**
   ```bash
   npx playwright test --timeout=60000
   ```

**解决方案**：

```nginx
# Nginx 配置示例
server {
    listen 80;
    server_name _;
    root /var/www/html/admin;
    index index.html;

    location / {
        try_files $uri $uri/ $uri.html /index.html;
        add_header Cache-Control no-cache;
    }

    location /_next/ {
        expires 1y;
        add_header Cache-Control public;
    }

    location /api/ {
        proxy_pass http://127.0.0.1:3000;
    }
}
```

**根本原因**：
- 前端配置了 `trailingSlash: true`，但服务器部署的是旧版本代码
- 缓存导致浏览器使用过期的 JavaScript 代码

---

## 总结

| 操作 | 命令 |
|-----|------|
| 查看设备 | `flutter devices` |
| 运行 Debug | `flutter run` |
| 热重载 | `r` 或 Ctrl+S |
| 热重启 | `R` |
| 查看日志 | `flutter logs` |
| Release 构建 | `./gradlew assembleRelease` |

---

*开发时多使用热重载，发布前用 Release 测试。*

---

## 更新记录

| 日期 | 更新内容 |
|-----|---------|
| 2026-05-25 | 安全修复：flutter run/logs/logcat 标注持续运行命令；adb logcat 改为 -d dump 模式；curl 加超时；playwright 加 --timeout |
