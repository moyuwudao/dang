---
alwaysApply: false
description: 通用规则目录说明
---

# Rules

## Structure

Rules are organized into a **common** layer plus **language-specific** directories:

```
rules/
├── common/          # Language-agnostic principles (always install)
│   ├── coding-style.md
│   ├── git-workflow.md
│   ├── testing.md
│   ├── performance.md
│   ├── patterns.md
│   ├── hooks.md
│   ├── agents.md
│   ├── code-review.md
│   ├── development-workflow.md
│   └── security.md
├── dart/            # Dart/Flutter specific
│   ├── coding-style.md
│   ├── testing.md
│   ├── security.md
│   └── patterns.md
└── [project-specific]/  # dang 项目特定规则
    ├── SOUL.md
    ├── USER.md
    ├── INTERACTION.md
    └── RED_LINES.md
```

- **common/** contains universal principles applicable to all projects.
- **dart/** extends common rules with Dart/Flutter-specific patterns, tools, and code examples.
- **project-specific/** contains dang project's unique collaboration rules.

## Installation

### Manual Installation

```bash
# Install common rules (required for all projects)
cp -r rules/common ~/.trae-cn/rules/common

# Install Dart/Flutter specific rules
cp -r rules/dart ~/.trae-cn/rules/dart

# Install project-specific rules
cp -r rules/[project-specific] ~/.trae-cn/rules/dang
```

## Rules vs Skills vs Agents

- **Rules** define standards, conventions, and checklists (e.g., "80% test coverage", "no hardcoded secrets").
- **Skills** provide deep, actionable reference material for specific tasks.
- **Agents** are autonomous specialists for specific scenarios (code review, TDD, build errors).

Language-specific rule files reference relevant skills and agents where appropriate.

## Rule Priority

When project-specific rules, language-specific rules, and common rules conflict:

**project-specific > language-specific > common**

- `rules/common/` defines universal defaults
- `rules/dart/` overrides for Dart/Flutter idioms
- `rules/[project-specific]/` overrides for dang project's unique needs

## Core Philosophy

| Layer | Purpose | Examples |
|-------|---------|----------|
| **common** | Universal principles | Git workflow, testing requirements, security checklist |
| **dart** | Dart/Flutter specifics | dart format, Riverpod patterns, Flutter security |
| **project-specific** | Dang project unique needs | SOUL.md (collaboration style), USER.md (Walle's preferences), RED_LINES.md (safety boundaries) |
