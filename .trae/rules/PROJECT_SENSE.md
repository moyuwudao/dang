---
alwaysApply: false
globs: lib/**/*.dart, pubspec.yaml
description: 项目感知规则 - 如何快速理解项目结构、技术栈、现有约定
---
# PROJECT_SENSE.md - 项目感知规则

## 核心理念

当 Walle 给我一个新任务时，我需要能够快速"看懂"这个项目。
这份文档告诉我：
- **项目是什么**
- **怎么组织的**
- **用什么技术**
- **有哪些约定**

---

## 项目基本信息

### 是什么

**changji_app（畅记）** 是一个 AI 语音笔记应用。

**核心功能**：
- 录音 → 转文字 → AI 分析
- 支持 OCR（拍照识别文字）
- 速记笔记
- AI 角色设定（不同场景用不同 AI 风格）
- 数据备份（WebDAV）

**目标用户**：
- 有录音笔记需求的个人/小团队
- 不想花太多钱买会员的用户
- 有能力提供自己 API 密钥的用户

---

## 技术栈

### 框架

| 技术 | 用途 |
|-----|------|
| **Flutter** | 跨平台应用框架（Android/iOS/Linux/macOS/Windows） |
| **Dart** | 编程语言 |

### 状态管理

| 技术 | 说明 |
|-----|------|
| **flutter_riverpod** | 应用状态管理 |

### 数据库

| 技术 | 说明 |
|-----|------|
| **drift** | SQLite ORM 数据库 |
| **sqlite3_flutter_libs** | SQLite 原生库 |

### 核心功能库

| 功能 | 库 |
|-----|---|
| 录音 | `record` |
| 权限管理 | `permission_handler` |
| OCR | `google_mlkit_text_recognition` |
| 图片选择 | `image_picker` |
| 网络请求 | `dio` |
| 路由 | `go_router` |
| 音频播放 | `just_audio` |
| 分享 | `share_plus` |
| 压缩 | `archive` |

---

## 项目结构

```
dang/
├── lib/                          # 主要代码
│   ├── main.dart                 # 入口文件
│   ├── core/                     # 核心模块
│   │   ├── models/               # 数据模型
│   │   ├── services/             # 服务（API、录音、存储等）
│   │   ├── theme/                 # 主题（颜色、样式）
│   │   └── widgets/               # 通用组件
│   ├── data/                     # 数据层
│   │   ├── database/             # 数据库
│   │   ├── models/               # 数据模型
│   │   └── repositories/         # 数据仓库
│   ├── features/                 # 功能模块
│   │   ├── home/                 # 首页
│   │   ├── recording/            # 录音功能
│   │   ├── records/              # 记录列表
│   │   ├── ocr/                  # OCR 功能
│   │   ├── quick_note/           # 速记
│   │   ├── mindmap/              # 思维导图
│   │   ├── settings/             # 设置
│   │   ├── statistics/           # 统计
│   │   ├── reminders/            # 提醒
│   │   ├── reports/              # 报告
│   │   └── workbench/            # 工作台
│   ├── routes/                   # 路由配置
│   └── l10n/                     # 国际化
├── android/                      # Android 平台代码
├── ios/                          # iOS 平台代码
├── test/                         # 测试代码
└── pubspec.yaml                  # 依赖配置
```

---

## 约定与模式

### 服务层（services/）

**规则**：所有服务都是独立的，放在 `lib/core/services/`

**命名**：
- `xxx_service.dart` - 服务文件
- 使用 Riverpod 的 Provider 暴露

**示例**：
```dart
// lib/core/services/recording_service.dart
class RecordingService { ... }

// 在文件中或单独文件导出 Provider
final recordingServiceProvider = Provider<RecordingService>((ref) => ...);
```

---

### 功能模块（features/）

**规则**：每个功能一个文件夹，包含 screens、widgets、providers

**结构**：
```
features/
└── xxx/
    ├── screens/      # 页面
    ├── widgets/      # 组件
    ├── providers/    # 状态
    ├── models/       # 模型（如果只有这个功能用到）
    └── services/     # 服务（如果只有这个功能用到）
```

---

### 状态管理（Riverpod）

**Provider 命名**：
- `xxxProvider` - Provider
- `xxxNotifier` - Notifier
- `xxxState` - State 类

**位置**：
- 通常在 `providers/` 文件夹
- 或者在 `screens/` 同级的 `providers/`

---

### 路由（go_router）

**规则**：集中在 `lib/routes/app_router.dart`

**用法**：
```dart
// 定义路由
final appRouter = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, __) => HomeScreen()),
    // ...
  ],
);

// 使用
MaterialApp.router(routerConfig: appRouter)
```

---

### 数据库（drift）

**规则**：
- 数据库定义在 `lib/data/database/app_database.dart`
- 生成的代码在 `app_database.g.dart`
- 使用 Repository 模式访问数据

---

## 我理解项目的方式

### 当需要了解某个功能时

1. **看 `features/` 下的模块名** - 模块名即功能名
2. **看 `screens/`** - 找到主页面
3. **看 `providers/`** - 了解状态管理
4. **看 `services/`** - 了解数据来源

### 当需要找代码时

**按功能找**：
- 录音相关 → `features/recording/`
- 记录列表 → `features/records/`
- 设置 → `features/settings/`

**按类型找**：
- 所有服务 → `core/services/`
- 所有模型 → `core/models/` 或 `data/models/`
- 所有页面 → `features/*/screens/`

### 当需要修改时

1. **先理解这个模块的结构** - 看 screen、provider、service
2. **找到对应的文件** - 不要猜，用搜索
3. **遵循现有模式** - 看同目录下其他文件怎么写
4. **如果要改核心逻辑** - 先问 Walle（按 INTERACTION.md）

---

## 关键技术概念（简明版）

### Riverpod 状态管理

**简单的理解**：
- Provider = 数据的"提供者"
- Widget 通过 `ref.watch(provider)` 读取数据
- 数据变化时，Widget 自动更新

### Drift 数据库

**简单的理解**：
- 像是在代码里定义表格
- 自动生成查询代码
- 用起来像在用对象而不是 SQL

### Go Router

**简单的理解**：
- 定义"网址"和"页面"的对应关系
- 支持嵌套路由
- 可以跳转、传参

---

## 项目现状

### 已有功能

- ✅ 录音 + 转文字
- ✅ AI 摘要分析
- ✅ AI 角色切换
- ✅ OCR 拍照识字
- ✅ 速记
- ✅ 思维导图生成
- ✅ 数据备份（WebDAV）
- ✅ 统计页面
- ✅ 多语言（中文/英文）
- ✅ 暗黑模式

### 构建环境

- **WSL**：Ubuntu 24.04，Flutter 在 `/home/mayn/flutter`
- **Android SDK**：在 `/home/mayn/Android/Sdk`
- **签名**：使用 `changji.jks`
- **构建输出**：APK 在 `build/app/outputs/flutter-apk/`

---

## 总结

| 我需要 | 去哪找 |
|-------|--------|
| 页面代码 | `features/[模块]/screens/` |
| 状态管理 | `features/[模块]/providers/` |
| 服务 | `core/services/` |
| 数据库 | `lib/data/database/` |
| 路由 | `lib/routes/` |
| 主题 | `core/theme/` |
| 资源文件 | `android/app/src/main/res/` |

---

*当我不确定某个模块怎么工作的时候，我会先看这个模块的结构，再开始做。*
