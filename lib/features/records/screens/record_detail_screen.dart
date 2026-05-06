import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/models/ai_model_config.dart';
import '../../../core/models/ai_role.dart';
import '../../../core/models/transcription_progress.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/role_service.dart';
import '../../../core/services/transcription_service.dart';
import '../../../data/models/record_model.dart';
import '../../../data/repositories/record_repository.dart';
import '../../settings/providers/settings_provider.dart';
import '../providers/record_provider.dart';
import '../providers/transcription_progress_provider.dart';
import '../widgets/audio_player_widget.dart';
import '../widgets/transcription_progress_widget.dart';

class RecordDetailScreen extends ConsumerWidget {
  final int recordId;

  const RecordDetailScreen({super.key, required this.recordId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordAsync = ref.watch(recordDetailProvider(recordId));

    return recordAsync.when(
      data: (record) {
        if (record == null) {
          return const Scaffold(
            body: Center(child: Text('记录不存在')),
          );
        }
        return _RecordDetailView(record: record);
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('加载失败: $error')),
      ),
    );
  }
}

class _RecordDetailView extends ConsumerStatefulWidget {
  final RecordModel record;

  const _RecordDetailView({required this.record});

  @override
  ConsumerState<_RecordDetailView> createState() => _RecordDetailViewState();
}

class _RecordDetailViewState extends ConsumerState<_RecordDetailView> {
  late TextEditingController _contentController;
  bool _isEditing = false;
  bool _isRetrying = false;
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.record.content);
  }

  @override
  void didUpdateWidget(covariant _RecordDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.record.content != widget.record.content) {
      _contentController.text = widget.record.content ?? '';
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveContent() async {
    await ref.read(recordNotifierProvider.notifier).updateRecordContent(
          widget.record.id,
          _contentController.text,
        );
    setState(() {
      _isEditing = false;
    });
  }

  Future<void> _deleteRecord() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('此操作不可恢复，是否继续？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(recordNotifierProvider.notifier).deleteRecord(widget.record.id);
      if (mounted) {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.record;
    final progress = ref.watch(transcriptionProgressProvider)[record.id];

    return Scaffold(
      appBar: AppBar(
        title: Text(_formatDate(record.createdAt)),
        actions: [
          if (_isEditing)
            TextButton(
              onPressed: _saveContent,
              child: const Text('保存'),
            )
          else
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: _shareRecord,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _deleteRecord,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildTypeChip(),
                const SizedBox(width: 8),
                _buildStatusChip(),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    record.isFavorite ? Icons.star : Icons.star_border,
                    color: record.isFavorite ? AppColors.warning : null,
                  ),
                  onPressed: () {
                    ref.read(recordNotifierProvider.notifier).toggleFavorite(
                          record.id,
                          !record.isFavorite,
                        );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Transcription progress
            if (progress != null) ...[
              TranscriptionProgressWidget(progress: progress),
              const SizedBox(height: 16),
            ],

            if (_isEditing)
              TextField(
                controller: _contentController,
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: '输入内容...',
                  border: InputBorder.none,
                ),
              )
            else ...[
              if (record.content != null && record.content!.isNotEmpty)
                SelectableText(
                  record.content!,
                  style: Theme.of(context).textTheme.bodyLarge,
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        record.transcriptionStatus == TranscriptionStatus.pending
                            ? Icons.hourglass_empty
                            : record.transcriptionStatus == TranscriptionStatus.processing
                                ? Icons.sync
                                : record.transcriptionStatus == TranscriptionStatus.failed
                                    ? Icons.error_outline
                                    : Icons.description_outlined,
                        size: 48,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        record.transcriptionStatus == TranscriptionStatus.pending
                            ? '等待转写...'
                            : record.transcriptionStatus == TranscriptionStatus.processing
                                ? '转写中...'
                                : record.transcriptionStatus == TranscriptionStatus.failed
                                    ? '转写失败'
                                    : '暂无内容',
                        style: const TextStyle(color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                ),
            ],

            const SizedBox(height: 24),

            if (record.tags.isNotEmpty) ...[
              Text('标签', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: record.tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    side: BorderSide.none,
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () {
                      final newTags = record.tags.where((t) => t != tag).toList();
                      ref.read(recordNotifierProvider.notifier).updateTags(record.id, newTags);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Action buttons
            if (record.type == RecordType.audio && record.audioPath != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isRetrying ? null : _retryTranscription,
                  icon: _isRetrying
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.refresh),
                  label: Text(_isRetrying ? '转写中...' : '重新转写'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: record.transcriptionStatus == TranscriptionStatus.failed
                        ? AppColors.error
                        : AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],

            // AI Analysis button
            if (record.content != null && record.content!.isNotEmpty) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isAnalyzing ? null : _analyzeWithAI,
                  icon: _isAnalyzing
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.psychology),
                  label: Text(_isAnalyzing ? '分析中...' : 'AI分析文本'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Supplement idea button
            if (record.content != null && record.content!.isNotEmpty) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _showSupplementDialog,
                  icon: const Icon(Icons.add_comment),
                  label: const Text('补充完善想法'),
                ),
              ),
              const SizedBox(height: 16),
            ],

            TextButton.icon(
              onPressed: () => _showAddTagDialog(),
              icon: const Icon(Icons.add),
              label: const Text('添加标签'),
            ),

            const SizedBox(height: 24),

            if (record.type == RecordType.audio && record.audioPath != null)
              AudioPlayerWidget(audioPath: record.audioPath!),

            if (record.type == RecordType.ocr && record.imagePath != null)
              _buildImagePreview(),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip() {
    IconData icon;
    String label;
    Color color;

    switch (widget.record.type) {
      case RecordType.audio:
        icon = Icons.mic;
        label = '语音';
        color = AppColors.primary;
        break;
      case RecordType.ocr:
        icon = Icons.camera_alt;
        label = 'OCR';
        color = AppColors.secondary;
        break;
    }

    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(label),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide.none,
      labelStyle: TextStyle(color: color, fontSize: 12),
    );
  }

  Widget _buildStatusChip() {
    Color color;
    String text;

    switch (widget.record.transcriptionStatus) {
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

    return Chip(
      label: Text(text),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide.none,
      labelStyle: TextStyle(color: color, fontSize: 12),
    );
  }

  Future<void> _shareRecord() async {
    final text = widget.record.content ?? '';
    final date = _formatDate(widget.record.createdAt);
    final shareText = '$date\n\n$text';

    await Share.share(shareText, subject: '畅记分享');
  }

  Future<void> _retryTranscription() async {
    setState(() {
      _isRetrying = true;
    });

    final progressNotifier = ref.read(transcriptionProgressProvider.notifier);
    progressNotifier.startTranscription(widget.record.id);

    try {
      await ref.read(transcriptionServiceProvider).retryTranscription(
        widget.record.id,
        onProgress: (step, detail) {
          progressNotifier.updateStep(widget.record.id, step, TranscriptionStepStatus.running);
          progressNotifier.setCurrentAction(widget.record.id, detail);
        },
      );

      progressNotifier.updateStep(widget.record.id, 'save', TranscriptionStepStatus.success);
      progressNotifier.setCurrentAction(widget.record.id, '转写完成！');

      ref.invalidate(recordDetailProvider(widget.record.id));

      if (mounted) {
        final updatedRecord = await ref.read(recordRepositoryProvider).getRecordById(widget.record.id);
        final transcriptionText = updatedRecord?.content;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(transcriptionText != null && transcriptionText.isNotEmpty
                ? '转写成功'
                : '转写完成，但未获取到文本内容'),
            backgroundColor: transcriptionText != null && transcriptionText.isNotEmpty
                ? AppColors.success
                : AppColors.warning,
          ),
        );
      }
    } catch (e) {
      progressNotifier.setError(widget.record.id, e.toString());
      progressNotifier.updateStep(widget.record.id, 'upload', TranscriptionStepStatus.failed);
      ref.invalidate(recordDetailProvider(widget.record.id));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('转写失败: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRetrying = false;
        });
      }
    }
  }

  Future<void> _analyzeWithAI() async {
    // Show role selection dialog first
    final selectedRole = await _showRoleSelectionDialog();
    if (selectedRole == null) return;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final result = await ref.read(transcriptionServiceProvider).analyzeText(
        widget.record.content!,
        systemPrompt: selectedRole.systemPrompt,
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.psychology, size: 20),
                const SizedBox(width: 8),
                Text('${selectedRole.name}分析'),
              ],
            ),
            content: SingleChildScrollView(
              child: Text(result),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('关闭'),
              ),
              TextButton(
                onPressed: () {
                  _contentController.text = '${widget.record.content}\n\n--- ${selectedRole.name}分析 ---\n$result';
                  _saveContent();
                  Navigator.pop(context);
                },
                child: const Text('追加到记录'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('分析失败: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  Future<dynamic> _showRoleSelectionDialog() async {
    final roles = await RoleService.getAllRoles();

    if (!mounted) return null;

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择分析角色'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: roles.length,
            itemBuilder: (context, index) {
              final role = roles[index];
              return ListTile(
                leading: Icon(
                  role.isBuiltIn ? Icons.verified : Icons.person_outline,
                  color: role.isBuiltIn ? AppColors.success : AppColors.primary,
                ),
                title: Text(role.name),
                subtitle: Text(
                  role.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => Navigator.pop(context, role),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/settings/roles');
            },
            child: const Text('管理角色'),
          ),
        ],
      ),
    );
  }

  void _showSupplementDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('补充完善想法'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: '在此补充你的想法...',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final supplement = controller.text.trim();
              if (supplement.isNotEmpty) {
                final newContent = '${widget.record.content}\n\n[补充 ${DateTime.now().toString().substring(0, 16)}]\n$supplement';
                await ref.read(recordNotifierProvider.notifier).updateRecordContent(
                  widget.record.id,
                  newContent,
                );
                ref.invalidate(recordDetailProvider(widget.record.id));
              }
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('原始图片', style: Theme.of(context).textTheme.titleMedium),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            child: Image.file(
              File(widget.record.imagePath!),
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddTagDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加标签'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '输入标签名称', prefixText: '#'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final tag = controller.text.trim();
              if (tag.isNotEmpty) {
                final newTags = [...widget.record.tags, tag];
                ref.read(recordNotifierProvider.notifier).updateTags(widget.record.id, newTags);
              }
              Navigator.pop(context);
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
