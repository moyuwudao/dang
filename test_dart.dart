import 'dart:io';

void main() {
  var file = File('/mnt/c/flutter-sdk/packages/flutter_tools/bin/flutter_tools.dart');
  print('File exists: ${file.existsSync()}');
  if (file.existsSync()) {
    print('File size: ${file.lengthSync()}');
    print('File content:');
    print(file.readAsStringSync());
  }
}
