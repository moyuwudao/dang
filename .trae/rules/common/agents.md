---
alwaysApply: false
description: Agents 使用指南
---

# Agents Guide

## What are Agents

Agents are autonomous AI specialists with defined roles, tools, and workflows. They can:

- Execute complex tasks independently
- Use specific tools autonomously
- Follow structured workflows
- Report findings in standardized formats

## Agent vs Skill vs Command

| Type | Purpose | Autonomy | Example |
|------|---------|----------|---------|
| **Agent** | Autonomous specialist | High - can make decisions | `flutter-reviewer` reviews code |
| **Skill** | Reference material | Low - provides guidance | `tdd-workflow` shows TDD patterns |
| **Command** | Quick action trigger | Medium - executes specific task | `/flutter-review` invokes agent |

## Core Agents for Flutter Projects

### Code Quality

| Agent | Purpose | When to Use |
|-------|---------|-------------|
| **flutter-reviewer** | Flutter/Dart code review | PR preparation, after writing code |
| **code-reviewer** | General code quality | Any code changes |
| **security-reviewer** | Security vulnerabilities | Auth, payments, user data |
| **performance-optimizer** | Performance issues | Slow rendering, memory leaks |

### Development Workflow

| Agent | Purpose | When to Use |
|-------|---------|-------------|
| **planner** | Implementation planning | Before complex features |
| **tdd-guide** | Test-driven development | New features, bug fixes |
| **build-error-resolver** | Build/type errors | Compilation failures |
| **dart-build-resolver** | Dart-specific issues | pub get, analysis errors |

### Architecture

| Agent | Purpose | When to Use |
|-------|---------|-------------|
| **architect** | System design | New modules, refactoring |
| **code-explorer** | Codebase navigation | Understanding unfamiliar code |
| **refactor-cleaner** | Code cleanup | Technical debt reduction |

## Agent Workflows

### Code Review Workflow

```
1. User: /flutter-review
2. Agent: flutter-reviewer
   - Gathers context (git diff)
   - Reviews code (checklist)
   - Reports findings (severity levels)
3. User: Addresses CRITICAL/HIGH issues
4. Agent: Re-reviews if needed
```

### TDD Workflow

```
1. User: Describe feature
2. Agent: tdd-guide
   - Writes failing test (RED)
   - Guides minimal implementation (GREEN)
   - Refactors (IMPROVE)
   - Verifies coverage (80%+)
3. User: Reviews and approves
```

### Planning Workflow

```
1. User: Describe feature goal
2. Agent: planner
   - Analyzes requirements
   - Reviews architecture
   - Breaks down steps
   - Orders by dependencies
3. User: Approves plan
4. Agent: Executes or hands off
```

## When to Use Agents

### PROACTIVELY Use

- **planner** - Complex features, architectural changes
- **tdd-guide** - New features, bug fixes, refactoring
- **code-reviewer** - After writing any code
- **security-reviewer** - Security-sensitive code
- **build-error-resolver** - Build failures

### On Request

- **flutter-reviewer** - PR preparation
- **performance-optimizer** - Performance issues
- **refactor-cleaner** - Code quality improvements

## Agent Configuration

Agents are defined in `.trae/agents/` directory:

```yaml
# .trae/agents/flutter-reviewer.yaml
name: flutter-reviewer
description: Flutter/Dart code reviewer
tools: [Read, Grep, Glob, Bash]
model: sonnet
```

## Best Practices

### Using Agents Effectively

1. **Be specific** - Clear problem statements
2. **Provide context** - Relevant files, error messages
3. **Review output** - Agents are assistants, not oracles
4. **Iterate** - Refine based on results

### Agent Limitations

- Agents may not understand full project context
- Agents can make mistakes - verify critical changes
- Agents work best with clear, specific instructions
- Agents are not replacements for human judgment

## Recommended Agent Stack for Dang Project

```yaml
# Daily Development
- planner (feature planning)
- tdd-guide (implementation)
- flutter-reviewer (code review)
- build-error-resolver (error fixing)

# Periodic
- security-reviewer (security audit)
- performance-optimizer (optimization)
- refactor-cleaner (cleanup)

# As Needed
- architect (major changes)
- code-explorer (understanding code)
```

---

## Agent-Skill Mapping

### Agent 与技能的对应关系

| Agent | 关联技能 | 技能路径 | 用途说明 |
|-------|---------|---------|---------|
| **flutter-reviewer** | `flutter-dart-code-review` | `C:\Users\Mayn\.trae-cn\skills\flutter-dart-code-review\` | 代码审查时调用，提供检查清单 |
| **tdd-guide** | `tdd-workflow` | `C:\Users\Mayn\.trae-cn\skills\tdd-workflow\` | TDD 流程指导 |
| **security-reviewer** | `security-review` | `C:\Users\Mayn\.trae-cn\skills\security-review\` | 安全漏洞检查 |
| **architect** | `dart-flutter-patterns` | `C:\Users\Mayn\.trae-cn\skills\dart-flutter-patterns\` | 架构设计参考 |
| **code-explorer** | `codebase-onboarding` | `C:\Users\Mayn\.trae-cn\skills\codebase-onboarding\` | 代码库理解 |

### Agent 调用时自动激活的技能

```yaml
# Agent 执行时自动加载相关技能
flutter-reviewer:
  - flutter-dart-code-review
  - dart-flutter-patterns

tdd-guide:
  - tdd-workflow
  - dart-flutter-patterns

security-reviewer:
  - security-review

architect:
  - dart-flutter-patterns
  - android-clean-architecture
  - architecture-decision-records

code-explorer:
  - codebase-onboarding
```

---

## Skill Usage Guidelines

### 核心技能（始终可用）

这些技能在所有开发活动中自动加载：

1. **dart-flutter-patterns** - Dart/Flutter 最佳实践模式库
   - 空安全、不可变状态、异步组合
   - Riverpod 状态管理、GoRouter 导航、Dio 网络

2. **flutter-dart-code-review** - 代码审查检查清单
   - Widget 最佳实践、状态管理模式
   - 性能优化、无障碍支持、安全检查

### 场景触发技能

根据开发场景自动激活：

| 场景 | 自动激活技能 |
|-----|-------------|
| 新功能开发 | `tdd-workflow` |
| Bug 修复 | `tdd-workflow` |
| 代码审查 | `flutter-dart-code-review`, `security-review` |
| 架构设计 | `dart-flutter-patterns`, `architecture-decision-records` |
| API 设计 | `api-design` |
| 部署配置 | `deployment-patterns` |

### 手动调用

```bash
# 查看技能内容
/skill dart-flutter-patterns
/skill tdd-workflow
/skill security-review

# 直接调用关联 Agent
/flutter-review  # 自动使用 flutter-dart-code-review 技能
/tdd-guide       # 自动使用 tdd-workflow 技能
```

## See Also

- Development workflow: `development-workflow.md`
- Commands reference: Check `.trae/commands/`
- Skills reference: Check `.trae-cn/skills/`
