import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/app_logger.dart';
import '../../../core/services/cloud_api_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/cloud_config_sync_service.dart';
import '../../../core/services/secure_storage_service.dart';
import '../../settings/providers/settings_provider.dart';
import '../../subscription/providers/subscription_provider.dart';
import '../models/user_model.dart';

class AuthState {
  final bool isLoggedIn;
  final UserModel? user;
  final String? accessToken;
  final String? refreshToken;

  const AuthState({
    this.isLoggedIn = false,
    this.user,
    this.accessToken,
    this.refreshToken,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    UserModel? user,
    String? accessToken,
    String? refreshToken,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      user: user ?? this.user,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
    );
  }
}

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    AppLogger().i('Auth', 'build() 开始 - 检查登录状态');
    await CloudApiService.instance.loadToken();
    AppLogger().i('Auth', 'Token加载完成, isAuthenticated=${CloudApiService.instance.isAuthenticated}');
    if (CloudApiService.instance.isAuthenticated) {
      try {
        AppLogger().i('Auth', '请求 /auth/profile');
        final response = await CloudApiService.instance.get('/auth/profile');
        AppLogger().i('Auth', '/auth/profile 响应: ${response.statusCode}');
        final data = response.data['data'];
        return AuthState(
          isLoggedIn: true,
          user: UserModel.fromJson(data['user']),
          accessToken: CloudApiService.instance.accessToken,
        );
      } catch (e) {
        AppLogger().e('Auth', '/auth/profile 失败: $e');
        await CloudApiService.instance.clearToken();
        return const AuthState();
      }
    }
    AppLogger().i('Auth', '未登录');
    return const AuthState();
  }

  Future<void> login({required String phone, required String password}) async {
    AppLogger().i('Auth', '密码登录开始: phone=$phone');
    state = const AsyncLoading();
    try {
      final response = await CloudApiService.instance.post('/auth/login', data: {
        'phone': phone,
        'password': password,
      });
      AppLogger().i('Auth', '/auth/login 响应: ${response.statusCode}');

      final data = response.data['data'];
      final accessToken = data['accessToken'] as String;
      await CloudApiService.instance.setToken(accessToken);
      AppLogger().i('Auth', '密码登录成功');

      await _fetchAndConfigureApiKey();
      await _fetchSubscription();

      state = AsyncData(AuthState(
        isLoggedIn: true,
        user: UserModel.fromJson(data['user']),
        accessToken: accessToken,
        refreshToken: data['refreshToken'] as String?,
      ));
    } catch (e, st) {
      AppLogger().e('Auth', '密码登录失败: $e');
      state = AsyncError(e, st);
    }
  }

  Future<void> _fetchAndConfigureApiKey() async {
    try {
      AppLogger().i('Auth', '尝试从服务器获取 API Key');
      final response = await CloudApiService.instance.get('/api-key');
      final data = response.data['data'];
      if (data != null && data['apiKey'] != null) {
        AppLogger().i('Auth', '成功获取 API Key, provider=${data['provider']}');

        // 修复 Issue 2：从订阅中找当前模型的 multiplier
        // 没有 multiplier 时（套餐没设置或模型不在套餐内）默认 1.0
        double multiplier = 1.0;
        try {
          final subResp = await CloudApiService.instance.get('/subscription');
          final subData = subResp.data['data'] as Map<String, dynamic>?;
          if (subData != null) {
            final policies = (subData['apiPolicies'] as List<dynamic>?) ?? [];
            final model = data['model'] as String?;
            final provider = data['provider'] as String?;
            for (final p in policies) {
              final m = Map<String, dynamic>.from(p as Map);
              // 按 model 或 provider 匹配
              final match = (model != null && m['model'] == model) ||
                  (model != null && m['modelPattern'] == model) ||
                  (provider != null && m['provider'] == provider);
              if (match) {
                multiplier = (m['multiplier'] as num?)?.toDouble() ?? 1.0;
                AppLogger().i('Auth', '从订阅 apiPolicies 找到 multiplier=$multiplier (model=$model)');
                break;
              }
            }
          }
        } catch (e) {
          AppLogger().w('Auth', '从订阅查 multiplier 失败，使用默认 1.0: $e');
        }

        await ref.read(apiServiceProvider).configureFromServer({
          ...data,
          'multiplier': multiplier,
        });
        // 登录成功且服务器返回了 API Key，自动开启云端 AI 开关
        // 这样云端套餐的 defaultConfigs/apiPolicies 才能自动应用到手机端
        await ref.read(cloudApiEnabledProvider.notifier).setEnabled(true);
        AppLogger().i('Auth', '已自动开启云端 AI 开关');
      } else {
        AppLogger().w('Auth', '服务器未返回 API Key，用户需要手动配置');
      }
    } catch (e) {
      AppLogger().w('Auth', '获取 API Key 失败: $e');
    }
  }

  Future<void> smsLogin({required String phone, required String smsCode}) async {
    AppLogger().i('Auth', '短信登录开始: phone=$phone');
    state = const AsyncLoading();
    try {
      final response = await CloudApiService.instance.post('/auth/sms-login', data: {
        'phone': phone,
        'smsCode': smsCode,
      });
      AppLogger().i('Auth', '/auth/sms-login 响应: ${response.statusCode}');

      final data = response.data['data'];
      final accessToken = data['accessToken'] as String;
      await CloudApiService.instance.setToken(accessToken);
      AppLogger().i('Auth', '短信登录成功');

      await _fetchAndConfigureApiKey();
      await _fetchSubscription();

      state = AsyncData(AuthState(
        isLoggedIn: true,
        user: UserModel.fromJson(data['user']),
        accessToken: accessToken,
        refreshToken: data['refreshToken'] as String?,
      ));
    } catch (e, st) {
      AppLogger().e('Auth', '短信登录失败: $e');
      state = AsyncError(e, st);
    }
  }

  Future<void> register({
    required String phone,
    required String password,
    required String smsCode,
  }) async {
    state = const AsyncLoading();
    try {
      final response = await CloudApiService.instance.post('/auth/register', data: {
        'phone': phone,
        'password': password,
        'smsCode': smsCode,
      });

      final data = response.data['data'];
      final accessToken = data['accessToken'] as String;
      await CloudApiService.instance.setToken(accessToken);

      await _fetchAndConfigureApiKey();
      await _fetchSubscription();

      state = AsyncData(AuthState(
        isLoggedIn: true,
        user: UserModel.fromJson(data['user']),
        accessToken: accessToken,
        refreshToken: data['refreshToken'] as String?,
      ));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> _fetchSubscription() async {
    try {
      AppLogger().i('Auth', '登录成功，自动刷新套餐数据');
      await ref.read(subscriptionNotifierProvider.notifier).fetchSubscription();
      AppLogger().i('Auth', '套餐数据刷新完成');
    } catch (e) {
      AppLogger().w('Auth', '套餐数据刷新失败: $e');
    }
  }

  Future<void> logout() async {
    // 1. 清除云端配置条目和 functionAssignments（从 MultiApiConfig 中移除）
    await CloudConfigSyncService.clearCloudConfigs();

    // 2. 彻底删除所有云端相关数据（SecureStorage + SharedPreferences）
    await ref.read(apiServiceProvider).clearCloudApiConfig();
    await SecureStorageService().deleteCloudApiEnabled();
    await CloudApiService.instance.clearToken();

    // 3. 彻底删除 multi_api_config_v2（退出后不应残留任何配置）
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('multi_api_config_v2');

    // 4. 清除内存中的 API 配置
    ref.read(apiServiceProvider).clear();

    // 5. 刷新相关 Provider（使订阅数据重新加载，未登录时为空）
    ref.invalidate(configuredProviderProvider);
    ref.invalidate(cloudApiEnabledProvider);
    ref.invalidate(subscriptionNotifierProvider);

    state = const AsyncData(AuthState());
  }

  Future<Map<String, dynamic>> sendSmsCode({
    required String phone,
    String? captcha,
  }) async {
    AppLogger().i('Auth', '请求发送短信验证码: phone=$phone');
    final response = await CloudApiService.instance.post('/auth/send-sms-code', data: {
      'phone': phone,
      if (captcha != null) 'captcha': captcha,
    });
    AppLogger().i('Auth', '/auth/send-sms-code 响应: ${response.statusCode}');

    return response.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> refreshCaptcha() async {
    AppLogger().i('Auth', '请求刷新图片验证码');
    final response = await CloudApiService.instance.get('/auth/captcha');
    AppLogger().i('Auth', '/auth/captcha 响应: ${response.statusCode}');
    return response.data['data'] as Map<String, dynamic>;
  }
}

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
