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
