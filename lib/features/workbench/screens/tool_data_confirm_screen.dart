import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/record_model.dart';
import '../../../data/models/tool_output_model.dart';
import '../../../data/repositories/record_repository.dart';
import '../../../data/repositories/tool_output_repository.dart';
import '../models/data_source_selection.dart';
import '../models/tool_data_source.dart';
import '../models/tool_template.dart';
import '../tools/tool_configs.dart';
import '../tools/tool_templates.dart';
import '../widgets/data_source_selector.dart';
import '../widgets/template_selector.dart';

class ToolDataConfirmScreen extends ConsumerStatefulWidget {
  final ToolConfig config;

  const ToolDataConfirmScreen({super.key, required this.config});

  @override
  ConsumerState<ToolDataConfirmScreen> createState() =>
      _ToolDataConfirmScreenState();
}

class _ToolDataConfirmScreenState extends ConsumerState<ToolDataConfirmScreen> {
  DataSourceSelection _dataSourceSelection = DataSourceSelection(
    selectedCategories: [DataSourceCategory.records],
    selectedTags: [],
    selectedToolOutputIds: [],
    dateRange: DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 7)),
      end: DateTime.now(),
    ),
    includeAiAnalysis: true,
  );

  List<RecordModel> _previewRecords = [];
  List<ToolOutputModel> _previewToolOutputs = [];
  bool _isLoading = true;
  ToolTemplate? _selectedTemplate;
  List<ToolTemplate> _templates = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _templates = _getBuiltInTemplates(widget.config.id);
    _selectedTemplate = _templates.firstWhere(
      (t) => t.isDefault,
      orElse: () => _templates.first,
    );

    await _refreshPreview();

    setState(() => _isLoading = false);
  }

  List<ToolTemplate> _getBuiltInTemplates(String toolId) {
    return builtInTemplates[toolId] ?? [];
  }

  Future<void> _refreshPreview() async {
    setState(() => _isLoading = true);

    final records = await _loadPreviewRecords();
    final toolOutputs = await _loadPreviewToolOutputs();

    setState(() {
      _previewRecords = records;
      _previewToolOutputs = toolOutputs;
      _isLoading = false;
    });
  }

  Future<List<RecordModel>> _loadPreviewRecords() async {
    if (!_dataSourceSelection.selectedCategories.contains(DataSourceCategory.records)) {
      return [];
    }

    final repository = ref.read(recordRepositoryProvider);
    final allRecords = await repository.getAllRecords();

    var filtered = allRecords.where((r) {
      final created = r.createdAt;
      return !created.isBefore(_dataSourceSelection.dateRange!.start) &&
          !created.isAfter(_dataSourceSelection.dateRange!.end.add(const Duration(days: 1)));
    }).toList();

    if (_dataSourceSelection.selectedTags.isNotEmpty) {
      filtered = filtered.where((r) {
        return _dataSourceSelection.selectedTags.any((tag) => r.tags.contains(tag));
      }).toList();
    }

    return filtered.take(5).toList();
  }

  Future<List<ToolOutputModel>> _loadPreviewToolOutputs() async {
    if (!_dataSourceSelection.selectedCategories.contains(DataSourceCategory.toolOutput)) {
      return [];
    }

    if (_dataSourceSelection.selectedToolOutputIds.isEmpty) {
      return [];
    }

    final repository = ref.read(toolOutputRepositoryProvider);
    final outputs = <ToolOutputModel>[];

    for (final id in _dataSourceSelection.selectedToolOutputIds) {
      final output = await repository.getToolOutputById(id);
      if (output != null) {
        outputs.add(output);
      }
    }

    return outputs;
  }

  void _handleDataSourceChanged(DataSourceSelection selection) {
    setState(() => _dataSourceSelection = selection);
    _refreshPreview();
  }

  void _confirm() {
    final hasRecords = _dataSourceSelection.selectedCategories.contains(DataSourceCategory.records) &&
        _previewRecords.isNotEmpty;
    final hasToolOutputs = _dataSourceSelection.selectedCategories.contains(DataSourceCategory.toolOutput) &&
        _previewToolOutputs.isNotEmpty;

    if (!hasRecords && !hasToolOutputs) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请至少选择一种数据源'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final dataSource = ToolDataSource.fromSelection(_dataSourceSelection);

    context.push(
      '/tool-execute',
      extra: {
        'config': widget.config,
        'dataSource': dataSource,
        'template': _selectedTemplate,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.config.title} - 数据确认'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDataSourceSection(),
                  const SizedBox(height: 24),
                  TemplateSelector(
                    templates: _templates,
                    selectedTemplate: _selectedTemplate,
                    onSelected: (template) =>
                        setState(() => _selectedTemplate = template),
                  ),
                  const SizedBox(height: 24),
                  _buildPreviewSection(),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _confirm,
                      icon: const Icon(Icons.check_circle),
                      label: const Text('确认并执行'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDataSourceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.dataset, color: AppColors.primary, size: 18),
            SizedBox(width: 8),
            Text(
              '数据源配置',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DataSourceSelector(
          selection: _dataSourceSelection,
          onChanged: _handleDataSourceChanged,
          toolId: widget.config.id,
        ),
      ],
    );
  }

  Widget _buildPreviewSection() {
    final hasRecords = _previewRecords.isNotEmpty;
    final hasToolOutputs = _previewToolOutputs.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.preview, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            const Text('数据预览',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const Spacer(),
            Text(
              '共 ${_previewRecords.length + _previewToolOutputs.length} 条',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (!hasRecords && !hasToolOutputs)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('该条件下暂无数据',
                style: TextStyle(color: AppColors.textSecondary)),
          )
        else ...[
          if (hasToolOutputs) ...[
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text('工具输出',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
            ),
            ..._previewToolOutputs.map((o) => _buildToolOutputPreviewItem(o)),
            const SizedBox(height: 12),
          ],
          if (hasRecords) ...[
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text('原始记录',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
            ),
            ..._previewRecords.map((r) => _buildRecordPreviewItem(r)),
          ],
        ],
      ],
    );
  }

  Widget _buildToolOutputPreviewItem(ToolOutputModel output) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.output, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    output.title,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${output.createdAt.month}/${output.createdAt.day} ${output.createdAt.hour}:${output.createdAt.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordPreviewItem(RecordModel record) {
    IconData icon;
    switch (record.type) {
      case RecordType.audio:
        icon = Icons.mic;
      case RecordType.ocr:
        icon = Icons.image;
      case RecordType.text:
        icon = Icons.text_snippet;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.content?.isNotEmpty == true
                        ? record.content!.length > 50
                            ? '${record.content!.substring(0, 50)}...'
                            : record.content!
                        : '${record.type.name} 记录',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${record.createdAt.month}/${record.createdAt.day} ${record.createdAt.hour}:${record.createdAt.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
            if (record.tags.isNotEmpty)
              Wrap(
                spacing: 4,
                children: record.tags
                    .take(2)
                    .map((tag) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(tag,
                              style: const TextStyle(
                                  fontSize: 10, color: AppColors.primary)),
                        ))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}
