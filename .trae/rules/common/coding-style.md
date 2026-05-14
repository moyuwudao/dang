---
alwaysApply: false
description: 通用代码风格原则
---

# Common Coding Style

## Purpose

Universal coding style principles applicable across all languages and frameworks.

## Core Principles

### 1. Readability First

- Code is read more often than written
- Favor explicit over implicit
- Favor clear over clever
- Names should reveal intent

### 2. Consistency

- Follow project conventions
- Use established patterns
- Avoid personal style preferences
- Automate formatting where possible

### 3. Simplicity

- Functions should do one thing
- Keep functions under 50 lines
- Keep files under 800 lines
- Avoid deep nesting (>4 levels)

### 4. Immutability

- Prefer `const` and `final` where possible
- Avoid mutable shared state
- Use copy-on-write patterns
- Return new instances instead of modifying

### 5. Error Handling

- Handle errors explicitly
- Don't swallow exceptions
- Provide meaningful error messages
- Fail fast, fail loudly

## Formatting

- Use automated formatters (language-specific)
- Consistent indentation (2 or 4 spaces, language-dependent)
- Line length limits (80-120 chars, language-dependent)
- Trailing commas on multi-line structures (where supported)

## Naming

- Variables/functions: descriptive, intention-revealing
- Classes/types: nouns, domain concepts
- Boolean variables: `is*`, `has*`, `can*` prefixes
- Avoid abbreviations unless universally understood

## Comments

- Code should be self-documenting
- Comments explain **why**, not **what**
- Remove commented-out code before commit
- Use TODO comments with context and owner

## See Also

- Language-specific style: `dart/coding-style.md`
- Project-specific conventions: Check project root rules
