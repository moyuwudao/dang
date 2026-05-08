import 'package:flutter/material.dart';
import '../services/stats_service.dart';

class StatsChart extends StatelessWidget {
  final UsageStats stats;

  const StatsChart({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildOverviewCards(theme),
          const SizedBox(height: 24),
          _buildRecordsChart(theme),
          const SizedBox(height: 24),
          _buildTagsCloud(theme),
          const SizedBox(height: 24),
          _buildActivityChart(theme),
        ],
      ),
    );
  }

  Widget _buildOverviewCards(ThemeData theme) {
    final cards = [
      _StatCard(
        icon: Icons.mic,
        label: '总记录数',
        value: stats.totalRecords.toString(),
        color: theme.primaryColor,
      ),
      _StatCard(
        icon: Icons.audio_file,
        label: '语音记录',
        value: stats.audioRecords.toString(),
        color: const Color(0xFF8B5CF6),
      ),
      _StatCard(
        icon: Icons.image,
        label: 'OCR记录',
        value: stats.ocrRecords.toString(),
        color: const Color(0xFFEC4899),
      ),
      _StatCard(
        icon: Icons.check_circle,
        label: '转写成功',
        value: stats.successfulTranscriptions.toString(),
        color: const Color(0xFF10B981),
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: cards,
    );
  }

  Widget _buildRecordsChart(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '记录趋势',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildBarChart(stats.recordsPerDay, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(Map<String, int> data, ThemeData theme) {
    if (data.isEmpty) {
      return const Center(child: Text('暂无数据'));
    }

    final maxValue = data.values.reduce((a, b) => a > b ? a : b);
    final sortedEntries = data.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final last7Days = sortedEntries.take(7).toList();

    return SizedBox(
      height: 150,
      child: Row(
        children: last7Days.map((entry) {
          final height = (entry.value / maxValue) * 100;
          final date = DateTime.parse(entry.key);
          final dayName = _getDayName(date.weekday);

          return Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.2),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8)),
                      ),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          height: height > 0 ? height : 2,
                          decoration: BoxDecoration(
                            color: theme.primaryColor,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(8)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  dayName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTagsCloud(ThemeData theme) {
    if (stats.tagsFrequency.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: Text('暂无标签数据')),
        ),
      );
    }

    final sortedTags = stats.tagsFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topTags = sortedTags.take(10).toList();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '热门标签',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: topTags.map((tag) {
                final popularity = tag.value / sortedTags.first.value;
                final fontSize = 14 + (popularity * 8);

                return Chip(
                  label: Text(
                    '${tag.key} (${tag.value})',
                    style: TextStyle(fontSize: 13, color: theme.primaryColor),
                  ),
                  backgroundColor: theme.primaryColor.withOpacity(0.1),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityChart(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '使用统计',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _ActivityItem(
                    icon: Icons.calendar_today,
                    label: '使用天数',
                    value: '${stats.daysUsed}天',
                    color: theme.primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _ActivityItem(
                    icon: Icons.star,
                    label: '收藏记录',
                    value: stats.favoriteRecords.toString(),
                    color: const Color(0xFFF59E0B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _ActivityItem(
                    icon: Icons.summarize,
                    label: 'AI总结',
                    value: stats.aiSummaryCount.toString(),
                    color: const Color(0xFF8B5CF6),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _ActivityItem(
                    icon: Icons.share,
                    label: '分享次数',
                    value: stats.shareCount.toString(),
                    color: const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return '一';
      case 2:
        return '二';
      case 3:
        return '三';
      case 4:
        return '四';
      case 5:
        return '五';
      case 6:
        return '六';
      case 7:
        return '日';
      default:
        return '';
    }
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _ActivityItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style:
              theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}
