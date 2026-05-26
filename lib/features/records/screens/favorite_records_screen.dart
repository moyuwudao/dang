import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../data/models/record_model.dart';
import '../../../data/models/tool_output_model.dart';
import '../../../data/repositories/tool_output_repository.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../providers/record_provider.dart';

class FavoriteRecordsScreen extends ConsumerStatefulWidget {
  const FavoriteRecordsScreen({super.key});

  @override
  ConsumerState<FavoriteRecordsScreen> createState() => _FavoriteRecordsScreenState();
}

class _FavoriteRecordsScreenState extends ConsumerState<FavoriteRecordsScreen> {
  List<ToolOutputModel> _favoriteToolOutputs = [];
  bool _isLoadingToolOutputs = true;

  @override
  void initState() {
    super.initState();
    _loadFavoriteToolOutputs();
  }

  Future<void> _loadFavoriteToolOutputs() async {
    setState(() => _isLoadingToolOutputs = true);
    try {
      final repository = ref.read(toolOutputRepositoryProvider);
      final allOutputs = await repository.getAllToolOutputs();
      _favoriteToolOutputs = allOutputs.where((o) => o.isFavorite).toList();
    } catch (e) {
      _favoriteToolOutputs = [];
    }
    setState(() => _isLoadingToolOutputs = false);
  }

  Future<void> _toggleToolOutputFavorite(int id, bool current) async {
    final repository = ref.read(toolOutputRepositoryProvider);
    await repository.updateFavorite(id, !current);
    await _loadFavoriteToolOutputs();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final favoriteRecordsAsync = ref.watch(favoriteRecordsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.favorites),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFavoriteToolOutputs,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(favoriteRecordsProvider);
          await _loadFavoriteToolOutputs();
        },
        child: CustomScrollView(
          slivers: [
            // 记录收藏部分
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Icon(Icons.bookmark, color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      l10n.favoriteRecords,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            favoriteRecordsAsync.when(
              data: (records) {
                if (records.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        l10n.noFavoriteRecords,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final record = records[index];
                      return _FavoriteRecordCard(record: record);
                    },
                    childCount: records.length,
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) => SliverToBoxAdapter(
                child: Center(child: Text('${l10n.loadFailed}: $error')),
              ),
            ),

            // 工具输出收藏部分
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Row(
                  children: [
                    Icon(Icons.output, color: AppColors.secondary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      l10n.toolOutputFavorites,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isLoadingToolOutputs)
              const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_favoriteToolOutputs.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    l10n.noFavoriteToolOutputs,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final output = _favoriteToolOutputs[index];
                    return _FavoriteToolOutputCard(
                      output: output,
                      onUnfavorite: () => _toggleToolOutputFavorite(output.id, output.isFavorite),
                    );
                  },
                  childCount: _favoriteToolOutputs.length,
                ),
              ),

            const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
          ],
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
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.star,
                    color: Colors.amber,
                  ),
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

  Widget _buildStatusBadge(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (record.transcriptionStatus == TranscriptionStatus.none) {
      return const SizedBox.shrink();
    }

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
        parts.add(l10n.typeVoice);
        break;
      case RecordType.ocr:
        parts.add(l10n.typeOcr);
        break;
      case RecordType.text:
        parts.add(l10n.typeText);
        break;
    }

    if (record.content != null && record.content!.isNotEmpty) {
      parts.add('${record.content!.length}${l10n.characters}');
    }

    return parts.join(' · ');
  }
}

class _FavoriteToolOutputCard extends ConsumerWidget {
  final ToolOutputModel output;
  final VoidCallback onUnfavorite;

  const _FavoriteToolOutputCard({
    required this.output,
    required this.onUnfavorite,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: () => _showDetail(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.output,
                      size: 16,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      output.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.star, color: Colors.amber),
                    onPressed: onUnfavorite,
                    tooltip: l10n.unfavorite,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                output.content.length > 120
                    ? '${output.content.substring(0, 120)}...'
                    : output.content,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (output.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: output.tags.map((tag) {
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

  void _showDetail(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              output.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.share_outlined),
                            onPressed: () {
                              Share.share(
                                '${output.title}\n\n${output.content}\n\n${l10n.appName}',
                                subject: output.title,
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy_outlined),
                            onPressed: () async {
                              await Clipboard.setData(
                                ClipboardData(text: output.content),
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(l10n.copiedToClipboard)),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${output.createdAt.year}/${output.createdAt.month.toString().padLeft(2, '0')}/${output.createdAt.day.toString().padLeft(2, '0')} ${output.createdAt.hour.toString().padLeft(2, '0')}:${output.createdAt.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (output.tags.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
                      spacing: 8,
                      children: output.tags.map((tag) {
                        return Chip(
                          label: Text(tag),
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          labelStyle: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                          ),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        );
                      }).toList(),
                    ),
                  ),
                const Divider(),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    child: SelectableText(
                      output.content,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
