import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/throttle_scope.dart';
import '../providers/health_check_provider.dart';

/// ============================================================================
/// 限流状态徽标（A2 阶段新增）
///
/// 展示在 Key 旁边的限流状态小标签：
///   - 显示限流范围（速率/并发/日配额）
///   - 显示剩余时间
///   - 点击可查看详情
/// ============================================================================
class ThrottleBadge extends ConsumerWidget {
  final String keyId;
  final bool dense;

  const ThrottleBadge({
    super.key,
    required this.keyId,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final throttle = ref.watch(healthCheckProvider.select((s) => s.throttles[keyId]));

    if (throttle == null || !throttle.isActive) {
      return const SizedBox.shrink();
    }

    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: () => _showDetail(context, ref, throttle),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: dense ? 4 : 6,
          vertical: dense ? 1 : 2,
        ),
        decoration: BoxDecoration(
          color: throttle.scope.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: throttle.scope.color.withValues(alpha: 0.4),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _iconForScope(throttle.scope),
              size: dense ? 9 : 11,
              color: throttle.scope.color,
            ),
            SizedBox(width: dense ? 2 : 3),
            Text(
              _labelForScope(throttle.scope, throttle.remaining),
              style: TextStyle(
                fontSize: dense ? 9 : 10,
                color: throttle.scope.color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForScope(ThrottleScope scope) {
    switch (scope) {
      case ThrottleScope.rate:
        return Icons.speed;
      case ThrottleScope.concurrent:
        return Icons.people;
      case ThrottleScope.daily:
        return Icons.calendar_today;
      case ThrottleScope.unknown:
        return Icons.help_outline;
    }
  }

  String _labelForScope(ThrottleScope scope, Duration? remaining) {
    if (remaining == null) {
      switch (scope) {
        case ThrottleScope.rate:
          return '速率';
        case ThrottleScope.concurrent:
          return '并发';
        case ThrottleScope.daily:
          return '日配额';
        case ThrottleScope.unknown:
          return '限流';
      }
    }
    if (remaining.inSeconds <= 0) return '即将恢复';
    if (remaining.inSeconds < 60) return '${remaining.inSeconds}s';
    if (remaining.inMinutes < 60) return '${remaining.inMinutes}m';
    if (remaining.inHours < 24) return '${remaining.inHours}h';
    return '明天';
  }

  void _showDetail(BuildContext context, WidgetRef ref, KeyThrottleState throttle) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(_iconForScope(throttle.scope), color: throttle.scope.color),
            const SizedBox(width: 8),
            Text('${throttle.scope.label}详情'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (throttle.message != null && throttle.message!.isNotEmpty) ...[
              const Text('消息:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 4),
              Text(throttle.message!,
                  style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 12),
            ],
            if (throttle.occurredAt != null) ...[
              const Text('触发时间:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 4),
              Text(_formatTime(throttle.occurredAt!),
                  style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 12),
            ],
            if (throttle.until != null) ...[
              const Text('恢复时间:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 4),
              Text(_formatTime(throttle.until!),
                  style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 12),
            ],
            if (throttle.remaining != null) ...[
              const Text('剩余:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 4),
              Text(_formatDuration(throttle.remaining!),
                  style: const TextStyle(fontSize: 12)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.invalidate(healthCheckProvider);
              Navigator.pop(ctx);
            },
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime t) {
    return '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')} '
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration d) {
    if (d.inSeconds <= 0) return '即将恢复';
    if (d.inHours >= 24) return '${d.inDays} 天 ${d.inHours % 24} 小时';
    if (d.inHours > 0) return '${d.inHours} 小时 ${d.inMinutes % 60} 分钟';
    if (d.inMinutes > 0) return '${d.inMinutes} 分钟 ${d.inSeconds % 60} 秒';
    return '${d.inSeconds} 秒';
  }
}
