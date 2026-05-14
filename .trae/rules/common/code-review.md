---
alwaysApply: false
description: 代码审查标准
---

# Code Review Standards

## Purpose

Code review ensures quality, security, and maintainability before code is merged.

## When to Review

**MANDATORY review triggers:**

- After writing or modifying code
- Before any commit to shared branches
- When security-sensitive code is changed (auth, payments, user data)
- When architectural changes are made
- Before merging pull requests

**Pre-Review Requirements:**

Before requesting review, ensure:

- [ ] All automated checks (CI/CD) are passing
- [ ] Merge conflicts are resolved
- [ ] Branch is up to date with target branch
- [ ] `lint` and `typecheck` are clean

## Review Checklist

Before marking code complete:

### Quality

- [ ] Code is readable and well-named
- [ ] Functions are focused (<50 lines)
- [ ] Files are cohesive (<800 lines)
- [ ] No deep nesting (>4 levels)
- [ ] Errors are handled explicitly
- [ ] No hardcoded secrets or credentials
- [ ] No debug statements (console.log, print, etc.)
- [ ] Tests exist for new functionality
- [ ] Test coverage meets 80% minimum

### Security

- [ ] No hardcoded API keys, tokens, passwords
- [ ] User input is validated and sanitized
- [ ] SQL queries use parameterization
- [ ] Authentication/authorization checks present
- [ ] Sensitive data not logged
- [ ] HTTPS enforced for network calls

### Architecture

- [ ] Follows project structure
- [ ] No circular dependencies
- [ ] Layer boundaries respected
- [ ] Dependencies injected, not instantiated
- [ ] Single responsibility principle followed

## Security Review Triggers

**STOP and use security-reviewer agent when:**

- Authentication or authorization code
- User input handling
- Database queries
- File system operations
- External API calls
- Cryptographic operations
- Payment or financial code
- Secrets management

## Review Severity Levels

| Level | Meaning | Action |
|-------|---------|--------|
| **CRITICAL** | Security vulnerability or data loss risk | **BLOCK** - Must fix before merge |
| **HIGH** | Bug or significant quality issue | **WARN** - Should fix before merge |
| **MEDIUM** | Maintainability concern | **INFO** - Consider fixing |
| **LOW** | Style or minor suggestion | **NOTE** - Optional |

## Agent Usage

Use these agents for code review:

| Agent | Purpose |
|-------|---------|
| **code-reviewer** | General code quality, patterns, best practices |
| **security-reviewer** | Security vulnerabilities, OWASP Top 10 |
| **Language-specific** | e.g., `flutter-reviewer`, `typescript-reviewer` |

## Review Workflow

```
1. Run git diff to understand changes
2. Check security checklist first (CRITICAL)
3. Review code quality checklist (HIGH)
4. Run relevant tests
5. Verify coverage >= 80%
6. Report findings grouped by severity
7. Address CRITICAL and HIGH issues before merge
```

## Output Format

When reporting review findings:

```markdown
# Code Review Report

## Summary
- Files changed: X
- Lines added/removed: +Y/-Z
- Issues found: N (M CRITICAL, K HIGH, ...)

## CRITICAL Issues (Must Fix)
1. [Issue description with file:line]
   - Impact: ...
   - Fix: ...

## HIGH Issues (Should Fix)
...

## MEDIUM Issues (Consider Fixing)
...
```

## See Also

- Development workflow: `development-workflow.md`
- Git workflow: `git-workflow.md`
- Security guidelines: `security.md`
