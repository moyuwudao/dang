---
alwaysApply: true
description: 规则编写指导 - 如何正确编写和维护规则文档
---

# RULES_GUIDE.md - 规则编写指导

## 核心理念

**规则是约束，也是保护。**
好的规则应该：
- 清晰明确，不产生歧义
- 可执行，能落地验证
- 有边界，知道什么该做、什么不该做

---

## 规则文件标准格式

### 1. 文件头（必须）

每个规则文件必须以 YAML Front Matter 开头：

```markdown
---
alwaysApply: true | false
description: 简短描述，说明规则用途和触发场景
---
```

**alwaysApply 设置原则**：

| 设置 | 适用场景 | 示例 |
|-----|---------|------|
| `alwaysApply: true` | 核心规则，每次对话都需要了解 | SOUL.md, USER.md, INTERACTION.md, RED_LINES.md |
| `alwaysApply: false` | 按需加载，特定场景才需要 | BUILD.md, API_DESIGN.md, QWEN_ASR_API.md |

**description 要求**：
- 简短明了，不超过 50 字
- 说明规则用途和触发场景
- 示例：`description: 交互基础规则 - 何时问问题、何时行动、如何确认`

### 2. 文件命名规范

| 类型 | 命名格式 | 示例 |
|-----|---------|------|
| 核心规则 | 大写驼峰 | `SOUL.md`, `USER.md`, `RED_LINES.md` |
| 功能规则 | 大写下划线 | `API_DESIGN.md`, `BUILD_TROUBLESHOOTING.md` |
| 专项规则 | 项目名-功能 | `dang-构建apk规则.md` |
| API 规范 | API名_功能_API | `QWEN_ASR_API.md`, `QWEN_REALTIME_ASR_API.md` |
| 模板文件 | 大写下划线 | `API_TEMPLATE.md` |

### 3. 文件内容结构

```markdown
# 标题（与文件名对应）

## 概述
简要说明规则目的和适用范围

---

## 核心内容

### 分类一
具体内容...

### 分类二
具体内容...

---

## 使用指南
如何应用此规则

---

## 更新记录
| 日期 | 更新内容 | 更新人 |
|-----|---------|-------|
| YYYY-MM-DD | 说明 | 姓名 |
```

---

## 规则编写 checklist

### 创建新规则时

- [ ] 确定规则类型（核心/功能/专项/API）
- [ ] 设置正确的 `alwaysApply` 属性
- [ ] 编写清晰的 `description`
- [ ] 遵循文件命名规范
- [ ] 包含完整的文件头
- [ ] 内容结构清晰，分节明确
- [ ] 添加更新记录
- [ ] **在 INDEX.md 中注册**
- [ ] 检查是否与现有规则冲突

### 更新现有规则时

- [ ] 查看 INDEX.md 确认规则位置
- [ ] 遵循原有格式和风格
- [ ] 更新更新记录
- [ ] 检查是否影响其他规则

---

## 🚨 强制检查流程（必须执行）

### 创建/修改规则时的强制步骤

**步骤 1：创建文件后立即检查文件头**
```
□ 文件包含 --- 开头的 YAML Front Matter
□ 设置了 alwaysApply: true 或 false
□ description 不为空且不超过50字
```

**步骤 2：命名检查**
```
□ 核心规则：大写驼峰（SOUL.md）
□ 功能规则：大写下划线（API_DESIGN.md）
□ 专项规则：项目名-功能（dang-构建apk规则.md）
□ API规范：API名_功能_API（QWEN_ASR_API.md）
```

**步骤 3：内容结构检查**
```
□ 包含 # 标题
□ 包含 ## 概述
□ 包含 ## 核心内容
□ 包含 ## 更新记录
```

**步骤 4：INDEX.md 注册（最关键！）**
```
□ 在 INDEX.md 对应分类中添加规则
□ 标注 [alwaysApply: true/false]
□ 添加 ✅ 标记
□ 更新规则总数
```

**步骤 5：使用 Rule Validator 验证**
```
运行：/validate-rule <文件名>
确认：✅ 验证通过
```

### 未执行强制检查的后果

| 遗漏项 | 后果 |
|-------|------|
| 缺少文件头 | 规则无法被系统识别，白写 |
| 未注册 INDEX.md | 规则无法被发现，其他任务不知道存在 |
| description 为空 | 无法了解规则用途，影响加载决策 |
| 未验证 | 可能遗漏其他问题，导致规则无效 |

---

## 🤖 自动化验证（Rule Validator）

### 什么是 Rule Validator

Rule Validator 是一个自动化检查工具，用于验证规则文件是否符合规范。

### 如何使用

**创建规则后，必须运行验证：**
```
/validate-rule <文件名>
```

**示例：**
```
/validate-rule NEW_RULE.md

输出：
✅ 文件头正确
✅ 命名规范
✅ 内容结构完整
❌ 未在 INDEX.md 注册

建议：在 INDEX.md 的 dang 项目特定规则中添加：
├── NEW_RULE.md ✅ 规则说明 [alwaysApply: false]
```

### 验证项目

| 检查项 | 说明 | 自动修复 |
|-------|------|---------|
| 文件头 | YAML Front Matter 格式 | ❌ |
| alwaysApply | true/false 设置 | ❌ |
| description | 非空且不超过50字 | ❌ |
| 命名规范 | 符合命名规则 | ❌ |
| 内容结构 | 标题、概述、内容、更新记录 | ❌ |
| INDEX注册 | 在 INDEX.md 中注册 | ✅ 可自动添加 |
| 更新日志 | INDEX.md 中有更新记录 | ✅ 可自动添加 |

### 自动修复功能

对于以下问题，Rule Validator 可以自动修复：
- 未在 INDEX.md 注册 → 自动添加到对应分类
- 未更新日志 → 自动添加更新记录
- 规则总数不匹配 → 自动更新计数

---

## 常见错误

### ❌ 错误示例 1：缺少文件头

```markdown
# 我的规则

内容...
```

**问题**：没有 `alwaysApply` 和 `description`，系统无法正确加载

### ✅ 正确示例

```markdown
---
alwaysApply: false
description: 说明规则用途和触发场景
---

# 我的规则

内容...
```

### ❌ 错误示例 2：description 为空

```markdown
---
alwaysApply: false
description: 
---
```

**问题**：description 为空，无法了解规则用途

### ✅ 正确示例

```markdown
---
alwaysApply: false
description: 构建异常案例集锦 - 收集所有构建问题及解决方案
---
```

### ❌ 错误示例 3：未在 INDEX.md 注册

**问题**：新规则创建后，INDEX.md 未更新，导致规则无法被发现

### ✅ 正确做法

创建规则后，立即在 INDEX.md 的对应分类中添加：

```markdown
├── NEW_RULE.md             ✅ 规则说明 [alwaysApply: false]
```

---

## 规则优先级

当规则冲突时，优先级如下：

```
项目特定规则 > 语言特定规则 > 通用规则
```

**示例**：
- 通用规则：`common/coding-style.md` 说"使用自动化格式化"
- Dart 规则：`dart/coding-style.md` 说"使用 `dart format`，80 字符限制"
- 项目规则：无特定覆盖

**结果**：使用 `dart format .`，80 字符限制

---

## 规则引用规范

### 引用其他规则

在规则中引用其他规则，而不是复制内容：

```markdown
详见 [BUILD_TROUBLESHOOTING.md](BUILD_TROUBLESHOOTING.md) 案例集锦
```

### 引用案例

```markdown
参考 CASE-001: [APK 复制后不是最新](BUILD_TROUBLESHOOTING.md#case-001)
```

---

## 规则维护流程

### 新增规则

1. 确定规则类型和命名
2. 编写规则内容（遵循标准格式）
3. 在 INDEX.md 中注册
4. 检查规则冲突
5. 更新更新日志

### 修改规则

1. 查看 INDEX.md 确认规则位置
2. 修改规则内容
3. 更新更新记录
4. 检查影响范围

### 删除规则

1. 确认无其他规则引用
2. 从 INDEX.md 中移除
3. 删除文件
4. 更新更新日志

---

## 规则质量检查

### 自我检查清单

- [ ] 规则是否清晰明确？
- [ ] 规则是否可执行？
- [ ] 规则是否有边界？
- [ ] 规则是否与其他规则冲突？
- [ ] 规则是否已注册到 INDEX.md？
- [ ] 规则是否有更新记录？

### 常见问题

| 问题 | 解决方案 |
|-----|---------|
| 规则过于笼统 | 添加具体示例和边界条件 |
| 规则不可执行 | 添加操作步骤和验证方法 |
| 规则冲突 | 明确优先级或合并规则 |
| 规则未注册 | 立即添加到 INDEX.md |

---

## 示例：完整的规则文件

```markdown
---
alwaysApply: false
description: API 调用规范总纲 - 定义 API 文档索引和设计原则
---

# API 调用规范总纲

## 概述

本文档是 API 调用规范的一级规则，定义了不同 API 服务应参考的文档资源。

---

## 两级规范体系

| 级别 | 作用 | 命名规范 |
|------|------|---------|
| 一级 | API 调用总纲、文档索引 | `API_*.md` |
| 二级 | 具体 API 服务的详细规范 | `<API_NAME>_*.md` |

---

## API 文档索引

### 语音转写（ASR）

| API 服务 | 二级规范文档 | 状态 |
|---------|------------|------|
| 阿里云通义千问 | [QWEN_ASR_API.md](QWEN_ASR_API.md) | ✅ 可用 |

---

## 使用指南

新增 API 规范时：
1. 复制 [API_TEMPLATE.md](API_TEMPLATE.md) 内容
2. 重命名为 `<API_NAME>_<功能>_API.md`
3. 填入实际 API 信息
4. 更新本文档索引

---

## 更新记录

| 日期 | 更新内容 | 更新人 |
|-----|---------|-------|
| 2026-05-12 | 初始版本 | AI |
```

---

## 总结

**编写规则的核心原则**：

1. **格式规范**：文件头、命名、结构
2. **注册管理**：必须在 INDEX.md 中注册
3. **引用优先**：引用其他规则，避免复制
4. **更新记录**：每次修改都要记录
5. **质量检查**：自我检查清单

**记住**：
- 规则是给人看的，不是给机器看的
- 清晰 > 完整 > 完美
- 先完成，再完善

---

*本文档持续更新，遇到新问题请及时补充。*
