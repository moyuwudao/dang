import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/transcription_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.auto_fix_high), text: 'AI配置'),
            Tab(icon: Icon(Icons.storage_outlined), text: '数据管理'),
            Tab(icon: Icon(Icons.settings_outlined), text: '系统设置'),
          ],
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          AiConfigTab(),
          DataManagementTab(),
          SystemSettingsTab(),
        ],
      ),
    );
  }
}

class AiConfigTab extends ConsumerWidget {
  const AiConfigTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return ListView(
      children: [
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
              leading: const Icon(Icons.key_outlined, color: AppColors.primary),
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
        _buildSection(
          context,
          title: 'AI角色管理',
          children: [
            ListTile(
              leading: const Icon(Icons.psychology, color: AppColors.secondary),
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
          ],
        ),
        _buildSection(
          context,
          title: '工具AI配置',
          children: [
            ListTile(
              leading:
                  const Icon(Icons.settings_outlined, color: AppColors.success),
              title: const Text('工具方案配置'),
              subtitle: const Text('管理各工具的AI模板，支持新增和删除'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/settings/tool-ai-config'),
            ),
          ],
        ),
        _buildSection(
          context,
          title: '自动分析',
          children: [
            ListTile(
              leading: const Icon(Icons.smart_toy, color: AppColors.primary),
              title: const Text('自动分析设置'),
              subtitle: const Text('转写完成后自动进行AI分析'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/settings/auto-analysis'),
            ),
          ],
        ),
      ],
    );
  }
}

class DataManagementTab extends ConsumerWidget {
  const DataManagementTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return ListView(
      children: [
        _buildSection(
          context,
          title: '数据统计',
          children: [
            ListTile(
              leading: const Icon(Icons.bar_chart, color: AppColors.info),
              title: const Text('使用统计'),
              subtitle: const Text('查看记录趋势和热门标签'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/statistics'),
            ),
            ListTile(
              leading: const Icon(Icons.api_outlined, color: AppColors.success),
              title: const Text('API调用分析'),
              subtitle: const Text('查看API调用统计和工具使用量'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/statistics/api-analysis'),
            ),
          ],
        ),
        _buildSection(
          context,
          title: l10n.dataManagement,
          children: [
            ListTile(
              leading: const Icon(Icons.backup_outlined, color: AppColors.info),
              title: const Text('备份管理'),
              subtitle: const Text('数据备份、导出和恢复'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/settings/backup'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_sweep, color: AppColors.warning),
              title: const Text('回收站'),
              subtitle: const Text('查看和管理已删除的记录'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/settings/recycle-bin'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: AppColors.error),
              title: Text(l10n.usageStatsClear),
              onTap: () => _showClearDataDialog(context, ref),
            ),
          ],
        ),
      ],
    );
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
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.deleteButton)),
                );
                Navigator.pop(context);
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l10n.yes),
          ),
        ],
      ),
    );
  }
}

class SystemSettingsTab extends ConsumerWidget {
  const SystemSettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return ListView(
      children: [
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
          ],
        ),
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

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重新转写'),
        content: const Text('将处理所有未正常转写的录音，是否继续？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

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
