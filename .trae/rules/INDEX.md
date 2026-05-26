---
alwaysApply: true
description: 规则索引 - 所有规则的目录和快速定位
---

# INDEX.md - 规则索引

> **最后更新**: 2026-05-25
> **规则总数**: 29 个（核心 5 + 功能 13 + 代码 6 + API 5）

---

## 一、核心规则（alwaysApply: true）

| 文件 | 用途 | 加载时机 |
|------|------|---------|
| [SOUL.md](SOUL.md) | AI 角色定义 | 每次对话 |
| [USER.md](USER.md) | 用户画像和偏好 | 每次对话 |
| [INTERACTION.md](INTERACTION.md) | 交互与沟通规则 | 每次对话 |
| [RED_LINES.md](RED_LINES.md) | 安全红线 | 每次对话 |
| [HIGH_RISK_OPS.md](HIGH_RISK_OPS.md) | 高风险操作规范 | 每次对话 |

---

## 二、功能规则（alwaysApply: false，按需加载）

### 2.1 构建相关

| 文件 | 用途 | 触发条件 |
|------|------|---------|
| [BUILD.md](BUILD.md) | 构建流程规范（唯一构建规则源） | 编辑 android/、pubspec.yaml 等 |
| [BUILD_TROUBLESHOOTING.md](BUILD_TROUBLESHOOTING.md) | 构建问题排查 | 构建失败时 |
| [dang-构建apk规则.md](dang-构建apk规则.md) | APK 签名配置 | 编辑 android/、build.gradle.kts |

### 2.2 调试与测试

| 文件 | 用途 | 触发条件 |
|------|------|---------|
| [DEBUG.md](DEBUG.md) | 调试规范 | 排查 bug 时 |
| [DEBUG_CASES.md](DEBUG_CASES.md) | 错误案例集锦 | 参考历史问题解决方案 |
| [API_TESTING.md](API_TESTING.md) | API 测试规范 | 编辑 test/、API 相关代码 |
| [API_TROUBLESHOOTING.md](API_TROUBLESHOOTING.md) | API 问题排查 | API 调用失败时 |
| [PLAYWRIGHT_E2E.md](PLAYWRIGHT_E2E.md) | Chrome DevTools MCP E2E 测试 | 服务器端按钮问题、admin/ 测试 |

### 2.3 服务器相关

| 文件 | 用途 | 触发条件 |
|------|------|---------|
| [SERVER_DEPLOY.md](SERVER_DEPLOY.md) | 阿里云 ECS 部署 | 编辑 admin/、server/ |
| [SERVER_DEPLOY_PROCEDURE.md](SERVER_DEPLOY_PROCEDURE.md) | 部署流程 | 编辑 admin/、server/ |
| [SERVER_OPS.md](SERVER_OPS.md) | 服务器运维 | 编辑 admin/、server/ |
| [SERVER_SECURITY.md](SERVER_SECURITY.md) | 服务器安全 | 编辑 admin/、server/ |
| [SERVER_API.md](SERVER_API.md) | 畅记云 API | 编辑 admin/、server/、lib/**/api/ |

### 2.4 其他

| 文件 | 用途 | 触发条件 |
|------|------|---------|
| [PROJECT_SENSE.md](PROJECT_SENSE.md) | 项目感知（技术栈/结构/约定） | 编辑 lib/**/*.dart、pubspec.yaml |
| [CONTEXT.md](CONTEXT.md) | 上下文保持与决策记忆 | 按需 |
| [DEPENDENCY.md](DEPENDENCY.md) | 依赖管理 | 编辑 pubspec.yaml |
| [LINT.md](LINT.md) | Lint 规范 | 编辑 lib/ |
| [NAMING_CONVENTIONS.md](NAMING_CONVENTIONS.md) | 命名规范 | 编辑 lib/ |
| [RULES_GUIDE.md](RULES_GUIDE.md) | 规则编写指导 | 编写/修改规则时 |
| [RULES_AGENTS.md](RULES_AGENTS.md) | Agents 使用指南 | 使用 Agents 时 |

---

## 三、代码规则（alwaysApply: false，按路径加载）

### 3.1 通用规则

| 文件 | 用途 | 适用路径 |
|------|------|---------|
| [common/coding-style.md](common/coding-style.md) | 通用代码风格 | 所有代码 |
| [common/testing.md](common/testing.md) | 通用测试要求 | test/ |
| [common/security.md](common/security.md) | 通用安全指南 | 所有代码 |
| [common/git-workflow.md](common/git-workflow.md) | Git 工作流 | .git/、.gitignore |
| [common/development-workflow.md](common/development-workflow.md) | 开发工作流 | 所有代码 |
| [common/patterns.md](common/patterns.md) | 通用设计模式 | 所有代码 |

### 3.2 Dart/Flutter 规则

| 文件 | 用途 | 适用路径 |
|------|------|---------|
| [dart/coding-style.md](dart/coding-style.md) | Dart 代码风格 | lib/**/*.dart |
| [dart/testing.md](dart/testing.md) | Dart 测试规范 | test/**/*.dart |
| [dart/security.md](dart/security.md) | Dart 安全规范 | lib/**/*.dart |
| [dart/patterns.md](dart/patterns.md) | Dart 设计模式 | lib/**/*.dart |

### 3.3 特定功能规则

| 文件 | 用途 | 适用路径 |
|------|------|---------|
| [RIVERPOD.md](RIVERPOD.md) | Riverpod 状态管理 | lib/**/providers/ |

---

## 四、API 规范（alwaysApply: false，按意图加载）

| 文件 | API | 触发条件 |
|------|-----|---------|
| [API_DESIGN.md](API_DESIGN.md) | API 设计总览 | 设计/修改 API 时 |
| [API_RED_LINES.md](API_RED_LINES.md) | API 红线 | 调用任何 API 时 |
| [API_TEMPLATE.md](API_TEMPLATE.md) | API 规范模板 | 新增 API 规范时 |
| [QWEN_ASR_API.md](QWEN_ASR_API.md) | 通义听悟离线转写 | 使用离线转写功能时 |
| [QWEN_REALTIME_ASR_API.md](QWEN_REALTIME_ASR_API.md) | 通义听悟实时转写 | 使用实时转写功能时 |

---

## 五、规则加载机制

### alwaysApply: true（5个）
每次对话自动加载，包含核心交互规则和安全红线。

### alwaysApply: false + glob 匹配
编辑特定文件时自动加载对应规则：

| glob 模式 | 加载规则 |
|-----------|---------|
| `lib/**/*.dart` | dart/coding-style, dart/security, dart/patterns, RIVERPOD, PROJECT_SENSE |
| `test/**/*.dart` | dart/testing, API_TESTING |
| `android/**` | BUILD, dang-构建apk规则 |
| `admin/**, server/**` | SERVER_* 系列 |
| `.git/**, .gitignore` | common/git-workflow |
| `pubspec.yaml` | DEPENDENCY, BUILD, dang-构建apk规则, PROJECT_SENSE |

### 意图触发（SKILL）
通过用户意图触发，不依赖文件编辑。SKILL 为纯引用模式，触发后指引读取对应的功能规则：
- 构建 APK → build-apk SKILL → [BUILD.md](BUILD.md)
- 构建失败 → build-troubleshoot SKILL → [BUILD_TROUBLESHOOTING.md](BUILD_TROUBLESHOOTING.md)
- 服务器部署 → server-deploy SKILL → [SERVER_DEPLOY.md](SERVER_DEPLOY.md)
- 服务器运维 → server-ops SKILL → [SERVER_OPS.md](SERVER_OPS.md)

### MCP 服务器
通过 MCP 协议提供的外部服务，可直接在 IDE 内调用：

| MCP 服务器 | 工具数 | 用途 |
|-----------|--------|------|
| **Chrome DevTools MCP** | 28 个 | 浏览器操作、截图、性能审计（Lighthouse）、网络监控、JS 调试 |
| **GitHub MCP** | 26 个 | Issue/PR 管理、代码推送、仓库操作、代码搜索 |
| `aliyun-servers` | SSH | 阿里云 ECS 远程连接（mcp-server-ssh），用于服务器部署和运维 |

> **Chrome DevTools MCP 使用规范** → 详见 [PLAYWRIGHT_E2E.md](PLAYWRIGHT_E2E.md)
> **GitHub MCP 使用规范** → 详见 [common/git-workflow.md](common/git-workflow.md)

---

## 六、规则优先级

**项目特定 > 语言特定 > 通用**

当规则冲突时：
1. 项目规则（如 dang-构建apk规则.md）优先级最高
2. 语言规则（如 dart/coding-style.md）次之
3. 通用规则（如 common/coding-style.md）最低

---

## 七、文档目录（非规则）

以下文件已从 rules/ 移出到 docs/：

| 文件 | 内容 |
|------|------|
| [docs/REALTIME_TRANSCRIPTION_ANALYSIS.md](../docs/REALTIME_TRANSCRIPTION_ANALYSIS.md) | 实时转写技术分析 |
| [docs/REALTIME_TRANSCRIPTION_PLAN.md](../docs/REALTIME_TRANSCRIPTION_PLAN.md) | 实时转写问题排查记录 |
| [docs/TINGWU_REALTIME_IMPLEMENTATION.md](../docs/TINGWU_REALTIME_IMPLEMENTATION.md) | 听悟实时转写实现文档 |
| [docs/TINGWU_OFFLINE_IMPLEMENTATION.md](../docs/TINGWU_OFFLINE_IMPLEMENTATION.md) | 听悟离线转写实现文档 |
| [docs/SERVER_STATUS.md](../docs/SERVER_STATUS.md) | 服务器状态记录 |

---

## 八、规则维护

新增/修改/删除规则时：
1. 遵循 [RULES_GUIDE.md](RULES_GUIDE.md)
2. 更新本索引
3. 检查是否与现有规则冲突
4. 更新各规则的"更新记录"部分

---

*本索引是规则的入口，帮助快速定位需要的规则。*

---

## 九、更新记录

| 日期 | 更新内容 |
|-----|---------|
| 2026-05-25 | 重大更新：13个规则文件增加命令超时与自动终止机制。RED_LINES.md（5.1-5.4 禁止无限等待命令+超时要求+自动恢复）、INTERACTION.md（命令超时自动处理+只读操作免确认）、SERVER_OPS/BUILD/DEPENDENCY/DEPLOY/DEPLOY_PROCEDURE/DEBUG/DEBUG_CASES/API_TROUBLESHOOTING/PLAYWRIGHT_E2E/API_TESTING/common/hooks/dart/testing/dart/security/common/security 共15个文件 |
