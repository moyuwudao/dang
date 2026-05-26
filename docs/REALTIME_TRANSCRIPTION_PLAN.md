---
alwaysApply: false
description: 实时转写问题分析与解决方案 - 记录问题现象和修复方案
---

# 实时转写问题分析与解决方案

## 📊 问题现状

### 用户日志分析

```
❌ 问题1: 完全没有 [Realtime] 调试日志
   → checkRealtimeAvailability() 根本没有被调用
   
❌ 问题2: 直接调用了文件转写
   → TranscribeAudio: provider=qwen
   → Qwen ASR: model=qwen3-asr-flash
   → 说明录音结束后走了 TranscriptionQueue
   
✅ 问题3: 文件转写成功
   → content: "你太弱了。"
   → 证明 API Key 是正确的
```

---

## 🔴 根本原因分析

### 可能的原因（按可能性排序）

| 排名 | 可能原因 | 可能性 | 说明 |
|------|---------|--------|------|
| 1 | 用户没有开启"实时转写"开关 | ⭐⭐⭐⭐⭐ | 最可能 |
| 2 | `isRealtimeAvailable` 为 false，无法开启开关 | ⭐⭐⭐⭐ | 检查配置 |
| 3 | `initState` 中的 `addPostFrameCallback` 没有执行 | ⭐⭐⭐ | 异步问题 |
| 4 | `checkRealtimeAvailability()` 抛异常但被吞掉 | ⭐⭐ | 异常处理 |
| 5 | Riverpod Provider 注入失败 | ⭐ | 依赖问题 |

---

## 🎯 多套解决方案

### 方案 A：简化流程 - 默认开启 + 录音时检查（推荐）

**思路**：不依赖 UI 状态，直接在录音时检查并启动实时转写

**优点**：
- ✅ 简单直接，不依赖 UI 状态
- ✅ 自动检测配置，无需用户手动开启
- ✅ 即使配置不存在也不影响录音

**缺点**：
- ❌ 没有"实时转写开关"UI
- ❌ 无法让用户选择是否开启

**实施步骤**：
1. 修改 `startRecording()` 方法
2. 在录音开始时检查实时转写配置
3. 如果配置存在，自动启动实时转写
4. 移除"实时转写开关"UI（或者保留但不依赖）

---

### 方案 B：修复现有流程 - 保留开关但改进检查逻辑

**思路**：保留"实时转写开关"，但修复检查和启动逻辑

**优点**：
- ✅ 保留用户控制能力
- ✅ 更清晰的交互

**缺点**：
- ❌ 问题可能在于配置本身，需要更多调试
- ❌ 可能需要多次迭代

**实施步骤**：
1. 在 `startRecording()` 方法开始时，**强制重新检查**配置
2. 如果配置存在，设置 `isRealtimeAvailable = true`
3. 如果 `isRealtimeEnabled = true`，启动实时转写
4. 添加更详细的错误提示

---

### 方案 C：完全重写 - 使用文件转写代替实时转写（保底）

**思路**：既然文件转写已经工作，就直接使用文件转写

**优点**：
- ✅ 100% 可用，不依赖 WebSocket
- ✅ 延迟不是问题（录音结束后才转写）
- ✅ 开发和维护成本低

**缺点**：
- ❌ 不是真正的"实时"转写
- ❌ 需要录音结束后才能看到结果
- ❌ 录音时间长时，等待时间久

**实施步骤**：
1. 移除所有实时转写相关代码
2. 简化录音流程，录音结束后直接转写
3. 修改 UI，移除"实时转写开关"

---

### 方案 D：渐进式方案 - 方案 A + 方案 B 结合

**思路**：先用方案 A 快速验证，再逐步完善

**实施步骤**：
1. **第一阶段**：实施方案 A（默认开启）
   - 修改 `startRecording()` 自动检查并启动
   - 测试实时转写是否工作
   
2. **第二阶段**：如果方案 A 工作
   - 添加"实时转写开关"UI
   - 让用户可以手动关闭

3. **第三阶段**：如果方案 A 不工作
   - 检查配置文件加载
   - 添加更多调试信息
   - 可能需要检查 WebSocket 连接

---

## 🤔 推荐方案

### **推荐：方案 D（渐进式方案）**

理由：
1. **快速验证**：先用最简单的方案 A 验证功能是否可用
2. **风险可控**：每阶段都能测试，不会一下子改太多
3. **有保底**：方案 C 作为最终保底

---

## 📋 实施计划

### 第一步：实施方案 A（10分钟）

```dart
// 在 startRecording() 方法开始时
Future<void> startRecording() async {
  try {
    // 1. 检查麦克风权限
    final hasPermission = await _recordingService.hasPermission();
    if (!hasPermission) {
      state = state.copyWith(error: '需要麦克风权限');
      return;
    }

    // 2. 【新增】检查实时转写配置并自动启动
    final realtimeAvailable = await checkRealtimeAvailability();
    debugPrint('[Realtime] Auto-check result: $realtimeAvailable');

    // 3. 开始录音
    final path = await _recordingService.startRecording();

    state = state.copyWith(
      isRecording: true,
      isRealtimeEnabled: realtimeAvailable, // 【新增】根据配置自动设置
      // ...
    );

    // 4. 如果配置存在，自动启动实时转写
    if (realtimeAvailable) {
      _startRealtimeTranscription();
    }
  } catch (e) {
    state = state.copyWith(error: '开始录音失败: $e');
  }
}
```

### 第二步：测试验证（5分钟）

1. 安装 APK
2. 配置实时转写 API Key
3. 直接点击录音按钮
4. 查看日志是否有 `[Realtime]` 输出

### 第三步：根据结果调整

- ✅ 如果成功 → 实施方案 D 第二阶段
- ❌ 如果失败 → 检查日志，定位问题

---

## ⚠️ 需要你确认

**问题**：
1. 你的"实时转写"开关是开启还是关闭状态？
2. 你希望保留"实时转写开关"UI 吗？
3. 还是说录音结束后直接转写（方案 C）也可以接受？

**请回复**：
- **A** → 实施方案 D（渐进式，先测试再说）
- **B** → 实施方案 A（简化流程）
- **C** → 实施方案 C（文件转写保底）
- 或者告诉我你的想法

---

*文档创建时间：2026-05-17 02:15*
