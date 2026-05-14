---
alwaysApply: false
description: 规则体系总览 - 快速查找指南和规则层次结构
---

# 规则体系总览

## 规则层次结构

```
┌─────────────────────────────────────────────────────────┐
│                   dang 项目特定规则                      │
│  (最高优先级 - 覆盖所有下层规则)                         │
├─────────────────────────────────────────────────────────┤
│  SOUL.md          │ 合作灵魂和基调                      │
│  USER.md          │ 用户 Walle 的信息和偏好              │
│  INTERACTION.md   │ 交互规则（何时问、何时做）           │
│  RED_LINES.md     │ 安全红线（绝对不能做的）             │
│  CONTEXT.md       │ 上下文保持规则                       │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                    Dart/Flutter 规则                     │
│  (中优先级 - 覆盖通用规则)                               │
├─────────────────────────────────────────────────────────┤
│  coding-style.md  │ Dart 代码风格、格式化、Dart 3 特性    │
│  testing.md       │ Dart 测试规范、TDD、覆盖率           │
│  security.md      │ Flutter 安全、密钥管理、网络安全     │
│  patterns.md      │ Dart 架构模式、Repository、Riverpod  │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                      通用规则                            │
│  (基础层 - 适用于所有项目)                               │
├─────────────────────────────────────────────────────────┤
│  coding-style.md  │ 通用代码风格原则                     │
│  testing.md       │ 通用测试要求（80% 覆盖率、AAA 模式）   │
│  security.md      │ 通用安全指南                         │
│  code-review.md   │ 代码审查标准                         │
│  git-workflow.md  │ Git 工作流、Commit 规范              │
│  development-workflow.md │ 开发工作流（Research→Deploy） │
│  hooks.md         │ Hooks 系统配置                       │
│  agents.md        │ Agents 使用指南                      │
│  performance.md   │ 性能优化、模型选择                   │
│  patterns.md      │ 通用设计模式                         │
└─────────────────────────────────────────────────────────┘
```

## 规则优先级

**当规则冲突时：**

```
项目特定规则 > 语言特定规则 > 通用规则
```

### 示例

**场景**: 代码格式化

1. **通用规则** (`common/coding-style.md`): "使用自动化格式化工具"
2. **Dart 规则** (`dart/coding-style.md`): "使用 `dart format`，80 字符行限制"
3. **项目规则** (无特定覆盖)

**结果**: 使用 `dart format .`，80 字符限制

---

## 快速查找指南

### 我要...

| 需求 | 查看规则 |
|-----|---------|
| **写代码** | `dart/coding-style.md` → `common/coding-style.md` |
| **写测试** | `dart/testing.md` → `common/testing.md` |
| **提交代码** | `common/git-workflow.md` |
| **代码审查** | `common/code-review.md` |
| **安全检查** | `dart/security.md` → `common/security.md` → `RED_LINES.md` |
| **架构设计** | `dart/patterns.md` → `common/patterns.md` |
| **使用 Agents** | `common/agents.md` |
| **配置 Hooks** | `common/hooks.md` |
| **性能优化** | `common/performance.md` |
| **开发流程** | `common/development-workflow.md` |

### 安全问题优先级

**安全相关规则优先级最高**：

1. `RED_LINES.md` - 绝对不能做的
2. `dart/security.md` - Flutter 特定安全
3. `common/security.md` - 通用安全

---

## Agents 和 Commands

### 推荐 Agents

| 场景 | Agent | 说明 |
|-----|-------|------|
| 新功能开发 | `tdd-guide` | TDD 流程指导 |
| 代码审查 | `flutter-reviewer` | Flutter 代码审查 |
| 规划功能 | `planner` | 实现计划制定 |
| 构建错误 | `build-error-resolver` | 编译错误修复 |
| 安全检查 | `security-reviewer` | 安全漏洞审查 |

### 推荐 Commands

| Command | 用途 |
|---------|------|
| `/flutter-review` | Flutter 代码审查 |
| `/flutter-test` | Flutter 测试 |
| `/flutter-build` | Flutter 构建 |
| `/code-review` | 通用代码审查 |
| `/plan` | 功能规划 |
| `/tdd-guide` | TDD 流程 |

---

## 推荐技能（Skills）

### 核心技能（必加载）

| 技能名称 | 路径 | 用途 | 触发场景 |
|---------|------|------|---------|
| **dart-flutter-patterns** | `C:\Users\Mayn\.trae-cn\skills\dart-flutter-patterns\` | Dart/Flutter 最佳实践 | 编写 Dart/Flutter 代码时自动调用 |
| **flutter-dart-code-review** | `C:\Users\Mayn\.trae-cn\skills\flutter-dart-code-review\` | 代码审查检查清单 | 代码审查时自动调用 |
| **tdd-workflow** | `C:\Users\Mayn\.trae-cn\skills\tdd-workflow\` | TDD 开发流程 | 新功能开发、Bug修复时自动调用 |
| **security-review** | `C:\Users\Mayn\.trae-cn\skills\security-review\` | 安全检查清单 | 处理认证、敏感数据时自动调用 |

### 辅助技能（按需加载）

| 技能名称 | 路径 | 用途 | 触发场景 |
|---------|------|------|---------|
| **android-clean-architecture** | `C:\Users\Mayn\.trae-cn\skills\android-clean-architecture\` | Android 架构模式 | Android 平台开发时调用 |
| **api-design** | `C:\Users\Mayn\.trae-cn\skills\api-design\` | REST API 设计 | 设计 API 接口时调用 |
| **deployment-patterns** | `C:\Users\Mayn\.trae-cn\skills\deployment-patterns\` | CI/CD 部署模式 | 配置部署流程时调用 |
| **codebase-onboarding** | `C:\Users\Mayn\.trae-cn\skills\codebase-onboarding\` | 项目结构分析 | 新成员入职、项目理解时调用 |
| **architecture-decision-records** | `C:\Users\Mayn\.trae-cn\skills\architecture-decision-records\` | ADR 记录 | 重大架构决策时调用 |

### 技能调用规则

#### 自动触发规则

| 触发条件 | 技能 | 优先级 |
|---------|------|--------|
| 编写 Dart/Flutter 代码 | `dart-flutter-patterns` | 高 |
| 代码审查 | `flutter-dart-code-review` | 高 |
| 新功能开发 | `tdd-workflow` | 高 |
| 处理敏感数据/认证 | `security-review` | 高 |
| Android 平台开发 | `android-clean-architecture` | 中 |
| API 接口设计 | `api-design` | 中 |
| 部署配置 | `deployment-patterns` | 中 |

#### 手动调用方式

```
/skill dart-flutter-patterns    # 查看 Dart/Flutter 模式
/skill flutter-dart-code-review # 查看代码审查清单
/skill tdd-workflow             # 查看 TDD 流程
/skill security-review          # 查看安全检查清单
```

---

---

## 规则文件清单

### dang 项目特定（15 个）

```
.trae/rules/
├── SOUL.md                  ✅ 我们的灵魂
├── USER.md                  ✅ 关于 Walle
├── INTERACTION.md           ✅ 交互规则
├── RED_LINES.md            ✅ 安全红线
├── CONTEXT.md              ✅ 上下文保持
├── PROJECT_SENSE.md        ✅ 项目感知
├── NAMING_CONVENTIONS.md   ✅ 命名约定
├── CODE_STYLE.md           ✅ 代码风格（被 dart/coding-style.md 扩展）
├── RIVERPOD.md             ✅ 状态管理
├── TESTING.md              ✅ 测试规范（被 dart/testing.md 扩展）
├── LINT.md                 ✅ Lint 检查
├── GIT_WORKFLOW.md         ✅ Git 规范（被 common/git-workflow.md 扩展）
├── DEPENDENCY.md           ✅ 依赖管理
├── BUILD.md                ✅ 构建规范
└── DEBUG.md                ✅ 开发调试
```

### Dart/Flutter特定（5 个）

```
.trae/rules/dart/
├── README.md               ✅ 目录说明
├── coding-style.md         ✅ Dart 代码风格
├── testing.md              ✅ Dart 测试规范
├── security.md             ✅ Dart 安全规范
└── patterns.md             ✅ Dart 架构模式
```

### 通用规则（10 个）

```
.trae/rules/common/
├── README.md               ✅ 目录说明
├── coding-style.md         ✅ 通用代码风格
├── testing.md              ✅ 通用测试要求
├── security.md             ✅ 通用安全指南
├── code-review.md          ✅ 代码审查标准
├── git-workflow.md         ✅ Git 工作流
├── development-workflow.md ✅ 开发工作流
├── hooks.md                ✅ Hooks 系统
├── agents.md               ✅ Agents 指南
├── performance.md          ✅ 性能优化
└── patterns.md             ✅ 通用模式
```

---

## 更新日志

### 2026-05-11 - 规则体系重构

**新增**：
- ✅ common/ 通用规则层（10 个文件）
- ✅ dart/ Dart 特定规则层（5 个文件）
- ✅ 规则层次结构文档

**优化**：
- ✅ RED_LINES.md 添加 Flutter 特定安全规范
- ✅ 明确规则优先级关系

**影响**：
- 规则更系统化、可扩展
- 通用规则可复用到其他项目
- Dart 规则更贴合 Flutter 开发

---

## 如何使用

### 新项目

1. 复制 `common/` 目录（通用规则）
2. 复制语言特定目录（如 `dart/`）
3. 创建项目特定规则（参考 `SOUL.md`, `USER.md` 等）

### 现有项目

1. 查看 `INDEX.md` 了解规则体系
2. 根据需要逐步采用规则
3. 优先采用高优先级规则（安全、测试、代码风格）

### 规则冲突处理

1. 检查规则优先级
2. 项目特定规则优先
3. 如无明确优先级，采用更具体的规则

---

## 维护

- **通用规则** - 定期同步 `.trae-cn/rules/common/`
- **Dart 规则** - 定期同步 `.trae-cn/rules/dart/`
- **项目规则** - 根据项目进展更新

---

*最后更新：2026-05-11*
