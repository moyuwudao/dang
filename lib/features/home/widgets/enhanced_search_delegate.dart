import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/record_model.dart';
import '../../records/providers/record_provider.dart';

class EnhancedRecordSearchDelegate extends SearchDelegate<List<String>> {
  EnhancedRecordSearchDelegate({
    List<String> initialTags = const [],
  }) : _selectedTags = List.from(initialTags);

  List<String> _selectedTags;

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          _selectedTags.clear();
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, _selectedTags);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final allTagsAsync = ref.watch(allTagsProvider);
        final searchResults = ref.watch(searchRecordsWithTagsProvider((
          query: query,
          tags: _selectedTags,
        )));

        return Column(
          children: [
            // 标签云
            allTagsAsync.when(
              data: (tags) {
                if (tags.isEmpty) return const SizedBox.shrink();
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).dividerColor.withOpacity(0.5),
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.local_offer_outlined,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(width: 6),
                          Text(
                            '标签',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: tags.map((tag) {
                          final isSelected = _selectedTags.contains(tag);
                          return GestureDetector(
                            onTap: () {
                              if (isSelected) {
                                _selectedTags.remove(tag);
                              } else {
                                _selectedTags.add(tag);
                              }
                              query = '';
                              showSuggestions(context);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary.withOpacity(0.2)
                                    : AppColors.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(20),
                                border: isSelected
                                    ? Border.all(
                                        color: AppColors.primary.withOpacity(0.5),
                                      )
                                    : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isSelected) ...[
                                    const Icon(
                                      Icons.check,
                                      size: 14,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 4),
                                  ],
                                  Text(
                                    tag,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.textSecondary,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            // 已选标签
            if (_selectedTags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        children: _selectedTags.map((tag) {
                          return Chip(
                            label: Text(tag),
                            deleteIcon: const Icon(Icons.close, size: 14),
                            onDeleted: () {
                              _selectedTags.remove(tag);
                              query = '';
                              showSuggestions(context);
                            },
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            labelStyle: const TextStyle(color: AppColors.primary),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: searchResults.when(
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
                            '未找到相关记录',
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
                  child: Text('搜索失败: $error'),
                ),
              ),
            ),
          ],
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          context.push('/record/${record.id}');
        },
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
