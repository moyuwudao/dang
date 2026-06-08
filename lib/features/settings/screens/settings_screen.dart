import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/transcription_service.dart';
import '../../../core/services/cloud_config_sync_service.dart';
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
          tabs: [
            Tab(icon: const Icon(Icons.auto_fix_high), text: l10n.aiConfig),
            Tab(icon: const Icon(Icons.storage_outlined), text: l10n.dataManagement),
            Tab(icon: const Icon(Icons.account_circle_outlined), text: l10n.accountManagement),
            Tab(icon: const Icon(Icons.settings_outlined), text: l10n.settingsTitle),
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
          title: l10n.debugTools,
          children: [
            ListTile(
              leading: const Icon(Icons.terminal, color: AppColors.warning),
              title: Text(l10n.viewLogs),
              subtitle: Text(l10n.viewLogs),
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
              title: Text(l10n.apiKeySettings),
              subtitle: Text(l10n.quickConfigWizardDesc),
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
              title: Text(l10n.apiConfigManagement),
              subtitle: Text(l10n.multiApiConfigDesc),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/settings/multi-api'),
            ),
          ],
        ),
        _buildSection(
          context,
          title: l10n.aiRoleManagement,
          children: [
            ListTile(
              leading: const Icon(Icons.psychology, color: AppColors.secondary),
              title: Text(l10n.aiRoleManagement),
              subtitle: Text(l10n.aiAnalysisRolesDesc),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/settings/roles'),
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined,
                  color: AppColors.purple),
              title: Text(l10n.promptTemplateManagement),
              subtitle: Text(l10n.promptTemplateManagementDesc),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/settings/prompt-templates'),
            ),
          ],
        ),
        _buildSection(
          context,
          title: l10n.toolAiConfig,
          children: [
            ListTile(
              leading:
                  const Icon(Icons.settings_outlined, color: AppColors.success),
              title: Text(l10n.toolConfigTitle),
              subtitle: Text(l10n.toolConfigDesc),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/settings/tool-ai-config'),
            ),
          ],
        ),
        _buildSection(
          context,
          title: l10n.autoAnalysis,
          children: [
            ListTile(
              leading: const Icon(Icons.smart_toy, color: AppColors.primary),
              title: Text(l10n.autoAnalysis),
              subtitle: Text(l10n.autoAnalysisDesc),
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
          title: l10n.dataStatistics,
          children: [
            ListTile(
              leading: const Icon(Icons.bar_chart, color: AppColors.info),
              title: Text(l10n.usageStatistics),
              subtitle: Text(l10n.usageStatsDesc),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/statistics'),
            ),
            ListTile(
              leading: const Icon(Icons.api_outlined, color: AppColors.success),
              title: Text(l10n.apiCallAnalysis),
              subtitle: Text(l10n.apiCallAnalysisDesc),
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
              title: Text(l10n.dataBackup),
              subtitle: Text(l10n.backupManagementDesc),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/settings/backup'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_sweep, color: AppColors.warning),
              title: Text(l10n.recycleBin),
              subtitle: Text(l10n.recycleBinDesc),
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
    final themeModeAsync = ref.watch(themeModeProvider);
    final themeMode = themeModeAsync.valueOrNull ?? ThemeMode.system;
    final localeAsync = ref.watch(localeProvider);
    final locale = localeAsync.valueOrNull ?? const Locale('zh');

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
    final themeModeAsync = ref.watch(themeModeProvider);
    final currentThemeMode = themeModeAsync.valueOrNull ?? ThemeMode.system;
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
              trailing: currentThemeMode == ThemeMode.light
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
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
              trailing: currentThemeMode == ThemeMode.dark
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
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
              trailing: currentThemeMode == ThemeMode.system
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
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
    final localeAsync = ref.watch(localeProvider);
    final currentLocale = localeAsync.valueOrNull ?? const Locale('zh');
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
              trailing: currentLocale.languageCode == 'en'
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
              trailing: currentLocale.languageCode == 'zh'
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
        title: Text(l10n.retryFailedTranscriptions),
        content: Text(l10n.retryFailedTranscriptionsConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.confirm),
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
            content: Text('${l10n.retranscribeError}: $e'),
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
    final l10n = AppLocalizations.of(context)!;
    final authAsync = ref.watch(authNotifierProvider);
    final authState = authAsync.valueOrNull ?? const AuthState();
    final subscriptionAsync = ref.watch(subscriptionNotifierProvider);

    return subscriptionAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _buildContent(context, ref, authState, const SubscriptionState(), l10n),
      data: (subscriptionState) => _buildContent(context, ref, authState, subscriptionState, l10n),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, AuthState authState, SubscriptionState subscriptionState, AppLocalizations l10n) {
    return ListView(
      children: [
        _buildUserCard(context, authState, l10n),
        const SizedBox(height: 16),
        _buildSubscriptionCard(context, subscriptionState, l10n),
        const SizedBox(height: 16),
        _buildSection(
          context,
          title: l10n.accountManagement,
          children: [
            if (!authState.isLoggedIn) ...[
              ListTile(
                leading: const Icon(Icons.login, color: AppColors.primary),
                title: Text(l10n.loginRegisterDesc),
                subtitle: Text(l10n.loginSubtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/login'),
              ),
            ] else ...[
              ListTile(
                leading: const Icon(Icons.person, color: AppColors.primary),
                title: Text(l10n.personalInfo),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/profile'),
              ),
              ListTile(
                leading: const Icon(Icons.workspace_premium, color: AppColors.warning),
                title: Text(l10n.mySubscription),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _checkLoginAndNavigate(context, '/subscription/mine'),
              ),
              ListTile(
                leading: const Icon(Icons.shopping_cart, color: AppColors.success),
                title: Text(l10n.purchasePlan),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _checkLoginAndNavigate(context, '/subscription/store'),
              ),
              ListTile(
                leading: const Icon(Icons.account_balance_wallet, color: AppColors.primary),
                title: Text(l10n.rechargeCenter),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _checkLoginAndNavigate(context, '/subscription/recharge'),
              ),
              ListTile(
                leading: const Icon(Icons.receipt_long, color: AppColors.info),
                title: Text(l10n.transactionRecords),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _checkLoginAndNavigate(context, '/subscription/orders'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.error),
                title: Text(l10n.logout),
                onTap: () => _showLogoutConfirm(context, ref),
              ),
            ],
            // 用量统计（始终可见，未登录看本地统计，登录后看云端+本地）
            const Divider(),
            ListTile(
              leading: const Icon(Icons.bar_chart, color: AppColors.info),
              title: const Text('用量统计'),
              subtitle: Text(
                authState.isLoggedIn ? '查看云端计费和本地用量' : '查看本地 API 用量',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/settings/usage'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSection(
          context,
          title: l10n.aiServiceConfig,
          children: [
            ListTile(
              leading: const Icon(Icons.cloud, color: AppColors.primary),
              title: Text(l10n.cloudAiService),
              subtitle: Text(
                authState.isLoggedIn
                    ? l10n.cloudAiServiceLoggedIn
                    : l10n.cloudAiServiceNotLoggedIn,
              ),
              trailing: Switch(
                value: (ref.watch(cloudApiEnabledProvider).valueOrNull ?? false) && authState.isLoggedIn,
                onChanged: authState.isLoggedIn
                    ? (value) => _onCloudAiToggle(context, ref, value)
                    : null,
              ),
              onTap: !authState.isLoggedIn
                  ? () => _showLoginPrompt(context)
                  : null,
            ),
            ListTile(
              leading: const Icon(Icons.key, color: AppColors.secondary),
              title: Text(l10n.localApiConfig),
              subtitle: Text(l10n.apiKeyHelp),
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
    final authState = container.read(authNotifierProvider).valueOrNull;
    if (!(authState?.isLoggedIn ?? false)) {
      _showLoginPrompt(context);
      return;
    }
    context.push(route);
  }

  /// 处理云端AI开关切换
  Future<void> _onCloudAiToggle(BuildContext context, WidgetRef ref, bool value) async {
    if (!value) {
      // ??????AI??????????????????
      await ref.read(cloudApiEnabledProvider.notifier).setEnabled(false);
      await CloudConfigSyncService.clearCloudConfigs();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已关闭云端AI服务，恢复本地配置')),
        );
      }
      return;
    }

    // ???????I????????????
    final subscriptionState = ref.read(subscriptionNotifierProvider).valueOrNull;
    final defaultConfigs = subscriptionState?.defaultConfigs ?? [];

    if (defaultConfigs.isEmpty) {
      // 修复异常6：defaultConfigs 为空时也要 setEnabled(true)，并跳转到 API 配置管理
      await ref.read(cloudApiEnabledProvider.notifier).setEnabled(true);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已开启云端AI服务，请到 API配置管理 配置模型'),
            duration: Duration(seconds: 3),
          ),
        );
        // 跳转到 API 配置管理
        context.push('/settings/multi-api');
      }
      return;
    }

    // 显示确认对话框
    final result = await showDialog<CloudSyncAction>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _CloudSyncDialog(
        defaultConfigs: defaultConfigs,
      ),
    );

    if (result == null || !context.mounted) return;

    switch (result) {
      case CloudSyncAction.sync:
        // 同步云端默认配置
        await ref.read(cloudApiEnabledProvider.notifier).setEnabled(true);
        final syncResult = await CloudConfigSyncService.syncCloudDefaults(
          defaultConfigs: defaultConfigs,
          apiPolicies: subscriptionState?.apiPolicies ?? [],
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(syncResult.success
                  ? 'Cloud AI enabled, ${syncResult.message}'
                  : 'Sync failed: ${syncResult.message}'),
            ),
          );
        }
      case CloudSyncAction.manual:
        // 手动配置：仅同步套餐内可用 API 到手机端，场景分配由用户自行配置
        await ref.read(cloudApiEnabledProvider.notifier).setEnabled(true);
        final syncResult = await CloudConfigSyncService.syncApiPolicies(
          apiPolicies: subscriptionState?.apiPolicies ?? [],
          defaultConfigs: subscriptionState?.defaultConfigs ?? const [],
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(syncResult.success
                  ? 'Cloud AI enabled, ${syncResult.message}'
                  : 'Sync failed: ${syncResult.message}'),
            ),
          );
          // 跳转到 API 配置管理，由用户自行配置场景分配
          context.push('/settings/multi-api');
        }
      case CloudSyncAction.cancel:
        // 取消：关闭云端 AI 开关，不执行任何同步
        await ref.read(cloudApiEnabledProvider.notifier).setEnabled(false);
        await CloudConfigSyncService.clearCloudConfigs();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已取消云端同步，云端AI服务保持关闭')),
          );
        }
        break;
    }
  }

  void _showLoginPrompt(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 48, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              l10n.loginSubtitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.loginRegisterDesc,
              style: const TextStyle(color: AppColors.textSecondary),
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
                child: Text(l10n.loginNow),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, AuthState state, AppLocalizations l10n) {
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
            state.isLoggedIn ? state.user?.nickname ?? l10n.user : l10n.notLoggedIn,
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
              child: Text(l10n.loginRegisterDesc),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard(BuildContext context, SubscriptionState state, AppLocalizations l10n) {
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
              Text(
                l10n.currentPlan,
                style: const TextStyle(
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
                  state.isActive ? l10n.statusActive : l10n.statusExpired,
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
            state.planName ?? l10n.freePlan,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: state.tokenBalance.totalTokens > 0
                ? state.tokenBalance.usedTokens / state.tokenBalance.totalTokens
                : 0,
            backgroundColor: AppColors.divider,
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          ),
          const SizedBox(height: 8),
          Text(
            '配额: ${state.tokenBalance.quotaRemaining}  充值: ${state.tokenBalance.rechargeBalance}',
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
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmLogout),
        content: Text(l10n.logoutConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(authNotifierProvider.notifier).logout();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: Text(l10n.logout),
          ),
        ],
      ),
    );
  }
}

enum CloudSyncAction { sync, manual, cancel }

/// Cloud config sync confirmation dialog
class _CloudSyncDialog extends StatelessWidget {
  final List<DefaultConfig> defaultConfigs;

  const _CloudSyncDialog({required this.defaultConfigs});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.cloud_sync, color: AppColors.primary, size: 32),
      title: const Text('打开云端API'),
      // Issue 2 修复：content 用 scrollable + 限制最大高度，避免按钮和功能列表重叠
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 460),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '请选择云端API的同步方式：',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              // 三个选项说明
              _buildOptionItem(
                icon: Icons.auto_fix_high,
                color: AppColors.primary,
                title: '按云端默认配置执行',
                desc: '将套餐内各功能默认API + 套餐内可用API 同步到手机端',
              ),
              const SizedBox(height: 8),
              _buildOptionItem(
                icon: Icons.tune,
                color: AppColors.secondary,
                title: '手动配置',
                desc: '仅将套餐内可用API 同步到手机端，场景分配由用户自行配置',
              ),
              const SizedBox(height: 8),
              _buildOptionItem(
                icon: Icons.close,
                color: Colors.grey,
                title: '取消',
                desc: '不执行同步，也不打开云端API开关',
              ),
              // Issue 2 修复：用 ExpansionTile 折叠套餐内可用功能列表，避免占用过多空间
              if (defaultConfigs.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Divider(),
                Theme(
                  // 去掉默认的分割线 padding，让折叠区域更紧凑
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(bottom: 4),
                    title: const Text(
                      '套餐内可用功能',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      '${defaultConfigs.length} 个功能（点击展开）',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    initiallyExpanded: false,
                    children: defaultConfigs.map((config) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4, left: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, size: 14, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${_getFunctionTypeName(config.functionType)}: ${config.modelPattern}',
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actionsAlignment: MainAxisAlignment.end,
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        // 按钮竖排：每个按钮 100% 宽度，文字不会被截断
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, CloudSyncAction.sync),
            icon: const Icon(Icons.cloud_sync, size: 18),
            label: const Text(
              '按云端默认配置执行',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pop(context, CloudSyncAction.manual),
            icon: const Icon(Icons.tune, size: 18),
            label: const Text(
              '手动配置',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.secondary,
              side: const BorderSide(color: AppColors.secondary),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => Navigator.pop(context, CloudSyncAction.cancel),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[700],
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            child: const Text('取消', style: TextStyle(fontSize: 14)),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionItem({
    required IconData icon,
    required Color color,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              Text(
                desc,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getFunctionTypeName(String functionType) {
    switch (functionType) {
      case 'textAnalysis':
        return '文本分析';
      case 'speechTranscribe':
        return '语言转写';
      case 'speechRealtime':
        return '实时语音转写';
      case 'speechOffline':
        return '离线语音转写';
      case 'imageRecognition':
        return '图像识别';
      // 兼容旧 enum
      case 'transcribe':
        return '实时转写';
      case 'transcribeFile':
        return '文件转写';
      case 'summary':
        return '摘要';
      case 'translate':
        return '翻译';
      case 'mindMap':
        return '思维导图';
      case 'image':
        return '图像识别';
      // 英文 → 中文兜底
      case 'voice_transcription':
        return '语言转写';
      case 'realtime_transcription':
        return '实时语音转写';
      case 'offline_transcription':
        return '离线语音转写';
      default:
        return functionType;
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
