import 'package:flutter/material.dart';

import '../widgets/api_key_pool_view.dart';

/// API Key 池管理页面（A1 阶段新增）
class ApiKeyPoolScreen extends StatelessWidget {
  const ApiKeyPoolScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Key 池'),
      ),
      body: const ApiKeyPoolView(),
    );
  }
}
