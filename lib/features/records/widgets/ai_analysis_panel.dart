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
            const Text(
              'AI分析',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
                tooltip: '添加AI分析',
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
          const Text(
            '点击 + 使用AI角色分析此记录',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyzingIndicator() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.info,
            ),
          ),
          SizedBox(width: 12),
          Text(
            'AI正在分析中...',
            style: TextStyle(color: AppColors.info, fontSize: 13),
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
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个分析结果吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
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
            child: const Text('删除'),
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
      final confirm = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('已存在分析结果'),
          content: Text('角色"${role.name}"已有分析结果，是否重新分析？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('重新分析'),
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

      final buffer = StringBuffer();
      buffer.writeln('=== 原始转写文本 ===');
      buffer.writeln(widget.record.content ?? '');

      if (widget.record.supplements.isNotEmpty) {
        buffer.writeln('\n\n=== 补充内容 ===');
        for (final supplement in widget.record.supplements) {
          buffer.writeln(
              '\n--- ${supplement.type == 'audio' ? '录音补充' : supplement.type == 'image' ? '图片补充' : '文本补充'} [${supplement.createdAt}] ---');
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
          contentToAnalyze == '=== 原始转写文本 ===' ||
          contentToAnalyze.replaceAll(RegExp(r'[=\s\n\-]'), '').isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('没有可分析的内容，请先添加转写文本或补充内容'),
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
              content: Text('${role.name} 分析完成'),
              backgroundColor: AppColors.success),
        );
        if (widget.onAnalysisComplete != null) {
          widget.onAnalysisComplete!();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('分析失败: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }
}
