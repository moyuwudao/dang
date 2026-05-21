---
alwaysApply: false
description: 规则体系辅助资源 - Agents、Commands、Skills 配置
---

# RULES_AGENTS.md - 规则体系辅助资源

> **规则总览** → 详见 [INDEX.md](INDEX.md)

---

## 一、推荐 Agents

| 场景 | Agent | 说明 |
|-----|-------|------|
| 新功能开发 | `tdd-guide` | TDD 流程指导 |
| 代码审查 | `flutter-reviewer` | Flutter 代码审查 |
| 规划功能 | `planner` | 实现计划制定 |
| 构建错误 | `build-error-resolver` | 编译错误修复 |
| 安全检查 | `security-reviewer` | 安全漏洞审查 |
| API 测试 | `api-tester` | API 本地测试验证 |
| 构建阻断 | `build-guard` | 构建前强制检查 |
| 规则验证 | `rule-validator` | 规则文件自动验证 |

---

## 二、推荐 Commands

| Command | 用途 |
|---------|------|
| `/flutter-review` | Flutter 代码审查 |
| `/flutter-test` | Flutter 测试 |
| `/flutter-build` | Flutter 构建 |
| `/code-review` | 通用代码审查 |
| `/plan` | 功能规划 |
| `/tdd-guide` | TDD 流程 |
| `/validate-rule` | 规则文件验证 |

---

## 三、推荐 Skills

### 核心技能（必加载）

| 技能名称 | 用途 | 触发场景 |
|---------|------|---------|
| **dart-flutter-patterns** | Dart/Flutter 最佳实践 | 编写 Dart/Flutter 代码时 |
| **flutter-dart-code-review** | 代码审查检查清单 | 代码审查时 |
| **tdd-workflow** | TDD 开发流程 | 新功能开发、Bug修复时 |
| **security-review** | 安全检查清单 | 处理认证、敏感数据时 |

### 辅助技能（按需加载）

| 技能名称 | 用途 | 触发场景 |
|---------|------|---------|
| **android-clean-architecture** | Android 架构模式 | Android 平台开发时 |
| **api-design** | REST API 设计 | 设计 API 接口时 |
| **deployment-patterns** | CI/CD 部署模式 | 配置部署流程时 |
| **codebase-onboarding** | 项目结构分析 | 新成员入职、项目理解时 |
| **architecture-decision-records** | ADR 记录 | 重大架构决策时 |
| **rule-validator** | 规则文件验证 | 创建/修改规则时 |

### 自动触发规则

| 触发条件 | 技能 | 优先级 |
|---------|------|--------|
| 编写 Dart/Flutter 代码 | `dart-flutter-patterns` | 高 |
| 代码审查 | `flutter-dart-code-review` | 高 |
| 新功能开发 | `tdd-workflow` | 高 |
| 处理敏感数据/认证 | `security-review` | 高 |
| 创建/修改规则 | `rule-validator` | 高 |
| Android 平台开发 | `android-clean-architecture` | 中 |
| API 接口设计 | `api-design` | 中 |
| 部署配置 | `deployment-patterns` | 中 |

---

## 更新记录

| 日期 | 更新内容 |
|-----|---------|
| 2026-05-21 | 从 INDEX.md 拆分，独立为 RULES_AGENTS.md |
