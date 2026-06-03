# 畅记 (Changji) 项目 Code Wiki

> 最后更新：2026-05-30
> 项目概述：AI语音笔记应用，包含移动端、服务端和管理后台

---

## 目录

1. [项目概述](#项目概述)
2. [技术栈](#技术栈)
3. [项目架构](#项目架构)
4. [核心模块说明](#核心模块说明)
5. [数据模型](#数据模型)
6. [关键服务](#关键服务)
7. [API文档](#api文档)
8. [部署与运行](#部署与运行)
9. [开发规范](#开发规范)

---

## 项目概述

### 项目简介

**畅记 (Changji)** 是一个完整的AI语音笔记应用，包含三个主要部分：

- **Flutter 移动应用** - 核心用户端，提供录音、转写、AI分析等功能
- **NestJS 服务端** - 云端API服务，处理用户、订阅、API密钥管理
- **Next.js 管理后台** - 运营管理后台，用于管理用户、订阅、监控等

### 核心功能

1. **录音与实时转写** - 支持本地录音和云端实时转写
2. **AI智能分析** - 基于不同AI角色进行内容分析
3. **OCR文字识别** - 拍照识别文字
4. **思维导图生成** - AI自动生成思维导图
5. **数据备份** - WebDAV云端备份
6. **订阅管理** - 多套餐、多计费模式
7. **API密钥分发** - 云端API密钥托管服务

---

## 技术栈

### 前端 (Flutter 应用)

| 技术 | 用途 |
|------|------|
| Flutter | 跨平台移动应用框架 |
| Dart | 编程语言 |
| flutter_riverpod | 状态管理 |
| drift | SQLite ORM |
| go_router | 路由管理 |
| record | 录音功能 |
| permission_handler | 权限管理 |
| dio | HTTP客户端 |
| google_mlkit_text_recognition | OCR识别 |
| shared_preferences | 本地存储 |
| flutter_secure_storage | 安全存储 |

### 后端 (NestJS 服务)

| 技术 | 用途 |
|------|------|
| NestJS | Node.js Web框架 |
| TypeScript | 编程语言 |
| TypeORM | ORM框架 |
| PostgreSQL | 关系型数据库 |
| Redis | 缓存/会话存储 |
| JWT | 认证令牌 |
| bcrypt | 密码加密 |
| PM2 | 进程管理 |
| @nestjs/schedule | 定时任务 |

### 管理后台 (Next.js)

| 技术 | 用途 |
|------|------|
| Next.js | React SSR框架 |
| React | UI框架 |
| TypeScript | 编程语言 |
| TailwindCSS | CSS框架 |
| NextUI | UI组件库 |
| Axios | HTTP客户端 |
| Recharts | 图表库 |
| Playwright | E2E测试 |

---

## 项目架构

### 目录结构

```
changji/
├── lib/                      # Flutter应用源代码
│   ├── core/                # 核心模块
│   │   ├── models/          # 数据模型
│   │   ├── services/        # 业务服务
│   │   ├── theme/           # 主题配置
│   │   ├── utils/           # 工具函数
│   │   └── widgets/         # 通用组件
│   ├── data/                # 数据层
│   │   ├── database/        # 数据库
│   │   ├── models/          # 数据模型
│   │   └── repositories/    # 数据仓库
│   ├── features/            # 功能模块
│   │   ├── auth/            # 认证
│   │   ├── home/            # 首页
│   │   ├── recording/       # 录音
│   │   ├── records/         # 记录管理
│   │   ├── ocr/             # OCR
│   │   ├── quick_note/      # 速记
│   │   ├── mindmap/         # 思维导图
│   │   ├── settings/        # 设置
│   │   ├── statistics/      # 统计
│   │   ├── subscription/    # 订阅
│   │   ├── workbench/       # 工作台
│   │   └── ...              # 其他功能
│   ├── routes/              # 路由配置
│   ├── l10n/                # 国际化
│   ├── main.dart            # 应用入口
│   └── main_simple.dart     # 简化入口
├── server/                  # NestJS服务端
│   ├── src/
│   │   ├── admin/           # 管理模块
│   │   ├── ai/              # AI路由模块
│   │   ├── api-key/         # API密钥模块
│   │   ├── auth/            # 认证模块
│   │   ├── common/          # 通用模块
│   │   ├── monitor/         # 监控模块
│   │   ├── payment/         # 支付模块
│   │   ├── plan/            # 套餐模块
│   │   ├── redis/           # Redis模块
│   │   ├── subscription/    # 订阅模块
│   │   │   ├── billing/     # 计费策略
│   │   │   ├── dto/         # 数据传输对象
│   │   │   ├── entities/    # 数据实体
│   │   │   └── ...          # 其他
│   │   ├── app.module.ts    # 应用主模块
│   │   └── main.ts          # 服务入口
│   ├── dist/                # 编译输出
│   ├── migrations/          # 数据库迁移
│   └── package.json
├── admin/                   # Next.js管理后台
│   ├── components/          # 组件
│   ├── pages/               # 页面
│   ├── public/              # 静态资源
│   ├── services/            # 服务
│   ├── styles/              # 样式
│   ├── types/               # 类型定义
│   ├── out/                 # 编译输出
│   └── package.json
├── .trae/                   # 项目配置和规则
│   ├── rules/               # 开发规范
│   ├── skills/              # AI技能
│   └── agents/              # AI代理
└── docs/                    # 文档
```

### 架构分层

#### Flutter应用架构

```
UI层 (Features/Screens)
    ↓
状态管理层 (Riverpod Providers)
    ↓
服务层 (Services)
    ↓
数据层 (Repositories/Database)
    ↓
本地存储/网络 (SQLite/API)
```

#### NestJS服务端架构

```
控制器层 (Controllers) → API端点
    ↓
服务层 (Services) → 业务逻辑
    ↓
数据访问层 (TypeORM/Repositories)
    ↓
数据库 (PostgreSQL/Redis)
```

---

## 核心模块说明

### Flutter 应用模块

#### 1. 录音模块 (`features/recording/`)

**功能**：
- 音频录制
- 实时波形显示
- 录音暂停/恢复
- 录音保存

**关键文件**：
- `recording_provider.dart` - 状态管理
- `recording_screen.dart` - 录音页面
- `recording_service.dart` - 录音服务

#### 2. 记录管理模块 (`features/records/`)

**功能**：
- 记录列表展示
- 记录详情查看
- AI分析面板
- 音频播放
- 收藏管理
- 回收站

**关键文件**：
- `record_provider.dart` - 记录状态管理
- `record_list.dart` - 记录列表组件
- `record_detail_screen.dart` - 详情页面
- `ai_analysis_panel.dart` - AI分析面板

#### 3. AI分析模块 (`core/services/`)

**功能**：
- AI摘要生成
- AI角色切换
- 多API提供商支持
- 提示词模板管理

**关键服务**：
- `ai_summary_service.dart` - AI摘要服务
- `role_service.dart` - 角色服务
- `prompt_template_service.dart` - 提示词模板服务
- `tingwu_service.dart` - 通义听悟服务

#### 4. 工作台模块 (`features/workbench/`)

**功能**：
- AI工具链
- 工具模板管理
- 数据源选择
- 工具输出管理

**关键文件**：
- `workbench_provider.dart` - 工作台状态
- `tool_template_provider.dart` - 工具模板
- `workbench_screen.dart` - 工作台页面

#### 5. 设置模块 (`features/settings/`)

**功能**：
- API密钥配置
- AI角色管理
- 提示词模板管理
- 备份管理
- 主题切换

### NestJS 服务端模块

#### 1. 认证模块 (`auth/`)

**功能**：
- 用户注册/登录
- JWT令牌生成/刷新
- SMS验证码发送
- 用户信息管理

**关键文件**：
- `auth.controller.ts` - 认证控制器
- `auth.service.ts` - 认证服务
- `jwt-auth.guard.ts` - JWT守卫
- `user.entity.ts` - 用户实体

#### 2. 订阅模块 (`subscription/`)

**功能**：
- 套餐管理
- 订阅创建/更新
- 配额管理
- 计费策略（支持多种计费模式）

**关键文件**：
- `subscription.controller.ts` - 订阅控制器
- `subscription.service.ts` - 订阅服务
- `plan.entity.ts` - 套餐实体
- `billing/` - 计费策略目录

**计费策略**：
- `package-billing.strategy.ts` - 包量计费
- `pay-as-you-go-billing.strategy.ts` - 按量计费
- `subscription-billing.strategy.ts` - 订阅计费

#### 3. API密钥模块 (`api-key/`)

**功能**：
- API密钥池管理
- 用户API密钥分配
- 健康检查
- 速率限制

**关键文件**：
- `api-key.controller.ts` - API密钥控制器
- `api-key.service.ts` - API密钥服务
- `api-key.entity.ts` - API密钥实体

#### 4. 管理模块 (`admin/`)

**功能**：
- 管理后台API
- 用户管理
- 审计日志
- 系统监控

#### 5. 监控模块 (`monitor/`)

**功能**：
- 系统指标收集
- 性能监控
- 健康检查

---

## 数据模型

### Flutter 应用数据模型

#### 核心模型

| 模型 | 文件 | 用途 |
|------|------|------|
| User | `core/models/user.dart` | 用户信息 |
| Note | `core/models/note.dart` | 笔记 |
| RecordModel | `data/models/record_model.dart` | 录音记录 |
| AiModelConfig | `core/models/ai_model_config.dart` | AI模型配置 |
| AiRole | `core/models/ai_role.dart` | AI角色 |
| AnalysisConfig | `core/models/analysis_config.dart` | 分析配置 |
| PromptTemplate | `core/models/prompt_template.dart` | 提示词模板 |
| RealtimeTranscriptionResult | `core/models/realtime_transcription_result.dart` | 实时转写结果 |

#### 数据库模型

**数据库配置**：`data/database/app_database.dart`

| 表 | 用途 |
|----|------|
| records | 录音记录 |
| tool_outputs | 工具输出 |

### NestJS 服务端数据实体

| 实体 | 文件 | 用途 |
|------|------|------|
| User | `auth/entities/user.entity.ts` | 用户 |
| Plan | `subscription/entities/plan.entity.ts` | 套餐 |
| Subscription | `subscription/entities/subscription.entity.ts` | 订阅 |
| ApiKey | `api-key/entities/api-key.entity.ts` | API密钥 |
| UserApiKey | `api-key/entities/user-api-key.entity.ts` | 用户API密钥 |
| ApiUsageLog | `subscription/entities/api-usage-log.entity.ts` | API使用日志 |
| RechargeRecord | `subscription/entities/recharge-record.entity.ts` | 充值记录 |
| UserBalance | `subscription/entities/user-balance.entity.ts` | 用户余额 |
| PlanFeatureQuota | `subscription/entities/plan-feature-quota.entity.ts` | 套餐功能配额 |
| PlanApiPolicy | `subscription/entities/plan-api-policy.entity.ts` | 套餐API策略 |
| PlanDefaultConfig | `subscription/entities/plan-default-config.entity.ts` | 套餐默认配置 |
| BillingStandard | `subscription/entities/billing-standard.entity.ts` | 计费标准 |
| TokenPricing | `subscription/entities/token-pricing.entity.ts` | Token定价 |
| AuditLog | `admin/entities/audit-log.entity.ts` | 审计日志 |

---

## 关键服务

### Flutter 应用服务

#### 核心服务

| 服务 | 文件 | 功能 |
|------|------|------|
| RecordingService | `core/services/recording_service.dart` | 录音服务 |
| TranscriptionService | `core/services/transcription_service.dart` | 转写服务 |
| RealtimeTranscriptionService | `core/services/realtime_transcription_service.dart` | 实时转写服务 |
| AiSummaryService | `core/services/ai_summary_service.dart` | AI摘要服务 |
| TingwuService | `core/services/tingwu_service.dart` | 通义听悟服务 |
| ApiService | `core/services/api_service.dart` | API服务 |
| CloudApiService | `core/services/cloud_api_service.dart` | 云端API服务 |
| StorageService | `core/services/storage_service.dart` | 存储服务 |
| SecureStorageService | `core/services/secure_storage_service.dart` | 安全存储服务 |
| BackupService | `core/services/backup_service.dart` | 备份服务 |
| WebdavSyncService | `core/services/webdav_sync_service.dart` | WebDAV同步服务 |
| AuthService | `core/services/auth_service.dart` | 认证服务 |
| SubscriptionService | `core/services/subscription_service.dart` | 订阅服务 |
| ThemeService | `core/services/theme_service.dart` | 主题服务 |

### NestJS 服务端服务

#### 核心服务

| 服务 | 文件 | 功能 |
|------|------|------|
| AuthService | `auth/auth.service.ts` | 认证服务 |
| SubscriptionService | `subscription/subscription.service.ts` | 订阅服务 |
| ApiKeyService | `api-key/api-key.service.ts` | API密钥服务 |
| AiService | `ai/ai.service.ts` | AI服务 |
| AiRouterService | `ai/ai-router.service.ts` | AI路由服务 |
| PaymentService | `payment/payment.service.ts` | 支付服务 |
| MonitorService | `monitor/monitor.service.ts` | 监控服务 |
| MetricsService | `monitor/metrics.service.ts` | 指标服务 |
| AdminService | `admin/admin.service.ts` | 管理服务 |
| AuditService | `admin/services/audit.service.ts` | 审计服务 |
| PlanService | `plan/plan.service.ts` | 套餐服务 |
| RedisService | `redis/redis.service.ts` | Redis服务 |
| SubscriptionSchedulerService | `subscription/subscription-scheduler.service.ts` | 订阅调度服务 |
| BillingStrategyFactory | `subscription/billing/billing-strategy.factory.ts` | 计费策略工厂 |

---

## API文档

### 服务端API基础信息

**Base URL**: `http://101.133.238.249/api/v1`

**认证方式**: JWT Bearer Token

### 认证API

| 端点 | 方法 | 功能 |
|------|------|------|
| `/auth/register` | POST | 用户注册 |
| `/auth/login` | POST | 用户登录 |
| `/auth/profile` | GET | 获取用户信息 |
| `/auth/send-sms-code` | POST | 发送短信验证码 |

### 订阅API

| 端点 | 方法 | 功能 |
|------|------|------|
| `/subscription` | GET | 获取当前订阅 |
| `/subscription` | POST | 创建订阅 |
| `/subscription/plans` | GET | 获取套餐列表 |
| `/subscription/quota/use` | POST | 使用配额 |

### API密钥API

| 端点 | 方法 | 功能 |
|------|------|------|
| `/api-key` | GET | 获取分配的API密钥 |
| `/api-key/refresh` | POST | 刷新API密钥 |
| `/api-key/admin/list` | GET | 管理员：列出所有API密钥 |
| `/api-key/admin/create` | POST | 管理员：创建API密钥 |
| `/api-key/admin/:id` | DELETE | 管理员：删除API密钥 |

### 管理API

| 端点 | 方法 | 功能 |
|------|------|------|
| `/admin/users` | GET | 用户列表 |
| `/admin/audit-logs` | GET | 审计日志 |
| `/monitor/metrics` | GET | 系统指标 |
| `/monitor/health` | GET | 健康检查 |

---

## 部署与运行

### Flutter应用构建

**环境要求**：
- Flutter SDK
- Android SDK
- WSL环境（推荐用于构建）

**构建步骤**：
```bash
# 进入WSL
wsl -d dang

# 清理构建
flutter clean

# 获取依赖
flutter pub get

# 构建Release APK
flutter build apk --release
```

**APK输出位置**：`build/app/outputs/flutter-apk/app-release.apk`

### NestJS服务端部署

**服务器信息**：
- IP: 101.133.238.249
- OS: Ubuntu 22.04
- 部署用户: admin

**部署步骤**：
```bash
# 1. 连接服务器
ssh changji

# 2. 进入项目目录
cd /home/admin/dang/server

# 3. 拉取最新代码
git pull origin master

# 4. 安装依赖
npm install

# 5. 构建
npm run build

# 6. 重启服务
pm2 restart changji-api
```

**服务管理**：
```bash
# 查看状态
pm2 status

# 查看日志
pm2 logs changji-api --nostream --lines 50

# 重启服务
pm2 restart changji-api
```

### Next.js管理后台部署

**部署步骤**：
```bash
# 1. 本地构建
cd admin
npm run build

# 2. 同步到服务器
# 或使用git pull + 构建

# 3. 服务器部署
cd /home/admin/dang/admin
git pull origin master
npm install
npm run build

# 4. 复制到Nginx目录
sudo rm -rf /var/www/html/admin/*
sudo cp -r out/* /var/www/html/admin/
sudo chown -R www-data:www-data /var/www/html/admin

# 5. 重启Nginx
sudo nginx -t && sudo systemctl reload nginx
```

### 服务器环境配置

**关键服务**：
- PostgreSQL: 14.22 (端口 5432)
- Redis: 6.0.16 (端口 6379)
- Nginx: 1.18.0 (端口 80, 443)
- PM2: 5.4.0

**数据库连接信息**：
- 用户: appuser
- 数据库: appdb
- 本地连接: postgresql://appuser:AppUser123456@localhost:5432/appdb

---

## 开发规范

### 代码风格

#### Dart/Flutter

- 使用 `flutter analyze` 进行代码检查
- 遵循 `dart format` 格式化规则
- 使用 `const` 构造函数优先
- 局部变量使用 `final`
- 字符串使用单引号

#### TypeScript/NestJS

- 遵循 ESLint 规则
- 使用类型注解
- 依赖注入遵循 NestJS 模式

### Git工作流

- 开发分支: 功能分支开发
- 主分支: master
- 提交前运行 lint 和测试

### 安全规范

- 禁止硬编码API密钥
- 使用 `flutter_secure_storage` 存储敏感数据
- 密码使用 bcrypt 哈希
- API使用JWT认证
- 禁止root登录SSH

### 测试规范

- 单元测试: 核心业务逻辑
- E2E测试: 使用 Playwright/Chrome DevTools MCP
- 构建前确保所有测试通过

---

## 相关文档

- [BUILD.md](../.trae/rules/BUILD.md) - 构建规范
- [PROJECT_SENSE.md](../.trae/rules/PROJECT_SENSE.md) - 项目感知
- [SERVER_DEPLOY.md](../.trae/rules/SERVER_DEPLOY.md) - 服务器部署
- [SERVER_API.md](../.trae/rules/SERVER_API.md) - 服务器API
- [RIVERPOD.md](../.trae/rules/RIVERPOD.md) - 状态管理
- [PLAYWRIGHT_E2E.md](../.trae/rules/PLAYWRIGHT_E2E.md) - E2E测试

---

## 更新记录

| 日期 | 更新内容 |
|------|---------|
| 2026-05-30 | 初始版本，完整项目架构和模块说明 |

