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
| **API 测试** | `API_TESTING.md` → `API_DESIGN.md` |
| **API 异常排查** | `API_TROUBLESHOOTING.md` → `API_RED_LINES.md` |
| **构建阻断** | `BUILD_RED_LINES.md` → `BUILD.md` |
| **服务器部署** | `SERVER_DEPLOY.md` → `SERVER_STATUS.md` |
| **规则一致性验证** | `rule-validator` Skill → `INDEX.md` |

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
| API 测试 | `api-tester` | API 本地测试验证 |
| 构建阻断 | `build-guard` | 构建前强制检查 |
| 规则验证 | `rule-validator` | 规则文件自动验证 |

### 推荐 Commands

| Command | 用途 |
|---------|------|
| `/flutter-review` | Flutter 代码审查 |
| `/flutter-test` | Flutter 测试 |
| `/flutter-build` | Flutter 构建 |
| `/code-review` | 通用代码审查 |
| `/plan` | 功能规划 |
| `/tdd-guide` | TDD 流程 |
| `/validate-rule` | 规则文件验证 |

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
| **rule-validator** | `.trae/skills/rule-validator.md` | 规则文件验证 | 创建/修改规则时调用 |

### 技能调用规则

#### 自动触发规则

| 触发条件 | 技能 | 优先级 |
|---------|------|--------|
| 编写 Dart/Flutter 代码 | `dart-flutter-patterns` | 高 |
| 代码审查 | `flutter-dart-code-review` | 高 |
| 新功能开发 | `tdd-workflow` | 高 |
| 处理敏感数据/认证 | `security-review` | 高 |
| 创建/修改规则 | `rule-validator` | 高 |
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

### dang 项目特定（28 个）

```
.trae/rules/
├── RULES_GUIDE.md          ✅ 规则编写指导 [alwaysApply: true]
├── SOUL.md                  ✅ 我们的灵魂 [alwaysApply: true]
├── USER.md                  ✅ 关于 Walle [alwaysApply: true]
├── INTERACTION.md           ✅ 交互规则 [alwaysApply: true]
├── RED_LINES.md            ✅ 安全红线 [alwaysApply: true]
├── BUILD_RED_LINES.md      ✅ 构建红线 [alwaysApply: true]
├── CONTEXT.md              ✅ 上下文保持 [alwaysApply: true]
├── PROJECT_SENSE.md        ✅ 项目感知 [alwaysApply: false]
├── NAMING_CONVENTIONS.md   ✅ 命名约定 [alwaysApply: false]
├── CODE_STYLE.md           ✅ 代码风格（被 dart/coding-style.md 扩展） [alwaysApply: false]
├── RIVERPOD.md             ✅ 状态管理 [alwaysApply: false]
├── TESTING.md              ✅ 测试规范（被 dart/testing.md 扩展） [alwaysApply: false]
├── LINT.md                 ✅ Lint 检查 [alwaysApply: false]
├── GIT_WORKFLOW.md         ✅ Git 规范（被 common/git-workflow.md 扩展） [alwaysApply: false]
├── DEPENDENCY.md           ✅ 依赖管理 [alwaysApply: false]
├── BUILD.md                ✅ 构建规范 [alwaysApply: false]
├── BUILD_TROUBLESHOOTING.md ✅ 构建异常案例集锦 [alwaysApply: false]
├── DEBUG.md                ✅ 开发调试 [alwaysApply: false]
├── API_DESIGN.md           ✅ API 调用总纲 [alwaysApply: false]
├── QWEN_ASR_API.md         ✅ 通义千问 ASR 规范 [alwaysApply: false]
├── QWEN_REALTIME_ASR_API.md ✅ 通义千问实时转写规范 [alwaysApply: false]
├── API_TESTING.md          ✅ API 测试规范 [alwaysApply: false]
├── REALTIME_TRANSCRIPTION_PLAN.md ✅ 实时转写问题分析 [alwaysApply: false] ← 新增
├── REALTIME_TRANSCRIPTION_ANALYSIS.md ✅ 实时转写架构分析 [alwaysApply: false] ← 新增
├── TINGWU_REALTIME_IMPLEMENTATION.md ✅ 通义听悟实时转写实现方案 [alwaysApply: false] ← 新增
├── TINGWU_OFFLINE_IMPLEMENTATION.md ✅ 通义听悟离线转写方案 [alwaysApply: false] ← 新增
├── API_TROUBLESHOOTING.md   ✅ API 异常案例集锦 [alwaysApply: false] ← 方案C新增
├── API_RED_LINES.md         ✅ API 调用红线 [alwaysApply: false] ← 方案C新增
├── SERVER_DEPLOY.md         ✅ 服务器部署规范 [alwaysApply: false] ← 新增
├── SERVER_STATUS.md         ✅ 服务器部署状态报告 [alwaysApply: false] ← 新增
└── dang-构建apk规则.md      ✅ APK 构建专项规则 [alwaysApply: false]
```

### 模板文件（1 个）

```
.trae/rules/
└── API_TEMPLATE.md          ✅ API 二级规范模板 [alwaysApply: false]
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

### 2026-05-20 - 服务器部署规则新增

**新增**：
- ✅ SERVER_DEPLOY.md - 阿里云ECS服务器部署规范
- ✅ SERVER_STATUS.md - 服务器部署状态报告

**优化**：
- ✅ INDEX.md 注册新文件，更新快速查找指南，更新决策树

**影响**：
- 服务器部署操作有标准化规范
- 服务器状态可追踪

### 2026-05-19 - 方案C：单源真理 + 引用统一

**核心理念变更**：
- ✅ 规则内容从"分散复制"改为"单源真理 + 引用统一"
- ✅ 构建流程统一由 BUILD.md 定义，其他规则只引用不复制

**新增**：
- ✅ API_TROUBLESHOOTING.md - API 异常案例集锦（从 BUILD_TROUBLESHOOTING.md 拆分）
- ✅ API_RED_LINES.md - API 调用红线规则

**优化**：
- ✅ dang-构建apk规则.md：精简为环境配置 + 签名信息，构建命令引用 BUILD.md
- ✅ RED_LINES.md 构建部分：从重复流程改为引用链接
- ✅ INTERACTION.md 构建询问：从嵌入命令改为引用链接
- ✅ BUILD_TROUBLESHOOTING.md：API 案例拆分到 API_TROUBLESHOOTING.md
- ✅ rule-validator Skill：新增交叉引用验证、案例连续性检查、alwaysApply 一致性检查、批量验证
- ✅ INDEX.md：注册新文件，更新快速查找指南，更新决策树

**影响**：
- 消除构建流程在 4 个文件中的重复定义
- API 异常案例独立管理，与构建案例分开
- 规则间引用关系更清晰，维护成本降低
- 规则验证能力增强

### 2026-05-18 - 实时转写规则新增

**新增**：
- ✅ REALTIME_TRANSCRIPTION_PLAN.md - 实时转写问题分析（alwaysApply: false）
- ✅ REALTIME_TRANSCRIPTION_ANALYSIS.md - 实时转写架构分析（alwaysApply: false）

**修复**：
- ✅ 补充文件头（alwaysApply + description）
- ✅ INDEX.md 注册新规则

**影响**：
- 记录实时转写问题现象和解决方案
- 梳理技术架构和优化建议

### 2026-05-18 - API 测试规则新增

**新增**：
- ✅ API_TESTING.md - API 测试规范（alwaysApply: false）

**优化**：
- ✅ INDEX.md 增加 API 测试场景到快速查找指南
- ✅ INDEX.md 增加 API 测试到规则加载决策树
- ✅ 明确"先本地测试，再构建 APK"原则

**影响**：
- 后续 API 集成必须先本地测试
- 避免反复构建 APK 调试 API 问题
- 提高 API 集成效率

### 2026-05-17 - 构建规则强化

**新增**：
- ✅ BUILD_RED_LINES.md - 构建红线规则（alwaysApply: true）

**优化**：
- ✅ INTERACTION.md 增加构建阻断机制
- ✅ 构建时必须调用 BUILD.md 规则（非 alwaysApply，需主动读取）
- ✅ 6 项强制检查清单（同步、构建、复制、命名、验证）

**影响**：
- 防止构建时遗漏 BUILD.md 规则
- 避免构建旧代码、复制缓存文件等问题
- 确保 APK 交付正确版本

### 2026-05-12 - 规则文档管理优化

**新增**：
- ✅ BUILD_TROUBLESHOOTING.md - 构建异常案例集锦
- ✅ API_DESIGN.md - API 调用规范总纲
- ✅ QWEN_ASR_API.md - 通义千问 ASR 规范
- ✅ QWEN_REALTIME_ASR_API.md - 通义千问实时转写规范
- ✅ API_TEMPLATE.md - API 规范模板
- ✅ RULES_GUIDE.md - 规则编写指导

**优化**：
- ✅ 设置 alwaysApply 属性，区分核心规则和专项规则
- ✅ 添加规则使用指南，避免一直调用所有规则
- ✅ 规则加载决策树，按需加载
- ✅ 修复 QWEN_REALTIME_ASR_API.md 缺少 description

**影响**：
- 减少 token 消耗
- 提高规则加载效率
- 避免无关规则干扰
- 规范新规则编写流程

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

## 规则使用指南

### alwaysApply 设置原则

| 设置 | 适用场景 | 当前文件 |
|-----|---------|---------|
| `alwaysApply: true` | 核心规则，每次对话都需要了解 | SOUL.md, USER.md, INTERACTION.md, RED_LINES.md, BUILD_RED_LINES.md, CONTEXT.md |
| `alwaysApply: false` | 按需加载，特定场景才需要 | 其他所有规则 |

### 如何避免一直调用规则

**问题**：规则文件过多，每次对话都加载所有规则会消耗大量 token

**解决方案**：

1. **核心规则常驻**（alwaysApply: true）
   - SOUL.md - 合作基调
   - USER.md - 用户偏好
   - INTERACTION.md - 交互边界
   - RED_LINES.md - 安全红线
   - BUILD_RED_LINES.md - 构建红线
   - CONTEXT.md - 上下文保持

2. **专项规则按需加载**（alwaysApply: false）
   - 构建相关 → 调用 BUILD.md, BUILD_TROUBLESHOOTING.md, dang-构建apk规则.md
   - API 开发 → 调用 API_DESIGN.md, QWEN_ASR_API.md, QWEN_REALTIME_ASR_API.md
   - API 异常排查 → 调用 API_TROUBLESHOOTING.md, API_RED_LINES.md
   - API 测试 → 调用 API_TESTING.md
   - 服务器部署 → 调用 SERVER_DEPLOY.md, SERVER_STATUS.md
   - 代码风格 → 调用 dart/coding-style.md
   - 测试相关 → 调用 dart/testing.md

3. **引用而非复制**
   - 在规则中引用其他规则，而不是复制内容
   - 示例：`详见 [BUILD_TROUBLESHOOTING.md](BUILD_TROUBLESHOOTING.md)`

4. **索引优先**
   - 先查看 INDEX.md 确定需要哪些规则
   - 按场景选择加载，避免全量加载

### 规则加载决策树

```
开始对话
    ↓
是否涉及构建？ → 是 → 加载 BUILD.md + BUILD_TROUBLESHOOTING.md + BUILD_RED_LINES.md
    ↓ 否
是否涉及服务器部署？ → 是 → 加载 SERVER_DEPLOY.md + SERVER_STATUS.md
    ↓ 否
是否涉及 API 测试？ → 是 → 加载 API_TESTING.md + API_DESIGN.md + 具体 API 规范
    ↓ 否
是否涉及 API 异常？ → 是 → 加载 API_TROUBLESHOOTING.md + API_RED_LINES.md
    ↓ 否
是否涉及 API？ → 是 → 加载 API_DESIGN.md + 具体 API 规范
    ↓ 否
是否涉及代码？ → 是 → 加载 dart/coding-style.md
    ↓ 否
是否涉及安全？ → 是 → 加载 RED_LINES.md + dart/security.md
    ↓ 否
使用核心规则即可
```

---

## 如何使用

### 新项目

1. 复制 `common/` 目录（通用规则）
2. 复制语言特定目录（如 `dart/`）
3. 创建项目特定规则（参考 `SOUL.md`, `USER.md` 等）
4. 设置合理的 `alwaysApply` 属性
5. 创建 INDEX.md 管理规则索引

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

*最后更新：2026-05-19*
