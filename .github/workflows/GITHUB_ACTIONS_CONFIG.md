# GitHub Actions 构建配置指南

## 配置步骤

### 1. 获取签名密钥的 Base64 编码

在 WSL 环境中执行以下命令：

```bash
cd /home/mayn/.android/signing
base64 changji.jks
```

复制输出的 Base64 编码字符串。

### 2. 在 GitHub 上配置 Secrets

打开你的 GitHub 仓库，进入 `Settings` -> `Secrets and variables` -> `Actions` -> `New repository secret`

添加以下 secrets：

| Secret 名称 | 值来源 |
|------------|--------|
| `KEYSTORE_BASE64` | 上面生成的 Base64 编码字符串 |
| `KEYSTORE_PASSWORD` | 密钥库密码（默认：123456） |
| `KEY_ALIAS` | 密钥别名（默认：changji） |
| `KEY_PASSWORD` | 密钥密码（默认：123456） |

### 3. 触发构建

构建会在以下情况自动触发：
- 推送代码到 `main` 分支
- 创建 Pull Request 到 `main` 分支
- 手动触发（在 GitHub Actions 页面点击 "Run workflow"）

### 4. 下载构建产物

构建完成