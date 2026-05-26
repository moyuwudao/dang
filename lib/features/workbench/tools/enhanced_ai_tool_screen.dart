import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:add_2_calendar/add_2_calendar.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/native_tool_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/record_model.dart';
import '../../../data/models/tool_output_model.dart';
import '../../../data/repositories/record_repository.dart';
import '../../../data/repositories/tool_output_repository.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../models/tool_data_source.dart';
import '../models/tool_template.dart';
import '../widgets/template_selector.dart';
import 'tool_configs.dart';
import 'tool_templates.dart';

class EnhancedAiToolScreen extends ConsumerStatefulWidget {
  final ToolConfig config;
  final ToolDataSource dataSource;
  final ToolTemplate template;

  const EnhancedAiToolScreen({
    super.key,
    required this.config,
    required this.dataSource,
    required this.template,
  });

  @override
  ConsumerState<EnhancedAiToolScreen> createState() =>
      _EnhancedAiToolScreenState();
}

class _EnhancedAiToolScreenState extends ConsumerState<EnhancedAiToolScreen> {
  bool _isGenerating = false;
  String _resultContent = '';
  List<ToolOutputModel> _savedResults = [];
  bool _isLoadingSaved = true;
  ToolTemplate? _currentTemplate;
  bool _showTemplateSelector = false;

  @override
  void initState() {
    super.initState();
    _currentTemplate = widget.template;
    _loadSavedResults();
    _generate();
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

      final buffer = StringBuffer();
      var hasData = false;

      // 处理原始记录数据源
      if (widget.dataSource.dateRange != null) {
        final repository = ref.read(recordRepositoryProvider);
        final allRecords = await repository.getAllRecords();

        var filteredRecords = allRecords.where((r) {
          final created = r.createdAt;
          return !created.isBefore(widget.dataSource.dateRange!.start) &&
              !created.isAfter(widget.dataSource.dateRange!.end
                  .add(const Duration(days: 1)));
        }).toList();

        if (widget.dataSource.selectedTags != null &&
            widget.dataSource.selectedTags!.isNotEmpty) {
          filteredRecords = filteredRecords.where((r) {
            return widget.dataSource.selectedTags!
                .any((tag) => r.tags.contains(tag));
          }).toList();
        }

        if (filteredRecords.isNotEmpty) {
          hasData = true;
          buffer.writeln(
              '${l10n.records} ${widget.dataSource.dateRange!.start.month}${l10n.month}${widget.dataSource.dateRange!.start.day}${l10n.day} - ${widget.dataSource.dateRange!.end.month}${l10n.month}${widget.dataSource.dateRange!.end.day}${l10n.day}:');
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
            if (widget.dataSource.includeAiAnalysis &&
                r.aiAnalysisResults.isNotEmpty) {
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
        }
      }

      // 处理工具输出数据源
      if (widget.dataSource.selectedToolOutputIds != null &&
          widget.dataSource.selectedToolOutputIds!.isNotEmpty) {
        final toolOutputRepo = ref.read(toolOutputRepositoryProvider);
        final outputs = <ToolOutputModel>[];

        for (final id in widget.dataSource.selectedToolOutputIds!) {
          final output = await toolOutputRepo.getToolOutputById(id);
          if (output != null) {
            outputs.add(output);
          }
        }

        if (outputs.isNotEmpty) {
          hasData = true;
          if (buffer.isNotEmpty) buffer.writeln();
          buffer.writeln('${l10n.savedResults}:');
          buffer.writeln();

          for (int i = 0; i < outputs.length; i++) {
            final o = outputs[i];
            buffer.writeln('--- ${l10n.toolOutput} ${i + 1}: ${o.title} ---');
            final content = o.content.length > 1000
                ? '${o.content.substring(0, 1000)}...'
                : o.content;
            buffer.writeln(content);
            buffer.writeln();
          }
        }
      }

      if (!hasData) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(l10n.noDataSourceAvailable), backgroundColor: AppColors.warning),
          );
        }
        return;
      }

      final input = buffer.toString();

      final apiService = ApiService();
      final result = await apiService.chatCompletionWithSystem(
        input,
        systemPrompt: _currentTemplate!.systemPrompt,
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

  Future<void> _regenerateWithTemplate(ToolTemplate template) async {
    setState(() {
      _currentTemplate = template;
      _showTemplateSelector = false;
      _resultContent = '';
    });
    await _generate();
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
        templateId: _currentTemplate?.id,
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

  Future<void> _deleteSavedResult(int id) async {
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

  void _copyResult() {
    final l10n = AppLocalizations.of(context)!;
    if (_resultContent.isEmpty) return;
    NativeToolService.copyToClipboard(_resultContent);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(l10n.copiedToClipboard), backgroundColor: AppColors.success),
    );
  }

  void _shareResult() {
    if (_resultContent.isEmpty) return;
    NativeToolService.shareText(
      '${widget.config.title}\n\n$_resultContent\n\n${AppLocalizations.of(context)!.appName}',
      subject: widget.config.title,
    );
  }

  Future<void> _sendEmail() async {
    if (_resultContent.isEmpty) return;
    await NativeToolService.sendEmail(
      subject:
          '${widget.config.title} - ${DateTime.now().month}${AppLocalizations.of(context)!.month}${DateTime.now().day}${AppLocalizations.of(context)!.day}',
      body: _resultContent,
    );
  }

  Future<void> _addToCalendar() async {
    final l10n = AppLocalizations.of(context)!;
    if (_resultContent.isEmpty) return;
    await NativeToolService.addToCalendar(
      title: widget.config.title,
      startTime: DateTime.now().add(const Duration(days: 1)),
      description: _resultContent.length > 200
          ? '${_resultContent.substring(0, 200)}...'
          : _resultContent,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(l10n.addedToCalendar), backgroundColor: AppColors.success),
      );
    }
  }

  void _showNativeActions() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(l10n.moreActions,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              _buildActionTile(
                icon: Icons.email_outlined,
                title: l10n.sendEmail,
                subtitle: l10n.sendEmailDesc,
                onTap: () {
                  Navigator.pop(context);
                  _sendEmail();
                },
              ),
              _buildActionTile(
                icon: Icons.calendar_today_outlined,
                title: l10n.addToCalendar,
                subtitle: l10n.addToCalendarDesc,
                onTap: () {
                  Navigator.pop(context);
                  _addToCalendar();
                },
              ),
              _buildActionTile(
                icon: Icons.copy_outlined,
                title: l10n.copyAll,
                subtitle: l10n.copyAllDesc,
                onTap: () {
                  Navigator.pop(context);
                  _copyResult();
                },
              ),
              _buildActionTile(
                icon: Icons.share_outlined,
                title: l10n.shareButton,
                subtitle: l10n.shareDesc,
                onTap: () {
                  Navigator.pop(context);
                  _shareResult();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: Text(subtitle,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
      onTap: onTap,
    );
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
        actions: [
          if (_resultContent.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: _showNativeActions,
              tooltip: l10n.moreActions,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTemplateBar(),
            const SizedBox(height: 16),
            if (_showTemplateSelector)
              Column(
                children: [
                  TemplateSelector(
                    templates: builtInTemplates[widget.config.id] ?? [],
                    selectedTemplate: _currentTemplate,
                    onSelected: _regenerateWithTemplate,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            if (_isGenerating) _buildLoadingState(),
            if (_resultContent.isNotEmpty) _buildResultSection(),
            if (_resultContent.isEmpty && !_isGenerating) _buildEmptyState(),
            const SizedBox(height: 24),
            _buildSavedResultsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateBar() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_fix_high, color: AppColors.primary, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${l10n.template}: ${_currentTemplate?.name ?? l10n.defaultTemplate}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: () =>
                setState(() => _showTemplateSelector = !_showTemplateSelector),
            child: Text(_showTemplateSelector ? l10n.expand : l10n.switchTemplate),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              l10n.aiAnalyzingData,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              '${l10n.usingTemplate}: ${_currentTemplate?.name}',
              style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
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
              icon: const Icon(Icons.copy, size: 20),
              onPressed: _copyResult,
              tooltip: l10n.copy,
            ),
            IconButton(
              icon: const Icon(Icons.share_outlined, size: 20),
              onPressed: _shareResult,
              tooltip: l10n.shareButton,
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
              NativeToolService.shareText(
                '${result.title}\n\n${result.content}\n\n${l10n.appName}',
                subject: result.title,
              );
            },
            child: Text(l10n.shareButton),
          ),
          TextButton(
            onPressed: () async {
              await NativeToolService.copyToClipboard(result.content);
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
