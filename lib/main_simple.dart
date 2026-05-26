import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/cloud_api_service.dart';
import 'features/auth/screens/sms_login_test_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CloudApiService.instance.initialize();
  runApp(const ProviderScope(child: SimpleApp()));
}

class SimpleApp extends StatelessWidget {
  const SimpleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '短信登录测试',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const SmsLoginTestScreen(),
    );
  }
}
