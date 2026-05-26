---
alwaysApply: false
description: Git 工作流规范
---

# Git Workflow

## Commit Message Format

```
<type>: <description>

<optional body>

<optional footer>
```

### Types

| Type | When to Use |
|------|-------------|
| `feat` | New feature |
| `fix` | Bug fix |
| `refactor` | Code refactoring (no functional change) |
| `docs` | Documentation only |
| `test` | Adding or updating tests |
| `chore` | Maintenance, build, config |
| `perf` | Performance improvements |
| `ci` | CI/CD configuration |

### Examples

```
feat: add recording transcription feature

- Implement transcription UI
- Add API integration
- Write unit tests

Closes #123
```

```
fix: resolve crash when recording exceeds 5 minutes

- Add duration validation
- Show error message to user
- Update error handling

Fixes #456
```

## Branch Naming

```
<type>/<description>
```

Examples:
- `feat/recording-transcription`
- `fix/login-crash`
- `refactor/state-management`
- `docs/api-documentation`

## Pull Request Workflow

### Before Creating PR

1. **Self-review your code**
2. **Run all tests** - ensure passing
3. **Run lint/typecheck** - ensure clean
4. **Update documentation** if needed
5. **Test manually** - verify functionality

### PR Description Template

```markdown
## What
[Brief description of changes]

## Why
[Problem this solves]

## How
[Key implementation details]

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] Manual testing performed
- [ ] Test coverage >= 80%

## Checklist
- [ ] Code follows style guidelines
- [ ] No hardcoded secrets
- [ ] Error handling complete
- [ ] Documentation updated
- [ ] Breaking changes documented

## Test Plan
- [ ] Step 1 to verify feature
- [ ] Step 2 to verify edge cases
- [ ] Step 3 to verify error handling
```

### PR Review Process

1. **Author** creates PR with complete description
2. **CI/CD** runs automated checks
3. **Reviewers** review code (see `code-review.md`)
4. **Author** addresses feedback
5. **Maintainer** merges after approval

## Pre-Commit Checklist

Before ANY commit:

- [ ] Code compiles/builds
- [ ] Tests pass
- [ ] Lint is clean
- [ ] Type check is clean
- [ ] No debug code (console.log, print, etc.)
- [ ] No hardcoded secrets
- [ ] Commit message follows format

## See Also

- Development workflow: `development-workflow.md`
- Code review standards: `code-review.md`
- Project-specific Git rules: Check project root

## GitHub MCP 集成

本项目可通过 GitHub MCP 直接在 IDE 内完成 Git 相关操作，无需手动执行命令。

### 可用 MCP 工具速查

| 操作 | MCP 工具 | 说明 |
|------|---------|------|
| 创建分支 | `mcp_GitHub_create_branch` | 从指定分支创建新分支 |
| 创建/更新文件 | `mcp_GitHub_create_or_update_file` | 直接写入单个文件 |
| 批量推送文件 | `mcp_GitHub_push_files` | 一次提交推送多个文件 |
| 查看文件内容 | `mcp_GitHub_get_file_contents` | 读取仓库中任意文件 |
| 查看提交历史 | `mcp_GitHub_list_commits` | 查看分支的提交记录 |
| 创建 Issue | `mcp_GitHub_create_issue` | 创建新 Issue |
| 管理 Issue | `mcp_GitHub_list_issues` / `_update_issue` / `_add_issue_comment` | Issue 全生命周期 |
| 创建 PR | `mcp_GitHub_create_pull_request` | 创建 Pull Request |
| 管理 PR | `mcp_GitHub_list_pull_requests` / `_get_pull_request` / `_merge_pull_request` | PR 审查与合并 |
| PR 审查 | `mcp_GitHub_create_pull_request_review` / `_get_pull_request_reviews` | 代码审查 |
| 代码搜索 | `mcp_GitHub_search_code` | 在仓库中搜索代码 |

### 适用场景

| 场景 | 推荐方式 |
|------|---------|
| 日常开发中的 git 操作 | 本地 `git` 命令（更快，支持 .gitignore） |
| 部署时的分支/PR 管理 | GitHub MCP（无需切换终端，可在 IDE 内完成） |
| 需要验证远程状态 | GitHub MCP（直接读取远程仓库内容） |
| 批量文件操作 | GitHub MCP（`push_files` 一次提交多文件）
