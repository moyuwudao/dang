---
name: "server-ops"
description: "Daily server operations for Alibaba Cloud ECS (101.133.238.249) including health checks, log management, and emergency response. Invoke when user asks to check server status, view logs, restart services, or mentions 服务器运维、日常检查、应急响应."
---

# Server Ops SKILL

## 触发条件

用户提到以下关键词时触发：
- 服务器状态 / 日常检查 / 查看日志
- server status / health check / view logs
- 重启服务 / 应急响应 / 磁盘清理

## 执行方式

**本 SKILL 不包含运维命令。运维时直接读取并执行 [SERVER_OPS.md](../rules/SERVER_OPS.md)。**

SERVER_OPS.md 是唯一运维规则源，包含：
- 服务器信息与连接方式
- 每日/每周/每月检查命令（只读/修改分类）
- 日志管理
- 应急响应流程
- **运维后验证**：使用 Chrome DevTools MCP 截图确认

## MCP 工具集成

| 阶段 | 工具 | 用途 |
|------|------|------|
| 重启/部署后验证 | Chrome DevTools MCP | 打开 admin 面板截图，确认功能正常 |
| 按钮问题排查 | Chrome DevTools MCP | 按 PLAYWRIGHT_E2E.md SOP 逐步排查 |

## 参考文档

- [SERVER_OPS.md](../rules/SERVER_OPS.md) - 完整运维规范（含 MCP 验证）
- [PLAYWRIGHT_E2E.md](../rules/PLAYWRIGHT_E2E.md) - Chrome DevTools MCP 测试 SOP
- [SERVER_DEPLOY.md](../rules/SERVER_DEPLOY.md) - 部署规范
