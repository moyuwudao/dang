import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/background_service.dart';
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
                leading: const Icon(Icons.key_outlined, color: AppColors.primary),
                title: Text(l10n.openaiApiKey),
                subtitle: Text(l10n.apiKeyHelp),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/settings/api-key'),
              ),
            ],
          ),

          // Appearance
          _buildSection(
            context,
            title: l10n.themeSettings,
            children: [
              ListTile(
                leading: const Icon(Icons.palette_outlined, color: AppColors.info),
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
            ],
          ),

          // Usage Statistics
          _buildSection(
            context,
            title: 'Usage Statistics',
            children: [
              Consumer(
                builder: (context, ref, child) {
                  final usageStatsAsync = ref.watch(usageStatsProvider);
                  return usageStatsAsync.when(
                    data: (stats) {
                      if (stats.isEmpty) {
                        return const ListTile(
                          leading: Icon(Icons.bar_chart, color: AppColors.info),
                          title: Text('No usage data yet'),
                          subtitle: Text('Start using AI features to see statistics'),
                        );
                      }
                      return Column(
                        children: stats.entries.map((entry) {
                          final providerName = entry.key;
                          final providerStats = entry.value as Map<String, dynamic>;
                          final callCount = providerStats['callCount'] ?? 0;
                          final tokenCount = providerStats['tokenCount'] ?? 0;
                          final features = providerStats['features'] as Map<String, dynamic>? ?? {};
                          final lastUsed = providerStats['lastUsed'] != null
                              ? DateTime.tryParse(providerStats['lastUsed'])
                              : null;

                          return ListTile(
                            leading: const Icon(Icons.smart_toy, color: AppColors.primary),
                            title: Text(providerName.toUpperCase()),
                            subtitle: Text(
                              '$callCount calls · $tokenCount tokens${lastUsed != null ? ' · Last used: ${_formatDate(lastUsed)}' : ''}',
                            ),
                            trailing: features.isNotEmpty
                                ? Wrap(
                                    spacing: 4,
                                    children: features.entries.map((f) {
                                      return Chip(
                                        label: Text(
                                          '${f.key}: ${f.value}',
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                        padding: EdgeInsets.zero,
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      );
                                    }).toList(),
                                  )
                                : null,
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const ListTile(
                      leading: CircularProgressIndicator(),
                      title: Text('Loading usage stats...'),
                    ),
                    error: (_, __) => const ListTile(
                      leading: Icon(Icons.error, color: AppColors.error),
                      title: Text('Failed to load usage stats'),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_sweep, color: AppColors.error),
                title: const Text('Clear Usage Statistics'),
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
                leading: const Icon(Icons.backup_outlined, color: AppColors.info),
                title: Text(l10n.dataBackup),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Data backup
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.error),
                title: Text(l10n.deleteButton),
                subtitle: Text(l10n.confirmDelete),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showClearDataDialog(context, ref),
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

  Widget _buildSection(BuildContext context, {
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
                ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: Text(l10n.darkTheme),
              onTap: () {
                ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_suggest),
              title: Text(l10n.systemTheme),
              onTap: () {
                ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system);
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

  Future<void> _retryFailedTranscriptions(BuildContext context, WidgetRef ref) async {
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

  void _showClearUsageStatsDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Usage Statistics'),
        content: const Text('Are you sure you want to clear all usage statistics? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await StorageService.clearUsageStats();
              Navigator.pop(context);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Usage statistics cleared'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Clear'),
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
              Navigator.pop(context);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.deleteButton)),
                );
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
