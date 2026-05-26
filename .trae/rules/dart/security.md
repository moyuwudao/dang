---
alwaysApply: false
description: Dart/Flutter 安全规范
---

# Dart/Flutter 安全规范

> 本文件扩展 `common/security.md`，添加 Dart、Flutter 和移动端特定安全要求。

## 🔴 密钥管理

### 绝对禁止

- ❌ 在 Dart 源代码中硬编码 API 密钥、令牌、密码
- ❌ 提交 `.env` 文件到 git 仓库
- ❌ 在日志中打印敏感数据
- ❌ 使用 `SharedPreferences` 存储明文敏感数据

### 正确做法

```dart
// ❌ 绝对禁止
const apiKey = 'sk-abc123...';
const apiSecret = 'secret_xyz...';

// ✅ 编译时配置（非机密，仅可配置）
const apiKey = String.fromEnvironment('API_KEY');

// ✅ 运行时从环境变量读取（开发环境）
import 'package:flutter_dotenv/flutter_dotenv.dart';
final apiKey = dotenv.env['API_KEY'];

// ✅ 运行时从安全存储读取（生产环境）
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
final storage = const FlutterSecureStorage();
final token = await storage.read(key: 'auth_token');
```

### 配置文件结构

```
project/
├── .env.example          # ✅ 提交（示例）
├── .env                  # ❌ 不提交（.gitignore）
├── .env.production       # ❌ 不提交（.gitignore）
└── secrets.env           # ❌ 不提交（.gitignore）
```

**.env.example**:
```env
# API Configuration
API_KEY=your_api_key_here
API_BASE_URL=https://api.example.com

# Feature Flags
ENABLE_TRANSCRIPTION=true
```

**.gitignore**:
```gitignore
# Environment variables
.env
.env.*
!env.example
secrets.env
```

## 🔴 网络安全

### HTTPS 强制

```dart
// ❌ 禁止 HTTP
final dio = Dio(BaseOptions(baseUrl: 'http://api.example.com'));

// ✅ 强制 HTTPS
final dio = Dio(BaseOptions(
  baseUrl: 'https://api.example.com',
  connectTimeout: const Duration(seconds: 10),
  receiveTimeout: const Duration(seconds: 30),
));
```

### Android 网络安全配置

创建 `android/app/src/main/res/xml/network_security_config.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <!-- 生产环境：禁止明文流量 -->
    <base-config cleartextTrafficPermitted="false">
        <trust-anchors>
            <certificates src="system" />
        </trust-anchors>
    </base-config>
    
    <!-- 开发环境：允许本地调试 -->
    <debug-overrides>
        <trust-anchors>
            <certificates src="user" />
        </trust-anchors>
    </debug-overrides>
</network-security-config>
```

在 `AndroidManifest.xml` 中引用：

```xml
<application
    android:networkSecurityConfig="@xml/network_security_config"
    ...>
</application>
```

### iOS ATS 配置

在 `ios/Runner/Info.plist` 中：

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
</dict>
```

### 证书锁定（高安全场景）

```dart
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

final dio = Dio();
(dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
  final client = HttpClient();
  client.badCertificateCallback = (X509Certificate cert, String host, int port) {
    // 验证证书指纹
    return cert.sha1 == 'expected_sha1_fingerprint';
  };
  return client;
};
```

## 🔴 输入验证

### SQL 注入防护

```dart
// ❌ SQL 注入风险
await db.rawQuery("SELECT * FROM users WHERE email = '$userInput'");

// ✅ 参数化查询
await db.query(
  'users',
  where: 'email = ?',
  whereArgs: [userInput],
);

// ✅ 使用 ORM（drift, sqflite）
final users = await (select(users)..where((u) => u.email.equals(userInput))).get();
```

### 深链验证

```dart
// ❌ 未验证深链
final uri = Uri.parse(incomingLink);
context.go(uri.path); // 可能导航到任意路由

// ✅ 验证深链
final uri = Uri.tryParse(incomingLink);
if (uri != null && 
    uri.host == 'myapp.com' && 
    _allowedPaths.contains(uri.path)) {
  context.go(uri.path);
} else {
  // 显示错误页面或导航到安全页面
  context.go('/error');
}
```

### 用户输入验证

```dart
// ✅ 使用正则验证
bool isValidEmail(String email) {
  return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
}

// ✅ 使用 package:validator
import 'package:validator/validator.dart';
if (!isEmail(userInput)) {
  throw FormatException('Invalid email');
}

// ✅ 长度限制
if (password.length < 8) {
  throw FormatException('Password too short');
}
```

## 🔴 数据保护

### 安全存储

```dart
// ❌ 不安全 - SharedPreferences 明文
final prefs = await SharedPreferences.getInstance();
await prefs.setString('auth_token', token);

// ✅ 安全 - flutter_secure_storage
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const storage = FlutterSecureStorage(
  aOptions: AndroidOptions(
    encryptedSharedPreferences: true,
  ),
  iOptions: IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  ),
);

await storage.write(key: 'auth_token', value: token);
final token = await storage.read(key: 'auth_token');
```

### 登出时清理

```dart
Future<void> logout() async {
  // 清除安全存储
  await storage.delete(key: 'auth_token');
  await storage.deleteAll();
  
  // 清除 SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  
  // 清除 Cookie
  await CookieManager().clearCookies();
  
  // 导航到登录页
  context.go('/login');
}
```

### 避免敏感数据日志

```dart
// ❌ 泄漏敏感数据
print('Token: $token');
debugPrint('User data: $userData');
print('API Response: $response');

// ✅ 使用日志级别
import 'package:logger/logger.dart';
final logger = Logger();

logger.i('User logged in'); // 不包含敏感数据
logger.e('Login failed', error: exception); // 记录异常但不记录 token
```

## 🟠 Android 特定安全

### 权限最小化

在 `AndroidManifest.xml` 中只声明必要权限：

```xml
<!-- ✅ 必要权限 -->
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />

<!-- ❌ 不必要权限 -->
<uses-permission android:name="android.permission.READ_CONTACTS" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

### 导出组件保护

```xml
<!-- ❌ 不安全的 Activity 导出 -->
<activity
    android:name=".ShareActivity"
    android:exported="true"> <!-- 任何应用可启动 -->
</activity>

<!-- ✅ 添加权限保护 -->
<activity
    android:name=".ShareActivity"
    android:exported="true"
    android:permission="com.example.PERMISSION_SHARE">
</activity>

<!-- ✅ 或使用 intent-filter 明确意图 -->
<activity
    android:name=".ShareActivity"
    android:exported="true">
    <intent-filter>
        <action android:name="android.intent.action.SEND" />
        <category android:name="android.intent.category.DEFAULT" />
        <data android:mimeType="text/plain" />
    </intent-filter>
</activity>
```

## 🟠 iOS 特定安全

### Keychain 访问组

在 `ios/Runner/Entitlements` 中配置：

```xml
<key>keychain-access-groups</key>
<array>
    <string>$(AppIdentifierPrefix)com.example.dang.shared</string>
</array>
```

### 生物识别认证

```dart
import 'package:local_auth/local_auth.dart';

final LocalAuthentication auth = LocalAuthentication();

// 检查是否可用
final bool canCheckBiometrics = await auth.canCheckBiometrics;
final List<BiometricType> availableBiometrics = await auth.getAvailableBiometrics();

// 认证
final bool didAuthenticate = await auth.authenticate(
  localizedReason: '请认证以访问录音',
  options: const AuthenticationOptions(
    stickyAuth: true,
    biometricOnly: true,
  ),
);

if (didAuthenticate) {
  // 访问敏感数据
}
```

## 🟡 安全响应协议

### 发现安全问题时

1. **立即停止** - 停止当前开发
2. **使用 security-reviewer agent** - 全面审查
3. **修复 CRITICAL 问题** - 优先修复
4. **轮换密钥** - 如有暴露
5. **审查整个代码库** - 查找类似问题
6. **记录问题和修复** - 防止再次发生

### 安全检查清单

提交前检查：

- [ ] 无硬编码密钥
- [ ] 所有 API 调用使用 HTTPS
- [ ] 用户输入已验证
- [ ] 敏感数据使用安全存储
- [ ] 无敏感数据日志
- [ ] 权限最小化
- [ ] 深链已验证
- [ ] 登出时清理数据

## 安全工具

### 自动化检查

```yaml
# analysis_options.yaml
linter:
  rules:
    - avoid_print  # 禁止 print
```

### 依赖审计

```bash
# 检查依赖漏洞（网络操作，设 60 秒超时）
timeout 60 dart pub outdated
timeout 60 flutter pub outdated

# 使用 dart audit（下载 + 运行，设 120 秒超时）
timeout 120 dart pub global activate dart_audit
dart audit
```

### 静态分析

```bash
# 运行分析
flutter analyze

# 严格模式
flutter analyze --fatal-infos --fatal-warnings
```

## 另请参阅

- 通用安全规范：`common/security.md`
- 安全红线：`RED_LINES.md`
- 安全审查 agent：`agent: security-reviewer`
