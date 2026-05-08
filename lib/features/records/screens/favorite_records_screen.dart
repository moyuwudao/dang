import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../data/models/record_model.dart';
import '../providers/record_provider.dart';

class FavoriteRecordsScreen extends ConsumerWidget {
  const FavoriteRecordsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteRecordsAsync = ref.watch(favoriteRecordsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('收藏记录'),
      ),
      body: favoriteRecordsAsync.when(
        data: (records) {
          if (records.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.star_border,
              title: '暂无收藏',
              description: '点击记录中的星星图标收藏记录',
              onAction: () => context.pop(),
              actionText: '返回',
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(favoriteRecordsProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: records.length,
              itemBuilder: (context, index) {
                final record = records[index];
                return _FavoriteRecordCard(record: record);
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
                onPressed: () => ref.refresh(favoriteRecordsProvider),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoriteRecordCard extends ConsumerWidget {
  final RecordModel record;

  const _FavoriteRecordCard({required this.record});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  const SizedBox(width: 8),
                  Icon(
                    Icons.star,
                    color: AppColors.warning,
                  ),
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
}