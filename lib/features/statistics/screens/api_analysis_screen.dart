import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/stats_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';

class ApiAnalysisScreen extends ConsumerWidget {
  const ApiAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final statsAsync = ref.watch(statsServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.apiCallAnalysis),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: statsAsync.when(
        data: (stats) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildOverviewCards(context, stats),
              const SizedBox(height: 24),
              _buildApiCallsChart(context, stats),
              const SizedBox(height: 24),
              _buildToolUsageChart(context, stats),
              const SizedBox(height: 24),
              _buildDailyCallsChart(context, stats),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('${l10n.loadFailed}: $error'),
        ),
      ),
    );
  }

  Widget _buildOverviewCards(BuildContext context, UsageStats stats) {
    final l10n = AppLocalizations.of(context)!;
    final cards = [
      _StatCard(
        icon: Icons.api,
        label: l10n.totalCalls,
        value: stats.totalApiCalls.toString(),
        color: const Color(0xFF6366F1),
      ),
      _StatCard(
        icon: Icons.check_circle,
        label: l10n.successRate,
        value: '${stats.apiSuccessRate.toStringAsFixed(1)}%',
        color: const Color(0xFF10B981),
      ),
      _StatCard(
        icon: Icons.text_fields,
        label: l10n.textCalls,
        value: stats.apiTextCalls.toString(),
        color: const Color(0xFF8B5CF6),
      ),
      _StatCard(
        icon: Icons.mic,
        label: l10n.voiceCalls,
        value: stats.apiVoiceCalls.toString(),
        color: const Color(0xFFEC4899),
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

  Widget _buildApiCallsChart(BuildContext context, UsageStats stats) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.apiCallTypeDistribution,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildTypeBar(l10n.text, stats.apiTextCalls, const Color(0xFF8B5CF6),
                    stats.totalApiCalls),
                const SizedBox(width: 12),
                _buildTypeBar(l10n.voice, stats.apiVoiceCalls,
                    const Color(0xFFEC4899), stats.totalApiCalls),
                const SizedBox(width: 12),
                _buildTypeBar(l10n.image, stats.apiImageCalls,
                    const Color(0xFFF59E0B), stats.totalApiCalls),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _ActivityItem(
                    icon: Icons.image,
                    label: l10n.imageCalls,
                    value: stats.apiImageCalls.toString(),
                    color: const Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _ActivityItem(
                    icon: Icons.cancel,
                    label: l10n.failedCalls,
                    value: stats.apiFailedCalls.toString(),
                    color: const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeBar(String label, int value, Color color, int total) {
    final percentage = total > 0 ? (value / total) * 100 : 0;

    return Expanded(
      child: Column(
        children: [
          SizedBox(
            height: 80,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  width: double.infinity,
                  height: 80,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                Container(
                  width: double.infinity,
                  height: percentage > 0 ? percentage * 0.8 : 2,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                Positioned(
                  top: 0,
                  child: Text(
                    value.toString(),
                    style: TextStyle(fontWeight: FontWeight.bold, color: color),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style:
                const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildToolUsageChart(BuildContext context, UsageStats stats) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final toolUsage = stats.apiCallsByTool;

    if (toolUsage.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(child: Text(l10n.noToolCallData)),
        ),
      );
    }

    final sortedTools = toolUsage.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topTools = sortedTools.take(10).toList();
    final maxValue = sortedTools.first.value;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.toolCallUsage,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...topTools.map((entry) {
              final percentage = (entry.value / maxValue) * 100;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _getToolName(entry.key),
                          style: const TextStyle(fontSize: 13),
                        ),
                        Text(
                          entry.value.toString(),
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Container(
                        width: percentage,
                        decoration: BoxDecoration(
                          color: theme.primaryColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (sortedTools.length > 10)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l10n.moreTools(sortedTools.length - 10),
                  style: const TextStyle(
                      color: AppColors.textTertiary, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getToolName(String toolId) {
    final toolNames = {
      'mindmap': '知识脑图',
      'weekly_report': '智能周报',
      'smart_todo': '智能待办',
      'meeting_minutes': '会议纪要',
      'email_draft': '邮件草稿',
      'multi_platform_copy': '多平台文案',
      'voice_diary': '语音日记',
      'quick_translate': '快速翻译',
      'time_audit': '时间审计',
      'project_review': '项目复盘',
      'swot_analysis': 'SWOT分析',
      'customer_profile': '客户画像',
      'trend_insight': '趋势洞察',
      'competitor_radar': '竞品雷达',
      'decision_matrix': '决策矩阵',
      'project_board': '项目看板',
      'lightweight_crm': '轻量CRM',
      'invoice_recognition': '发票识别',
      'contract_summary': '合同摘要',
      'quotation': '报价单',
      'knowledge_card': '知识卡片',
      'ai_advisor': 'AI顾问',
      'creative_diverge': '创意发散',
      'knowledge_qa': '知识库问答',
      'writing_workshop': '写作工坊',
      'daily_three_questions': '每日三问',
    };
    return toolNames[toolId] ?? toolId;
  }

  Widget _buildDailyCallsChart(BuildContext context, UsageStats stats) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final dailyCalls = stats.apiCallsPerDay;

    if (dailyCalls.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(child: Text(l10n.noDailyCallData)),
        ),
      );
    }

    final sortedEntries = dailyCalls.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final last7Days = sortedEntries.take(7).toList();
    final maxValue = last7Days.isNotEmpty
        ? last7Days.map((e) => e.value).reduce((a, b) => a > b ? a : b)
        : 1;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.recent7DaysApiTrend,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
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
                        Text(
                          entry.value.toString(),
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return '周一';
      case 2:
        return '周二';
      case 3:
        return '周三';
      case 4:
        return '周四';
      case 5:
        return '周五';
      case 6:
        return '周六';
      case 7:
        return '周日';
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
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style:
              theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
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
