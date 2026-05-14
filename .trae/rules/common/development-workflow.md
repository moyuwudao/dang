---
alwaysApply: false
description: 开发工作流（Research→Build→Test→Deploy）
---

# Development Workflow

The Feature Implementation Workflow describes the complete development pipeline from idea to merged code.

## Feature Implementation Workflow

### 0. Research & Reuse (MANDATORY before implementation)

**Search before writing:**

1. **GitHub code search** - Find existing implementations and patterns
2. **Library docs** - Confirm API behavior and usage
3. **Package registries** - npm, PyPI, crates.io, pub.dev
4. **Search for adaptable implementations** - Port proven solutions

**Principle:** Prefer adopting or porting a proven approach over writing net-new code.

### 1. Plan First

**Use planner agent** to create implementation plan:

- Generate planning docs (PRD, architecture, system design)
- Identify dependencies and risks
- Break down into phases
- Define success criteria

**Output:** Clear implementation plan with ordered steps.

### 2. TDD Approach

**Use tdd-guide agent:**

1. **Write test first** (RED) - Describe expected behavior
2. **Run test** - Verify it FAILS
3. **Write minimal implementation** (GREEN) - Just enough to pass
4. **Run test** - Verify it PASSES
5. **Refactor** (IMPROVE) - Clean up while keeping tests green
6. **Verify coverage** - Ensure 80%+ coverage

### 3. Code Review

**Use code-reviewer agent immediately after writing code:**

- Apply review checklist from `code-review.md`
- Address CRITICAL and HIGH issues
- Fix MEDIUM issues when possible
- Document any intentional deviations

### 4. Commit & Push

**Follow git workflow:**

- Detailed commit messages (see `git-workflow.md`)
- Follow conventional commits format
- Push with complete history
- Create PR with comprehensive description

### 5. Pre-Review Checks

**Before requesting review:**

- [ ] All automated checks (CI/CD) passing
- [ ] Merge conflicts resolved
- [ ] Branch up to date with target
- [ ] Tests passing
- [ ] Coverage >= 80%
- [ ] Lint and typecheck clean

### 6. Address Review Feedback

**Respond to all comments:**

- Fix identified issues
- Discuss disagreements respectfully
- Document decisions
- Re-request review after addressing feedback

### 7. Merge & Deploy

**After approval:**

- Merge to target branch
- Monitor deployment
- Verify in production
- Close associated issues

## Workflow Summary

```
Research → Plan → TDD (Red-Green-Refactor) → Review → Commit → PR → Merge → Deploy
```

## Agent Usage by Phase

| Phase | Recommended Agent | Associated Skills |
|-------|------------------|------------------|
| Research | `exa-search`, `deep-research` | `codebase-onboarding` |
| Plan | `planner` | `architecture-decision-records` |
| TDD | `tdd-guide` | `tdd-workflow`, `dart-flutter-patterns` |
| Code Review | `code-reviewer`, `security-reviewer` | `flutter-dart-code-review`, `security-review` |
| Build Errors | `build-error-resolver` | `dart-flutter-patterns` |
| Testing | `flutter-test`, `test-coverage` | `tdd-workflow` |

## Skills Integration in Workflow

### Phase 0: Research & Reuse

**Required Skills:**
- `codebase-onboarding` - 理解项目结构和约定
- `dart-flutter-patterns` - 参考现有模式

**Activation:** Automatic when exploring codebase

---

### Phase 1: Plan First

**Required Skills:**
- `architecture-decision-records` - 记录架构决策
- `api-design` - 如果涉及 API 设计

**Activation:** When using `planner` agent

---

### Phase 2: TDD Approach

**Required Skills:**
- `tdd-workflow` - TDD 流程指导（强制）
- `dart-flutter-patterns` - Dart/Flutter 编码模式

**Activation:** When using `tdd-guide` agent

**TDD Workflow with Skills:**
```
1. Write failing test → Use `tdd-workflow` patterns
2. Implement code → Use `dart-flutter-patterns` for best practices
3. Refactor → Use `flutter-dart-code-review` checklist
4. Verify coverage → Use `tdd-workflow` guidelines
```

---

### Phase 3: Code Review

**Required Skills:**
- `flutter-dart-code-review` - 代码审查检查清单（强制）
- `security-review` - 安全检查（强制）

**Activation:** When using `code-reviewer` or `security-reviewer` agents

**Review Checklist (from Skills):**

| Skill | Focus Area |
|-------|-----------|
| `flutter-dart-code-review` | Widget 最佳实践、状态管理、性能、无障碍 |
| `security-review` | 密钥管理、输入验证、SQL注入、认证授权 |

---

### Phase 4-7: Commit → PR → Review → Merge

**Required Skills:**
- `deployment-patterns` - CI/CD 部署模式

**Activation:** During deployment configuration

---

## Skills Activation Matrix

### Automatic Activation Rules

```yaml
# 技能自动激活规则
rules:
  - trigger: "编写 Dart/Flutter 代码"
    skills: ["dart-flutter-patterns"]
    priority: high

  - trigger: "新功能开发"
    skills: ["tdd-workflow", "dart-flutter-patterns"]
    priority: high

  - trigger: "Bug 修复"
    skills: ["tdd-workflow"]
    priority: high

  - trigger: "代码审查"
    skills: ["flutter-dart-code-review", "security-review"]
    priority: high

  - trigger: "处理敏感数据/认证"
    skills: ["security-review"]
    priority: critical

  - trigger: "API 设计"
    skills: ["api-design"]
    priority: medium

  - trigger: "部署配置"
    skills: ["deployment-patterns"]
    priority: medium
```

### Manual Activation Commands

```bash
# 手动调用技能
/skill dart-flutter-patterns    # 查看 Dart/Flutter 最佳实践
/skill tdd-workflow             # 查看 TDD 流程
/skill flutter-dart-code-review # 查看代码审查清单
/skill security-review          # 查看安全检查清单
/skill api-design               # 查看 API 设计规范
```

## Quality Gates

| Gate | Criteria | Tool | Required Skills |
|------|----------|------|----------------|
| Pre-commit | Build passes, tests pass | Local | `tdd-workflow` |
| Pre-PR | Coverage >= 80%, lint clean | Local | `tdd-workflow`, `flutter-dart-code-review` |
| Pre-merge | All CI checks pass, review approved | CI/CD | `flutter-dart-code-review`, `security-review` |
| Pre-deploy | E2E tests pass, canary healthy | CI/CD | `deployment-patterns` |

## See Also

- Git workflow: `git-workflow.md`
- Code review: `code-review.md`
- Testing: `testing.md`
- Performance: `performance.md`
- Agents guide: `agents.md`
