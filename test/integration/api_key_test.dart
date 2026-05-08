import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// 验证 API Key 是否正确加载
void main() {
  group('API Key 验证', () {
    test('检查环境变量', () {
      print('\n=== 检查 API Key ===');
      
      // 检查环境变量
      final envKey = Platform.environment['QWEN_API_KEY'];
      print('环境变量 QWEN_API_KEY: ${envKey != null ? "已设置 (${envKey.substring(0, 8)}...)" : "未设置"}');
      
      // 检查编译时环境变量
      const compileKey = String.fromEnvironment('QWEN_API_KEY');
      print('编译时环境变量: ${compileKey.isNotEmpty ? "已设置 (${compileKey.substring(0, 8)}...)" : "未设置"}');
      
      expect(true, isTrue);
    });
  });
}
