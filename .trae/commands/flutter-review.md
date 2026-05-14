# Flutter 代码审查

## 用途

对 Flutter/Dart 代码进行全面审查，检查代码质量、安全性、性能和最佳实践。

## 触发方式

```bash
/flutter-review [文件路径或 PR 链接]
```

## 审查范围

### 自动检查
- [ ] `flutter analyze` 通过
- [ ] `dart format --set-exit-if-changed .` 通过
- [ ] `flutter test` 通过
- [ ] 测试覆盖率 >= 80%

### 手动审查

#### 代码质量
- 遵循 dart/coding-style.md
- 遵循 common/coding-style.md
- 命名符合 NAMING_CONVENTIONS.md
- 函数职责单一
- 代码可读性好

#### 安全性
- 无硬编码密钥（RED_LINES.md）
- 输入验证完整
- 无敏感数据泄露
- 网络安全（HTTPS）

#### 性能
- 无不必要的 rebuild
- 列表使用 const
- 避免在 build 中创建对象
- 图片缓存正确

#### 测试
- 单元测试覆盖率 >= 80%
- 关键逻辑有测试
- 测试遵循 AAA 模式
- 测试独立、可重复

#### Riverpod
- Provider 类型选择正确
- 状态不可变
- 错误处理完整
- 遵循 RIVERPOD.md

## 输出格式

```markdown
## Flutter 代码审查结果

### 自动检查
- ✅ flutter analyze
- ✅ dart format
- ✅ 测试通过
- ⚠️ 覆盖率 75%（目标 80%）

### 代码质量

#### ✅ 做得好的
- 代码结构清晰
- 命名规范
- 错误处理完整

#### 🟡 建议改进
1. [recording_service.dart:45] 函数过长（60 行）
   - 建议：拆分为更小的函数
   - 影响：可读性、可测试性

2. [user_provider.dart:23] 状态可变
   - 建议：使用 copyWith 模式
   - 影响：状态管理可预测性

### 安全性

#### 🔴 必须修复
1. [api_client.dart:12] 硬编码 API 密钥
   - 建议：使用 String.fromEnvironment
   - 风险：密钥泄露

### 性能

#### 🟢 可选优化
1. [recording_list.dart:78] 列表项缺少 const
   - 建议：添加 const 构造函数
   - 影响：轻微性能提升

### 测试

#### 🔴 必须添加
1. [recording_service.dart] 无测试覆盖
   - 建议：添加单元测试
   - 影响：回归风险

## 总体评价
🟡 需要修改后重新审查

### 优先级
1. 🔴 移除硬编码密钥（安全）
2. 🔴 添加测试覆盖（质量）
3. 🟡 重构长函数（可维护性）
4. 🟢 性能优化（可选）
```

## 规则引用

- 代码审查标准：`common/code-review.md`
- Dart 代码风格：`dart/coding-style.md`
- 安全红线：`RED_LINES.md`
- 状态管理：`RIVERPOD.md`
- 测试规范：`dart/testing.md`

## 相关 Agent

- flutter-reviewer - 执行审查的 Agent
- tdd-guide - 指导测试编写
- security-reviewer - 深度安全检查

---

*审查的目的是帮助写出更好的代码，不是挑刺。*
