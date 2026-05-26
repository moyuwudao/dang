---
alwaysApply: false
description: Hooks 系统配置
---

# Hooks System

## Hook Types

Hooks automate repetitive tasks and enforce quality gates at specific points in the workflow.

### PreToolUse Hooks

Execute **before** a tool runs:

- **Validation** - Check parameters, permissions
- **Modification** - Adjust parameters
- **Confirmation** - Require explicit approval for sensitive operations

**Example:**
```yaml
PreToolUse:
  - name: security-check
    on: [Write, Edit, Bash]
    check: no-hardcoded-secrets
```

### PostToolUse Hooks

Execute **after** a tool runs:

- **Auto-format** - Apply code formatting
- **Auto-check** - Run lint/typecheck
- **Auto-commit** - Stage changes

**Example:**
```yaml
PostToolUse:
  - name: dart-format
    on: [Write, Edit]
    run: timeout 60 dart format
  - name: flutter-analyze
    on: [Write, Edit]
    run: timeout 120 flutter analyze
```

### Stop Hooks

Execute when session **ends**:

- **Final verification** - Ensure code is in good state
- **Cleanup** - Remove temporary files
- **Documentation** - Update session log

**Example:**
```yaml
Stop:
  - name: final-check
    run: [timeout 600 flutter test, timeout 120 flutter analyze]
  - name: session-log
    save: session-summary.md
```

## Auto-Accept Permissions

Use with **caution**:

- ✅ Enable for trusted, well-defined plans
- ⚠️ Disable for exploratory work
- ❌ Never use `dangerously-skip-permissions` flag
- ✅ Configure `allowedTools` in settings instead

## TodoWrite Best Practices

Use TodoWrite tool to:

- Track progress on multi-step tasks
- Verify understanding of instructions
- Enable real-time steering
- Show granular implementation steps

**Good TodoWrite:**
```markdown
- [x] Understand requirements
- [x] Analyze existing code
- [ ] Write failing test
- [ ] Implement feature
- [ ] Write passing test
- [ ] Refactor
- [ ] Verify coverage
```

**TodoWrite reveals:**

- Out of order steps
- Missing items
- Extra unnecessary items
- Wrong granularity
- Misinterpreted requirements

## Recommended Hooks for Flutter Projects

```yaml
# .trae/hooks.yaml
PostToolUse:
  - name: dart-format
    on: [Write, Edit]
    command: dart format
  - name: flutter-analyze
    on: [Write, Edit]
    command: flutter analyze
  - name: flutter-test
    on: [Write, Edit]
    command: flutter test --coverage

Stop:
  - name: final-verification
    command: [flutter test, flutter analyze]
```

## Hook Configuration

Create `.trae/hooks.yaml` in project root:

```yaml
version: 1
hooks:
  PreToolUse: [...]
  PostToolUse: [...]
  Stop: [...]
```

## See Also

- Development workflow: `development-workflow.md`
- Code style: `coding-style.md`
- Testing: `testing.md`
