---
alwaysApply: false
description: 畅记云API接口说明 - 认证、订阅、API Key分发接口
---

# SERVER_API.md - 畅记云 API 接口说明

> **部署规范** → 详见 [SERVER_DEPLOY.md](SERVER_DEPLOY.md)
> **API设计规范** → 详见 [API_DESIGN.md](API_DESIGN.md)

---

## 基础信息

- **Base URL**: `http://101.133.238.249/api/v1`
- **认证方式**: JWT Bearer Token
- **数据格式**: JSON

---

## 一、认证接口

### 用户注册
```
POST /auth/register
Content-Type: application/json

{
  "phone": "13800138000",
  "password": "test123456",
  "smsCode": "123456"
}

Response:
{
  "code": 200,
  "message": "success",
  "data": {
    "accessToken": "eyJhbGc...",
    "refreshToken": "eyJhb..."
  }
}
```

### 用户登录
```
POST /auth/login
Content-Type: application/json

{
  "phone": "13800138000",
  "password": "test123456"
}

Response:
{
  "code": 200,
  "message": "success",
  "data": {
    "accessToken": "eyJhbGc...",
    "refreshToken": "eyJhb..."
  }
}
```

### 获取用户信息
```
GET /auth/profile
Authorization: Bearer <accessToken>

Response:
{
  "code": 200,
  "message": "success",
  "data": {
    "id": "uuid",
    "phone": "13800138000"
  }
}
```

---

## 二、订阅管理接口

### 获取当前订阅
```
GET /subscription
Authorization: Bearer <accessToken>

Response:
{
  "code": 200,
  "message": "success",
  "data": {
    "planId": "free",
    "planName": "免费版",
    "status": "active",
    "expiresAt": null,
    "totalQuota": 30,
    "usedQuota": 0,
    "remainingQuota": 30
  }
}
```

### 创建订阅
```
POST /subscription
Authorization: Bearer <accessToken>
Content-Type: application/json

{
  "planId": "basic"
}
```

### 获取套餐列表
```
GET /subscription/plans
```

### 使用配额
```
POST /subscription/quota/use
Authorization: Bearer <accessToken>
Content-Type: application/json

{
  "amount": 5
}
```

### 创建套餐（管理员）
```
POST /subscription/plans
Authorization: Bearer <accessToken>
Content-Type: application/json

{
  "id": "premium",
  "name": "高级版",
  "description": "高级功能套餐",
  "priceCents": 19900,
  "durationDays": 30,
  "quotaType": "minutes",
  "quotaValue": 500
}
```

---

## 三、API Key 分发接口

### 获取分配的 API Key
```
GET /api-key
Authorization: Bearer <accessToken>

Response:
{
  "code": 200,
  "message": "success",
  "data": {
    "provider": "qwen",
    "apiKey": "sk-xxxxx",
    "model": "qwen-max",
    "rateLimitPerMin": 60,
    "expiresAt": "2026-05-21T10:30:00.000Z"
  }
}
```

### 刷新 API Key
```
POST /api-key/refresh
Authorization: Bearer <accessToken>
```

### 获取 API Key 列表（管理员）
```
GET /api-key/admin/list
Authorization: Bearer <accessToken>
```

### 创建 API Key（管理员）
```
POST /api-key/admin/create
Authorization: Bearer <accessToken>
Content-Type: application/json

{
  "provider": "qwen",
  "apiKey": "sk-xxxxx",
  "model": "qwen-max",
  "rateLimitPerMin": 60
}
```

### 删除 API Key（管理员）
```
DELETE /api-key/admin/:id
Authorization: Bearer <accessToken>
```

---

## 更新记录

| 日期 | 更新内容 |
|-----|---------|
| 2026-05-21 | 从 SERVER_DEPLOY.md 拆分，独立为 SERVER_API.md |
