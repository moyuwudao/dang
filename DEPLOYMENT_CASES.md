# 服务器管理后台部署案例集锦

> 记录 API Key 管理功能开发部署过程中遇到的所有异常及解决方案

---

## 案例 1：TypeScript 编译错误 - 缺少类型注解

### 现象
```
error TS2345: Argument of type 'string' is not assignable to parameter of type 'ApiKeyProvider'.
```

### 原因
`api-key.service.ts` 中 `createApiKey` 方法直接赋值 `provider` 字段，但类型不匹配。

### 解决方案
添加类型断言：
```typescript
provider: (dto.provider || ApiKeyProvider.CUSTOM) as ApiKeyProvider,
```

---

## 案例 2：数据库表结构不匹配 - 缺少新字段

### 现象
```
QueryFailedError: column ApiKey.name does not exist
```

### 原因
数据库表 `api_keys` 缺少新功能需要的字段（name, status, scopes 等）。

### 解决方案
1. 添加缺失的数据库列：
```sql
ALTER TABLE api_keys
ADD COLUMN name VARCHAR(255),
ADD COLUMN status VARCHAR(50) DEFAULT 'active',
ADD COLUMN scopes TEXT[] DEFAULT ARRAY['all'],
...;
```

2. 统一列名命名规范（PostgreSQL 不区分大小写，需使用双引号或下划线命名）。

---

## 案例 3：TypeORM 实体列名映射错误

### 现象
```
QueryFailedError: column ApiKey.apiSecretEncrypted does not exist
```

### 原因
TypeORM 默认将驼峰命名 `apiSecretEncrypted` 转换为下划线 `api_secret_encrypted`，但数据库中实际列名为 `apiSecretEncrypted`（驼峰命名）。

### 解决方案
在实体中显式指定 `name` 属性：
```typescript
@Column({ name: 'apiSecretEncrypted', nullable: true })
apiSecretEncrypted: string;
```

---

## 案例 4：PM2 运行旧代码

### 现象
修改代码后，API 仍然返回旧错误。

### 原因
`/opt/changji-cloud/api` 是独立部署目录，不是 git 仓库，git pull 不会自动同步。

### 解决方案
直接修改 `/opt/changji-cloud/api` 目录下的文件，然后重新构建：
```bash
cd /opt/changji-cloud/api
npm run build
pm2 restart changji-api
```

---

## 案例 5：NestJS 依赖注入失败 - HttpService

### 现象
```
Error: Nest can't resolve dependencies of the ApiKeyService (ApiKeyRepository, UserApiKeyRepository, ?). Please make sure that the argument HttpService at index [2] is available in the ApiKeyModule context.
```

### 原因
`ApiKeyModule` 缺少 `HttpModule` 导入。

### 解决方案
在 `api-key.module.ts` 中添加 `HttpModule`：
```typescript
import { HttpModule } from '@nestjs/axios';

@Module({
  imports: [
    TypeOrmModule.forFeature([ApiKey, UserApiKey]),
    HttpModule,  // <-- 添加这一行
    JwtModule.register({...}),
  ],
})
```

---

## 案例 6：前端无障碍访问警告

### 现象
```
An aria-label or aria-labelledby prop is required for accessibility.
```

### 原因
Next UI 的 `Button` 组件在使用 `isIconOnly` 属性时，需要提供 `aria-label` 或 `aria-labelledby`。

### 解决方案
为所有 `isIconOnly` 按钮添加 `aria-label`：
```tsx
<Button isIconOnly aria-label="删除用户">
  <Trash2 className="w-4 h-4" />
</Button>
```

---

## 案例 7：前端路由错误 - Abort fetching component

### 现象
```
Error: Abort fetching component for route: "/login"
```

### 原因
Axios 响应拦截器在收到 401 时无条件调用 `Router.push('/login')`，如果用户已在登录页面会导致路由冲突。

### 解决方案
添加页面判断：
```typescript
if (error.response?.status === 401) {
  localStorage.removeItem('accessToken');
  if (typeof window !== 'undefined' && window.location.pathname !== '/login') {
    Router.push('/login');
  }
}
```

---

## 案例 8：API 连通性测试逻辑不真实

### 现象
测试按钮显示"测试通过"，但实际 API Key 无效。

### 原因
使用 `/models` 接口测试，但很多平台（通义千问、DeepSeek）没有这个接口。

### 解决方案
使用各平台实际的 API 端点进行验证：
- **OpenAI**: `GET /v1/models`
- **Anthropic**: `POST /v1/messages` (最小请求)
- **通义千问**: `POST /v1/chat/completions`
- **DeepSeek**: `POST /v1/chat/completions`
- **Gemini**: `POST /v1beta/models/gemini-1.5-flash:generateContent`
- **Grok**: `POST /v1/chat/completions`

---

## 案例 9：PostgreSQL 列名大小写问题

### 现象
```
QueryFailedError: column ApiKey.rate_limit_per_min does not exist
```

### 原因
PostgreSQL 不区分大小写，会将 `rateLimitPerMin` 转换为小写 `ratelimitpermin`，但 TypeORM 期望的是 `rate_limit_per_min`。

### 解决方案
1. 在实体中显式指定下划线命名：
```typescript
@Column({ name: 'rate_limit_per_min', default: 60 })
rateLimitPerMin: number;
```

2. 或者重命名数据库列：
```sql
ALTER TABLE api_keys RENAME COLUMN "rateLimitPerMin" TO rate_limit_per_min;
```

---

## 案例 10：TypeORM synchronize 配置

### 现象
数据库表结构频繁出错，列名不匹配。

### 原因
`synchronize: false` 时 TypeORM 不会自动同步实体变更到数据库。

### 解决方案
临时启用 `synchronize: true` 自动创建表：
```typescript
TypeOrmModule.forRoot({
  ...
  synchronize: true,  // 开发环境临时启用
}),
```

**注意**：生产环境应使用数据库迁移（migrations）而不是 synchronize。

---

## 部署检查清单

- [ ] 确认 `/opt/changji-cloud/api` 目录代码已更新
- [ ] 确认 `npm run build` 编译成功（0 errors）
- [ ] 确认 `pm2 restart changji-api` 重启成功
- [ ] 确认数据库表结构匹配实体定义
- [ ] 确认所有 Module 依赖已正确导入
- [ ] 测试 API 接口返回正常

---

*最后更新：2026-05-26*
