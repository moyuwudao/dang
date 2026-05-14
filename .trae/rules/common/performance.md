---
alwaysApply: false
description: 性能优化和模型选择
---

# Performance Optimization

## Model Selection Strategy

Choose the right model for the task:

### Haiku (90% of Sonnet capability, 3x cost savings)

**Use for:**
- Lightweight agents with frequent invocation
- Pair programming and code generation
- Worker agents in multi-agent systems
- Simple Q&A, documentation lookup

### Sonnet (Best coding model)

**Use for:**
- Main development work
- Orchestrating multi-agent workflows
- Complex coding tasks
- Code review and refactoring

### Opus (Deepest reasoning)

**Use for:**
- Complex architectural decisions
- Maximum reasoning requirements
- Research and analysis tasks
- Strategic planning

## Context Window Management

**Avoid last 20% of context window for:**

- Large-scale refactoring
- Feature implementation spanning multiple files
- Debugging complex interactions

**Lower context sensitivity tasks (safe):**

- Single-file edits
- Independent utility creation
- Documentation updates
- Simple bug fixes

## Extended Thinking

Extended thinking is enabled by default, reserving up to 31,999 tokens for internal reasoning.

### Control Extended Thinking

- **Toggle**: Option+T (macOS) / Alt+T (Windows/Linux)
- **Config**: Set `alwaysThinkingEnabled` in `~/.claude/settings.json`
- **Budget cap**: `export MAX_THINKING_TOKENS=10000`
- **Verbose mode**: Ctrl+O to see thinking output

### When to Enable Extended Thinking

**Enable for:**
- Complex architectural decisions
- Multi-file refactoring
- Debugging difficult issues
- Strategic planning

**Disable for:**
- Simple edits
- Documentation updates
- Quick Q&A
- Routine tasks

## Plan Mode

For complex tasks requiring deep reasoning:

1. Ensure extended thinking is enabled (on by default)
2. Enable **Plan Mode** for structured approach
3. Use multiple critique rounds for thorough analysis
4. Use split role sub-agents for diverse perspectives

## Build Troubleshooting

**If build fails:**

1. Use **build-error-resolver** agent
2. Analyze error messages
3. Fix incrementally
4. Verify after each fix

## Performance Anti-Patterns

### Code-Level

- Expensive work in render/build methods
- Unnecessary re-renders
- Missing memoization
- Over-fetching data
- Synchronous operations on main thread

### Agent-Level

- Using Opus for simple tasks (overkill)
- Not providing enough context (under-specified)
- Running agents sequentially when parallel is possible
- Not using plan mode for complex tasks

## Optimization Checklist

- [ ] Right model for task complexity
- [ ] Context window managed effectively
- [ ] Extended thinking enabled for complex tasks
- [ ] Plan mode used for architectural decisions
- [ ] Parallel agents when possible
- [ ] Clear, specific instructions provided
- [ ] Results verified before merging

## See Also

- Development workflow: `development-workflow.md`
- Agents guide: `agents.md`
- Hooks system: `hooks.md`
