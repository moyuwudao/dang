import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../data/models/record_model.dart';
import '../providers/record_provider.dart';
import '../../../routes/app_router.dart';

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
            ref.read(paginatedRecordsProvider.notifier).reset();
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
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: Text('没有更多记录了', style: TextStyle(color: Colors.grey)),
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
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('加载失败: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(paginatedRecordsProvider.notifier).reset(),
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordCard extends ConsumerWidget {
  final RecordModel record;

  const _RecordCard({required this.record});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          return await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('确认删除'),
              content: const Text('确定要删除这条记录吗？'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('删除'),
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
                            _formatDate(record.createdAt),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _buildInfoText(record),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  record.content ?? '暂无内容',
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

  Widget _buildStatusBadge() {
    if (record.transcriptionStatus == TranscriptionStatus.none) {
      return const SizedBox.shrink();
    }

    Color color;
    String text;

    switch (record.transcriptionStatus) {
      case TranscriptionStatus.pending:
        color = AppColors.warning;
        text = '待转写';
        break;
      case TranscriptionStatus.processing:
        color = AppColors.info;
        text = '转写中';
        break;
      case TranscriptionStatus.success:
        color = AppColors.success;
        text = '已完成';
        break;
      case TranscriptionStatus.failed:
        color = AppColors.error;
        text = '失败';
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

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _buildInfoText(RecordModel record) {
    final parts = <String>[];
    
    switch (record.type) {
      case RecordType.audio:
        parts.add('语音记录');
        break;
      case RecordType.ocr:
        parts.add('OCR识别');
        break;
      case RecordType.text:
        parts.add('文本记录');
        break;
    }
    
    if (record.content != null && record.content!.isNotEmpty) {
      parts.add('${record.content!.length}字');
    }
    
    return parts.join(' · ');
  }

  void _handleShare(BuildContext context, RecordModel record) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('正在准备分享...'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}
