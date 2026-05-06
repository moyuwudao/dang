import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/record_model.dart';
import '../providers/record_provider.dart';

class RecordList extends ConsumerWidget {
  const RecordList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(recordsProvider);

    return recordsAsync.when(
      data: (records) {
        if (records.isEmpty) {
          return _buildEmptyState(context);
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: records.length,
          itemBuilder: (context, index) {
            final record = records[index];
            return _RecordCard(record: record);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('加载失败: $error'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.mic_none_outlined,
            size: 64,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            '还没有记录',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右下角按钮开始录音',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textTertiary,
                ),
          ),
        ],
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
      direction: DismissDirection.endToStart,
      background: Container(
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
        ref.read(recordNotifierProvider.notifier).deleteRecord(record.id);
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
                      child: Text(
                        _formatDate(record.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textTertiary,
                            ),
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

  Widget _buildStatusBadge() {
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
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return '刚刚';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}分钟前';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}小时前';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}天前';
    } else {
      return '${date.month}月${date.day}日';
    }
  }
}
