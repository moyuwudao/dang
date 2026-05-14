import 'dart:io';

void main() {
  // 测试Windows路径格式
  var file1 = File('C:/flutter-sdk/packages/flutter_tools/bin/flutter_tools.dart');
  print('Windows path exists: ${file1.existsSync()}');
  
  // 测试WSL路径格式
  var file2 = File('/mnt/c/flutter-sdk/packages/flutter_tools/bin/flutter_tools.dart');
  print('WSL path exists: ${file2.existsSync()}');
}
