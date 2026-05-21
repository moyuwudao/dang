---
alwaysApply: false
globs: .gitignore, .git/**
description: Git 工作流规范 - 分支命名、提交规范、合并流程
---

# GIT_WORKFLOW.md - Git 工作流规范

## 核心理念

Git 工作流的目标是：
- **追踪历史**：清楚知道每个改动的目的
- **安全协作**：不会意外丢失代码
- **易于回溯**：有问题能快速定位和回退

---

## 分支命名

### 分支类型

| 类型 | 命名格式 | 示例 |
|-----|---------|------|
| **功能分支** | `feature/xxx` | `feature/recording-animation` |
| **修复分支** | `fix/xxx` | `fix/transcription-crash` |
| **重构分支** | `refactor/xxx` | `refactor/settings-screen` |
| **实验分支** | `experiment/xxx` | `experiment/new-ai-provider` |
| **文档分支** | `docs/xxx` | `docs/readme` |

### 命名规则

- ✅ 用小写和连字符
- ❌ 不用空格、大写、特殊字符
- ❌ 不用中文

```
✅ feature/user-settings-page
❌ Feature/UserSettingsPage
❌ feature/用户设置页面
```

---

## 提交规范（Commit Message）

### 格式

```
<类型>: <简短描述>

[可选正文]

[可选-footer]
```

### 类型

| 类型 | 说明 | 示例 |
|-----|------|------|
| `feat` | 新功能 | `feat: add recording-animation` |
| `fix` | 修复 bug | `fix: transcription crash on long audio` |
| `refactor` | 重构（无功能变化） | `refactor: extract recording service` |
| `docs` | 文档更新 | `docs: update README.md` |
| `test` | 测试相关 | `test: add user repository tests` |
| `chore` | 构建、配置、维护 | `chore: update dependencies` |
| `perf` | 性能优化 | `perf: improve image caching` |
| `ci` | CI/CD配置 | `ci: add coverage reporting` |

### 完整示例

```
feat: add recording transcription feature

- Implement transcription UI with real-time updates
- Add API integration for Whisper transcription
- Write unit tests for transcription service
- Update user guide

Closes #123
```

```
fix: resolve crash when recording exceeds 5 minutes

- Add duration validation in RecordingService
- Show user-friendly error message
- Update error handling in RecordingStateNotifier

Fixes #456
Test Plan:
- [ ] Verify recording stops at 5 minutes
- [ ] Verify error message displays
- [ ] Verify no crash in logs
```

### 提交前检查清单

提交前必须检查：

- [ ] 代码编译/构建通过
- [ ] 测试通过
- [ ] Lint 检查干净
- [ ] 类型检查干净
- [ ] 无调试代码（print、debugPrint 等）
- [ ] 无硬编码密钥
- [ ] 提交信息符合格式
| `docs` | 文档 | `docs: update README` |
| `style` | 格式（不影响功能） | `style: format code` |
| `refactor` | 重构 | `refactor: extract transcription service` |
| `test` | 测试 | `test: add transcription service tests` |
| `chore` | 杂项 | `chore: update dependencies` |

### 示例

```bash
# 简短提交
git commit -m "feat: add dark mode support"

# 详细提交
git commit -m "feat: add recording animation

Add smooth animation when recording starts and stops.
Animation duration: 300ms, ease-in-out curve.

Closes #123"
```

### 规则

- ✅ 第一行不超过 50 字
- ✅ 用祈使句（"add" 而不是 "added"）
- ✅ 不需要句号结尾
- ❌ 不要写 "fixed bugs" 这种模糊描述

---

## 提交工作流

### 典型流程

```bash
# 1. 创建功能分支
git checkout -b feature/recording-animation

# 2. 开发... 提交...
git add .
git commit -m "feat: add recording button animation"

# 3. 保持分支最新（定期拉取主分支）
git fetch origin
git merge origin/main

# 4. 完成开发后，合并到 main
git checkout main
git merge feature/recording-animation

# 5. 删除分支
git branch -d feature/recording-animation
```

### 提交前检查清单

```bash
# 1. 看状态
git status

# 2. 看改了哪些文件
git diff --stat

# 3. 运行 lint
flutter analyze

# 4. 确认后再提交
git add .
git commit -m "feat: ..."
```

---

## 分支操作

### 查看分支

```bash
# 本地分支
git branch

# 所有分支（包括远程）
git branch -a
```

### 切换分支

```bash
git checkout main           # 切换到 main
git checkout -b xxx        # 创建并切换
```

### 合并分支

```bash
# 切到要合并到的分支
git checkout main

# 合并功能分支
git merge feature/xxx
```

### 删除分支

```bash
# 删除本地分支（已合并）
git branch -d feature/xxx

# 强制删除本地分支
git branch -D feature/xxx

# 删除远程分支
git push origin --delete feature/xxx
```

---

## 保护规则

### main 分支

- ❌ 不要直接在 main 上开发
- ❌ 不要强制 push (`git push --force`)
- ✅ 所有的改动通过分支合并

### commit 不要包含

- ❌ 密钥或凭证
- ❌ 编译产物（`build/`）
- ❌ IDE 配置（除非是项目统一的）
- ❌ 大文件（>5MB）

### .gitignore

确保以下被忽略：

```
# 编译产物
build/
.dart_tool/

# IDE
.idea/
.vscode/

# 环境文件
.env
secrets.env

# OS
.DS_Store
Thumbs.db
```

---

## Pull Request 流程

### 创建 PR 前

1. **自审代码**
2. **运行所有测试** - 确保通过
3. **运行 lint/typecheck** - 确保干净
4. **更新文档**（如需要）
5. **手动测试** - 验证功能

### PR 描述模板

```markdown
## 改动内容
[简要描述改动]

## 解决的问题
[描述解决的问题]

## 实现方式
[关键实现细节]

## 测试
- [ ] 已添加/更新单元测试
- [ ] 已添加/更新集成测试
- [ ] 已手动测试
- [ ] 测试覆盖率 >= 80%

## 检查清单
- [ ] 代码符合风格指南
- [ ] 无硬编码密钥
- [ ] 错误处理完整
- [ ] 文档已更新
- [ ] 破坏性变更已记录

## 测试计划
- [ ] 验证功能的步骤 1
- [ ] 验证边界条件的步骤 2
- [ ] 验证错误处理的步骤 3
```

### PR 审查流程

1. **作者** 创建 PR 并附完整描述
2. **CI/CD** 运行自动化检查
3. **审查者** 审查代码（见 `code-review.md`）
4. **作者** 处理反馈
5. **维护者** 批准后合并

### 合并后

- 监控部署
- 验证生产环境
- 关闭相关问题

---

## 另请参阅

- 开发工作流：`common/development-workflow.md`
- 代码审查：`common/code-review.md`
- 测试规范：`dart/testing.md`

---

## 回退操作

### 撤销未提交的修改

```bash
# 撤销所有修改
git checkout -- .

# 撤销某个文件
git checkout -- lib/main.dart
```

### 撤销已提交的内容

```bash
# 撤销最后一次提交（保留修改）
git reset --soft HEAD^

# 撤销最后一次提交（不保留修改）
git reset --hard HEAD^

# 回退到某个版本
git reset --hard abc1234
```

### 恢复删除的分支

```bash
# 找到删除前的 commit
git reflog

# 恢复分支
git checkout -b feature/xxx abc1234
```

---

## 协作注意

### 推送到远程

```bash
# 首次推送分支
git push -u origin feature/xxx

# 后续推送
git push
```

### 拉取最新代码

```bash
# 拉取并合并
git pull

# 或者分步做
git fetch origin
git merge origin/main
```

### 遇到冲突

```bash
# 1. 先看哪些文件冲突
git status

# 2. 打开文件手动解决冲突
# 冲突标记：
# <<<<<<< HEAD
# 你的代码
# =======
# 别人的代码
# >>>>>>> branch

# 3. 解决后标记为已解决
git add <file>

# 4. 继续合并
git commit
```

---

## Git 在这个项目的用法

### 规则

| 规则 | 说明 |
|-----|------|
| **不要直接 commit 到 main** | 所有改动通过分支 |
| **commit 前运行 lint** | `flutter analyze` 通过后再提交 |
| **描述要清楚** | 让别人（和未来的自己）看懂 |
| **不要提交密钥** | API Key 等敏感信息绝对不能提交 |

### 我的权限

根据 RED_LINES.md：
- ❌ 不能强制 push
- ❌ 不能删除远程分支
- ❌ 不能修改 git 历史
- ✅ 可以创建分支
- ✅ 可以 commit（在你的确认下）
- ✅ 可以 merge（在你的确认下）

---

## 总结

| 操作 | 命令 |
|-----|------|
| 创建分支 | `git checkout -b feature/xxx` |
| 查看状态 | `git status` |
| 提交 | `git add . && git commit -m "feat: ..."` |
| 拉取 | `git pull` |
| 合并 | `git merge feature/xxx` |
| 删除分支 | `git branch -d feature/xxx` |
| 撤销修改 | `git checkout -- .` |

---

*良好的 Git 习惯让项目历史清晰可追溯，有问题时能快速定位。*
