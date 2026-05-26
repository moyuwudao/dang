---
alwaysApply: false
globs: admin/**, test/e2e/**
description: Chrome DevTools MCP E2E 测试规范 - 浏览器测试、性能审计、视觉验证
---

# Chrome DevTools MCP E2E 测试规范

## 核心理念

**用 Chrome DevTools MCP 进行真浏览器 E2E 测试。** 相比 Playwright，Chrome DevTools MCP 零安装、零配置，具备更强大的审计能力。

当 Flutter APP 无法测试服务器端/Web 端问题时，直接用 Chrome DevTools MCP 操作浏览器。

---

## 🛠 可用 MCP 工具速查

### 浏览器操作
| 工具 | 用途 |
|------|------|
| `mcp_Chrome_DevTools_MCP_navigate_page` | 导航到 URL |
| `mcp_Chrome_DevTools_MCP_click` | 点击元素（需要 uid） |
| `mcp_Chrome_DevTools_MCP_fill` | 输入文本 |
| `mcp_Chrome_DevTools_MCP_fill_form` | 批量填写表单 |
| `mcp_Chrome_DevTools_MCP_hover` | 悬停元素 |
| `mcp_Chrome_DevTools_MCP_press_key` | 按键操作 |
| `mcp_Chrome_DevTools_MCP_wait_for` | 等待文本出现 |
| `mcp_Chrome_DevTools_MCP_type_text` | 键盘输入 |

### 视觉验证
| 工具 | 用途 |
|------|------|
| `mcp_Chrome_DevTools_MCP_take_screenshot` | 截图（支持全页/元素级） |
| `mcp_Chrome_DevTools_MCP_take_snapshot` | 获取页面 a11y 树快照（含 uid） |

### 调试与监控
| 工具 | 用途 |
|------|------|
| `mcp_Chrome_DevTools_MCP_list_console_messages` | 获取控制台日志 |
| `mcp_Chrome_DevTools_MCP_list_network_requests` | 获取网络请求列表 |
| `mcp_Chrome_DevTools_MCP_get_network_request` | 获取单个请求详情 |
| `mcp_Chrome_DevTools_MCP_evaluate_script` | 执行 JS 脚本 |

### 性能与质量
| 工具 | 用途 |
|------|------|
| `mcp_Chrome_DevTools_MCP_lighthouse_audit` | Lighthouse 审计（SEO/可访问性/最佳实践） |
| `mcp_Chrome_DevTools_MCP_performance_start_trace` | 开始性能追踪 |
| `mcp_Chrome_DevTools_MCP_performance_stop_trace` | 停止性能追踪 |
| `mcp_Chrome_DevTools_MCP_performance_analyze_insight` | 分析性能洞察 |

### 页面管理
| 工具 | 用途 |
|------|------|
| `mcp_Chrome_DevTools_MCP_new_page` | 打开新标签 |
| `mcp_Chrome_DevTools_MCP_list_pages` | 列出所有页面 |
| `mcp_Chrome_DevTools_MCP_select_page` | 选择页面 |
| `mcp_Chrome_DevTools_MCP_close_page` | 关闭页面 |
| `mcp_Chrome_DevTools_MCP_resize_page` | 调整视口大小 |
| `mcp_Chrome_DevTools_MCP_emulate` | 模拟网络/CPU/设备 |

---

## 按钮问题排查流程（标准 SOP）

### 步骤 1：打开页面并获取快照

```
1. mcp_Chrome_DevTools_MCP_navigate_page(type="url", url="http://101.133.238.249/admin/dashboard")
2. mcp_Chrome_DevTools_MCP_take_snapshot()
   → 获取页面所有元素的 uid，找到目标按钮的 uid
```

### 步骤 2：点击前截图对比

```
3. mcp_Chrome_DevTools_MCP_take_screenshot(fullPage=true)
   → 保存点击前状态
```

### 步骤 3：点击并验证

```
4. mcp_Chrome_DevTools_MCP_click(uid="<按钮uid>")
5. mcp_Chrome_DevTools_MCP_take_screenshot(fullPage=true)
   → 对比点击前后页面变化
6. mcp_Chrome_DevTools_MCP_take_snapshot()
   → 查看 URL 是否变化、DOM 是否更新
```

### 步骤 4：检查错误

```
7. mcp_Chrome_DevTools_MCP_list_console_messages(types=["error", "warn"])
   → 捕获 JS 错误
8. mcp_Chrome_DevTools_MCP_list_network_requests(resourceTypes=["xhr", "fetch"])
   → 检查 API 请求是否发送、响应状态码
```

---

## 测试场景

### 场景 1：登录 + 功能验证

```
// 1. 打开登录页
mcp_Chrome_DevTools_MCP_navigate_page(type="url", url="http://101.133.238.249/admin/login")

// 2. 获取快照找到表单元素 uid
mcp_Chrome_DevTools_MCP_take_snapshot()

// 3. 批量填写表单
mcp_Chrome_DevTools_MCP_fill_form(elements=[
  {uid: "<email输入框uid>", value: "admin@example.com"},
  {uid: "<密码输入框uid>", value: "password"}
])

// 4. 点击登录
mcp_Chrome_DevTools_MCP_click(uid="<登录按钮uid>")

// 5. 等待页面跳转
mcp_Chrome_DevTools_MCP_wait_for(text="Dashboard", timeout=10000)
```

### 场景 2：按钮无响应复现

```
// 完整复现流程
1. navigate 到目标页面
2. take_screenshot → screenshot_before.png
3. click 目标按钮
4. wait_for（等待可能的响应）
5. take_screenshot → screenshot_after.png（对比）
6. list_console_messages（检查 JS 错误）
7. list_network_requests（检查 API 是否发送）
8. 如果以上都无变化 → 报告"按钮点击后无任何响应"
```

### 场景 3：性能审计

```
// Lighthouse 审计（导航模式 → 重新加载并审计）
mcp_Chrome_DevTools_MCP_lighthouse_audit(mode="navigation", device="desktop")
→ 返回 SEO、可访问性、最佳实践评分

// 性能追踪（自定义分析）
mcp_Chrome_DevTools_MCP_performance_start_trace(reload=true, autoStop=true)
→ 自动完成追踪并返回 Core Web Vitals 数据

// 分析具体性能问题
mcp_Chrome_DevTools_MCP_performance_analyze_insight(
  insightSetId="<从追踪结果获取>",
  insightName="LCPBreakdown"
)
```

### 场景 4：移动端适配检查

```
mcp_Chrome_DevTools_MCP_emulate(viewport="375x812x2,mobile,touch")
mcp_Chrome_DevTools_MCP_navigate_page(type="url", url="http://101.133.238.249/admin/dashboard")
mcp_Chrome_DevTools_MCP_take_screenshot(fullPage=true)
```

### 场景 5：API 请求验证

```
// 获取网络请求列表
mcp_Chrome_DevTools_MCP_list_network_requests(resourceTypes=["fetch", "xhr"])

// 查看具体请求详情
mcp_Chrome_DevTools_MCP_get_network_request(reqid=<请求ID>)
→ 返回请求头、请求体、响应状态码、响应体
```

---

## 按钮问题排查清单

| 检查项 | MCP 工具 | 预期结果 |
|-------|---------|---------|
| 按钮存在且可见 | `take_snapshot` → 找到按钮 uid | 按钮在 a11y 树中 |
| 点击不抛异常 | `click` 不报错 | 操作成功 |
| 点击后有响应 | `take_screenshot` 对比前后 | 页面有变化 |
| 点击后 URL 变化 | `take_snapshot` 检查 URL | URL 变化或内容更新 |
| 无 JS 错误 | `list_console_messages(types=["error"])` | 无错误消息 |
| API 请求发送 | `list_network_requests` | 请求到达服务器 |
| API 响应正常 | `get_network_request` | 200/201 状态码 |

---

## 与原有 Playwright 的关系

| 对比维度 | Chrome DevTools MCP（推荐） | Playwright（备用） |
|---------|--------------------------|-------------------|
| 安装 | 零安装，IDE 内置 | 需要 npm install + 浏览器 |
| 配置 | 零配置 | 需要 playwright.config.ts |
| 审计能力 | ✅ Lighthouse + 性能追踪 | ❌ 需额外工具 |
| CI/CD | ❌ 需 IDE 运行 | ✅ 可独立运行 |
| 适用场景 | 开发期快速测试、调试 | 自动化 CI、定期回归 |

---

## 更新记录

| 日期 | 更新内容 |
|-----|---------|
| 2026-05-25 | 升级为 Chrome DevTools MCP 规范：添加完整工具速查表、SOP 流程、性能审计、移动端测试 |
| 2026-05-23 | 初始版本（Playwright E2E） |
