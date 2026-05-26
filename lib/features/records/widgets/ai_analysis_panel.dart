import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/ai_role.dart';
import '../../../core/services/role_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/transcription_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/record_model.dart';
import '../../records/providers/record_provider.dart';
import '../widgets/ai_analysis_card.dart';
import 'ai_role_picker.dart';
import '../../../l10n/generated/app_localizations.dart';

// l10n keys used: addAiAnalysis, aiAnalyzing, tapToAnalyze, analysisComplete, analysisFailed, noContentToAnalyze, reanalyze, analysisExists, cancelButton, confirmButton, deleteButton, confirmDeleteTitle, confirmDelete, originalTranscription, supplementContent, audioSupplement, imageSupplement, textSupplement, saveSuccess

class AiAnalysisPanel extends ConsumerStatefulWidget {
  final RecordModel record;
  final VoidCallback? onAnalysisComplete;

  const AiAnalysisPanel({
    super.key,
    required this.record,
    this.onAnalysisComplete,
  });

  @override
  ConsumerState<AiAnalysisPanel> createState() => _AiAnalysisPanelState();
}

class _AiAnalysisPanelState extends ConsumerState<AiAnalysisPanel> {
  bool _isAnalyzing = false;
  String? _autoAnalysisRoleId;

  @override
  void initState() {
    super.initState();
    _loadAutoAnalysisConfig();
  }

  Future<void> _loadAutoAnalysisConfig() async {
    final config = await StorageService.getAutoAnalysisConfig();
    if (mounted && config.enabled) {
      setState(() {
        _autoAnalysisRoleId = config.defaultRoleId;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final record = widget.record;
    // Filter out auto-analysis results, only show manual analysis results
    final analyses = record.aiAnalysisResults
        .where((r) => r.roleId != _autoAnalysisRoleId)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.psychology, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              l10n.aiAnalysis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            if (_isAnalyzing)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 20),
                onPressed: () => _showRolePicker(),
                tooltip: l10n.addAiAnalysis,
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (analyses.isEmpty && !_isAnalyzing)
          _buildEmptyState()
        else
          ...analyses.map((result) => AiAnalysisCard(
                roleName: result.roleName,
                content: result.content,
                roleId: result.roleId,
                onDelete: () => _confirmRemoveAnalysis(result.roleId),
              )),
        if (_isAnalyzing) _buildAnalyzingIndicator(),
      ],
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Icon(Icons.auto_awesome,
              size: 32, color: AppColors.primary.withOpacity(0.5)),
          const SizedBox(height: 8),
          Text(
            l10n.tapToAnalyze,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyzingIndicator() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.info,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            l10n.aiAnalyzing,
            style: const TextStyle(color: AppColors.info, fontSize: 13),
          ),
        ],
      ),
    );
  }

  void _showRolePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AiRolePicker(
        onRoleSelected: (role) => _handleAiAnalysisWithRole(role),
        onManageRoles: () => context.push('/settings/roles'),
      ),
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
    final hasExisting = widget.record.aiAnalysisResults.any(
      (r) => r.roleId == role.id,
    );

    if (hasExisting) {
      final l10n = AppLocalizations.of(context)!;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.analysisExists),
          content: Text('${role.name}${l10n.analysisExistsConfirm}'),
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

      if (confirm != true) return;
    }

    setState(() => _isAnalyzing = true);
    _executeAiAnalysis(role);
  }

  void _executeAiAnalysis(AiRole role) async {
    try {
      final transcriptionService = ref.read(transcriptionServiceProvider);

      final l10n = AppLocalizations.of(context)!;
      final buffer = StringBuffer();
      buffer.writeln('=== ${l10n.originalTranscription} ===');
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

      final contentToAnalyze = buffer.toString().trim();
      if (contentToAnalyze.isEmpty ||
          contentToAnalyze == '=== ${l10n.originalTranscription} ===' ||
          contentToAnalyze.replaceAll(RegExp(r'[=\s\n\-]'), '').isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.noContentToAnalyze),
              backgroundColor: AppColors.warning,
            ),
          );
          setState(() => _isAnalyzing = false);
        }
        return;
      }

      final result = await transcriptionService.analyzeText(
        buffer.toString(),
        systemPrompt: role.systemPrompt,
      );

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${role.name} ${l10n.analysisComplete}'),
              backgroundColor: AppColors.success),
        );
        if (widget.onAnalysisComplete != null) {
          widget.onAnalysisComplete!();
        }
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.analysisFailed}: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }
}
