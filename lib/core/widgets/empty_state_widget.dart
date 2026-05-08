import 'package:flutter/material.dart';

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionText;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(32),
              ),
              child: Icon(
                icon,
                size: 60,
                color: theme.primaryColor,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(actionText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class EmptyStateType {
  static EmptyStateWidget records({VoidCallback? onAdd}) {
    return EmptyStateWidget(
      icon: Icons.mic_none,
      title: '暂无记录',
      description: '开始录制你的第一条语音笔记吧，畅记会帮你自动转写和分析',
      actionText: '开始录音',
      onAction: onAdd,
    );
  }

  static EmptyStateWidget search({VoidCallback? onRetry}) {
    return EmptyStateWidget(
      icon: Icons.search_off,
      title: '未找到相关记录',
      description: '尝试使用其他关键词搜索，或查看全部记录',
      actionText: '查看全部',
      onAction: onRetry,
    );
  }

  static EmptyStateWidget error({required String message, VoidCallback? onRetry}) {
    return EmptyStateWidget(
      icon: Icons.error_outline,
      title: '加载失败',
      description: message,
      actionText: '重试',
      onAction: onRetry,
    );
  }

  static EmptyStateWidget noInternet({VoidCallback? onRetry}) {
    return EmptyStateWidget(
      icon: Icons.wifi_off,
      title: '网络连接失败',
      description: '请检查网络连接后重试',
      actionText: '重新连接',
      onAction: onRetry,
    );
  }

  static EmptyStateWidget noPermissions({VoidCallback? onSettings}) {
    return EmptyStateWidget(
      icon: Icons.security,
      title: '权限不足',
      description: '需要授予录音和存储权限才能使用完整功能',
      actionText: '去设置',
      onAction: onSettings,
    );
  }

  static EmptyStateWidget weeklyReport() {
    return const EmptyStateWidget(
      icon: Icons.summarize_outlined,
      title: '选择时间范围生成周报',
      description: 'AI将自动汇总该时间段内的所有记录，帮你快速回顾',
    );
  }

  static EmptyStateWidget noApiKey({VoidCallback? onConfig}) {
    return EmptyStateWidget(
      icon: Icons.key_off,
      title: '尚未配置AI服务',
      description: '配置API Key后即可使用语音转写和AI分析功能',
      actionText: '快速配置',
      onAction: onConfig,
    );
  }
}