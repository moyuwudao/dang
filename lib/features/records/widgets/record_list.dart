import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../data/models/record_model.dart';
import '../providers/record_provider.dart';
import '../../../routes/app_router.dart';
import '../../../l10n/generated/app_localizations.dart';

// l10n keys used: noMoreRecords, loadFailed, retryButton, cancelButton, deleteButton, confirmDeleteTitle, confirmDelete, year, month, day, voiceRecord, ocrRecord, textRecord, characters, statusPending, statusProcessing, statusCompleted, statusFailed, preparingToShare

class RecordList extends ConsumerStatefulWidget {
  const RecordList({super.key});

  @override
  ConsumerState<RecordList> createState() => _RecordListState();
}

class _RecordListState extends ConsumerState<RecordList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      ref.read(paginatedRecordsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final recordsAsync = ref.watch(paginatedRecordsProvider);

    return recordsAsync.when(
      data: (records) {
        if (records.isEmpty) {
          return EmptyStateType.records(
            onAdd: () => context.goNamed(AppRoute.recording.name),
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(paginatedRecordsProvider);
            await ref.read(paginatedRecordsProvider.future);
          },
          child: ListView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: records.length + 1,
            itemBuilder: (context, index) {
              if (index == records.length) {
                final hasMore = ref.read(paginatedRecordsProvider.notifier).hasMore;
                final isLoading = ref.read(paginatedRecordsProvider.notifier).isLoading;
                if (isLoading) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (hasMore) {
                  return const SizedBox.shrink();
                }
                final l10n = AppLocalizations.of(context)!;
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(l10n.noMoreRecords, style: const TextStyle(color: Colors.grey)),
                  ),
                );
              }
              final record = records[index];
              return _RecordCard(record: record);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) {
        final l10n = AppLocalizations.of(context)!;
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${l10n.loadFailed}: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(paginatedRecordsProvider.notifier).reset(),
                child: Text(l10n.retryButton),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RecordCard extends ConsumerWidget {
  final RecordModel record;

  const _RecordCard({required this.record});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Dismissible(
      key: Key('record_${record.id}'),
      direction: DismissDirection.horizontal,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.share,
          color: Colors.white,
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          ref.read(recordNotifierProvider.notifier).deleteRecord(record.id);
        } else {
          _handleShare(context, record);
        }
      },
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          final l10n = AppLocalizations.of(context)!;
          return await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: Text(l10n.confirmDeleteTitle),
              content: Text(l10n.confirmDelete),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(l10n.cancelButton),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: Text(l10n.deleteButton),
                ),
              ],
            ),
          );
        }
        return true;
      },
      child: Card(
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatDate(context, record.createdAt),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _buildInfoText(context, record),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(context),
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

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        if (record.isRealtime)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    if (record.transcriptionStatus == TranscriptionStatus.none) {
      return const SizedBox.shrink();
    }

    Color color;
    String text;

    final l10n = AppLocalizations.of(context)!;
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

  String _formatDate(BuildContext context, DateTime date) {
    final l10n = AppLocalizations.of(context)!;
    return '${date.year}${l10n.year}${date.month}${l10n.month}${date.day}${l10n.day} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _buildInfoText(BuildContext context, RecordModel record) {
    final l10n = AppLocalizations.of(context)!;
    final parts = <String>[];
    
    switch (record.type) {
      case RecordType.audio:
        parts.add(l10n.voiceRecord);
        break;
      case RecordType.ocr:
        parts.add(l10n.ocrRecord);
        break;
      case RecordType.text:
        parts.add(l10n.textRecord);
        break;
    }
    
    if (record.content != null && record.content!.isNotEmpty) {
      parts.add('${record.content!.length}${l10n.characters}');
    }
    
    return parts.join(' · ');
  }

  void _handleShare(BuildContext context, RecordModel record) {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.preparingToShare),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}
