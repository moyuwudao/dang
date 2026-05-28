import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/ai_model_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/tag_selector.dart';
import '../../../core/widgets/expandable_text_field.dart';
import '../../../data/models/record_model.dart';
import '../../../data/repositories/record_repository.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../records/providers/record_provider.dart';
import '../../records/widgets/record_list.dart';
import '../../settings/providers/settings_provider.dart';
import '../../workbench/providers/workbench_provider.dart';
import '../widgets/enhanced_search_delegate.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const _widgetChannel = MethodChannel('com.changji.app/widget');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkWidgetLaunchAction();
    });
    _widgetChannel.setMethodCallHandler(_handleMethodCall);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (call.method == 'widgetAction') {
      final String? action = call.arguments as String?;
      if (action != null && mounted) {
        _navigateByAction(action);
      }
    }
  }

  void _navigateByAction(String action) {
    switch (action) {
      case 'start_recording':
        context.push('/recording');
        break;
      case 'start_camera':
        context.push('/ocr');
        break;
      case 'start_quick_note':
        context.push('/quick-note');
        break;
    }
  }

  Future<void> _checkWidgetLaunchAction() async {
    try {
      final String? action =
          await _widgetChannel.invokeMethod('getLaunchAction');
      if (action != null && mounted) {
        _navigateByAction(action);
      }
    } catch (e) {
      // Widget launch action not available
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final configuredProviderAsync = ref.watch(configuredProviderProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appName),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: EnhancedRecordSearchDelegate(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.star_outline),
            onPressed: () => context.push('/favorites'),
          ),
          IconButton(
            icon: const Icon(Icons.dashboard_outlined),
            onPressed: () => context.push('/workbench'),
            tooltip: l10n.workbench,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: const RecordList(),
      floatingActionButton: configuredProviderAsync.when(
        data: (configuredProvider) {
          final canRecord = AiModelConfig.canUseFeature(
              AppFeature.recording, configuredProvider);
          final canOcr =
              AiModelConfig.canUseFeature(AppFeature.ocr, configuredProvider);

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHomeQuickActions(),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'text',
                onPressed: () => _showTextInputDialog(context, ref),
                backgroundColor: AppColors.info,
                child: const Icon(Icons.text_fields),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'ocr',
                onPressed: canOcr ? () => context.push('/ocr') : null,
                backgroundColor:
                    canOcr ? AppColors.secondary : AppColors.textTertiary,
                child: const Icon(Icons.camera_alt_outlined),
              ),
              const SizedBox(height: 8),
              FloatingActionButton(
                heroTag: 'record',
                onPressed: canRecord ? () => context.push('/recording') : null,
                backgroundColor:
                    canRecord ? AppColors.primary : AppColors.textTertiary,
                child: const Icon(Icons.mic),
              ),
            ],
          );
        },
        loading: () => const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 8),
            FloatingActionButton.small(
              heroTag: 'text',
              onPressed: null,
              backgroundColor: AppColors.textTertiary,
              child: Icon(Icons.text_fields),
            ),
            SizedBox(height: 8),
            FloatingActionButton.small(
              heroTag: 'ocr',
              onPressed: null,
              backgroundColor: AppColors.textTertiary,
              child: Icon(Icons.camera_alt_outlined),
            ),
            SizedBox(height: 8),
            FloatingActionButton(
              heroTag: 'record',
              onPressed: null,
              backgroundColor: AppColors.textTertiary,
              child: Icon(Icons.mic),
            ),
          ],
        ),
        error: (_, __) => const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 8),
            FloatingActionButton.small(
              heroTag: 'text',
              onPressed: null,
              backgroundColor: AppColors.textTertiary,
              child: Icon(Icons.text_fields),
            ),
            SizedBox(height: 8),
            FloatingActionButton.small(
              heroTag: 'ocr',
              onPressed: null,
              backgroundColor: AppColors.textTertiary,
              child: Icon(Icons.camera_alt_outlined),
            ),
            SizedBox(height: 8),
            FloatingActionButton(
              heroTag: 'record',
              onPressed: null,
              backgroundColor: AppColors.textTertiary,
              child: Icon(Icons.mic),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showTextInputDialog(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final List<String> tags = [];

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(l10n.textInput),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ExpandableTextField(
                    controller: controller,
                    hintText: l10n.textInputHint,
                    minLines: 5,
                    maxLines: 8,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        l10n.addTagOptional,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TagSelector(
                          selectedTags: tags,
                          onTagsChanged: (newTags) {
                            setState(() {
                              tags.clear();
                              tags.addAll(newTags);
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(l10n.cancelButton),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(l10n.saveButton),
              ),
            ],
          );
        },
      ),
    );

    if (result == true && controller.text.trim().isNotEmpty) {
      try {
        final recordRepository = ref.read(recordRepositoryProvider);
        await recordRepository.createRecordFromFields(
          type: RecordType.audio,
          content: controller.text.trim(),
          tags: List<String>.from(tags),
          transcriptionStatus: TranscriptionStatus.none,
        );

        // 刷新列表
        ref.invalidate(paginatedRecordsProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.saveSuccess),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${l10n.saveFailed}: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }

    controller.dispose();
  }

  Widget _buildHomeQuickActions() {
    final workbenchState = ref.watch(workbenchProvider);
    final homeTools = workbenchState.valueOrNull?.tools.where((t) => 
      t.isEnabled && (workbenchState.valueOrNull?.layoutConfig.showInHome[t.id] ?? false)
    ).toList() ?? [];

    if (homeTools.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: homeTools.map((tool) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: FloatingActionButton.small(
            heroTag: 'home_tool_${tool.id}',
            onPressed: () => context.push(tool.route),
            backgroundColor: tool.color,
            child: Icon(tool.icon),
          ),
        );
      }).toList(),
    );
  }
}

class RecordSearchDelegate extends SearchDelegate {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context)!.searchHint),
      );
    }
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final searchResults = ref.watch(searchRecordsProvider(query));
        return searchResults.when(
          data: (records) {
            if (records.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.search_off_outlined,
                      size: 64,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.noSearchResults,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: records.length,
              itemBuilder: (context, index) {
                final record = records[index];
                return _SearchRecordCard(record: record);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text('${AppLocalizations.of(context)!.searchFailed}: $error'),
          ),
        );
      },
    );
  }
}

class _SearchRecordCard extends StatelessWidget {
  final RecordModel record;

  const _SearchRecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/record/${record.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildTypeIcon(),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _formatDate(context, l10n, record.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textTertiary,
                          ),
                    ),
                  ),
                  _buildStatusBadge(context, l10n),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                record.content ?? l10n.noContent,
                style: Theme.of(context).textTheme.bodyLarge,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (record.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: record.tags.map((tag) {
                    return Chip(
                      label: Text(tag),
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      side: BorderSide.none,
                      padding: EdgeInsets.zero,
                      labelStyle: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeIcon() {
    IconData icon;
    Color color;

    switch (record.type) {
      case RecordType.audio:
        icon = Icons.mic;
        color = AppColors.primary;
        break;
      case RecordType.ocr:
        icon = Icons.camera_alt;
        color = AppColors.secondary;
        break;
      case RecordType.text:
        icon = Icons.text_fields;
        color = AppColors.info;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }

  Widget _buildStatusBadge(BuildContext context, AppLocalizations l10n) {
    Color color;
    String text;

    switch (record.transcriptionStatus) {
      case TranscriptionStatus.pending:
        color = AppColors.warning;
        text = l10n.statusPending;
        break;
      case TranscriptionStatus.processing:
        color = AppColors.info;
        text = l10n.statusProcessing;
        break;
      case TranscriptionStatus.success:
        color = AppColors.success;
        text = l10n.statusCompleted;
        break;
      case TranscriptionStatus.failed:
        color = AppColors.error;
        text = l10n.statusFailed;
        break;
      case TranscriptionStatus.none:
        color = AppColors.textTertiary;
        text = '';
        break;
    }

    if (record.transcriptionStatus == TranscriptionStatus.none) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatDate(BuildContext context, AppLocalizations l10n, DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return l10n.justNow;
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}${l10n.minutesAgo}';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}${l10n.hoursAgo}';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}${l10n.daysAgo}';
    } else {
      return '${date.month}${l10n.month}${date.day}${l10n.day}';
    }
  }
}
