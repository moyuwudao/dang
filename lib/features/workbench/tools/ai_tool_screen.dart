import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/record_repository.dart';
import '../../../data/repositories/tool_output_repository.dart';
import '../../../data/models/tool_output_model.dart';
import 'tool_configs.dart';

class AiToolScreen extends ConsumerStatefulWidget {
  final ToolConfig config;

  const AiToolScreen({super.key, required this.config});

  @override
  ConsumerState<AiToolScreen> createState() => _AiToolScreenState();
}

class _AiToolScreenState extends ConsumerState<AiToolScreen> {
  bool _isGenerating = false;
  String _resultContent = '';
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 7)),
    end: DateTime.now(),
  );
  final _textController = TextEditingController();
  List<ToolOutputModel> _savedResults = [];
  bool _isLoadingSaved = true;

  @override
  void initState() {
    super.initState();
    _loadSavedResults();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedResults() async {
    try {
      final repository = ref.read(toolOutputRepositoryProvider);
      final results = await repository.getToolOutputsByToolId(widget.config.id);
      setState(() {
        _savedResults = results;
        _isLoadingSaved = false;
      });
    } catch (e) {
      setState(() => _isLoadingSaved = false);
    }
  }

  Future<void> _saveResult(String content) async {
    final nameController = TextEditingController(
      text:
          '${widget.config.title} - ${DateTime.now().month}/${DateTime.now().day}',
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('保存${widget.config.title}结果'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: '名称',
            hintText: '输入保存名称',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (confirmed == true && nameController.text.trim().isNotEmpty) {
      final repository = ref.read(toolOutputRepositoryProvider);
      await repository.createToolOutput(
        toolId: widget.config.id,
        title: nameController.text.trim(),
        content: content,
      );
      await _loadSavedResults();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('已保存'), backgroundColor: AppColors.success),
        );
      }
    }
  }

  Future<void> _deleteSavedResult(String id) async {
    final repository = ref.read(toolOutputRepositoryProvider);
    await repository.deleteToolOutput(id);
    await _loadSavedResults();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('已删除'), backgroundColor: AppColors.success),
      );
    }
  }

  Future<void> _generate() async {
    setState(() => _isGenerating = true);

    try {
      final apiConfig = await StorageService.getApiConfig();
      if (apiConfig == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('请先配置API Key'), backgroundColor: AppColors.error),
          );
        }
        return;
      }

      String input;

      if (widget.config.inputMode == ToolInputMode.records) {
        final repository = ref.read(recordRepositoryProvider);
        final allRecords = await repository.getAllRecords();

        final filteredRecords = allRecords.where((r) {
          final created = r.createdAt;
          return !created.isBefore(_dateRange.start) &&
              !created.isAfter(_dateRange.end.add(const Duration(days: 1)));
        }).toList();

        if (filteredRecords.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('该时间段内没有记录'),
                  backgroundColor: AppColors.warning),
            );
          }
          return;
        }

        final buffer = StringBuffer();
        buffer.writeln(
            '以下是 ${_dateRange.start.month}月${_dateRange.start.day}日 到 ${_dateRange.end.month}月${_dateRange.end.day}日 的记录：');
        buffer.writeln();

        for (int i = 0; i < filteredRecords.length; i++) {
          final r = filteredRecords[i];
          buffer.writeln('--- 记录 ${i + 1} (${_formatDate(r.createdAt)}) ---');
          if (r.content != null && r.content!.isNotEmpty) {
            final content = r.content!.length > 500
                ? '${r.content!.substring(0, 500)}...'
                : r.content!;
            buffer.writeln(content);
          }
          if (r.aiAnalysisResults.isNotEmpty) {
            buffer.writeln('[AI分析摘要]');
            for (final analysis in r.aiAnalysisResults) {
              final summary = analysis.content.length > 200
                  ? '${analysis.content.substring(0, 200)}...'
                  : analysis.content;
              buffer.writeln('- ${analysis.roleName}: $summary');
            }
          }
          buffer.writeln();
        }

        input = buffer.toString();
      } else {
        input = _textController.text.trim();
        if (input.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('请输入内容'), backgroundColor: AppColors.warning),
            );
          }
          return;
        }
      }

      final apiService = ref.read(apiServiceProvider);
      final result = await apiService.chatCompletionWithSystem(
        input,
        systemPrompt: widget.config.systemPrompt,
        toolId: widget.config.id,
      );

      if (mounted) {
        setState(() => _resultContent = result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('生成失败: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  void _copyResult() {
    if (_resultContent.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _resultContent));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('已复制到剪贴板'), backgroundColor: AppColors.success),
    );
  }

  void _shareResult() {
    if (_resultContent.isEmpty) return;
    Share.share(
      '${widget.config.title}\n\n$_resultContent\n\n来自畅记 App',
      subject: widget.config.title,
    );
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.config.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInputSection(),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generate,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(_isGenerating
                    ? '生成中...'
                    : widget.config.generateButtonText),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_resultContent.isNotEmpty) _buildResultSection(),
            if (_resultContent.isEmpty && !_isGenerating) _buildEmptyState(),
            const SizedBox(height: 24),
            _buildSavedResultsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    final children = <Widget>[];

    if (widget.config.showDateRange) {
      final startStr = '${_dateRange.start.month}/${_dateRange.start.day}';
      final endStr = '${_dateRange.end.month}/${_dateRange.end.day}';
      children.add(
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _pickDateRange,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.date_range, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('时间范围',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(
                            '$startStr - $endStr（${_dateRange.duration.inDays}天）',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                      color: AppColors.textTertiary),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Column(children: children);
  }

  Widget _buildResultSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.description, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            const Text('生成结果',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.save_outlined, size: 20),
              onPressed: () => _saveResult(_resultContent),
              tooltip: '保存',
            ),
            IconButton(
              icon: const Icon(Icons.share_outlined, size: 20),
              onPressed: _shareResult,
              tooltip: '分享',
            ),
            IconButton(
              icon: const Icon(Icons.copy, size: 20),
              onPressed: _copyResult,
              tooltip: '复制',
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: SelectableText(
            _resultContent,
            style: const TextStyle(fontSize: 14, height: 1.8),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(Icons.auto_awesome_outlined,
                size: 64, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text(
              widget.config.emptyStateText,
              style: TextStyle(color: AppColors.textTertiary, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedResultsSection() {
    if (_isLoadingSaved) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.folder_open, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            const Text('已保存的结果',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const Spacer(),
            Text('${_savedResults.length} 份',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 8),
        if (_savedResults.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('暂无保存的结果',
                style: TextStyle(color: AppColors.textSecondary)),
          )
        else
          ..._savedResults.map((result) => _buildSavedResultCard(result)),
      ],
    );
  }

  Widget _buildSavedResultCard(ToolOutputModel result) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _showSavedResultDetail(result),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.description, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${result.createdAt.month}/${result.createdAt.day} ${result.createdAt.hour}:${result.createdAt.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: AppColors.error),
                onPressed: () => _deleteSavedResult(result.id),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSavedResultDetail(ToolOutputModel result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(result.title),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(
              result.content,
              style: const TextStyle(fontSize: 14, height: 1.8),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
          TextButton(
            onPressed: () {
              Share.share(
                '${result.title}\n\n${result.content}\n\n来自畅记 App',
                subject: result.title,
              );
            },
            child: const Text('分享'),
          ),
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: result.content));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('已复制到剪贴板'),
                      backgroundColor: AppColors.success),
                );
              }
            },
            child: const Text('复制'),
          ),
        ],
      ),
    );
  }
}
