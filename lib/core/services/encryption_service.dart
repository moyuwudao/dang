import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pointycastle/export.dart';

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();

  factory EncryptionService() => _instance;

  EncryptionService._internal();

  static const String _encryptionKeyKey = 'encryption_key';
  // IV 不再持久化，每次加密随机生成
  static const int _ivLength = 16;
  static const int _keyLength = 32;

  Uint8List? _key;

  Future<void> init() async {
    await _ensureKeyExists();
  }

  Future<void> _ensureKeyExists() async {
    final prefs = await SharedPreferences.getInstance();

    String? keyString = prefs.getString(_encryptionKeyKey);

    if (keyString == null) {
      _key = _generateRandomBytes(_keyLength);

      // TODO: 迁移到 flutter_secure_storage 存储密钥，SharedPreferences 为明文存储不安全
      await prefs.setString(_encryptionKeyKey, base64Encode(_key!));
    } else {
      _key = base64Decode(keyString);
    }
  }

  Uint8List _generateRandomBytes(int length) {
    final secureRandom = FortunaRandom();
    final random = Random.secure();
    final seed = List<int>.generate(32, (_) => random.nextInt(256));
    secureRandom.seed(KeyParameter(Uint8List.fromList(seed)));
    return secureRandom.nextBytes(length);
  }

  /// 加密字符串，返回 base64(iv + encrypted)
  String encrypt(String plainText) {
    if (_key == null) {
      throw Exception('Encryption service not initialized');
    }

    final iv = _generateRandomBytes(_ivLength);
    final cipher = CBCBlockCipher(AESFastEngine())
      ..init(true, ParametersWithIV(KeyParameter(_key!), iv));

    final paddedData = _padData(utf8.encode(plainText));
    final encrypted = _processBlocks(cipher, paddedData);

    // 拼接 iv + encrypted
    final combined = Uint8List(iv.length + encrypted.length);
    combined.setAll(0, iv);
    combined.setAll(iv.length, encrypted);

    return base64Encode(combined);
  }

  /// 解密字符串，输入为 base64(iv + encrypted)
  String decrypt(String encryptedText) {
    if (_key == null) {
      throw Exception('Encryption service not initialized');
    }

    final combined = base64Decode(encryptedText);
    if (combined.length < _ivLength + 16) {
      throw FormatException('Invalid encrypted data: too short');
    }

    final iv = combined.sublist(0, _ivLength);
    final encrypted = combined.sublist(_ivLength);

    final cipher = CBCBlockCipher(AESFastEngine())
      ..init(false, ParametersWithIV(KeyParameter(_key!), iv));

    final decrypted = _processBlocks(cipher, encrypted);
    final unpadded = _unpadData(decrypted);

    return utf8.decode(unpadded);
  }

  /// 加密字节数据，返回 iv + encrypted
  Uint8List encryptBytes(Uint8List data) {
    if (_key == null) {
      throw Exception('Encryption service not initialized');
    }

    final iv = _generateRandomBytes(_ivLength);
    final cipher = CBCBlockCipher(AESFastEngine())
      ..init(true, ParametersWithIV(KeyParameter(_key!), iv));

    final paddedData = _padData(data);
    final encrypted = _processBlocks(cipher, paddedData);

    final combined = Uint8List(iv.length + encrypted.length);
    combined.setAll(0, iv);
    combined.setAll(iv.length, encrypted);

    return combined;
  }

  /// 解密字节数据，输入为 iv + encrypted
  Uint8List decryptBytes(Uint8List combined) {
    if (_key == null) {
      throw Exception('Encryption service not initialized');
    }

    if (combined.length < _ivLength + 16) {
      throw FormatException('Invalid encrypted data: too short');
    }

    final iv = combined.sublist(0, _ivLength);
    final encrypted = combined.sublist(_ivLength);

    final cipher = CBCBlockCipher(AESFastEngine())
      ..init(false, ParametersWithIV(KeyParameter(_key!), iv));

    final decrypted = _processBlocks(cipher, encrypted);
    return _unpadData(decrypted);
  }

  Uint8List _padData(List<int> data) {
    final blockSize = 16;
    final padLength = blockSize - (data.length % blockSize);
    final padded = Uint8List(data.length + padLength);
    padded.setAll(0, data);
    for (var i = 0; i < padLength; i++) {
      padded[data.length + i] = padLength;
    }
    return padded;
  }

  /// PKCS7 去填充，带合法性验证
  Uint8List _unpadData(Uint8List data) {
    if (data.isEmpty) {
      throw FormatException('Invalid padding: empty data');
    }

    final padLength = data.last;

    // PKCS7 填充值必须在 1..blockSize 之间
    if (padLength == 0 || padLength > 16) {
      throw FormatException('Invalid PKCS7 padding value: $padLength');
    }

    // 验证所有填充字节一致
    for (var i = 1; i <= padLength; i++) {
      if (data[data.length - i] != padLength) {
        throw FormatException('Invalid PKCS7 padding: inconsistent padding bytes');
      }
    }

    return data.sublist(0, data.length - padLength);
  }

  Uint8List _processBlocks(BlockCipher cipher, Uint8List data) {
    final blockSize = cipher.blockSize;
    final result = Uint8List(data.length);

    for (var i = 0; i < data.length; i += blockSize) {
      final block = data.sublist(i, i + blockSize);
      final encryptedBlock = cipher.process(block);
      result.setAll(i, encryptedBlock);
    }

    return result;
  }

  String maskApiKey(String apiKey) {
    if (apiKey.length <= 8) {
      return '*' * apiKey.length;
    }
    return '${apiKey.substring(0, 4)}${'*' * (apiKey.length - 8)}${apiKey.substring(apiKey.length - 4)}';
  }

  bool isValidApiKey(String apiKey) {
    return apiKey.isNotEmpty && apiKey.length >= 8;
  }
}
