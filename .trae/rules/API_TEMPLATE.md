---
alwaysApply: false
description: API 二级规范模板 - 用于创建新的 API 规范文档
---

# API 二级规范模板

本文档是 API 二级规范的模板，用于记录具体 API 服务的详细调用规范。

---

## 使用说明

新增 API 规范时：
1. 复制本文档内容
2. 重命名为 `<API_NAME>_<功能>_API.md`
3. 填入实际 API 信息
4. 更新 [API_DESIGN.md](API_DESIGN.md) 的索引

---

## 模板内容

```markdown
# <API 服务名称> <功能> 规范

## 概述

[简要说明 API 功能、使用场景、版本信息]

---

## API 信息

| 项目 | 值 |
|------|-----|
| **服务名称** |  |
| **端点** |  |
| **认证方式** |  |
| **请求限制** |  |
| **参考文档** |  |

---

## 请求格式

### 请求头

```http
Content-Type: application/json
Authorization: Bearer <API_KEY>
```

### 请求体结构

```json
{
  "字段1": "说明",
  "字段2": "说明"
}
```

### 必填参数

| 参数 | 类型 | 说明 |
|------|------|------|
|  |  |  |

### 可选参数

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
|  |  |  |  |

---

## 响应格式

### 成功响应

```json
{
  "code": 0,
  "message": "success",
  "data": {}
}
```

### 错误响应

```json
{
  "code": 400,
  "message": "错误描述",
  "request_id": "xxx"
}
```

### 解析代码

```dart
// Dart 解析代码示例
```

---

## 关键格式要求

### 1. [要点名称]

**✅ 正确**：
```dart
```

**❌ 错误**：
```dart
```

### 2. [要点名称]

**✅ 正确**：
```dart
```

**❌ 错误**：
```dart
```

---

## 错误处理

### 错误码对照表

| 错误码 | 含义 | 处理方式 |
|--------|------|---------|
| 400 | 请求参数错误 | 检查参数格式 |
| 401 | 认证失败 | 检查 API Key |
| 403 | 权限不足 | 检查账户权限 |
| 429 | 请求过于频繁 | 实现限流/重试 |
| 500 | 服务器错误 | 重试或联系支持 |

### 重试策略

```dart
// 重试逻辑示例
```

---

## 代码示例

### 完整调用示例

```dart
import 'package:dio/dio.dart';

class ApiClient {
  final Dio _dio;
  
  ApiClient() : _dio = Dio(BaseOptions(
    baseUrl: 'https://api.example.com',
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
  ));
  
  Future<ApiResult> call() async {
    try {
      final response = await _dio.post('/endpoint', data: {
        // 请求参数
      });
      
      if (response.statusCode == 200) {
        return ApiResult.success(response.data);
      } else {
        return ApiResult.error('请求失败: ${response.statusCode}');
      }
    } on DioException catch (e) {
      return ApiResult.error(_handleError(e));
    }
  }
  
  String _handleError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return '连接超时';
      case DioExceptionType.receiveTimeout:
        return '响应超时';
      case DioExceptionType.badResponse:
        return '服务器错误: ${e.response?.statusCode}';
      default:
        return '未知错误';
    }
  }
}
```

---

## 测试案例

### 案例 1：[场景描述]

**输入**：
```

```

**预期输出**：
```

```

**实际结果**：
- 日期：
- 状态：✅ 成功 / ❌ 失败

---

## 常见问题

### Q1: [问题描述]

**A**: [解答]

---

## 修改记录

| 日期 | 修改内容 | 结果 |
|-----|---------|------|
|  | 初始版本 |  |

---

*本文档是 API 规范的模板，新 API 应基于此模板创建独立文档。*
