import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/app_logger.dart';
import '../../../core/services/cloud_api_service.dart';
import '../../../core/services/api_service.dart';
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
        await ref.read(apiServiceProvider).configureFromServer(data);
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
    // 1. 彻底删除所有云端相关数据（SecureStorage + SharedPreferences）
    await ref.read(apiServiceProvider).clearCloudApiConfig();
    await SecureStorageService().deleteCloudApiEnabled();
    await CloudApiService.instance.clearToken();

    // 2. 清除内存中的 API 配置
    ref.read(apiServiceProvider).clear();

    // 3. 刷新相关 Provider（使订阅数据重新加载，未登录时为空）
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
