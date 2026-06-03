import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/api_key_pool.dart';
import '../../../core/models/health_check_result.dart';
import '../../../core/models/throttle_scope.dart';
import '../../../core/services/health_check_service.dart';
import '../providers/health_check_provider.dart';
import '../providers/multi_api_pools_provider.dart';

/// ============================================================================
/// 健康检查 Tab（A2 阶段新增）
///
/// 展示：
///   1. 全局健康状态快照
///   2. 每个 Key 的最近一次检查结果
///   3. 一键"全部检查"按钮
///   4. 单个 Key 的重测操作
/// ============================================================================
class HealthCheckTab extends ConsumerStatefulWidget {
  const HealthCheckTab({super.key});

  @override
  ConsumerState<HealthCheckTab> createState() => _HealthCheckTabState();
}

class _HealthCheckTabState extends ConsumerState<HealthCheckTab> {
  bool _isCheckingAll = false;

  @override
  void initState() {
    super.initState();
    // 首次加载时从缓存恢复
    Future.microtask(() {
      ref.read(healthCheckProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final healthState = ref.watch(healthCheckProvider);
    final pools = ref.watch(multiApiPoolsProvider);
    final snapshot = healthState.snapshot;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 快照概览
        if (snapshot != null)
          _SnapshotCard(
            snapshot: snapshot,
            lastCheckedAt: healthState.lastCheckedAt,
          ),
        const SizedBox(height: 12),

        // 操作按钮
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: _isCheckingAll
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.refresh),
                label: const Text('全部检查'),
                onPressed: _isCheckingAll ? null : _checkAll,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('自动轮询'),
                value: healthState.enabled,
                onChanged: (v) =>
                    ref.read(healthCheckProvider.notifier).setEnabled(v),
                dense: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 按 Pool 分组展示
        for (final pool in pools.pools) ...[
          _PoolHealthSection(
            pool: pool,
            onTestKey: _testKey,
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Future<void> _checkAll() async {
    final pools = ref.read(multiApiPoolsProvider).pools;
    setState(() => _isCheckingAll = true);
    try {
      final service = ref.read(healthCheckServiceProvider);
      final results = await service.checkAll(pools);
      for (final r in results) {
        ref.read(healthCheckProvider.notifier).updateResult(r);
        if (r.status == HealthStatus.throttled) {
          ref.read(healthCheckProvider.notifier).setThrottle(
                keyId: r.keyId,
                isThrottled: true,
                scope: r.details?['scope'] != null
                    ? _parseScope(r.details!['scope'])
                    : ThrottleScope.unknown,
                until: null,
                message: r.errorMessage,
              );
        } else if (r.status.isUsable) {
          ref.read(healthCheckProvider.notifier).clearThrottle(r.keyId);
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('检查完成: ${results.length} 个 Key')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCheckingAll = false);
    }
  }

  Future<void> _testKey(ApiKeyEntry key, ApiKeyPool pool) async {
    ref.read(healthCheckProvider.notifier).setChecking(key.id, true);
    try {
      final service = ref.read(healthCheckServiceProvider);
      final result = await service.checkKey(key: key, pool: pool);
      ref.read(healthCheckProvider.notifier).updateResult(result);
      if (result.status == HealthStatus.throttled) {
        ref.read(healthCheckProvider.notifier).setThrottle(
              keyId: key.id,
              isThrottled: true,
              scope: result.details?['scope'] != null
                  ? _parseScope(result.details!['scope'])
                  : ThrottleScope.unknown,
              until: null,
              message: result.errorMessage,
            );
      } else if (result.status.isUsable) {
        ref.read(healthCheckProvider.notifier).clearThrottle(key.id);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${key.name}: ${result.status.label} (${result.responseTimeMs}ms)'),
          ),
        );
      }
    } finally {
      ref.read(healthCheckProvider.notifier).setChecking(key.id, false);
    }
  }

  ThrottleScope _parseScope(dynamic value) {
    if (value is String) {
      return ThrottleScope.values.firstWhere(
        (s) => s.name == value,
        orElse: () => ThrottleScope.unknown,
      );
    }
    return ThrottleScope.unknown;
  }
}

// ============================================================================
// 快照卡片
// ============================================================================
class _SnapshotCard extends StatelessWidget {
  final HealthCheckSnapshot snapshot;
  final DateTime? lastCheckedAt;

  const _SnapshotCard({required this.snapshot, required this.lastCheckedAt});

  @override
  Widget build(BuildContext context) {
    final ratio = snapshot.healthRatio;
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.health_and_safety, color: Colors.green),
                SizedBox(width: 8),
                Text('健康状态总览',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                    value: '${snapshot.healthyKeys}',
                    label: '健康',
                    color: Colors.green),
                _StatItem(
                    value: '${snapshot.throttledKeys}',
                    label: '限流',
                    color: Colors.orange),
                _StatItem(
                    value: '${snapshot.errorKeys}',
                    label: '错误',
                    color: Colors.red),
                _StatItem(
                    value: '${snapshot.totalKeys}',
                    label: '总数',
                    color: Colors.blue),
              ],
            ),
            const SizedBox(height: 8),
            if (lastCheckedAt != null)
              Text('最后检查: ${_formatRelative(lastCheckedAt!)}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(
                ratio >= 0.8
                    ? Colors.green
                    : ratio >= 0.5
                        ? Colors.orange
                        : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatRelative(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes} 分钟前';
    if (diff.inHours < 24) return '${diff.inHours} 小时前';
    return '${diff.inDays} 天前';
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

// ============================================================================
// Pool 健康分组
// ============================================================================
class _PoolHealthSection extends ConsumerWidget {
  final ApiKeyPool pool;
  final Future<void> Function(ApiKeyEntry, ApiKeyPool) onTestKey;

  const _PoolHealthSection({required this.pool, required this.onTestKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthState = ref.watch(healthCheckProvider);
    return Card(
      elevation: 1,
      child: ExpansionTile(
        leading: const Icon(Icons.cloud_queue, color: Colors.indigo),
        title: Text(pool.displayName,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Text('${pool.keys.length} 个 Key',
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
        children: pool.keys.map((key) {
          final result = healthState.latestResults[key.id];
          final throttle = healthState.throttleFor(key.id);
          final isChecking = healthState.checking.contains(key.id);
          return ListTile(
            dense: true,
            leading: SizedBox(
              width: 24,
              height: 24,
              child: isChecking
                  ? const Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : Icon(
                      _iconForStatus(result?.status),
                      color: result?.status.color ?? Colors.grey,
                      size: 20,
                    ),
            ),
            title: Text(key.name,
                style: const TextStyle(fontSize: 13)),
            subtitle: result != null
                ? Text(
                    result.displaySummary,
                    style: const TextStyle(fontSize: 11),
                  )
                : (throttle.isActive
                    ? Text(throttle.scope.label,
                        style: TextStyle(
                            fontSize: 11, color: throttle.scope.color))
                    : const Text('未检查',
                        style:
                            TextStyle(fontSize: 11, color: Colors.grey))),
            trailing: IconButton(
              icon: const Icon(Icons.refresh, size: 18),
              onPressed: isChecking ? null : () => onTestKey(key, pool),
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _iconForStatus(HealthStatus? status) {
    if (status == null) return Icons.help_outline;
    switch (status) {
      case HealthStatus.healthy:
        return Icons.check_circle;
      case HealthStatus.slow:
        return Icons.access_time;
      case HealthStatus.throttled:
        return Icons.block;
      case HealthStatus.serverError:
      case HealthStatus.clientError:
        return Icons.error;
      case HealthStatus.timeout:
        return Icons.timer_off;
      case HealthStatus.network:
        return Icons.wifi_off;
      case HealthStatus.unknown:
        return Icons.help_outline;
    }
  }
}
