import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/transcription_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
      ),
      body: ListView(
        children: [
          // API Configuration
          _buildSection(
            context,
            title: l10n.apiKeySettings,
            children: [
              ListTile(
                leading:
                    const Icon(Icons.auto_fix_high, color: AppColors.success),
                title: const Text('快速配置向导'),
                subtitle: const Text('3步完成AI服务配置，推荐新手使用'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/settings/api-key-wizard'),
              ),
              ListTile(
                leading:
                    const Icon(Icons.key_outlined, color: AppColors.primary),
                title: Text(l10n.openaiApiKey),
                subtitle: Text(l10n.apiKeyHelp),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/settings/api-key'),
              ),
              ListTile(
                leading: const Icon(Icons.dns, color: AppColors.secondary),
                title: const Text('多API配置管理'),
                subtitle: const Text('为语音/图像/文本配置独立API，支持多平台'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/settings/multi-api'),
              ),
            ],
          ),

          // Appearance
          _buildSection(
            context,
            title: l10n.themeSettings,
            children: [
              ListTile(
                leading:
                    const Icon(Icons.palette_outlined, color: AppColors.info),
                title: Text(l10n.themeSettings),
                subtitle: Text(_getThemeModeText(context, themeMode)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showThemeModeDialog(context, ref),
              ),
              ListTile(
                leading: const Icon(Icons.language, color: AppColors.info),
                title: Text(l10n.languageSettings),
                subtitle: Text(_getLocaleText(context, locale)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showLanguageDialog(context, ref),
              ),
            ],
          ),

          // Transcription Management
          _buildSection(
            context,
            title: l10n.transcribeTitle,
            children: [
              ListTile(
                leading: const Icon(Icons.refresh, color: AppColors.warning),
                title: Text(l10n.retryButton),
                subtitle: Text(l10n.transcribeDescription),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _retryFailedTranscriptions(context, ref),
              ),
              ListTile(
                leading: const Icon(Icons.smart_toy, color: AppColors.primary),
                title: const Text('自动分析设置'),
                subtitle: const Text('转写完成后自动进行AI分析'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/settings/auto-analysis'),
              ),
            ],
          ),

          // AI Role Management
          _buildSection(
            context,
            title: 'AI角色管理',
            children: [
              ListTile(
                leading:
                    const Icon(Icons.psychology, color: AppColors.secondary),
                title: const Text('AI分析角色'),
                subtitle: const Text('管理系统角色和自定义分析角色'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/settings/roles'),
              ),
              ListTile(
                leading: const Icon(Icons.description_outlined,
                    color: AppColors.purple),
                title: const Text('Prompt模板管理'),
                subtitle: const Text('管理内置和自定义AI分析模板'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/settings/prompt-templates'),
              ),
              ListTile(
                leading:
                    const Icon(Icons.article_outlined, color: AppColors.info),
                title: const Text('分析模板设置'),
                subtitle: const Text('设置周报和脑图的默认分析模板'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/settings/analysis-templates'),
              ),
            ],
          ),

          // Smart Reminders
          _buildSection(
            context,
            title: '智能提醒',
            children: [
              ListTile(
                leading: const Icon(Icons.notifications_active,
                    color: AppColors.primary),
                title: const Text('提醒事项'),
                subtitle: const Text('查看和管理您的待办提醒'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showRemindersDialog(context),
              ),
            ],
          ),

          // Data Statistics
          _buildSection(
            context,
            title: '数据统计',
            children: [
              ListTile(
                leading: const Icon(Icons.bar_chart, color: AppColors.info),
                title: const Text('使用统计'),
                subtitle: const Text('查看记录趋势和热门标签'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showStatsDialog(context),
              ),
            ],
          ),

          // Usage Statistics
          _buildSection(
            context,
            title: l10n.usageStatistics,
            children: [
              Consumer(
                builder: (context, ref, child) {
                  final usageStatsAsync = ref.watch(usageStatsProvider);
                  return usageStatsAsync.when(
                    data: (stats) {
                      if (stats.isEmpty) {
                        return ListTile(
                          leading: const Icon(Icons.bar_chart,
                              color: AppColors.info),
                          title: Text(l10n.usageStatsEmpty),
                          subtitle: Text(l10n.usageStatsEmptyHint),
                        );
                      }
                      return Column(
                        children: [
                          ...stats.entries.map((entry) {
                            final providerName = entry.key;
                            final providerStats =
                                entry.value as Map<String, dynamic>;
                            final callCount = providerStats['callCount'] ?? 0;
                            final tokenCount = providerStats['tokenCount'] ?? 0;
                            final features = providerStats['features']
                                    as Map<String, dynamic>? ??
                                {};
                            final lastUsed = providerStats['lastUsed'] != null
                                ? DateTime.tryParse(providerStats['lastUsed'])
                                : null;

                            return ListTile(
                              leading: const Icon(Icons.smart_toy,
                                  color: AppColors.primary),
                              title: Text(providerName.toUpperCase()),
                              subtitle: Text(
                                '$callCount ${l10n.calls} · $tokenCount ${l10n.tokens}${lastUsed != null ? ' · ${l10n.lastUsed}: ${_formatDate(lastUsed)}' : ''}',
                              ),
                              trailing: features.isNotEmpty
                                  ? Wrap(
                                      spacing: 4,
                                      children: features.entries.map((f) {
                                        return Chip(
                                          label: Text(
                                            '${f.key}: ${f.value}',
                                            style:
                                                const TextStyle(fontSize: 10),
                                          ),
                                          padding: EdgeInsets.zero,
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        );
                                      }).toList(),
                                    )
                                  : null,
                            );
                          }),
                          // 查看详情按钮
                          ListTile(
                            leading: const Icon(Icons.visibility,
                                color: AppColors.info),
                            title: Text(l10n.usageStatsDetail),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _showUsageStatsDetail(context, stats),
                          ),
                        ],
                      );
                    },
                    loading: () => const ListTile(
                      leading: CircularProgressIndicator(),
                      title: Text('Loading usage stats...'),
                    ),
                    error: (_, __) => ListTile(
                      leading: const Icon(Icons.error, color: AppColors.error),
                      title: Text(l10n.errorGeneric),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_sweep, color: AppColors.error),
                title: Text(l10n.usageStatsClear),
                onTap: () => _showClearUsageStatsDialog(context, ref),
              ),
            ],
          ),

          // Data Management
          _buildSection(
            context,
            title: l10n.dataManagement,
            children: [
              ListTile(
                leading:
                    const Icon(Icons.backup_outlined, color: AppColors.info),
                title: Text(l10n.dataBackup),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/settings/backup'),
              ),
              ListTile(
                leading:
                    const Icon(Icons.delete_sweep, color: AppColors.warning),
                title: const Text('回收站'),
                subtitle: const Text('查看和管理已删除的记录'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/settings/recycle-bin'),
              ),
            ],
          ),

          // About
          _buildSection(
            context,
            title: l10n.about,
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(l10n.version),
                subtitle: const Text('1.0.0'),
              ),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: Text(l10n.privacyPolicy),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/privacy-policy'),
              ),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: Text(l10n.termsOfService),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/terms-of-service'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        ...children,
      ],
    );
  }

  String _getThemeModeText(BuildContext context, ThemeMode mode) {
    final l10n = AppLocalizations.of(context)!;
    switch (mode) {
      case ThemeMode.light:
        return l10n.lightTheme;
      case ThemeMode.dark:
        return l10n.darkTheme;
      case ThemeMode.system:
        return l10n.systemTheme;
    }
  }

  String _getLocaleText(BuildContext context, Locale locale) {
    final l10n = AppLocalizations.of(context)!;
    switch (locale.languageCode) {
      case 'zh':
        return l10n.chinese;
      case 'en':
      default:
        return l10n.english;
    }
  }

  void _showThemeModeDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.themeSettings),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.light_mode),
              title: Text(l10n.lightTheme),
              onTap: () {
                ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(ThemeMode.light);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: Text(l10n.darkTheme),
              onTap: () {
                ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(ThemeMode.dark);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_suggest),
              title: Text(l10n.systemTheme),
              onTap: () {
                ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(ThemeMode.system);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.languageSettings),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(l10n.english),
              trailing: ref.watch(localeProvider).languageCode == 'en'
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                ref.read(localeProvider.notifier).setLocale(const Locale('en'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(l10n.chinese),
              trailing: ref.watch(localeProvider).languageCode == 'zh'
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                ref.read(localeProvider.notifier).setLocale(const Locale('zh'));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _retryFailedTranscriptions(
      BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final transcriptionService = ref.read(transcriptionServiceProvider);
      await transcriptionService.retryAllFailed();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.transcribeSuccess),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.transcribeError}: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showRemindersDialog(BuildContext context) {
    context.push('/reminders');
  }

  void _showStatsDialog(BuildContext context) {
    context.push('/statistics');
  }

  void _showUsageStatsDetail(BuildContext context, Map<String, dynamic> stats) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.usageStatsDetail),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: stats.entries.map((entry) {
                final providerName = entry.key;
                final providerStats = entry.value as Map<String, dynamic>;
                final callCount = providerStats['callCount'] ?? 0;
                final tokenCount = providerStats['tokenCount'] ?? 0;
                final features =
                    providerStats['features'] as Map<String, dynamic>? ?? {};
                final lastUsed = providerStats['lastUsed'] != null
                    ? DateTime.tryParse(providerStats['lastUsed'])
                    : null;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          providerName.toUpperCase(),
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        _buildStatRow('${l10n.calls}:', callCount.toString()),
                        _buildStatRow('${l10n.tokens}:', tokenCount.toString()),
                        if (lastUsed != null)
                          _buildStatRow(
                              '${l10n.lastUsed}:', _formatDate(lastUsed)),
                        if (features.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            '${l10n.features}:',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            children: features.entries.map((f) {
                              return Chip(
                                label: Text('${f.key}: ${f.value}'),
                                backgroundColor:
                                    AppColors.primary.withOpacity(0.1),
                                side: BorderSide.none,
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancelButton),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Text(value),
        ],
      ),
    );
  }

  void _showClearUsageStatsDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.usageStatsClear),
        content: Text(l10n.usageStatsClearConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancelButton),
          ),
          TextButton(
            onPressed: () async {
              await StorageService.clearUsageStats();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.usageStatsClear),
                  backgroundColor: AppColors.success,
                ),
              );
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l10n.clear),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _showClearDataDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDeleteTitle),
        content: Text(l10n.confirmDelete),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.no),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(settingsNotifierProvider.notifier).clearAllData();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.deleteButton)),
              );
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l10n.yes),
          ),
        ],
      ),
    );
  }
}
