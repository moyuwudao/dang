# 畅记 App - 客户端登录/付费界面方案

## 一、现有架构分析

### 1.1 技术栈
| 项目 | 技术 |
|------|------|
| 状态管理 | flutter_riverpod |
| 路由 | go_router |
| 主题 | 自定义 AppColors |
| 本地存储 | Drift (SQLite) |
| 网络请求 | dio |

### 1.2 现有设置页面结构
```
SettingsScreen (TabBarView)
├── AI配置 Tab
│   ├── 运行日志
│   ├── 快速配置向导
│   ├── API Key配置
│   ├── 多API配置
│   └── ...
├── 数据管理 Tab
│   ├── 备份管理
│   ├── 回收站
│   └── ...
└── 系统设置 Tab
    ├── 角色管理
    ├── 自动分析设置
    └── ...
```

---

## 二、新增界面规划

### 2.1 界面清单

| 界面 | 路径 | 说明 | 优先级 |
|------|------|------|--------|
| **登录页** | `/login` | 手机号+密码/验证码登录 | P0 |
| **注册页** | `/register` | 手机号注册 | P0 |
| **个人中心** | `/profile` | 用户信息/订阅状态 | P0 |
| **套餐商店** | `/subscription/store` | 购买套餐 | P0 |
| **我的订阅** | `/subscription/mine` | 当前订阅/余量 | P0 |
| **交易记录** | `/subscription/orders` | 订单/消费记录 | P1 |
| **充值中心** | `/subscription/recharge` | 账户余额充值 | P0 |
| **云API配置** | `/settings/cloud-api` | 云端API Key开关 | P0 |

### 2.2 设置页面改造

现有 `SettingsScreen` 从 3 个 Tab 改为 **4 个 Tab**：

```
SettingsScreen (TabBarView)
├── AI配置 Tab (现有)
├── 数据管理 Tab (现有)
├── 账户中心 Tab (新增) ⭐
│   ├── 登录/注册入口
│   ├── 个人信息
│   ├── 我的订阅
│   ├── 购买套餐
│   ├── 充值中心
│   └── 交易记录
└── 系统设置 Tab (现有)
```

---

## 三、关键业务规则补充

### 3.1 验证码防冲击机制

**风险**：恶意攻击者高频请求验证码，导致短信费用暴增、正常用户无法收到验证码。

**防护方案（多层）**：

| 层级 | 措施 | 说明 |
|------|------|------|
| **前端限制** | 60秒倒计时 | 按钮禁用，显示倒计时 |
| **前端限制** | 图形验证码 | 连续请求2次后，第3次必须输入图形验证码 |
| **后端限制** | 单手机号频率限制 | 1分钟1条、1小时5条、1天10条 |
| **后端限制** | IP频率限制 | 同IP 1小时最多10条 |
| **后端限制** | 图形验证码校验 | 连续请求3次后必须验证图形码 |
| **监控告警** | 异常流量检测 | 单手机号>10次/小时触发告警 |

**客户端实现**：
- 注册页增加图形验证码输入框（需要时显示）
- 发送验证码前检查是否需要图形验证码
- 后端返回 `needCaptcha: true` 时显示图形验证码

### 3.2 登录/未登录权限划分

| 功能 | 未登录（本地模式） | 已登录（云端模式） |
|------|------------------|------------------|
| 录音 | ✅ | ✅ |
| 本地AI转写（自配API） | ✅ | ✅ |
| 云端AI转写（分配API） | ❌ | ✅ |
| 查看订阅/套餐 | ❌ | ✅ |
| 购买套餐 | ❌ → 跳转登录 | ✅ |
| 充值余额 | ❌ → 跳转登录 | ✅ |
| 数据云同步 | ❌ | ✅ |
| 交易记录 | ❌ | ✅ |

**跳转逻辑**：
1. 点击需要登录的功能
2. 弹出底部提示：「该功能需要登录后使用」
3. 提供「去登录」和「取消」按钮
4. 登录成功后自动返回原页面

**云端AI开关逻辑**：
- 未登录时，云端AI开关禁用，提示「登录后开启」
- 已登录时，可以自由切换本地API / 云端API
- 切换时检查订阅状态，无有效订阅提示购买

### 3.3 三种套餐模式

| 模式 | 说明 | 退款规则 | 图标 |
|------|------|---------|------|
| **按月订阅** | 每月自动扣费，享受固定额度 | ❌ 不可退 | Icons.calendar_month |
| **固定套餐包** | 一次性购买，固定额度+有效期 | ❌ 不可退 | Icons.inventory_2 |
| **充值余额** | 充值金额到账户余额 | ✅ 可随时退 | Icons.account_balance_wallet |

**余额使用逻辑**：
- 余额可以购买「按月订阅」或「固定套餐包」
- 支付时优先扣除余额，余额不足再调起微信支付/支付宝
- 退款时原路返回（微信→微信零钱，支付宝→支付宝余额）

**套餐商店界面调整**：
- 顶部Tab切换：按月订阅 | 套餐包 | 充值
- 充值页面显示：当前余额、充值金额选择（50/100/200/500）、自定义金额
- 充值页面增加「退款」入口（已登录且有余额时显示）

### 3.4 注册赠送免费额度

**规则**：
- 首次注册登录后，自动赠送「新手体验包」
- 内容：100分钟转写额度，有效期7天
- 在「我的订阅」中显示为「新手体验包」
- 体验包过期后，提示购买正式套餐

**实现**：
- 注册接口返回时，后端自动创建体验包订阅
- 客户端登录成功后，显示欢迎弹窗：「欢迎加入畅记！已赠送100分钟体验额度」
- 体验包在订阅列表中标记为「体验」标签

---

## 四、详细界面设计

### 4.1 登录页 (LoginScreen)

```dart
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              // Logo
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.mic,
                    size: 40,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // 标题
              const Text(
                '欢迎回来',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '登录后解锁云端AI服务',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 40),
              // 手机号输入
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: '手机号',
                  hintText: '请输入手机号',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 密码输入
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: '密码',
                  hintText: '请输入密码',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // 忘记密码
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // TODO: 跳转忘记密码
                  },
                  child: const Text('忘记密码?'),
                ),
              ),
              const SizedBox(height: 24),
              // 登录按钮
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          '登录',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              // 验证码登录
              Center(
                child: TextButton(
                  onPressed: () {
                    // TODO: 跳转验证码登录
                  },
                  child: const Text('使用验证码登录'),
                ),
              ),
              const Spacer(),
              // 注册入口
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('还没有账号?'),
                    TextButton(
                      onPressed: () => context.push('/register'),
                      child: const Text('立即注册'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authNotifierProvider.notifier).login(
        phone: _phoneController.text,
        password: _passwordController.text,
      );
      if (mounted) {
        context.pop(); // 登录成功返回
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('登录失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
```

### 4.2 注册页 (RegisterScreen)

**更新点**：增加图形验证码支持

```dart
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _phoneController = TextEditingController();
  final _smsCodeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _captchaController = TextEditingController();
  bool _isLoading = false;
  bool _isSendingCode = false;
  int _countdown = 0;
  bool _needCaptcha = false; // 是否需要图形验证码
  String? _captchaImageUrl; // 图形验证码图片URL

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('注册账号'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '创建账号',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '注册即送100分钟体验额度',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 24),
              // 手机号
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: '手机号',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 验证码 + 发送按钮
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _smsCodeController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: '验证码',
                        prefixIcon: const Icon(Icons.message_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _countdown > 0 ? null : _sendSmsCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSendingCode
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _countdown > 0 ? '$_countdown秒' : '获取验证码',
                            ),
                    ),
                  ),
                ],
              ),
              // 图形验证码（需要时显示）
              if (_needCaptcha) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _captchaController,
                        decoration: InputDecoration(
                          labelText: '图形验证码',
                          prefixIcon: const Icon(Icons.security),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _refreshCaptcha,
                      child: Container(
                        width: 120,
                        height: 56,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.divider),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _captchaImageUrl != null
                            ? Image.network(_captchaImageUrl!, fit: BoxFit.cover)
                            : const Center(child: Icon(Icons.refresh)),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              // 密码
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: '密码',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 确认密码
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: '确认密码',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // 注册按钮
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('注册', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
              // 登录入口
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('已有账号?'),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('立即登录'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendSmsCode() async {
    setState(() => _isSendingCode = true);
    try {
      final result = await ref.read(authNotifierProvider.notifier).sendSmsCode(
        phone: _phoneController.text,
        captcha: _needCaptcha ? _captchaController.text : null,
      );
      
      // 检查是否需要图形验证码
      if (result['needCaptcha'] == true) {
        setState(() {
          _needCaptcha = true;
          _captchaImageUrl = result['captchaUrl'];
        });
        return;
      }
      
      setState(() => _countdown = 60);
      _startCountdown();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('发送失败: $e')),
      );
    } finally {
      setState(() => _isSendingCode = false);
    }
  }

  void _refreshCaptcha() async {
    final result = await ref.read(authNotifierProvider.notifier).refreshCaptcha();
    setState(() {
      _captchaImageUrl = result['captchaUrl'];
    });
  }

  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() => _countdown--);
      }
      return _countdown > 0 && mounted;
    });
  }

  Future<void> _register() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('两次密码不一致')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(authNotifierProvider.notifier).register(
        phone: _phoneController.text,
        password: _passwordController.text,
        smsCode: _smsCodeController.text,
      );
      if (mounted) {
        // 显示欢迎弹窗
        _showWelcomeDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('注册失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showWelcomeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('欢迎加入畅记！'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.card_giftcard, size: 48, color: AppColors.success),
            SizedBox(height: 16),
            Text('已赠送您新手体验包：'),
            Text('100分钟转写额度，有效期7天', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop(); // 返回上一页
            },
            child: const Text('开始使用'),
          ),
        ],
      ),
    );
  }
}
```

### 4.3 账户中心 Tab (AccountTab)

**更新点**：增加充值入口、未登录跳转提示

```dart
class AccountTab extends ConsumerWidget {
  const AccountTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final subscriptionState = ref.watch(subscriptionNotifierProvider);

    return ListView(
      children: [
        // 用户信息卡片
        _buildUserCard(context, authState),
        const SizedBox(height: 16),
        // 订阅状态卡片
        _buildSubscriptionCard(context, subscriptionState),
        const SizedBox(height: 16),
        // 功能列表
        _buildSection(
          context,
          title: '账户管理',
          children: [
            if (!authState.isLoggedIn) ...[
              ListTile(
                leading: const Icon(Icons.login, color: AppColors.primary),
                title: const Text('登录/注册'),
                subtitle: const Text('解锁云端AI服务，注册送100分钟'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/login'),
              ),
            ] else ...[
              ListTile(
                leading: const Icon(Icons.person, color: AppColors.primary),
                title: const Text('个人信息'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/profile'),
              ),
              ListTile(
                leading: const Icon(Icons.workspace_premium, color: AppColors.warning),
                title: const Text('我的订阅'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _checkLoginAndNavigate(context, '/subscription/mine'),
              ),
              ListTile(
                leading: const Icon(Icons.shopping_cart, color: AppColors.success),
                title: const Text('购买套餐'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _checkLoginAndNavigate(context, '/subscription/store'),
              ),
              ListTile(
                leading: const Icon(Icons.account_balance_wallet, color: AppColors.primary),
                title: const Text('充值中心'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _checkLoginAndNavigate(context, '/subscription/recharge'),
              ),
              ListTile(
                leading: const Icon(Icons.receipt_long, color: AppColors.info),
                title: const Text('交易记录'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _checkLoginAndNavigate(context, '/subscription/orders'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.error),
                title: const Text('退出登录'),
                onTap: () => _showLogoutConfirm(context, ref),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        // 云API配置
        _buildSection(
          context,
          title: 'AI服务配置',
          children: [
            ListTile(
              leading: const Icon(Icons.cloud, color: AppColors.primary),
              title: const Text('云端AI服务'),
              subtitle: Text(
                authState.isLoggedIn
                    ? '使用云端分配的API Key'
                    : '登录后开启云端AI服务',
              ),
              trailing: Switch(
                value: ref.watch(cloudApiEnabledProvider) && authState.isLoggedIn,
                onChanged: authState.isLoggedIn
                    ? (value) {
                        ref.read(cloudApiEnabledProvider.notifier).state = value;
                      }
                    : null,
              ),
              onTap: !authState.isLoggedIn
                  ? () => _showLoginPrompt(context)
                  : null,
            ),
            ListTile(
              leading: const Icon(Icons.key, color: AppColors.secondary),
              title: const Text('本地API配置'),
              subtitle: const Text('使用自己的API Key'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/settings/api-key'),
            ),
          ],
        ),
      ],
    );
  }

  void _checkLoginAndNavigate(BuildContext context, String route) {
    final authState = ProviderScope.containerOf(context).read(authNotifierProvider);
    if (!authState.isLoggedIn) {
      _showLoginPrompt(context);
      return;
    }
    context.push(route);
  }

  void _showLoginPrompt(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 48, color: AppColors.primary),
            const SizedBox(height: 16),
            const Text(
              '该功能需要登录后使用',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '登录后即可使用云端AI服务、购买套餐等功能',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('去登录'),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('暂不登录'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, AuthState state) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Icon(
              state.isLoggedIn ? Icons.person : Icons.person_outline,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            state.isLoggedIn ? state.user?.nickname ?? '用户' : '未登录',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (state.isLoggedIn) ...[
            const SizedBox(height: 4),
            Text(
              state.user?.phone ?? '',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context.push('/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('登录/注册'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard(BuildContext context, SubscriptionState state) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '当前套餐',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: state.isActive ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  state.isActive ? '生效中' : '已过期',
                  style: TextStyle(
                    fontSize: 12,
                    color: state.isActive ? AppColors.success : AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            state.planName ?? '免费版',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: state.totalQuota > 0 ? state.usedQuota / state.totalQuota : 0,
            backgroundColor: AppColors.divider,
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          ),
          const SizedBox(height: 8),
          Text(
            '已用 ${state.usedQuota} / ${state.totalQuota} 分钟',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  void _showLogoutConfirm(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('退出后将无法使用云端AI服务'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(authNotifierProvider.notifier).logout();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('退出'),
          ),
        ],
      ),
    );
  }
}
```

### 4.4 套餐商店 (SubscriptionStoreScreen)

**更新点**：三种模式Tab切换

```dart
class SubscriptionStoreScreen extends ConsumerStatefulWidget {
  const SubscriptionStoreScreen({super.key});

  @override
  ConsumerState<SubscriptionStoreScreen> createState() => _SubscriptionStoreScreenState();
}

class _SubscriptionStoreScreenState extends ConsumerState<SubscriptionStoreScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('购买套餐'),
        backgroundColor: AppColors.background,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: '按月订阅'),
            Tab(text: '套餐包'),
            Tab(text: '充值'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSubscriptionTab(),
          _buildPackageTab(),
          _buildRechargeTab(),
        ],
      ),
    );
  }

  // 按月订阅Tab
  Widget _buildSubscriptionTab() {
    final plansAsync = ref.watch(subscriptionPlansProvider);
    return plansAsync.when(
      data: (plans) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: plans.length,
        itemBuilder: (context, index) => _buildPlanCard(plans[index], isSubscription: true),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('加载失败: $error')),
    );
  }

  // 套餐包Tab
  Widget _buildPackageTab() {
    final plansAsync = ref.watch(packagePlansProvider);
    return plansAsync.when(
      data: (plans) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: plans.length,
        itemBuilder: (context, index) => _buildPlanCard(plans[index], isSubscription: false),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('加载失败: $error')),
    );
  }

  // 充值Tab
  Widget _buildRechargeTab() {
    final balance = ref.watch(userBalanceProvider);
    final rechargeAmounts = [50, 100, 200, 500];
    int selectedAmount = 100;

    return StatefulBuilder(
      builder: (context, setState) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 当前余额
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '账户余额',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '¥${balance.value ?? 0}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '选择充值金额',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: rechargeAmounts.map((amount) {
                final isSelected = selectedAmount == amount;
                return ChoiceChip(
                  label: Text('¥$amount'),
                  selected: isSelected,
                  onSelected: (_) => setState(() => selectedAmount = amount),
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Text(
              '或输入自定义金额',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText: '¥',
                hintText: '请输入金额',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                final amount = int.tryParse(value);
                if (amount != null) {
                  setState(() => selectedAmount = amount);
                }
              },
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => _recharge(selectedAmount),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('立即充值 ¥$selectedAmount'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(PlanModel plan, {required bool isSubscription}) {
    final isRecommended = plan.isRecommended;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRecommended ? AppColors.primary : AppColors.divider,
          width: isRecommended ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          if (isRecommended)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
              ),
              child: const Text(
                '推荐',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  plan.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '¥${plan.priceCents / 100}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isSubscription ? '/月' : '/${plan.durationDays}天',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...plan.features.map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(feature),
                    ],
                  ),
                )),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => _purchase(plan),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isRecommended ? AppColors.primary : AppColors.surfaceVariant,
                      foregroundColor: isRecommended ? Colors.white : AppColors.textPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '立即购买',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _purchase(PlanModel plan) {
    // 检查余额是否足够
    final balance = ref.read(userBalanceProvider).value ?? 0;
    if (balance >= plan.priceCents) {
      // 余额足够，询问是否使用余额
      _showBalancePaymentDialog(plan);
    } else {
      // 余额不足，调起支付
      _showPaymentDialog(plan);
    }
  }

  void _recharge(int amount) {
    // 调起微信支付/支付宝
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认充值'),
        content: Text('确认充值 ¥$amount?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: 调起支付
              Navigator.pop(context);
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  void _showBalancePaymentDialog(PlanModel plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认购买'),
        content: Text('使用余额购买 ${plan.name} 套餐?'),
        actions: [
          TextButton(
            onPressed: () => _showPaymentDialog(plan),
            child: const Text('其他支付方式'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: 使用余额支付
              Navigator.pop(context);
            },
            child: const Text('使用余额'),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(PlanModel plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认购买'),
        content: Text('确认购买 ${plan.name} 套餐?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: 创建订单并支付
              Navigator.pop(context);
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }
}
```

---

## 五、状态管理 (Riverpod)

### 5.1 Auth Provider

**更新点**：增加图形验证码支持、注册后显示欢迎弹窗

```dart
// providers/auth_provider.dart

@freezed
class AuthState with _$AuthState {
  const factory AuthState({
    @Default(false) bool isLoggedIn,
    UserModel? user,
    String? accessToken,
    String? refreshToken,
  }) = _AuthState;
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  Future<void> login({required String phone, required String password}) async {
    final response = await ApiService.instance.post('/auth/login', data: {
      'phone': phone,
      'password': password,
    });

    final data = response.data['data'];
    state = AuthState(
      isLoggedIn: true,
      user: UserModel.fromJson(data['user']),
      accessToken: data['accessToken'],
      refreshToken: data['refreshToken'],
    );

    // 保存到本地
    await SecureStorage.saveToken(data['accessToken']);
    await SecureStorage.saveRefreshToken(data['refreshToken']);
  }

  Future<void> register({
    required String phone,
    required String password,
    required String smsCode,
  }) async {
    final response = await ApiService.instance.post('/auth/register', data: {
      'phone': phone,
      'password': password,
      'smsCode': smsCode,
    });

    final data = response.data['data'];
    state = AuthState(
      isLoggedIn: true,
      user: UserModel.fromJson(data['user']),
      accessToken: data['accessToken'],
      refreshToken: data['refreshToken'],
    );

    // 保存到本地
    await SecureStorage.saveToken(data['accessToken']);
    await SecureStorage.saveRefreshToken(data['refreshToken']);
  }

  Future<void> logout() async {
    state = const AuthState();
    await SecureStorage.clearTokens();
  }

  Future<Map<String, dynamic>> sendSmsCode({
    required String phone,
    String? captcha,
  }) async {
    final response = await ApiService.instance.post('/auth/send-sms-code', data: {
      'phone': phone,
      if (captcha != null) 'captcha': captcha,
    });

    return response.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> refreshCaptcha() async {
    final response = await ApiService.instance.get('/auth/captcha');
    return response.data['data'] as Map<String, dynamic>;
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
```

### 5.2 Subscription Provider

**更新点**：增加余额、三种套餐类型

```dart
// providers/subscription_provider.dart

@freezed
class SubscriptionState with _$SubscriptionState {
  const factory SubscriptionState({
    @Default(false) bool isActive,
    String? planId,
    String? planName,
    @Default(0) int totalQuota,
    @Default(0) int usedQuota,
    DateTime? expiresAt,
    @Default(0) int balanceCents, // 余额（分）
  }) = _SubscriptionState;
}

class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  SubscriptionNotifier() : super(const SubscriptionState());

  Future<void> fetchSubscription() async {
    try {
      final response = await ApiService.instance.get('/subscription');
      final data = response.data['data'];
      state = SubscriptionState(
        isActive: data['status'] == 'active',
        planId: data['planId'],
        planName: data['planName'],
        totalQuota: data['totalQuota'] ?? 0,
        usedQuota: data['usedQuota'] ?? 0,
        expiresAt: data['expiresAt'] != null
            ? DateTime.parse(data['expiresAt'])
            : null,
        balanceCents: data['balanceCents'] ?? 0,
      );
    } catch (e) {
      // 未登录或请求失败，保持默认状态
      state = const SubscriptionState();
    }
  }
}

final subscriptionNotifierProvider = StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
  return SubscriptionNotifier();
});

// 按月订阅套餐
final subscriptionPlansProvider = FutureProvider<List<PlanModel>>((ref) async {
  final response = await ApiService.instance.get('/subscription/plans?type=subscription');
  final List<dynamic> data = response.data['data'];
  return data.map((e) => PlanModel.fromJson(e)).toList();
});

// 固定套餐包
final packagePlansProvider = FutureProvider<List<PlanModel>>((ref) async {
  final response = await ApiService.instance.get('/subscription/plans?type=package');
  final List<dynamic> data = response.data['data'];
  return data.map((e) => PlanModel.fromJson(e)).toList();
});

// 用户余额
final userBalanceProvider = FutureProvider<int>((ref) async {
  try {
    final response = await ApiService.instance.get('/subscription/balance');
    return response.data['data']['balanceCents'] as int? ?? 0;
  } catch (e) {
    return 0;
  }
});

final cloudApiEnabledProvider = StateProvider<bool>((ref) => false);
```

---

## 六、路由配置

```dart
// 在 app_router.dart 中添加新路由

enum AppRoute {
  // ... 现有路由
  login,
  register,
  profile,
  subscriptionStore,
  subscriptionMine,
  subscriptionOrders,
  recharge,
}

// 在 routes 列表中添加
GoRoute(
  path: '/login',
  name: AppRoute.login.name,
  pageBuilder: (context, state) =>
      _fadeScaleTransitionPage(const LoginScreen(), state),
),
GoRoute(
  path: '/register',
  name: AppRoute.register.name,
  pageBuilder: (context, state) =>
      _fadeScaleTransitionPage(const RegisterScreen(), state),
),
GoRoute(
  path: '/profile',
  name: AppRoute.profile.name,
  pageBuilder: (context, state) =>
      _slideLeftTransitionPage(const ProfileScreen(), state),
),
GoRoute(
  path: '/subscription/store',
  name: AppRoute.subscriptionStore.name,
  pageBuilder: (context, state) =>
      _slideLeftTransitionPage(const SubscriptionStoreScreen(), state),
),
GoRoute(
  path: '/subscription/mine',
  name: AppRoute.subscriptionMine.name,
  pageBuilder: (context, state) =>
      _slideLeftTransitionPage(const SubscriptionMineScreen(), state),
),
GoRoute(
  path: '/subscription/orders',
  name: AppRoute.subscriptionOrders.name,
  pageBuilder: (context, state) =>
      _slideLeftTransitionPage(const SubscriptionOrdersScreen(), state),
),
GoRoute(
  path: '/subscription/recharge',
  name: AppRoute.recharge.name,
  pageBuilder: (context, state) =>
      _slideLeftTransitionPage(const RechargeScreen(), state),
),
```

---

## 七、文件结构

```
lib/
├── features/
│   ├── auth/
│   │   ├── providers/
│   │   │   └── auth_provider.dart
│   │   ├── screens/
│   │   │   ├── login_screen.dart
│   │   │   ├── register_screen.dart
│   │   │   └── profile_screen.dart
│   │   └── models/
│   │       └── user_model.dart
│   ├── subscription/
│   │   ├── providers/
│   │   │   └── subscription_provider.dart
│   │   ├── screens/
│   │   │   ├── subscription_store_screen.dart
│   │   │   ├── subscription_mine_screen.dart
│   │   │   ├── subscription_orders_screen.dart
│   │   │   └── recharge_screen.dart
│   │   └── models/
│   │       └── plan_model.dart
│   └── settings/
│       └── screens/
│           └── settings_screen.dart (改造，新增账户中心Tab)
├── core/
│   └── services/
│       └── api_service.dart (新增云端API调用)
└── routes/
    └── app_router.dart (新增路由)
```

---

## 八、实施计划

| 阶段 | 任务 | 预计时间 |
|------|------|---------|
| **Phase 1** | 基础框架 | 2小时 |
| | - Auth Provider（含验证码） | 30分钟 |
| | - Subscription Provider（含余额） | 30分钟 |
| | - API Service 封装 | 1小时 |
| **Phase 2** | 登录/注册 | 3小时 |
| | - LoginScreen | 1小时 |
| | - RegisterScreen（含图形验证码） | 2小时 |
| **Phase 3** | 账户中心 | 3小时 |
| | - AccountTab（改造Settings） | 1.5小时 |
| | - ProfileScreen | 1.5小时 |
| **Phase 4** | 订阅/付费 | 5小时 |
| | - SubscriptionStoreScreen（三种模式） | 2.5小时 |
| | - RechargeScreen | 1.5小时 |
| | - SubscriptionMineScreen | 1小时 |
| **Phase 5** | 集成测试 | 2小时 |
| | - 路由配置 | 30分钟 |
| | - 状态联动 | 1小时 |
| | - 异常处理 | 30分钟 |

**总计: 约 15 小时（2-3天）**

---

*文档版本: v1.1*
*更新日期: 2026-05-21*
*更新内容: 补充验证码防冲击、登录权限划分、三种套餐模式、注册赠额*
*状态: 待实施*
