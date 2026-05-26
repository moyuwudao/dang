import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/transcription_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../providers/settings_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/screens/profile_screen.dart';
import '../../subscription/providers/subscription_provider.dart';
import 'multi_api_config_screen.dart';
import 'api_key_wizard_screen.dart';
import 'role_management_screen.dart';
import 'auto_analysis_settings_screen.dart';
import 'tool_ai_config_screen.dart';
import 'backup_management_screen.dart';
import 'recycle_bin_screen.dart';
import 'log_screen.dart';
import 'analysis_template_settings_screen.dart';
import 'prompt_template_management_screen.dart';

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
    final subscriptionState = subscriptionAsync.valueOrNull ?? const SubscriptionState();

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
            value: state.totalQuota > 0 ? state.usedQuota / state.totalQuota : 0,
            backgroundColor: AppColors.divider,
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.minutesUsed(state.usedQuota, state.totalQuota),
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
