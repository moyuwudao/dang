import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/usage_record.dart';
import '../providers/daily_usage_provider.dart';
import '../providers/multi_api_pools_provider.dart';

/// ============================================================================
/// 用量统计 Tab（A2 阶段新增）
///
/// 展示：
///   1. 当日用量总览
///   2. 各 Pool 的用量对比（横向柱状图）
///   3. 最近 7 天的用量趋势（折线图）
///   4. 调用成功/失败统计
/// ============================================================================
class UsageTab extends ConsumerWidget {
  const UsageTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usage = ref.watch(dailyUsageProvider);
    final pools = ref.watch(multiApiPoolsProvider);

    if (usage.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final summaries = usage.poolSummaries();
    final topPools = usage.topPoolsByUsage(limit: 5);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 总览卡片
        _TotalOverviewCard(
          totalTokens: usage.totalTokensToday,
          totalCalls: usage.totalCallsToday,
          successRate: usage.totalCallsToday == 0
              ? 1.0
              : (usage.totalCallsToday -
                      usage.today.values
                          .fold(0, (s, r) => s + r.errorCount)) /
                  usage.totalCallsToday,
        ),
        const SizedBox(height: 16),

        // 跨 Pool 对比
        if (summaries.isNotEmpty) ...[
          const _SectionHeader(title: 'Provider 用量对比'),
          const SizedBox(height: 8),
          _PoolComparisonCard(summaries: summaries),
          const SizedBox(height: 16),
        ],

        // 趋势
        if (pools.pools.isNotEmpty) ...[
          const _SectionHeader(title: '最近 7 天趋势'),
          const SizedBox(height: 8),
          ...pools.pools.map((pool) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _TrendCard(
                  poolName: pool.displayName,
                  trend: usage.trendForPool(pool.id, days: 7),
                ),
              )),
        ],

        // Top Pools
        if (topPools.isNotEmpty) ...[
          const SizedBox(height: 8),
          const _SectionHeader(title: '今日用量 Top 5'),
          const SizedBox(height: 8),
          _TopPoolsCard(summaries: topPools),
        ],

        const SizedBox(height: 24),
      ],
    );
  }
}

// ============================================================================
// 总览卡片
// ============================================================================
class _TotalOverviewCard extends StatelessWidget {
  final int totalTokens;
  final int totalCalls;
  final double successRate;

  const _TotalOverviewCard({
    required this.totalTokens,
    required this.totalCalls,
    required this.successRate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.show_chart, color: Colors.blue),
                SizedBox(width: 8),
                Text('今日用量总览',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _BigMetric(
                  value: _formatNumber(totalTokens),
                  label: 'Token 数',
                  color: Colors.blue,
                ),
                _BigMetric(
                  value: '$totalCalls',
                  label: '调用次数',
                  color: Colors.indigo,
                ),
                _BigMetric(
                  value: '${(successRate * 100).toStringAsFixed(1)}%',
                  label: '成功率',
                  color: successRate >= 0.9
                      ? Colors.green
                      : successRate >= 0.7
                          ? Colors.orange
                          : Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

class _BigMetric extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _BigMetric({
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
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

// ============================================================================
// Pool 对比
// ============================================================================
class _PoolComparisonCard extends StatelessWidget {
  final List<PoolUsageSummary> summaries;

  const _PoolComparisonCard({required this.summaries});

  @override
  Widget build(BuildContext context) {
    if (summaries.isEmpty) return const SizedBox.shrink();
    final maxTokens = summaries
        .map((s) => s.totalTokens)
        .fold<int>(0, (max, n) => n > max ? n : max)
        .toDouble();

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: summaries.map((s) {
            final ratio =
                maxTokens == 0 ? 0.0 : (s.totalTokens / maxTokens).clamp(0.0, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(s.poolName,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w500)),
                      ),
                      Text('${_formatNumber(s.totalTokens)} tokens · ${s.totalCalls} 次',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: ratio,
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(
                      ratio > 0.8 ? Colors.orange : Colors.blue,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

// ============================================================================
// 趋势卡片
// ============================================================================
class _TrendCard extends StatelessWidget {
  final String poolName;
  final List<UsageTrendPoint> trend;

  const _TrendCard({required this.poolName, required this.trend});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(poolName,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: trend.length < 2
                  ? const Center(
                      child: Text('数据不足',
                          style: TextStyle(fontSize: 12, color: Colors.grey)))
                  : CustomPaint(
                      size: Size.infinite,
                      painter: _SparklinePainter(
                        points: trend,
                        color: Colors.blue,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<UsageTrendPoint> points;
  final Color color;

  _SparklinePainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final maxTokens = points.map((p) => p.tokens).reduce(math.max);
    if (maxTokens == 0) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = (i / (points.length - 1)) * size.width;
      final y = size.height -
          (points[i].tokens / maxTokens) * size.height * 0.9 -
          size.height * 0.05;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);

    // 圆点
    final dotPaint = Paint()..color = color;
    for (var i = 0; i < points.length; i++) {
      final x = (i / (points.length - 1)) * size.width;
      final y = size.height -
          (points[i].tokens / maxTokens) * size.height * 0.9 -
          size.height * 0.05;
      canvas.drawCircle(Offset(x, y), 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.points != points;
  }
}

// ============================================================================
// Top Pools
// ============================================================================
class _TopPoolsCard extends StatelessWidget {
  final List<PoolUsageSummary> summaries;

  const _TopPoolsCard({required this.summaries});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Column(
        children: [
          for (var i = 0; i < summaries.length; i++)
            ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 14,
                backgroundColor: i == 0
                    ? Colors.amber
                    : i == 1
                        ? Colors.grey.shade400
                        : Colors.brown.shade300,
                child: Text('${i + 1}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ),
              title: Text(summaries[i].poolName,
                  style: const TextStyle(fontSize: 13)),
              trailing: Text('${_formatNumber(summaries[i].totalTokens)}',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(title,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87)),
    );
  }
}
