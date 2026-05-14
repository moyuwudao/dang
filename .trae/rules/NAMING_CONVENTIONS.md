---
alwaysApply: false
description: 项目命名约定 - 代码文件、类、变量、函数的命名规范
---
# NAMING_CONVENTIONS.md - 命名约定

## 核心理念

好的命名让代码自解释。
看名字就知道这是干什么的，减少需要读代码的时间。

---

## 文件命名

### Dart 文件（snake_case）

| 类型 | 规则 | 示例 |
|-----|------|------|
| **类文件** | `xxx_something.dart` | `recording_service.dart` |
| **页面文件** | `xxx_screen.dart` | `home_screen.dart` |
| **模型文件** | `xxx_model.dart` | `record_model.dart` |
| **Provider 文件** | `xxx_provider.dart` | `recording_provider.dart` |
| **工具文件** | `xxx_util.dart` | `date_util.dart` |

### 目录命名

| 位置 | 规则 | 示例 |
|-----|------|------|
| 功能模块 | snake_case | `quick_note/` |
| 屏幕目录 | screens | `features/recording/screens/` |
| 组件目录 | widgets | `features/records/widgets/` |
| 状态目录 | providers | `features/recording/providers/` |

---

## 类命名（PascalCase）

### 原则

- **见名知意**：看到名字知道是干什么的
- **名词开头**：类名是名词
- **不加类型前缀**：不要加 `Class`、`Object` 前缀

### 示例

| ✅ 正确 | ❌ 错误 | 原因 |
|--------|--------|------|
| `RecordingService` | `RecordingServiceClass` | 不需要加 Class |
| `TranscriptionState` | `TranscriptionStateClass` | 不需要加 Class |
| `AiModelConfig` | `Config` | 太模糊 |
| `RecordModel` | `Record` | Record 可能混淆 |

---

## 枚举命名（PascalCase）

| ✅ 正确 | ❌ 错误 |
|--------|--------|
| `AiProvider` | `ProviderType` |
| `TranscriptionMethod` | `transcription_method` |
| `AppFeature` | `FeatureEnum` |

枚举成员也用 PascalCase：

```dart
enum AiProvider {
  openAI,
  claude,
  qwen,
}
```

---

## Provider 命名

### Provider 变量

| 类型 | 规则 | 示例 |
|-----|------|------|
| **Service Provider** | `xxxServiceProvider` | `recordingServiceProvider` |
| **State Provider** | `xxxStateProvider` | `recordingStateProvider` |
| **Notifier Provider** | `xxxProvider` | `recordListProvider` |
| **Future Provider** | `xxxFutureProvider` | `recordsFutureProvider` |
| **Stream Provider** | `xxxStreamProvider` | `transcriptionStreamProvider` |

### StateNotifier 命名

| 部分 | 规则 | 示例 |
|-----|------|------|
| **State 类** | `XxxState` | `RecordingState` |
| **Notifier 类** | `XxxNotifier` | `RecordingStateNotifier` |

### 示例

```dart
// Service Provider
final recordingServiceProvider = Provider<RecordingService>((ref) {
  return RecordingService();
});

// State + Notifier Provider
final recordingStateProvider = StateNotifierProvider<RecordingStateNotifier, RecordingState>((ref) {
  return RecordingStateNotifier(...);
});

// 简单 State Provider
final isRecordingProvider = StateProvider<bool>((ref) => false);
```

---

## 变量命名（camelCase）

### 原则

- **小写开头**：第一个字母小写
- **见名知意**：看到名字知道包含什么
- **不用缩写**：除非是公认缩写（如 `api`、`id`）

### 示例

| ✅ 正确 | ❌ 错误 | 原因 |
|--------|--------|------|
| `recordingPath` | `recPath` | 缩写不清晰 |
| `transcriptionText` | `text` | 太模糊 |
| `isRecording` | `rec` | 缩写 |
| `currentUserId` | `cUid` | 不标准的缩写 |

### 私有变量

```dart
class RecordingService {
  final AudioRecorder _audioRecorder;  // 下划线开头
  StreamController<List<double>> _amplitudeController;
}
```

### 常量

```dart
const int maxRetryCount = 3;           // const 变量用 camelCase
static const String apiVersion = 'v1'; // static const 也是 camelCase
```

---

## 方法/函数命名（camelCase）

### 原则

- **动词开头**：描述做什么
- **清晰动作**：如 `start`、`stop`、`get`、`save`

### 常见动词

| 动作 | 用于 |
|-----|------|
| `get` | 获取数据 | `getRecordingPath()` |
| `set` | 设置值 | `setApiKey()` |
| `start` | 开始 | `startRecording()` |
| `stop` | 停止 | `stopRecording()` |
| `save` | 保存 | `saveRecord()` |
| `delete` | 删除 | `deleteRecord()` |
| `update` | 更新 | `updateSettings()` |
| `check` | 检查 | `hasPermission()` |
| `is`/`has`/`can` | 判断 | `isRecording`、`hasPermission` |

### 示例

```dart
Future<bool> hasPermission();
Future<String> startRecording();
Future<String?> stopRecording();
void cancelRecording();
```

---

## 布尔变量命名

| 类型 | 规则 | 示例 |
|-----|------|------|
| **is 开头的** | `isXxx` | `isRecording`、`isLoading` |
| **has 开头的** | `hasXxx` | `hasPermission`、`hasError` |
| **can 开头的** | `canXxx` | `canEdit`、`canDelete` |

---

## 回调/匿名函数

```dart
// 参数用简洁的名字
onTap: (context) => handleTap(context),
onChanged: (value) => updateValue(value),

// 异步操作
Future<void> save() async {
  await _repository.save();
}
```

---

## Widget 组件命名

### 页面/屏幕

```dart
class HomeScreen extends StatelessWidget { ... }
class RecordingScreen extends ConsumerWidget { ... }
```

### 通用组件

```dart
class RecordList extends StatelessWidget { ... }
class AudioPlayerWidget extends StatefulWidget { ... }
```

---

## 数据库相关

### 表名（snake_case，复数）

```dart
class Records extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 255)();
}
```

### 列名（snake_case）

```dart
IntColumn get id => integer().autoIncrement()();
TextColumn get createdAt => text()();
BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
```

---

## 路由命名

### 路径常量

```dart
abstract class AppRoutes {
  static const String home = '/';
  static const String recording = '/recording';
  static const String settings = '/settings';
}
```

### Route 文件

```dart
// routes/app_router.dart
GoRoute(
  path: AppRoutes.home,
  builder: (context, state) => const HomeScreen(),
)
```

---

## 资源文件命名

### 图片

```
ic_launcher.png
ic_camera.xml
widget_background.png
```

### 尺寸目录

```
mipmap-hdpi/    # 高清
mipmap-xhdpi/   # 超高清
mipmap-xxhdpi/  # 更高清
```

---

## 总结速查

| 类型 | 规则 | 示例 |
|-----|------|------|
| Dart 文件 | snake_case | `recording_service.dart` |
| 类名 | PascalCase | `RecordingService` |
| 枚举 | PascalCase | `AiProvider.openAI` |
| Provider | xxxProvider | `recordingServiceProvider` |
| 私有变量 | _camelCase | `_audioRecorder` |
| 普通变量 | camelCase | `currentPath` |
| 方法 | camelCase | `startRecording()` |
| 布尔 | is/has/can + Xxx | `isRecording` |
| 路径常量 | snake_case | `static const String recordingPath` |

---

*遇到不确定的命名，参考同目录下其他文件的风格。*
