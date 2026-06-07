import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/usage_record.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/cloud_usage_provider.dart';
import '../providers/daily_usage_provider.dart';
import '../providers/multi_api_pools_provider.dart';

/// ============================================================================
/// 用量统计 Tab（方案B：云端为主 + 本地折叠）
///
/// 展示逻辑：
///   1. 主区域：云端计费数据（登录后可用，标注"以云端计费为准"）
///   2. 折叠区：本地统计数据（始终可用，标注"仅供参考"）
///   3. 来源标注：每个 Provider 标注云端/本地 + 是否计费
///   4. 刷新：自动5分钟 + 手动刷新按钮
///   5. 离线降级：无云端数据时主区域展示本地数据
/// ============================================================================
class UsageTab extends ConsumerStatefulWidget {
  const UsageTab({super.key});

  @override
  ConsumerState<UsageTab> createState() => _UsageTabState();
}

class _UsageTabState extends ConsumerState<UsageTab> {
  bool _showLocalStats = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider).valueOrNull;
    final isLoggedIn = authState?.isLoggedIn == true;
    final localUsage = ref.watch(dailyUsageProvider);
    final cloudUsage = ref.watch(cloudUsageAutoProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ===== 主区域：云端计费统计 =====
        if (isLoggedIn && !cloudUsage.isLoading || cloudUsage.summary.logs.isNotEmpty)
          _buildCloudSection(context, cloudUsage)
        else if (isLoggedIn && cloudUsage.isLoading && cloudUsage.summary.logs.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          ),

        // ===== 离线/未登录降级：本地统计作为主展示 =====
        if (!isLoggedIn || (cloudUsage.summary.logs.isEmpty && !cloudUsage.isLoading))
          _buildLocalAsMainSection(context, localUsage, isLoggedIn),

        const SizedBox(height: 16),

        // ===== 折叠区：本地统计（登录后折叠，未登录时已展示） =====
        if (isLoggedIn && cloudUsage.summary.logs.isNotEmpty) ...[
          _buildLocalStatsCollapsible(context, localUsage),
          const SizedBox(height: 16),
        ],

        const SizedBox(height: 24),
      ],
    );
  }

  // ============================================================================
  // 云端计费统计区
  // ============================================================================
  Widget _buildCloudSection(BuildContext context, CloudUsageState cloudUsage) {
    final summary = cloudUsage.summary;
    final byProvider = summary.byProvider();
    final dailyTokens = summary.dailyBilledTokens();
    final providerList = byProvider.values.toList()
      ..sort((a, b) => b.billedTokens.compareTo(a.billedTokens));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题栏 + 刷新按钮
        Row(
          children: [
            const Icon(Icons.cloud_done, color: AppColors.primary, size: 18),
            const SizedBox(width: 6),
            const Expanded(
              child: Text(
                '云端计费统计',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            _RefreshButton(
              isLoading: cloudUsage.isLoading,
              lastFetchedAt: cloudUsage.lastFetchedAt,
              onRefresh: () => ref.read(cloudUsageProvider.notifier).fetch(force: true),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '以云端计费数据为准，含 API 系数',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 12),

        // 总览卡片
        _CloudOverviewCard(
          totalBilledTokens: summary.totalQuotaConsumed,
          totalRawTokens: summary.totalTokens,
          totalCalls: summary.totalCalls,
        ),
        const SizedBox(height: 16),

        // Provider 对比（含计费系数）
        if (providerList.isNotEmpty) ...[
          const _SectionHeader(title: 'Provider 用量对比'),
          const SizedBox(height: 8),
          _CloudProviderComparisonCard(providerStats: providerList),
          const SizedBox(height: 16),
        ],

        // 7天趋势
        if (dailyTokens.length >= 2) ...[
          const _SectionHeader(title: '最近 7 天计费趋势'),
          const SizedBox(height: 8),
          _CloudTrendCard(dailyTokens: dailyTokens),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  // ============================================================================
  // 本地统计作为主展示（未登录或无云端数据时）
  // ============================================================================
  Widget _buildLocalAsMainSection(BuildContext context, DailyUsageState localUsage, bool isLoggedIn) {
    final summaries = localUsage.poolSummaries();
    final topPools = localUsage.topPoolsByUsage(limit: 5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isLoggedIn ? Icons.device_hub : Icons.assessment,
              color: AppColors.warning,
              size: 18,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                isLoggedIn ? '本地统计（离线模式）' : '本地统计',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          isLoggedIn
              ? '云端数据暂不可用，展示本地统计（不含计费系数）'
              : '使用本地 API Key 的用量统计（不计费）',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 12),

        // 总览
        _LocalOverviewCard(
          totalTokens: localUsage.totalTokensToday,
          totalCalls: localUsage.totalCallsToday,
          successRate: localUsage.totalCallsToday == 0
              ? 1.0
              : (localUsage.totalCallsToday -
                      localUsage.today.values.fold(0, (s, r) => s + r.errorCount)) /
                  localUsage.totalCallsToday,
        ),
        const SizedBox(height: 16),

        // Provider 对比
        if (summaries.isNotEmpty) ...[
          const _SectionHeader(title: 'Provider 用量对比'),
          const SizedBox(height: 8),
          _LocalProviderComparisonCard(summaries: summaries),
          const SizedBox(height: 16),
        ],

        // Top Pools
        if (topPools.isNotEmpty) ...[
          const _SectionHeader(title: '今日用量 Top 5'),
          const SizedBox(height: 8),
          _TopPoolsCard(summaries: topPools),
        ],
      ],
    );
  }

  // ============================================================================
  // 折叠区：本地统计（登录后，云端数据可用时）
  // ============================================================================
  Widget _buildLocalStatsCollapsible(BuildContext context, DailyUsageState localUsage) {
    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _showLocalStats = !_showLocalStats),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.folder_outlined, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      '本地统计（仅供参考）',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                  Text(
                    '原始 ${localUsage.totalTokensToday} Tokens · ${localUsage.totalCallsToday} 次',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                  Icon(
                    _showLocalStats ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: Colors.grey.shade500,
                  ),
                ],
              ),
            ),
          ),
          if (_showLocalStats) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '本地统计记录的是 API 原始 Token 数，不含计费系数。与云端计费数据可能有差异。',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _SmallMetric(
                        value: _formatNumber(localUsage.totalTokensToday),
                        label: '原始Token',
                      ),
                      _SmallMetric(
                        value: '${localUsage.totalCallsToday}',
                        label: '调用次数',
                      ),
                      _SmallMetric(
                        value: '${localUsage.today.values.fold(0, (s, r) => s + r.errorCount)}',
                        label: '失败次数',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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

// ============================================================================
// 云端总览卡片
// ============================================================================
class _CloudOverviewCard extends StatelessWidget {
  final int totalBilledTokens;
  final int totalRawTokens;
  final int totalCalls;

  const _CloudOverviewCard({
    required this.totalBilledTokens,
    required this.totalRawTokens,
    required this.totalCalls,
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
                Icon(Icons.show_chart, color: AppColors.primary),
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
                  value: _formatNumber(totalBilledTokens),
                  label: '计费Token',
                  color: AppColors.primary,
                ),
                _BigMetric(
                  value: '$totalCalls',
                  label: '调用次数',
                  color: Colors.indigo,
                ),
                _BigMetric(
                  value: _formatNumber(totalRawTokens),
                  label: '原始Token',
                  color: Colors.grey,
                ),
              ],
            ),
            if (totalBilledTokens != totalRawTokens && totalRawTokens > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: Colors.blue.shade700),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '计费Token = 原始Token × API系数，系数越高消耗越快',
                        style: TextStyle(fontSize: 11, color: Colors.blue.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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

// ============================================================================
// 本地总览卡片
// ============================================================================
class _LocalOverviewCard extends StatelessWidget {
  final int totalTokens;
  final int totalCalls;
  final double successRate;

  const _LocalOverviewCard({
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
                Icon(Icons.show_chart, color: AppColors.warning),
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
                  label: '原始Token',
                  color: AppColors.warning,
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

// ============================================================================
// 云端 Provider 对比卡片
// ============================================================================
class _CloudProviderComparisonCard extends StatelessWidget {
  final List<ProviderCloudStats> providerStats;

  const _CloudProviderComparisonCard({required this.providerStats});

  @override
  Widget build(BuildContext context) {
    final maxTokens = providerStats
        .map((s) => s.billedTokens)
        .fold<int>(0, (max, n) => n > max ? n : max)
        .toDouble();

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: providerStats.map((s) {
            final ratio = maxTokens == 0
                ? 0.0
                : (s.billedTokens / maxTokens).clamp(0.0, 1.0);
            // 根据系数选择颜色
            final color = s.billedTokens > s.rawTokens
                ? Colors.orange // 有系数放大
                : AppColors.primary;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // 云端标识
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text('云端',
                            style: TextStyle(fontSize: 9, color: AppColors.primary)),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(s.provider,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w500)),
                      ),
                      Text(
                        '${_formatNumber(s.billedTokens)} 计费 · ${s.calls} 次',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  if (s.billedTokens != s.rawTokens && s.rawTokens > 0)
                    Text(
                      '原始 ${_formatNumber(s.rawTokens)} → 计费 ${_formatNumber(s.billedTokens)}',
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                    ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: ratio,
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ],
              ),
            );
          }).toList().cast<Widget>(),
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
// 本地 Provider 对比卡片
// ============================================================================
class _LocalProviderComparisonCard extends StatelessWidget {
  final List<PoolUsageSummary> summaries;

  const _LocalProviderComparisonCard({required this.summaries});

  @override
  Widget build(BuildContext context) {
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
            final ratio = maxTokens == 0
                ? 0.0
                : (s.totalTokens / maxTokens).clamp(0.0, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // 本地标识
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text('本地',
                            style: TextStyle(fontSize: 9, color: AppColors.warning)),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(s.poolName,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w500)),
                      ),
                      Text('${_formatNumber(s.totalTokens)} tokens · ${s.totalCalls} 次',
                          style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: ratio,
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation(AppColors.warning),
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
// 云端趋势卡片
// ============================================================================
class _CloudTrendCard extends StatelessWidget {
  final Map<DateTime, int> dailyTokens;

  const _CloudTrendCard({required this.dailyTokens});

  @override
  Widget build(BuildContext context) {
    final sorted = dailyTokens.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final points = sorted
        .map((e) => UsageTrendPoint(date: e.key, tokens: e.value))
        .toList();

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('计费Token消耗',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: points.length < 2
                  ? const Center(
                      child: Text('数据不足',
                          style: TextStyle(fontSize: 12, color: Colors.grey)))
                  : CustomPaint(
                      size: Size.infinite,
                      painter: _SparklinePainter(
                        points: points,
                        color: AppColors.primary,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Top Pools 卡片
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

// ============================================================================
// 刷新按钮
// ============================================================================
class _RefreshButton extends StatelessWidget {
  final bool isLoading;
  final DateTime? lastFetchedAt;
  final VoidCallback onRefresh;

  const _RefreshButton({
    required this.isLoading,
    this.lastFetchedAt,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: isLoading ? null : onRefresh,
      icon: isLoading
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.refresh, size: 16),
      label: Text(
        lastFetchedAt != null
            ? _timeAgo(lastFetchedAt!)
            : '刷新',
        style: const TextStyle(fontSize: 12),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
      ),
    );
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    return '${diff.inDays}天前';
  }
}

// ============================================================================
// 通用小组件
// ============================================================================
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

class _SmallMetric extends StatelessWidget {
  final String value;
  final String label;

  const _SmallMetric({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
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
              fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
    );
  }
}

// ============================================================================
// Sparkline 画笔
// ============================================================================
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
