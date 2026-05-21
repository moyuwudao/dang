import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/cloud_api_service.dart';
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

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _loadStoredAuth();
  }

  Future<void> _loadStoredAuth() async {
    await CloudApiService.instance.loadToken();
    if (CloudApiService.instance.isAuthenticated) {
      try {
        final response = await CloudApiService.instance.get('/auth/profile');
        final data = response.data['data'];
        state = AuthState(
          isLoggedIn: true,
          user: UserModel.fromJson(data['user']),
          accessToken: CloudApiService.instance.accessToken,
        );
      } catch (e) {
        await logout();
      }
    }
  }

  Future<void> login({required String phone, required String password}) async {
    final response = await CloudApiService.instance.post('/auth/login', data: {
      'phone': phone,
      'password': password,
    });

    final data = response.data['data'];
    final accessToken = data['accessToken'] as String;
    await CloudApiService.instance.setToken(accessToken);

    state = AuthState(
      isLoggedIn: true,
      user: UserModel.fromJson(data['user']),
      accessToken: accessToken,
      refreshToken: data['refreshToken'] as String?,
    );
  }

  Future<void> register({
    required String phone,
    required String password,
    required String smsCode,
  }) async {
    final response = await CloudApiService.instance.post('/auth/register', data: {
      'phone': phone,
      'password': password,
      'smsCode': smsCode,
    });

    final data = response.data['data'];
    final accessToken = data['accessToken'] as String;
    await CloudApiService.instance.setToken(accessToken);

    state = AuthState(
      isLoggedIn: true,
      user: UserModel.fromJson(data['user']),
      accessToken: accessToken,
      refreshToken: data['refreshToken'] as String?,
    );
  }

  Future<void> logout() async {
    state = const AuthState();
    await CloudApiService.instance.clearToken();
  }

  Future<Map<String, dynamic>> sendSmsCode({
    required String phone,
    String? captcha,
  }) async {
    final response = await CloudApiService.instance.post('/auth/send-sms-code', data: {
      'phone': phone,
      if (captcha != null) 'captcha': captcha,
    });

    return response.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> refreshCaptcha() async {
    final response = await CloudApiService.instance.get('/auth/captcha');
    return response.data['data'] as Map<String, dynamic>;
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
