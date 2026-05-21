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
│  BUILD_RED_LINES.md│ 构建红线（构建强制检查）            │
│  CONTEXT.md       │ 上下文保持规则                       │
│  COMMUNICATION.md │ 沟通规范（问题类型、确认机制）       │
│  BUILD_TRIGGER.md │ 构建触发规则（自动/询问构建）        │
│  HIGH_RISK_OPS.md │ 高风险操作规范                       │
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

**当规则冲突时：项目特定规则 > 语言特定规则 > 通用规则**

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
| **API 测试** | `API_TESTING.md` → `API_DESIGN.md` |
| **API 异常排查** | `API_TROUBLESHOOTING.md` → `API_RED_LINES.md` |
| **构建阻断** | `BUILD_RED_LINES.md` → `BUILD_TRIGGER.md` → `BUILD.md` |
| **构建触发** | `BUILD_TRIGGER.md` → `BUILD_RED_LINES.md` |
| **服务器部署** | `SERVER_DEPLOY.md` → `SERVER_DEPLOY_PROCEDURE.md` |
| **服务器安全** | `SERVER_SECURITY.md` |
| **服务器运维** | `SERVER_OPS.md` |
| **服务器API** | `SERVER_API.md` |
| **沟通规范** | `COMMUNICATION.md` |
| **高风险操作** | `HIGH_RISK_OPS.md` |
| **规则辅助资源** | `RULES_AGENTS.md`（Agents/Commands/Skills） |

### 安全问题优先级

1. `RED_LINES.md` - 绝对不能做的
2. `dart/security.md` - Flutter 特定安全
3. `common/security.md` - 通用安全

---

## 规则文件清单

### dang 项目特定（35 个）

```
.trae/rules/
├── RULES_GUIDE.md              ✅ 规则编写指导 [alwaysApply: true]
├── SOUL.md                     ✅ 我们的灵魂 [alwaysApply: true]
├── USER.md                     ✅ 关于 Walle [alwaysApply: true]
├── INTERACTION.md              ✅ 交互规则 [alwaysApply: true]
├── RED_LINES.md                ✅ 安全红线 [alwaysApply: true]
├── BUILD_RED_LINES.md          ✅ 构建红线 [alwaysApply: true]
├── CONTEXT.md                  ✅ 上下文保持 [alwaysApply: true]
├── COMMUNICATION.md            ✅ 沟通规范 [alwaysApply: true] ← 新增
├── BUILD_TRIGGER.md            ✅ 构建触发规则 [alwaysApply: false] ← 新增
├── HIGH_RISK_OPS.md            ✅ 高风险操作规范 [alwaysApply: true] ← 新增
├── PROJECT_SENSE.md            ✅ 项目感知 [alwaysApply: false]
├── NAMING_CONVENTIONS.md       ✅ 命名约定 [alwaysApply: false]
├── CODE_STYLE.md               ✅ 代码风格 [alwaysApply: false]
├── RIVERPOD.md                 ✅ 状态管理 [alwaysApply: false]
├── TESTING.md                  ✅ 测试规范 [alwaysApply: false]
├── LINT.md                     ✅ Lint 检查 [alwaysApply: false]
├── GIT_WORKFLOW.md             ✅ Git 规范 [alwaysApply: false]
├── DEPENDENCY.md               ✅ 依赖管理 [alwaysApply: false]
├── BUILD.md                    ✅ 构建规范 [alwaysApply: false]
├── BUILD_TROUBLESHOOTING.md    ✅ 构建异常案例集锦 [alwaysApply: false]
├── DEBUG.md                    ✅ 开发调试 [alwaysApply: false]
├── API_DESIGN.md               ✅ API 调用总纲 [alwaysApply: false]
├── API_RED_LINES.md            ✅ API 调用红线 [alwaysApply: false]
├── API_TESTING.md              ✅ API 测试规范 [alwaysApply: false]
├── API_TROUBLESHOOTING.md      ✅ API 异常案例集锦 [alwaysApply: false]
├── API_TEMPLATE.md             ✅ API 规范模板 [alwaysApply: false]
├── QWEN_ASR_API.md             ✅ 通义千问 ASR 规范 [alwaysApply: false]
├── QWEN_REALTIME_ASR_API.md    ✅ 通义千问实时转写规范 [alwaysApply: false]
├── SERVER_DEPLOY.md            ✅ 服务器部署规范 [alwaysApply: false]
├── SERVER_DEPLOY_PROCEDURE.md  ✅ 服务器部署流程 [alwaysApply: false] ← 新增
├── SERVER_SECURITY.md          ✅ 服务器安全防护 [alwaysApply: false] ← 新增
├── SERVER_OPS.md               ✅ 服务器运维规范 [alwaysApply: false] ← 新增
├── SERVER_API.md               ✅ 服务器API接口 [alwaysApply: false] ← 新增
├── SERVER_STATUS.md            ✅ 服务器部署状态报告 [alwaysApply: false]
├── RULES_AGENTS.md             ✅ 规则辅助资源 [alwaysApply: false] ← 新增
└── dang-构建apk规则.md          ✅ APK 构建专项规则 [alwaysApply: false]
```

### Dart/Flutter特定（5 个）

```
.trae/rules/dart/
├── coding-style.md         ✅ Dart 代码风格
├── testing.md              ✅ Dart 测试规范
├── security.md             ✅ Dart 安全规范
└── patterns.md             ✅ Dart 架构模式
```

### 通用规则（10 个）

```
.trae/rules/common/
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

## 规则加载决策树

```
开始对话
    ↓
是否涉及构建？ → 是 → BUILD.md + BUILD_TROUBLESHOOTING.md + BUILD_RED_LINES.md + BUILD_TRIGGER.md
    ↓ 否
是否涉及服务器？ → 是 → SERVER_DEPLOY.md + SERVER_DEPLOY_PROCEDURE.md + SERVER_SECURITY.md + SERVER_OPS.md + SERVER_API.md
    ↓ 否
是否涉及 API 测试？ → 是 → API_TESTING.md + API_DESIGN.md + 具体 API 规范
    ↓ 否
是否涉及 API 异常？ → 是 → API_TROUBLESHOOTING.md + API_RED_LINES.md
    ↓ 否
是否涉及 API？ → 是 → API_DESIGN.md + 具体 API 规范
    ↓ 否
是否涉及代码？ → 是 → dart/coding-style.md
    ↓ 否
是否涉及安全？ → 是 → RED_LINES.md + HIGH_RISK_OPS.md + dart/security.md
    ↓ 否
使用核心规则即可
```

---

## alwaysApply 设置原则

| 设置 | 适用场景 | 当前文件 |
|-----|---------|---------|
| `alwaysApply: true` | 核心规则，每次对话都需要 | SOUL.md, USER.md, INTERACTION.md, RED_LINES.md, BUILD_RED_LINES.md, CONTEXT.md, COMMUNICATION.md, HIGH_RISK_OPS.md |
| `alwaysApply: false` | 按需加载，特定场景才需要 | 其他所有规则 |

---

## 更新日志

### 2026-05-21 - 规则体系拆分优化（Claude.md 研究报告驱动）

**拆分优化**：
- ✅ INTERACTION.md (383行→135行) → 拆出 BUILD_TRIGGER.md, COMMUNICATION.md
- ✅ RED_LINES.md (289行→199行) → 拆出 HIGH_RISK_OPS.md
- ✅ SERVER_DEPLOY.md (1200+行→186行) → 拆出 SERVER_DEPLOY_PROCEDURE.md, SERVER_SECURITY.md, SERVER_OPS.md, SERVER_API.md
- ✅ INDEX.md (475行→精简) → 拆出 RULES_AGENTS.md

**新增文件**：
- BUILD_TRIGGER.md - 构建触发规则
- COMMUNICATION.md - 沟通规范
- HIGH_RISK_OPS.md - 高风险操作规范
- SERVER_DEPLOY_PROCEDURE.md - 服务器部署流程
- SERVER_SECURITY.md - 服务器安全防护
- SERVER_OPS.md - 服务器运维规范
- SERVER_API.md - 服务器API接口
- RULES_AGENTS.md - 规则辅助资源

**优化效果**：
- 所有规则文件控制在 200 行以内（符合 Claude.md 最佳实践）
- 消除内容重复，使用引用链接替代内联内容
- 提高规则加载效率，减少 token 消耗

### 2026-05-20 - 服务器部署规则新增

- ✅ SERVER_DEPLOY.md - 阿里云ECS服务器部署规范
- ✅ SERVER_STATUS.md - 服务器部署状态报告

### 2026-05-19 - 方案C：单源真理 + 引用统一

- ✅ 规则内容从"分散复制"改为"单源真理 + 引用统一"
- ✅ 新增 API_TROUBLESHOOTING.md, API_RED_LINES.md

---

*最后更新：2026-05-21*
