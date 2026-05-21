import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/transcription_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../providers/settings_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../subscription/providers/subscription_provider.dart';

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
    _tabController = TabController(length: 4, vsync: this);
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
            Tab(icon: Icon(Icons.account_circle_outlined), text: '账户中心'),
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
          AccountCenterTab(),
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
          title: '调试工具',
          children: [
            ListTile(
              leading: const Icon(Icons.terminal, color: AppColors.warning),
              title: const Text('运行日志'),
              subtitle: const Text('查看APP运行日志，用于排查问题'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/settings/logs'),
            ),
          ],
        ),
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

class AccountCenterTab extends ConsumerWidget {
  const AccountCenterTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final subscriptionState = ref.watch(subscriptionNotifierProvider);

    return ListView(
      children: [
        _buildUserCard(context, authState),
        const SizedBox(height: 16),
        _buildSubscriptionCard(context, subscriptionState),
        const SizedBox(height: 16),
        _buildSection(
          context,
          title: '账户管理',
          children: [
            if (!authState.isLoggedIn) ...[
              ListTile(
                leading: const Icon(Icons.login, color: AppColors.primary),
                title: const Text('登录/注册'),
                subtitle: const Text('解锁云端AI服务，注册送100分钟'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/login'),
              ),
            ] else ...[
              ListTile(
                leading: const Icon(Icons.person, color: AppColors.primary),
                title: const Text('个人信息'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/profile'),
              ),
              ListTile(
                leading: const Icon(Icons.workspace_premium, color: AppColors.warning),
                title: const Text('我的订阅'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _checkLoginAndNavigate(context, '/subscription/mine'),
              ),
              ListTile(
                leading: const Icon(Icons.shopping_cart, color: AppColors.success),
                title: const Text('购买套餐'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _checkLoginAndNavigate(context, '/subscription/store'),
              ),
              ListTile(
                leading: const Icon(Icons.account_balance_wallet, color: AppColors.primary),
                title: const Text('充值中心'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _checkLoginAndNavigate(context, '/subscription/recharge'),
              ),
              ListTile(
                leading: const Icon(Icons.receipt_long, color: AppColors.info),
                title: const Text('交易记录'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _checkLoginAndNavigate(context, '/subscription/orders'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.error),
                title: const Text('退出登录'),
                onTap: () => _showLogoutConfirm(context, ref),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        _buildSection(
          context,
          title: 'AI服务配置',
          children: [
            ListTile(
              leading: const Icon(Icons.cloud, color: AppColors.primary),
              title: const Text('云端AI服务'),
              subtitle: Text(
                authState.isLoggedIn
                    ? '使用云端分配的API Key'
                    : '登录后开启云端AI服务',
              ),
              trailing: Switch(
                value: ref.watch(cloudApiEnabledProvider) && authState.isLoggedIn,
                onChanged: authState.isLoggedIn
                    ? (value) {
                        ref.read(cloudApiEnabledProvider.notifier).state = value;
                      }
                    : null,
              ),
              onTap: !authState.isLoggedIn
                  ? () => _showLoginPrompt(context)
                  : null,
            ),
            ListTile(
              leading: const Icon(Icons.key, color: AppColors.secondary),
              title: const Text('本地API配置'),
              subtitle: const Text('使用自己的API Key'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/settings/api-key'),
            ),
          ],
        ),
      ],
    );
  }

  void _checkLoginAndNavigate(BuildContext context, String route) {
    final container = ProviderScope.containerOf(context);
    final authState = container.read(authNotifierProvider);
    if (!authState.isLoggedIn) {
      _showLoginPrompt(context);
      return;
    }
    context.push(route);
  }

  void _showLoginPrompt(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 48, color: AppColors.primary),
            const SizedBox(height: 16),
            const Text(
              '该功能需要登录后使用',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '登录后即可使用云端AI服务、购买套餐等功能',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('去登录'),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('暂不登录'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, AuthState state) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Icon(
              state.isLoggedIn ? Icons.person : Icons.person_outline,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            state.isLoggedIn ? state.user?.nickname ?? '用户' : '未登录',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (state.isLoggedIn) ...[
            const SizedBox(height: 4),
            Text(
              state.user?.phone ?? '',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context.push('/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('登录/注册'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard(BuildContext context, SubscriptionState state) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '当前套餐',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: state.isActive
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  state.isActive ? '生效中' : '已过期',
                  style: TextStyle(
                    fontSize: 12,
                    color: state.isActive ? AppColors.success : AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            state.planName ?? '免费版',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: state.totalQuota > 0 ? state.usedQuota / state.totalQuota : 0,
            backgroundColor: AppColors.divider,
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          ),
          const SizedBox(height: 8),
          Text(
            '已用 ${state.usedQuota} / ${state.totalQuota} 分钟',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirm(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('退出后将无法使用云端AI服务'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(authNotifierProvider.notifier).logout();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('退出'),
          ),
        ],
      ),
    );
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
