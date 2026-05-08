import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pointycastle/export.dart';

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  
  factory EncryptionService() => _instance;
  
  EncryptionService._internal();

  static const String _encryptionKeyKey = 'encryption_key';
  static const String _ivKey = 'encryption_iv';
  
  Uint8List? _key;
  Uint8List? _iv;

  Future<void> init() async {
    await _ensureKeyExists();
  }

  Future<void> _ensureKeyExists() async {
    final prefs = await SharedPreferences.getInstance();
    
    String? keyString = prefs.getString(_encryptionKeyKey);
    String? ivString = prefs.getString(_ivKey);
    
    if (keyString == null || ivString == null) {
      _key = _generateRandomBytes(32);
      _iv = _generateRandomBytes(16);
      
      await prefs.setString(_encryptionKeyKey, base64Encode(_key!));
      await prefs.setString(_ivKey, base64Encode(_iv!));
    } else {
      _key = base64Decode(keyString);
      _iv = base64Decode(ivString);
    }
  }

  Uint8List _generateRandomBytes(int length) {
    final secureRandom = FortunaRandom();
    final seed = List<int>.generate(length * 2, (_) => _getRandomByte());
    secureRandom.seed(KeyParameter(Uint8List.fromList(seed)));
    return secureRandom.nextBytes(length);
  }

  int _getRandomByte() {
    return DateTime.now().microsecondsSinceEpoch % 256;
  }

  String encrypt(String plainText) {
    if (_key == null || _iv == null) {
      throw Exception('Encryption service not initialized');
    }
    
    final cipher = CBCBlockCipher(AESFastEngine())
      ..init(true, ParametersWithIV(KeyParameter(_key!), _iv!));
    
    final paddedData = _padData(utf8.encode(plainText));
    final encrypted = _processBlocks(cipher, paddedData);
    
    return base64Encode(encrypted);
  }

  String decrypt(String encryptedText) {
    if (_key == null || _iv == null) {
      throw Exception('Encryption service not initialized');
    }
    
    try {
      final encrypted = base64Decode(encryptedText);
      final cipher = CBCBlockCipher(AESFastEngine())
        ..init(false, ParametersWithIV(KeyParameter(_key!), _iv!));
      
      final decrypted = _processBlocks(cipher, encrypted);
      final unpadded = _unpadData(decrypted);
      
      return utf8.decode(unpadded);
    } catch (e) {
      debugPrint('Decryption failed: $e');
      return encryptedText;
    }
  }

  Uint8List encryptBytes(Uint8List data) {
    if (_key == null || _iv == null) {
      throw Exception('Encryption service not initialized');
    }
    
    final cipher = CBCBlockCipher(AESFastEngine())
      ..init(true, ParametersWithIV(KeyParameter(_key!), _iv!));
    
    final paddedData = _padData(data);
    return _processBlocks(cipher, paddedData);
  }

  Uint8List decryptBytes(Uint8List encryptedData) {
    if (_key == null || _iv == null) {
      throw Exception('Encryption service not initialized');
    }
    
    try {
      final cipher = CBCBlockCipher(AESFastEngine())
        ..init(false, ParametersWithIV(KeyParameter(_key!), _iv!));
      
      final decrypted = _processBlocks(cipher, encryptedData);
      return _unpadData(decrypted);
    } catch (e) {
      debugPrint('Decryption failed: $e');
      return encryptedData;
    }
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

  Uint8List _unpadData(Uint8List data) {
    final padLength = data.last;
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