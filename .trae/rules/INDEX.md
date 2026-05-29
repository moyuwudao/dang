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

| MCP 服务器 | 工具数 | 用途 | 使用规范 |
|-----------|--------|------|---------|
| **CodeGraph MCP** | 10 个 | 代码理解、符号搜索、调用链追踪、影响分析、文件结构 | **SOUL.md 最高优先级** |
| **Chrome DevTools MCP** | 28 个 | 浏览器操作、截图、性能审计（Lighthouse）、网络监控、JS 调试 | [PLAYWRIGHT_E2E.md](PLAYWRIGHT_E2E.md) |
| **GitHub MCP** | 26 个 | Issue/PR 管理、代码推送、仓库操作、代码搜索 | [common/git-workflow.md](common/git-workflow.md) |
| **Playwright MCP** | 34 个 | 浏览器自动化、E2E 测试、页面截图、表单填写、HTTP 请求 | [PLAYWRIGHT_E2E.md](PLAYWRIGHT_E2E.md) |
| **aliyun-servers MCP** | 13 个 | SSH 远程执行、SFTP 文件传输、服务器运维 | [SERVER_DEPLOY.md](SERVER_DEPLOY.md) |

> **MCP 优先原则** → 详见 [SOUL.md](SOUL.md) 中的"工具选择决策"章节
> **工具选择决策流程** → 详见 [INTERACTION.md](INTERACTION.md) 中的"工具选择决策"章节

### CodeGraph MCP 工具速查

| 工具 | 用途 | 替代的 TOKEN 浪费操作 |
|------|------|---------------------|
| `codegraph_context` | 一站式代码理解（定义+调用者+被调用者+代码） | Grep × N + Read × N |
| `codegraph_search` | 按名称搜索符号（函数/类/变量/路由） | Grep 全项目模糊搜索 |
| `codegraph_callers` | 找到所有调用者 | 手动 Read + Grep 追踪 |
| `codegraph_callees` | 找到所有被调用者 | 逐文件 Read 分析 |
| `codegraph_trace` | 追踪 A→B 的完整调用路径 | 多轮 Read + Grep 串联 |
| `codegraph_impact` | 分析改动影响范围 | 猜测 + 反复搜索 |
| `codegraph_files` | 带元数据的文件树浏览 | LS + Glob 多次调用 |
| `codegraph_node` | 单个符号详情（含调用关系） | Read 整个文件 |
| `codegraph_explore` | 批量查看相关符号源码 | Read × N 个文件 |
| `codegraph_status` | 索引状态查询 | — |

### Playwright MCP 工具速查

| 工具 | 用途 | 替代方案 |
|------|------|---------|
| `playwright_navigate` | 导航到 URL | curl + 手动分析 |
| `playwright_screenshot` | 页面截图 | 文字描述+猜想 |
| `playwright_click` | 点击元素 | 反复读代码猜测 |
| `playwright_fill` | 填写表单 | 手动 curl POST |
| `playwright_evaluate` | 执行 JS 脚本 | 手动分析 DOM |
| `playwright_console_logs` | 获取控制台日志 | 猜测前端错误 |
| `playwright_get_visible_text` | 获取可见文本 | 截图后手动 OCR |
| `playwright_get_visible_html` | 获取可见 HTML | Read 源码猜测 |
| `playwright_hover` | 悬停元素 | 无法模拟 |
| `playwright_drag` | 拖拽元素 | 无法模拟 |
| `playwright_press_key` | 按键操作 | 无法模拟 |
| `playwright_select` | 下拉选择 | 手动 curl |
| `playwright_assert_response` | 断言响应 | 手动检查 |
| `playwright_expect_response` | 等待响应 | 盲目 sleep |
| `playwright_go_back` / `go_forward` | 前进/后退 | 重新 navigate |
| `playwright_resize` | 调整视口 | 无法模拟响应式 |
| `playwright_save_as_pdf` | 保存为 PDF | 手动打印 |
| `playwright_custom_user_agent` | 自定义 UA | 手动 curl -H |
| `playwright_delete` / `patch` / `put` / `post` / `get` | HTTP 请求方法 | curl 逐个执行 |
| `playwright_iframe_click` / `fill` | iframe 操作 | 几乎不可能手动 |
| `playwright_upload_file` | 上传文件 | 无法手动测试 |
| `start_codegen_session` / `get` / `end` / `clear` | 代码生成会话管理 | — |

### aliyun-servers MCP 工具速查

| 工具 | 用途 | 替代的 TOKEN 浪费 |
|------|------|-----------------|
| `ssh_exec` | 远程执行命令 | `wsl bash -c 'ssh changji "..."'` |
| `ssh_connect` | 建立 SSH 连接 | 每次手动 ssh |
| `ssh_disconnect` | 断开 SSH 连接 | — |
| `ssh_system_info` | 系统信息查询 | 逐个命令查询 |
| `ssh_list_connections` | 列出活跃连接 | 手动 ps 查看 |
| `ssh_keygen` | 生成 SSH 密钥 | 手动 ssh-keygen |
| `ssh_port_forward` | 端口转发 | 手动 ssh -L |
| `sftp_read` | 读取远程文件 | ssh cat + 复制 |
| `sftp_write` | 写入远程文件 | Write+scp 两步 |
| `sftp_ls` | 列出远程目录 | ssh ls |
| `sftp_mkdir` | 创建远程目录 | ssh mkdir |
| `sftp_rm` | 删除远程文件 | ssh rm |
| `sftp_stat` | 查看文件状态 | ssh stat |

### Skill 触发速查（用户意图 → Skill 映射）

| 用户意图/关键词 | 调用 Skill/Agent | 效果 |
|----------------|-----------------|------|
| 构建/打包/APK/编译 | `build-apk` | → [BUILD.md](BUILD.md) |
| 构建失败/打包出错 | `build-troubleshoot` | → [BUILD_TROUBLESHOOTING.md](BUILD_TROUBLESHOOTING.md) |
| 部署/上线/发布 | `server-deploy` | → [SERVER_DEPLOY.md](SERVER_DEPLOY.md) + aliyun-servers MCP |
| 服务器检查/日志/运维 | `server-ops` | → [SERVER_OPS.md](SERVER_OPS.md) + aliyun-servers MCP |
| 小程序/Taro/跨端小程序 | `TRAE-generate-mini-app` | 生成 Taro 多端小程序代码 |
| 设计系统/组件库/UI 一致性 | `design-system` | UI 组件系统设计 |
| 写测试/TDD/测试覆盖率 | `tdd-workflow` | 测试驱动开发流程 |
| API 设计/RESTful/接口 | `api-design` | RESTful API 设计规范 |
| 安全审查/漏洞扫描 | `security-review` | 安全审查清单 |
| 数据库迁移/schema 变更 | `database-migrations` | 数据库迁移最佳实践 |
| UI/前端/React/Vue 组件 | `frontend-architect` Agent | 前端架构与实现 |
| 后端/服务端/API 开发 | `backend-architect` Agent | 后端架构与实现 |
| CI/CD/部署流水线/自动化 | `devops-architect` Agent | DevOps 架构 |
| 性能优化/瓶颈分析 | `performance-expert` Agent | 性能分析优化 |
| AI/ML/LLM 集成 | `ai-integration-engineer` Agent | AI 功能集成 |
| 代码理解/项目入门/架构 | `codebase-onboarding` | 分析代码库，生成结构化入门指南 |
| 知识图谱/架构全景 | `understand` | 生成交互式代码知识图谱 |
| 先搜索现有方案/别造轮子 | `search-first` | 强制先搜索现有工具/库/方案 |
| API成本/模型省钱/Token | `cost-aware-llm-pipeline` | LLM API 成本优化（模型路由+预算） |
| 深度调研/研究报告 | `deep-research` | 多源网络深度调研（带来源引用） |
| 需求分析/PRD/功能规划 | `product-capability` | 需求→可实施方案转化 |
| 架构决策/技术选型/ADR | `architecture-decision-records` | 自动记录架构决策及理由 |
| 数据库查询/慢查询/索引 | `postgres-patterns` | PostgreSQL 查询优化与索引设计 |
| 竞品分析/市场调研 | `market-research` | 竞品对比与市场分析 |
| 浏览器测试/E2E/按钮问题 | Chrome DevTools MCP | → [PLAYWRIGHT_E2E.md](PLAYWRIGHT_E2E.md) |
| Git 操作/PR/Issue | GitHub MCP | → [common/git-workflow.md](common/git-workflow.md) |

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
| 2026-05-28 | 补充 Playwright MCP（34工具速查）、aliyun-servers MCP（13工具速查）、更新 MCP 服务器表为 5 个 |
| 2026-05-28 | Skill 触发速查新增 P0+P1 共 9 条：codebase-onboarding/understand/search-first/cost-aware/deep-research/product-capability/ADR/postgres-patterns/market-research |
| 2026-05-28 | 新增 CodeGraph MCP（10个工具+速查表）、完整 Skill 触发速查表（18条映射）、MCP 优先原则引用 |
| 2026-05-25 | 重大更新：13个规则文件增加命令超时与自动终止机制。RED_LINES.md（5.1-5.4 禁止无限等待命令+超时要求+自动恢复）、INTERACTION.md（命令超时自动处理+只读操作免确认）、SERVER_OPS/BUILD/DEPENDENCY/DEPLOY/DEPLOY_PROCEDURE/DEBUG/DEBUG_CASES/API_TROUBLESHOOTING/PLAYWRIGHT_E2E/API_TESTING/common/hooks/dart/testing/dart/security/common/security 共15个文件 |
