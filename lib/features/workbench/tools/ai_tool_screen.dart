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
import '../../../l10n/generated/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController(
      text:
          '${widget.config.title} - ${DateTime.now().month}/${DateTime.now().day}',
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${l10n.saveResult} ${widget.config.title}'),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: l10n.name,
            hintText: l10n.inputName,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.saveButton),
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
          SnackBar(
              content: Text(l10n.saveSuccess), backgroundColor: AppColors.success),
        );
      }
    }
  }

  Future<void> _deleteSavedResult(String id) async {
    final l10n = AppLocalizations.of(context)!;
    final repository = ref.read(toolOutputRepositoryProvider);
    await repository.deleteToolOutput(id);
    await _loadSavedResults();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(l10n.deleteSuccess), backgroundColor: AppColors.success),
      );
    }
  }

  Future<void> _generate() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isGenerating = true);

    try {
      final apiConfig = await StorageService.getApiConfig();
      if (apiConfig == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(l10n.pleaseConfigureApiKey), backgroundColor: AppColors.error),
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
              SnackBar(
                  content: Text(l10n.noRecordsInPeriod),
                  backgroundColor: AppColors.warning),
            );
          }
          return;
        }

        final buffer = StringBuffer();
        buffer.writeln(
            '${l10n.records} ${_dateRange.start.month}${l10n.month}${_dateRange.start.day}${l10n.day} - ${_dateRange.end.month}${l10n.month}${_dateRange.end.day}${l10n.day}:');
        buffer.writeln();

        for (int i = 0; i < filteredRecords.length; i++) {
          final r = filteredRecords[i];
          buffer.writeln('--- ${l10n.records} ${i + 1} (${_formatDate(r.createdAt)}) ---');
          if (r.content != null && r.content!.isNotEmpty) {
            final content = r.content!.length > 500
                ? '${r.content!.substring(0, 500)}...'
                : r.content!;
            buffer.writeln(content);
          }
          if (r.aiAnalysisResults.isNotEmpty) {
            buffer.writeln('[${l10n.aiAnalysisSummary}]');
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
              SnackBar(
                  content: Text(l10n.pleaseEnterContent), backgroundColor: AppColors.warning),
            );
          }
          return;
        }
      }

      final apiService = ApiService();
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
          SnackBar(content: Text('${l10n.generationFailed}: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  void _copyResult() {
    final l10n = AppLocalizations.of(context)!;
    if (_resultContent.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _resultContent));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(l10n.copiedToClipboard), backgroundColor: AppColors.success),
    );
  }

  void _shareResult() {
    if (_resultContent.isEmpty) return;
    Share.share(
      '${widget.config.title}\n\n$_resultContent\n\n${AppLocalizations.of(context)!.appName}',
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
    final l10n = AppLocalizations.of(context)!;
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
                    ? l10n.generating
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
    final l10n = AppLocalizations.of(context)!;
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
                        Text(l10n.timeRange,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(
                            '$startStr - $endStr（${_dateRange.duration.inDays}${l10n.days}）',
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
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.description, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Text(l10n.generateResult,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.save_outlined, size: 20),
              onPressed: () => _saveResult(_resultContent),
              tooltip: l10n.saveButton,
            ),
            IconButton(
              icon: const Icon(Icons.share_outlined, size: 20),
              onPressed: _shareResult,
              tooltip: l10n.shareButton,
            ),
            IconButton(
              icon: const Icon(Icons.copy, size: 20),
              onPressed: _copyResult,
              tooltip: l10n.copy,
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
    final l10n = AppLocalizations.of(context)!;
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
            Text(l10n.savedResults,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const Spacer(),
            Text(l10n.savedResultCount(_savedResults.length),
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
            child: Text(l10n.noSavedResults,
                style: const TextStyle(color: AppColors.textSecondary)),
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
    final l10n = AppLocalizations.of(context)!;
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
            child: Text(l10n.close),
          ),
          TextButton(
            onPressed: () {
              Share.share(
                '${result.title}\n\n${result.content}\n\n${l10n.appName}',
                subject: result.title,
              );
            },
            child: Text(l10n.shareButton),
          ),
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: result.content));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(l10n.copiedToClipboard),
                      backgroundColor: AppColors.success),
                );
              }
            },
            child: Text(l10n.copy),
          ),
        ],
      ),
    );
  }
}
