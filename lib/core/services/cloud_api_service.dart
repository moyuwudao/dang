import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_logger.dart';

class CloudApiService {
  static final CloudApiService _instance = CloudApiService._internal();
  factory CloudApiService() => _instance;
  CloudApiService._internal();

  static CloudApiService get instance => _instance;

  Dio? _dio;
  String? _baseUrl;
  String? _accessToken;
  bool _initialized = false;
  bool _initializing = false;

  Future<void> initialize() async {
    if (_initialized) return;
    if (_initializing) {
      while (_initializing) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      return;
    }
    _initializing = true;
    try {
      await loadToken();
      _baseUrl = await _getBaseUrl();
      _dio = Dio(BaseOptions(
        baseUrl: _baseUrl ?? 'http://101.133.238.249/api/v1',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
        },
      ));

      _dio!.interceptors.add(InterceptorsWrapper(
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
      _initialized = true;
    } finally {
      _initializing = false;
    }
  }

  Future<Dio> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
    return _dio!;
  }

  Future<String?> _getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('cloud_api_base_url');
  }

  Future<void> setBaseUrl(String url) async {
    _baseUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cloud_api_base_url', url);
    if (_dio != null) {
      _dio!.options.baseUrl = url;
    }
  }

  Future<void> setToken(String token) async {
    _accessToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cloud_access_token', token);
  }

  Future<void> clearToken() async {
    _accessToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cloud_access_token');
  }

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('cloud_access_token');
  }

  bool get isAuthenticated => _accessToken != null;

  String? get accessToken => _accessToken;

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    AppLogger().d('API', 'GET $path');
    final client = await _ensureInitialized();
    try {
      final response = await client.get(path, queryParameters: queryParameters);
      AppLogger().d('API', 'GET $path = ${response.statusCode}');
      return response;
    } catch (e) {
      AppLogger().e('API', 'GET $path 失败: $e');
      rethrow;
    }
  }

  Future<Response> post(String path, {dynamic data}) async {
    AppLogger().d('API', 'POST $path');
    final client = await _ensureInitialized();
    try {
      final response = await client.post(path, data: data);
      AppLogger().d('API', 'POST $path = ${response.statusCode}');
      return response;
    } catch (e) {
      AppLogger().e('API', 'POST $path 失败: $e');
      rethrow;
    }
  }

  Future<Response> put(String path, {dynamic data}) async {
    AppLogger().d('API', 'PUT $path');
    final client = await _ensureInitialized();
    try {
      final response = await client.put(path, data: data);
      AppLogger().d('API', 'PUT $path = ${response.statusCode}');
      return response;
    } catch (e) {
      AppLogger().e('API', 'PUT $path 失败: $e');
      rethrow;
    }
  }

  Future<Response> delete(String path) async {
    AppLogger().d('API', 'DELETE $path');
    final client = await _ensureInitialized();
    try {
      final response = await client.delete(path);
      AppLogger().d('API', 'DELETE $path = ${response.statusCode}');
      return response;
    } catch (e) {
      AppLogger().e('API', 'DELETE $path 失败: $e');
      rethrow;
    }
  }
}
