import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../widgets/usage_tab.dart';

/// 用量统计独立页面
/// 从设置页和我的订阅页均可进入
class UsageStatsScreen extends StatelessWidget {
  const UsageStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('用量统计'),
        centerTitle: true,
      ),
      body: const UsageTab(),
    );
  }
}
