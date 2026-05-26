import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/transcription_progress.dart';
import '../../../core/models/ai_role.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/role_service.dart';
import '../../../core/services/transcription_service.dart';
import '../../../core/services/share_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/app_logger.dart';
import '../../../data/models/record_model.dart';
import '../../../data/repositories/record_repository.dart';
import '../providers/record_provider.dart';
import '../providers/transcription_progress_provider.dart';
import '../widgets/audio_player_widget.dart';
import '../widgets/transcription_progress_widget.dart';
import '../widgets/expandable_text_section.dart';
import '../widgets/chunk_selection_dialog.dart';
import '../widgets/supplement_input_dialog.dart';
import '../widgets/ai_analysis_card.dart';
import '../widgets/ai_analysis_panel.dart';
import '../../../core/widgets/tag_selector.dart';
import '../../../l10n/generated/app_localizations.dart';

final shareServiceProvider = Provider((ref) => ShareService());

class RecordDetailScreen extends ConsumerWidget {
  final int recordId;

  const RecordDetailScreen({super.key, required this.recordId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordAsync = ref.watch(recordDetailProvider(recordId));
    final l10n = AppLocalizations.of(context)!;

    return recordAsync.when(
      data: (record) {
        if (record == null) {
          return Scaffold(
            body: Center(child: Text(l10n.recordNotFound)),
          );
        }
        return _RecordDetailView(record: record);
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('${l10n.loadFailed}: $error')),
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
  static const int _maxDebugLogs = 200;
  bool _isRetrying = false;
  bool _isAnalyzing = false;
  AiRole? _selectedRole;
  List<AiRole> _roles = [];
  final List<LogEntry> _debugLogs = [];
  void Function(LogEntry)? _logListener;

  @override
  void initState() {
    super.initState();
    _loadRoles();
    _setupLogListener();
  }

  void _setupLogListener() {
    final existingLogs = AppLogger().filterByTag('Transcription');
    _debugLogs.addAll(existingLogs);
    if (_debugLogs.length > _maxDebugLogs) {
      _debugLogs.removeRange(0, _debugLogs.length - _maxDebugLogs);
    }
    _logListener = (entry) {
      if (entry.tag == 'Transcription') {
        setState(() {
          _debugLogs.add(entry);
          if (_debugLogs.length > _maxDebugLogs) {
            _debugLogs.removeAt(0);
          }
        });
      }
    };
    AppLogger().addListener(_logListener!);
  }

  @override
  void dispose() {
    if (_logListener != null) {
      AppLogger().removeListener(_logListener!);
    }
    super.dispose();
  }

  Future<void> _loadRoles() async {
    final roles = await RoleService.getAllRoles();
    setState(() {
      _roles = roles;
    });
  }

  Future<void> _deleteRecord() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDeleteTitle),
        content: Text(l10n.deleteRecordConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l10n.deleteButton),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // 先保存到回收站
      await StorageServiceRecycleBin.addToRecycleBin(widget.record);
      // 再从数据库删除
      await ref
          .read(recordNotifierProvider.notifier)
          .deleteRecord(widget.record.id);
      if (mounted) {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.record;
    final progress = ref.watch(transcriptionProgressProvider).valueOrNull?[record.id];
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(_formatDate(record.createdAt)),
        actions: [
          if (_isRetrying)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.primary),
              onPressed: _showRetryOptions,
              tooltip: l10n.retranscribe,
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

            // Original transcription text (expandable, default 3 lines)
            ExpandableTextSection(
              title: l10n.originalTranscription,
              content: record.content,
              icon: Icons.description_outlined,
              iconColor: AppColors.primary,
              editable: true,
              initiallyExpanded: false,
              maxLines: 3,
              directEdit: true,
              onContentChanged: (newContent) async {
                await ref
                    .read(recordNotifierProvider.notifier)
                    .updateRecordContent(
                      widget.record.id,
                      newContent,
                    );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.contentUpdated),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
            ),

            // Debug logs section
            if (_debugLogs.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade700),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.transcriptionLog,
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            if (_isRetrying)
                              const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white70),
                                ),
                              ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _debugLogs.clear();
                                });
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                l10n.clear,
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        shrinkWrap: true,
                        reverse: true,
                        itemCount: _debugLogs.length,
                        itemBuilder: (context, index) {
                          final log = _debugLogs[_debugLogs.length - 1 - index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              '[${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}] ${log.message}',
                              style: TextStyle(
                                color: log.level == LogLevel.error
                                    ? Colors.red.shade300
                                    : log.level == LogLevel.warning
                                        ? Colors.orange.shade300
                                        : Colors.grey.shade400,
                                fontSize: 11,
                                fontFamily: 'monospace',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Supplement idea button
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _showSupplementInputDialog,
                icon: const Icon(Icons.add_comment),
                label: Text(l10n.supplementIdeas),
              ),
            ),

            // Supplements
            if (record.supplements.isNotEmpty) _buildSupplementsSection(record),

            const SizedBox(height: 16),

            // Auto Analysis Results (only show results from saved auto-analysis config)
            _buildAutoAnalysisResultsSection(record),

            // AI Analysis Panel (manual analysis results)
            AiAnalysisPanel(record: record),

            const SizedBox(height: 16),

            // Tags section - single row layout
            _buildTagsSection(record),

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

  Widget _buildSupplementsSection(RecordModel record) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.add_comment, size: 20, color: AppColors.info),
                const SizedBox(width: 8),
                Text(
                  l10n.supplementContent,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          ...record.supplements.map((supplement) {
            return Column(
              children: [
                ListTile(
                  leading: Icon(
                    supplement.type == 'audio'
                        ? Icons.mic
                        : supplement.type == 'image'
                            ? Icons.image
                            : Icons.text_fields,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    supplement.type == 'text'
                        ? supplement.content
                        : '${supplement.type == 'audio' ? l10n.audioSupplement : l10n.imageSupplement}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${supplement.createdAt.month}月${supplement.createdAt.day}日 ${supplement.createdAt.hour}:${supplement.createdAt.minute.toString().padLeft(2, '0')}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 转写按钮（仅音频和图片显示）
                      if (supplement.type != 'text' &&
                          (supplement.transcribedContent == null ||
                              supplement.transcribedContent!.isEmpty))
                        IconButton(
                          icon: const Icon(Icons.transcribe,
                              color: AppColors.info),
                          onPressed: () => _transcribeSupplement(supplement),
                          tooltip: l10n.transcribing,
                        ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: AppColors.error),
                        onPressed: () => _deleteSupplement(supplement.id),
                      ),
                    ],
                  ),
                ),
                // 显示转写后的文本
                if (supplement.transcribedContent != null &&
                    supplement.transcribedContent!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(72, 0, 16, 8),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.check_circle,
                                  size: 14, color: AppColors.success),
                              const SizedBox(width: 4),
                              Text(
                                l10n.transcriptionResult,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            supplement.transcribedContent!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Future<void> _deleteSupplement(String supplementId) async {
    final newSupplements =
        widget.record.supplements.where((s) => s.id != supplementId).toList();
    await ref.read(recordNotifierProvider.notifier).updateSupplements(
          widget.record.id,
          newSupplements,
        );
    ref.invalidate(recordDetailProvider(widget.record.id));
  }

  Future<void> _transcribeSupplement(SupplementItem supplement) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.transcribingSupplement),
          duration: const Duration(seconds: 1),
        ),
      );

      final transcriptionService = ref.read(transcriptionServiceProvider);
      final transcribed =
          await transcriptionService.transcribeSupplement(supplement);

      // 更新补充内容列表
      final newSupplements = widget.record.supplements.map((s) {
        if (s.id == supplement.id) {
          return transcribed;
        }
        return s;
      }).toList();

      await ref.read(recordNotifierProvider.notifier).updateSupplements(
            widget.record.id,
            newSupplements,
          );
      ref.invalidate(recordDetailProvider(widget.record.id));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.supplementTranscriptionComplete),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.transcribeError}: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _showRetryOptions() async {
    final l10n = AppLocalizations.of(context)!;
    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.retranscribeOptions),
        content: Text(l10n.selectParagraphsToRetranscribe),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: Text(l10n.cancelButton),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'all'),
            child: Text(l10n.retranscribeAll),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'select'),
            child: Text(l10n.selectParagraphs),
          ),
        ],
      ),
    );

    if (action == 'cancel' || action == null) return;

    if (action == 'all') {
      await _retryTranscription();
    } else if (action == 'select') {
      await _retrySelectedChunks();
    }
  }

  Future<void> _retrySelectedChunks() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final chunks = await ref
          .read(transcriptionServiceProvider)
          .getAudioChunks(widget.record.audioPath!);

      if (!mounted) return;

      final selectedIndices = await showDialog<List<int>>(
        context: context,
        builder: (context) => ChunkSelectionDialog(
          chunks: chunks,
          title: l10n.selectParagraphsToRetranscribe,
        ),
      );

      if (selectedIndices == null || selectedIndices.isEmpty) return;

      setState(() {
        _isRetrying = true;
        _debugLogs.clear();
      });

      final progressNotifier = ref.read(transcriptionProgressProvider.notifier);
      progressNotifier.startTranscription(widget.record.id);

      final result =
          await ref.read(transcriptionServiceProvider).retranscribeChunks(
        widget.record.audioPath!,
        chunkIndices: selectedIndices,
        onProgress: (step, detail) {
          AppLogger().i('Transcription', '$step: $detail');
          progressNotifier.updateStep(
              widget.record.id, step, TranscriptionStepStatus.running);
          progressNotifier.setCurrentAction(widget.record.id, detail);
        },
      );

      // Merge with existing content
      final existingContent = widget.record.content ?? '';
      final newContent = existingContent.isNotEmpty
          ? '$existingContent\n\n[重新转写段落: ${selectedIndices.map((i) => i + 1).join(', ')}]\n$result'
          : result;

      await ref.read(recordNotifierProvider.notifier).updateRecordContent(
            widget.record.id,
            newContent,
          );

      progressNotifier.updateStep(
          widget.record.id, 'save', TranscriptionStepStatus.success);
      progressNotifier.setCurrentAction(widget.record.id, l10n.transcriptionCompleteWithResult);
      ref.invalidate(recordDetailProvider(widget.record.id));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.selectedParagraphsSuccess),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.transcribeError}: $e'),
            backgroundColor: AppColors.error,
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

  Future<void> _retryTranscription() async {
    if (_isRetrying) return;

    setState(() {
      _isRetrying = true;
      _debugLogs.clear();
    });

    if (!mounted) {
      setState(() {
        _isRetrying = false;
      });
      return;
    }

    final progressNotifier = ref.read(transcriptionProgressProvider.notifier);
    progressNotifier.startTranscription(widget.record.id);

    final wasSuccessful =
        widget.record.transcriptionStatus == TranscriptionStatus.success;
    final originalContent = widget.record.content ?? '';

    try {
      final result = await ref.read(transcriptionServiceProvider).transcribeAudio(
            widget.record.audioPath!,
            onProgress: (step, detail) {
              if (!mounted) return;
              AppLogger().i('Transcription', '$step: $detail');
              progressNotifier.updateStep(
                  widget.record.id, step, TranscriptionStepStatus.running);
              progressNotifier.setCurrentAction(widget.record.id, detail);

              if (!wasSuccessful &&
                  detail.contains('转写完成') &&
                  !detail.contains('失败')) {
                progressNotifier.updatePartialContent(widget.record.id, detail);
              }
            },
          );

      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      progressNotifier.updateStep(
          widget.record.id, 'save', TranscriptionStepStatus.success);
      progressNotifier.setCurrentAction(widget.record.id, l10n.transcriptionCompleteWithResult);

      await ref.read(recordRepositoryProvider).updateRecordContent(
            widget.record.id,
            result,
          );
      await ref.read(recordRepositoryProvider).updateTranscriptionStatus(
            widget.record.id,
            TranscriptionStatus.success,
            null,
          );

      ref.invalidate(recordDetailProvider(widget.record.id));

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                result.isNotEmpty ? l10n.transcriptionSuccess : l10n.transcriptionSuccessNoContent),
            backgroundColor: result.isNotEmpty
                ? AppColors.success
                : AppColors.warning,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      progressNotifier.setError(widget.record.id, e.toString());
      progressNotifier.updateStep(
          widget.record.id, 'upload', TranscriptionStepStatus.failed);

      if (wasSuccessful) {
        await ref.read(recordRepositoryProvider).updateRecordContent(
              widget.record.id,
              originalContent,
            );
      }

      await ref.read(recordRepositoryProvider).updateTranscriptionStatus(
            widget.record.id,
            TranscriptionStatus.failed,
            e.toString(),
          );

      ref.invalidate(recordDetailProvider(widget.record.id));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.transcribeError}: $e'),
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

  Future<dynamic> _showRoleSelectionDialog() async {
    final roles = await RoleService.getAllRoles();

    if (!mounted) return null;

    final l10n = AppLocalizations.of(context)!;
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.selectAnalysisRole),
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
            child: Text(l10n.cancelButton),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/settings/roles');
            },
            child: Text(l10n.manageRoles),
          ),
        ],
      ),
    );
  }

  Future<void> _showSupplementInputDialog() async {
    final result = await showDialog<SupplementItem>(
      context: context,
      builder: (context) => const SupplementInputDialog(),
    );

    if (result == null) return;

    final newSupplements = [...widget.record.supplements, result];
    await ref.read(recordNotifierProvider.notifier).updateSupplements(
          widget.record.id,
          newSupplements,
        );
    ref.invalidate(recordDetailProvider(widget.record.id));

    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.supplementAdded),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _shareRecord() async {
    final shareService = ref.read(shareServiceProvider);
    final targets = shareService.getAvailableTargets();

    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;
    final selectedTarget = await showDialog<ShareTarget>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.selectShareMethod),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: targets.length,
            itemBuilder: (context, index) {
              final target = targets[index];
              return ListTile(
                leading: Icon(_getShareIcon(target), color: AppColors.primary),
                title: Text(target.name),
                onTap: () => Navigator.pop(context, target),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancelButton),
          ),
        ],
      ),
    );

    if (selectedTarget != null) {
      await shareService.shareRecord(widget.record, target: selectedTarget);
    }
  }

  IconData _getShareIcon(ShareTarget target) {
    switch (target) {
      case ShareTarget.system:
        return Icons.share;
      case ShareTarget.feishuDoc:
        return Icons.file_copy;
      case ShareTarget.wecomDoc:
        return Icons.business;
      case ShareTarget.wps:
        return Icons.document_scanner;
      case ShareTarget.notion:
        return Icons.edit_note;
      case ShareTarget.other:
        return Icons.more_horiz;
    }
  }

  Widget _buildTypeChip() {
    final l10n = AppLocalizations.of(context)!;
    IconData icon;
    String label;
    Color color;

    switch (widget.record.type) {
      case RecordType.audio:
        icon = Icons.mic;
        label = l10n.typeVoice;
        color = AppColors.primary;
        break;
      case RecordType.ocr:
        icon = Icons.camera_alt;
        label = l10n.typeOcr;
        color = AppColors.secondary;
        break;
      case RecordType.text:
        icon = Icons.text_fields;
        label = l10n.typeText;
        color = AppColors.info;
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
    final l10n = AppLocalizations.of(context)!;
    Color color;
    String text;

    switch (widget.record.transcriptionStatus) {
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

    return Row(
      children: [
        Chip(
          label: Text(text),
          backgroundColor: color.withOpacity(0.1),
          side: BorderSide.none,
          labelStyle: TextStyle(color: color, fontSize: 12),
        ),
        const SizedBox(width: 8),
        if (widget.record.type == RecordType.audio &&
            widget.record.audioPath != null &&
            widget.record.transcriptionStatus != TranscriptionStatus.processing)
          _buildRetryButton(),
      ],
    );
  }

  Widget _buildRetryButton() {
    final l10n = AppLocalizations.of(context)!;
    return IconButton(
      icon: Icon(
        Icons.refresh,
        size: 18,
        color: AppColors.info,
      ),
      onPressed: _retryTranscription,
      tooltip: l10n.retranscribe,
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
    );
  }

  Widget _buildImagePreview() {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(l10n.originalImage, style: Theme.of(context).textTheme.titleMedium),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              return ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(12)),
                child: Image.file(
                  File(widget.record.imagePath!),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  cacheWidth: (constraints.maxWidth * 2).toInt(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTagsSection(RecordModel record) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标签行：标签标题 + 标签详情 + 添加标签
        Row(
          children: [
            Text(l10n.tags, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(width: 8),
            if (record.tags.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '(${record.tags.length})',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                  ),
                ),
              ),
            const Spacer(),
            TagSelector(
              selectedTags: record.tags,
              onTagsChanged: (newTags) {
                ref
                    .read(recordNotifierProvider.notifier)
                    .updateTags(record.id, newTags);
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        // 已选标签展示
        if (record.tags.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: record.tags.map((tag) {
              return Chip(
                label: Text(tag),
                backgroundColor: AppColors.primary.withOpacity(0.1),
                side: BorderSide.none,
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () {
                  final newTags = record.tags.where((t) => t != tag).toList();
                  ref
                      .read(recordNotifierProvider.notifier)
                      .updateTags(record.id, newTags);
                },
              );
            }).toList(),
          ),
        // 相关记录放在标签下面
        _RelatedRecordsSection(record: record),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final l10n = AppLocalizations.of(context)!;
    return '${date.year}${l10n.year}${date.month}${l10n.month}${date.day}${l10n.day} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildAutoAnalysisResultsSection(RecordModel record) {
    return FutureBuilder(
      future: StorageService.getAutoAnalysisConfig(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final config = snapshot.data!;
        if (!config.enabled || config.defaultRoleId.isEmpty) {
          return const SizedBox.shrink();
        }

        // 查找自动分析设置中指定角色的分析结果
        final autoResults = record.aiAnalysisResults
            .where((r) => r.roleId == config.defaultRoleId)
            .toList();

        if (autoResults.isEmpty) return const SizedBox.shrink();

        final l10n = AppLocalizations.of(context)!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.auto_awesome, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  l10n.aiAnalysisResult,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    l10n.auto,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...autoResults.map((result) => _buildAiAnalysisCard(result)),
          ],
        );
      },
    );
  }

  Widget _buildAiAnalysisCard(AiAnalysisResult result) {
    return AiAnalysisCard(
      roleName: result.roleName,
      content: result.content,
      roleId: result.roleId,
      onDelete: () => _confirmRemoveAnalysis(result.roleId),
    );
  }

  void _confirmRemoveAnalysis(String roleId) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.confirmDeleteTitle),
        content: Text(l10n.confirmDelete),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancelButton),
          ),
          TextButton(
            onPressed: () {
              ref.read(recordNotifierProvider.notifier).removeAiAnalysis(
                    widget.record.id,
                    roleId,
                  );
              Navigator.pop(dialogContext);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l10n.deleteButton),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAiAnalysisWithRole(AiRole role) async {
    // 检查是否已有该角色的分析结果
    final hasExisting = widget.record.aiAnalysisResults.any(
      (r) => r.roleId == role.id,
    );

    // 如果已有分析结果，询问是否替换
    if (hasExisting) {
      final l10n = AppLocalizations.of(context)!;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.analysisExists),
          content: Text('${l10n.analysisExistsConfirm.replaceFirst('?', '')} (${role.name})?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.cancelButton),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.reanalyze),
            ),
          ],
        ),
      );

      if (confirm != true) {
        return;
      }
    }

    // 立即开始后台分析（不阻塞UI）
    setState(() {
      _isAnalyzing = true;
    });

    // 后台执行分析，不阻塞UI
    _executeAiAnalysis(role);
  }

  void _executeAiAnalysis(AiRole role) async {
    try {
      final transcriptionService = ref.read(transcriptionServiceProvider);
      final l10n = AppLocalizations.of(context)!;

      final buffer = StringBuffer();
      buffer.writeln('=== 原始转写文本 ===');
      buffer.writeln(widget.record.content ?? '');

      if (widget.record.supplements.isNotEmpty) {
        buffer.writeln('\n\n=== ${l10n.supplementContent} ===');
        for (final supplement in widget.record.supplements) {
          buffer.writeln(
              '\n--- ${supplement.type == 'audio' ? l10n.audioSupplement : supplement.type == 'image' ? l10n.imageSupplement : l10n.textSupplement} [${supplement.createdAt}] ---');

          if (supplement.type == 'text') {
            buffer.writeln(supplement.content);
          } else if (supplement.transcribedContent != null &&
              supplement.transcribedContent!.isNotEmpty) {
            buffer.writeln(supplement.transcribedContent);
          }
        }
      }

      final result = await transcriptionService.analyzeText(
        buffer.toString(),
        systemPrompt: role.systemPrompt,
      );

      // 保存分析结果
      final analysisResult = AiAnalysisResult(
        roleId: role.id,
        roleName: role.name,
        content: result,
        createdAt: DateTime.now(),
      );

      await ref.read(recordNotifierProvider.notifier).addAiAnalysis(
            widget.record.id,
            analysisResult,
          );

      ref.invalidate(recordDetailProvider(widget.record.id));

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${role.name} ${l10n.analysisComplete}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.analysisFailed}: $e'),
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
}

class _RelatedRecordsSection extends ConsumerStatefulWidget {
  final RecordModel record;

  const _RelatedRecordsSection({required this.record});

  @override
  ConsumerState<_RelatedRecordsSection> createState() =>
      _RelatedRecordsSectionState();
}

class _RelatedRecordsSectionState
    extends ConsumerState<_RelatedRecordsSection> {
  bool _isExpanded = false;
  late Future<List<RecordModel>> _relatedRecordsFuture;

  @override
  void initState() {
    super.initState();
    _relatedRecordsFuture = _findRelatedRecords(ref);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.record.tags.isEmpty) return const SizedBox.shrink();

    return FutureBuilder<List<RecordModel>>(
      future: _relatedRecordsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final related = snapshot.data!;
        final firstRecord = related.first;
        final remainingRecords =
            related.length > 1 ? related.sublist(1) : <RecordModel>[];

        final l10n = AppLocalizations.of(context)!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.link, size: 16, color: AppColors.info),
                const SizedBox(width: 6),
                Text(l10n.relatedRecords, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(width: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    l10n.relatedRecordCount(related.length),
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.info,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 只展示最近一条
            _buildRelatedRecordCard(firstRecord, ref),
            // 展开查看更多
            if (remainingRecords.isNotEmpty)
              AnimatedCrossFade(
                firstChild: TextButton.icon(
                  onPressed: () => setState(() => _isExpanded = true),
                  icon: const Icon(Icons.expand_more, size: 16),
                  label: Text(l10n.remainingRecords(remainingRecords.length)),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                secondChild: Column(
                  children: remainingRecords
                      .map((r) => _buildRelatedRecordCard(r, ref))
                      .toList(),
                ),
                crossFadeState: _isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),
          ],
        );
      },
    );
  }

  Widget _buildRelatedRecordCard(RecordModel r, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => context.push('/record/${r.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                r.type == RecordType.audio
                    ? Icons.mic
                    : r.type == RecordType.ocr
                        ? Icons.camera_alt
                        : Icons.edit_note,
                size: 18,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.content != null && r.content!.isNotEmpty
                          ? (r.content!.length > 60
                              ? '${r.content!.substring(0, 60)}...'
                              : r.content!)
                          : l10n.noContentAvailable,
                      style: const TextStyle(fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(r.createdAt),
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 16, color: AppColors.error),
                onPressed: () => _hideRelatedRecord(context, ref, r),
                tooltip: l10n.hideRecord,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _hideRelatedRecord(
      BuildContext context, WidgetRef ref, RecordModel relatedRecord) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.hideRecord),
        content: Text(l10n.hideRecordConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancelButton),
          ),
          TextButton(
            onPressed: () async {
              await StorageServiceHiddenRecords.hideRelatedRecord(
                  widget.record.id, relatedRecord.id);
              if (context.mounted) {
                Navigator.pop(context);
                ref.invalidate(recordDetailProvider(widget.record.id));
              }
            },
            child: Text(l10n.hide, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Future<List<RecordModel>> _findRelatedRecords(WidgetRef ref) async {
    const int maxRecords = 500;
    final repository = ref.read(recordRepositoryProvider);
    final hiddenIds = await StorageServiceHiddenRecords.getHiddenRelatedRecords(
        widget.record.id);

    final allRecords = await repository.getAllRecords();
    // 限制处理数量，避免大量记录时内存和性能问题
    final candidateRecords = allRecords
        .take(maxRecords)
        .where((r) => r.tags.any((tag) => widget.record.tags.contains(tag)))
        .toList();

    final scored = <RecordModel, int>{};
    for (final other in candidateRecords) {
      if (other.id == widget.record.id) continue;
      if (hiddenIds.contains(other.id)) continue;
      final commonTags =
          widget.record.tags.where((t) => other.tags.contains(t)).length;
      if (commonTags > 0) {
        scored[other] = commonTags;
      }
    }

    final sorted = scored.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.map((e) => e.key).toList();
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
