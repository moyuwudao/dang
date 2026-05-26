---
name: "server-deploy"
description: "Deploy to Alibaba Cloud ECS server (101.133.238.249) via SSH. Invoke when user asks to deploy, publish to server, ssh to server, or mentions 部署、上线、发布、服务器操作."
---

# Server Deploy SKILL

## 触发条件

用户提到以下关键词时触发：
- 部署 / 上线 / 发布到服务器
- deploy / publish / ssh to server
- 服务器操作 / 更新服务器代码

## 执行方式

**本 SKILL 不包含部署流程。部署时直接读取并执行 [SERVER_DEPLOY.md](../rules/SERVER_DEPLOY.md)。**

SERVER_DEPLOY.md 是唯一部署规则源，包含：
- 服务器信息与连接方式（SSH/MCP）
- 前端/API/完整部署流程
- **部署后验证**：使用 Chrome DevTools MCP 截图、检查控制台
- **GitHub MCP**：部署分支创建、PR 管理

## MCP 工具集成

| 阶段 | 工具 | 用途 |
|------|------|------|
| 部署前代码管理 | GitHub MCP | 创建分支、推送代码、管理 PR |
| 部署后验证 | Chrome DevTools MCP | 打开 admin 面板截图、检查错误 |
| 服务器连接 | aliyun-servers MCP | SSH 远程执行 |

## 参考文档

- [SERVER_DEPLOY.md](../rules/SERVER_DEPLOY.md) - 完整部署规范（含 MCP 验证流程）
- [PLAYWRIGHT_E2E.md](../rules/PLAYWRIGHT_E2E.md) - Chrome DevTools MCP 测试 SOP
- [SERVER_DEPLOY_PROCEDURE.md](../rules/SERVER_DEPLOY_PROCEDURE.md) - 部署流程
- [SERVER_OPS.md](../rules/SERVER_OPS.md) - 运维规范
