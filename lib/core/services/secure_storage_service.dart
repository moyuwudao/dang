import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _apiKeyKey = 'secure_api_key';
  static const String _accessKeySecretKey = 'secure_access_key_secret';
  static const String _cloudAccessTokenKey = 'secure_cloud_access_token';
  static const String _cloudRefreshTokenKey = 'secure_cloud_refresh_token';
  static const String _encryptionKeyKey = 'secure_encryption_key';
  static const String _webdavPasswordKey = 'secure_webdav_password';
  static const String _cloudApiEnabledKey = 'secure_cloud_api_enabled';

  Future<void> saveApiKey(String apiKey) async {
    await _storage.write(key: _apiKeyKey, value: apiKey);
  }

  Future<String?> getApiKey() async {
    return await _storage.read(key: _apiKeyKey);
  }

  Future<void> deleteApiKey() async {
    await _storage.delete(key: _apiKeyKey);
  }

  Future<void> saveAccessKeySecret(String secret) async {
    await _storage.write(key: _accessKeySecretKey, value: secret);
  }

  Future<String?> getAccessKeySecret() async {
    return await _storage.read(key: _accessKeySecretKey);
  }

  Future<void> deleteAccessKeySecret() async {
    await _storage.delete(key: _accessKeySecretKey);
  }

  Future<void> saveCloudTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: _cloudAccessTokenKey, value: accessToken);
    await _storage.write(key: _cloudRefreshTokenKey, value: refreshToken);
  }

  Future<String?> getCloudAccessToken() async {
    return await _storage.read(key: _cloudAccessTokenKey);
  }

  Future<String?> getCloudRefreshToken() async {
    return await _storage.read(key: _cloudRefreshTokenKey);
  }

  Future<void> deleteCloudTokens() async {
    await _storage.delete(key: _cloudAccessTokenKey);
    await _storage.delete(key: _cloudRefreshTokenKey);
  }

  Future<void> saveEncryptionKey(List<int> key) async {
    await _storage.write(key: _encryptionKeyKey, value: _bytesToBase64(key));
  }

  Future<List<int>?> getEncryptionKey() async {
    final encoded = await _storage.read(key: _encryptionKeyKey);
    if (encoded == null) return null;
    return _base64ToBytes(encoded);
  }

  Future<void> deleteEncryptionKey() async {
    await _storage.delete(key: _encryptionKeyKey);
  }

  Future<void> saveWebDAVPassword(String password) async {
    await _storage.write(key: _webdavPasswordKey, value: password);
  }

  Future<String?> getWebDAVPassword() async {
    return await _storage.read(key: _webdavPasswordKey);
  }

  Future<void> deleteWebDAVPassword() async {
    await _storage.delete(key: _webdavPasswordKey);
  }

  Future<void> saveCloudApiEnabled(bool enabled) async {
    await _storage.write(key: _cloudApiEnabledKey, value: enabled.toString());
  }

  Future<bool> getCloudApiEnabled() async {
    final value = await _storage.read(key: _cloudApiEnabledKey);
    return value == 'true';
  }

  Future<void> deleteCloudApiEnabled() async {
    await _storage.delete(key: _cloudApiEnabledKey);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  String _bytesToBase64(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  List<int> _base64ToBytes(String encoded) {
    final List<int> bytes = [];
    for (int i = 0; i < encoded.length; i += 2) {
      bytes.add(int.parse(encoded.substring(i, i + 2), radix: 16));
    }
    return bytes;
  }
}