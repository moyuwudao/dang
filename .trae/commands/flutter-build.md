# Flutter 构建

## 用途

指导 Flutter 项目的构建流程，包括 APK、iOS、Web 等平台的构建。

## 触发方式

```bash
/flutter-build [平台或构建类型]
```

## 构建命令

### Android APK

```bash
# Debug 构建（快速，用于开发测试）
flutter build apk --debug

# Release 构建（优化，用于发布）
flutter build apk --release

# 分析构建大小
flutter build apk --analyze-size

# 构建到指定目录
flutter build apk --output=build/app/outputs/apk/release/
```

### iOS

```bash
# Debug 构建
flutter build ios --debug

# Release 构建（无签名，用于测试）
flutter build ios --release --no-codesign

# App Store 构建（需要签名）
flutter build ios --release
```

### Web

```bash
# 构建 Web 版本
flutter build web

# 优化构建
flutter build web --release
```

## 构建前检查清单

### 必须检查

- [ ] `flutter analyze` 通过
- [ ] `flutter test` 通过
- [ ] 无硬编码密钥
- [ ] 版本号已更新
- [ ] 更新日志已编写

### 推荐检查

- [ ] 性能测试通过
- [ ] 手动测试关键功能
- [ ] 截图已更新（如有 UI 改动）
- [ ] 文档已更新

## Android 构建配置

### build.gradle.kts

```kotlin
android {
    compileSdk = 34
    
    defaultConfig {
        applicationId = "com.example.dang"
        minSdk = 21
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"
    }
    
    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}
```

### 签名配置（生产环境）

**重要**: 签名密钥必须保密，遵循 RED_LINES.md

```kotlin
android {
    signingConfigs {
        create("release") {
            storeFile = file("keystore/release.jks")
            storePassword = System.getenv("STORE_PASSWORD")
            keyAlias = "upload"
            keyPassword = System.getenv("KEY_PASSWORD")
        }
    }
    
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
```

## 常见问题解决

### Gradle 构建失败

```bash
# 清理并重新构建
flutter clean
rm -rf android/.gradle
flutter pub get
flutter build apk
```

### 依赖冲突

```bash
# 查看依赖树
flutter pub deps

# 检查过时依赖
flutter pub outdated

# 强制清理依赖缓存
flutter clean
flutter pub cache repair
```

### 内存不足

```bash
# 增加 Gradle 内存
# android/gradle.properties:
org.gradle.jvmargs=-Xmx2048m -XX:MaxPermSize=512m
```

## 构建优化

### 减小 APK 大小

1. **启用代码压缩**
```kotlin
buildTypes {
    release {
        isMinifyEnabled = true
        isShrinkResources = true
    }
}
```

2. **移除未使用的资源**
```yaml
# pubspec.yaml
# 只包含需要的字体和资源
```

3. **分析构建大小**
```bash
flutter build apk --analyze-size
```

### 提高构建速度

1. **使用构建缓存**
```bash
# 启用 Gradle 缓存
org.gradle.caching=true
```

2. **增量构建**
```bash
# 只构建改动的部分
flutter build apk --target-platform android-arm64
```

## 发布流程

### 1. 版本号管理

```yaml
# pubspec.yaml
version: 1.2.3+4  # 1.2.3 是 versionName，4 是 versionCode
```

### 2. 构建 Release

```bash
flutter build apk --release
```

### 3. 验证构建

```bash
# 检查 APK 信息
aapt dump badging build/app/outputs/apk/release/app-release.apk

# 在设备上安装测试
flutter install --apk
```

### 4. 发布说明

编写 release notes，包括：
- 新功能
- Bug 修复
- 性能改进
- 已知问题

## 规则引用

- 构建规范：`BUILD.md`
- 安全红线：`RED_LINES.md`（签名配置）
- 依赖管理：`DEPENDENCY.md`
- Git 工作流：`GIT_WORKFLOW.md`（发布标签）

## 相关 Agent

- build-error-resolver - 构建错误诊断
- flutter-reviewer - 构建前代码审查

---

*构建是开发流程的最后一步，确保每次构建都可靠。*
