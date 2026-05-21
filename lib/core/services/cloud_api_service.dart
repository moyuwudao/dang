import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CloudApiService {
  static final CloudApiService _instance = CloudApiService._internal();
  factory CloudApiService() => _instance;
  CloudApiService._internal();

  static CloudApiService get instance => _instance;

  late final Dio _dio;
  String? _baseUrl;
  String? _accessToken;

  Future<void> initialize() async {
    _baseUrl = await _getBaseUrl();
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl ?? 'https://101.133.238.249:3000/api/v1',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (_accessToken != null) {
          options.headers['Authorization'] = 'Bearer $_accessToken';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await clearToken();
        }
        handler.next(error);
      },
    ));
  }

  Future<String?> _getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('cloud_api_base_url');
  }

  Future<void> setBaseUrl(String url) async {
    _baseUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cloud_api_base_url', url);
    _dio.options.baseUrl = url;
  }

  // TODO: 迁移到 flutter_secure_storage 存储敏感 token，SharedPreferences 不安全
  Future<void> setToken(String token) async {
    _accessToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cloud_access_token', token);
  }

  // TODO: 迁移到 flutter_secure_storage 存储敏感 token，SharedPreferences 不安全
  Future<void> clearToken() async {
    _accessToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cloud_access_token');
  }

  // TODO: 迁移到 flutter_secure_storage 存储敏感 token，SharedPreferences 不安全
  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('cloud_access_token');
  }

  bool get isAuthenticated => _accessToken != null;

  String? get accessToken => _accessToken;

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    return _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) async {
    return _dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) async {
    return _dio.put(path, data: data);
  }

  Future<Response> delete(String path) async {
    return _dio.delete(path);
  }
}
