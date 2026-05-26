import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/record_model.dart';
import '../../../data/repositories/record_repository.dart';
import '../../../l10n/generated/app_localizations.dart';

class WeeklyReportScreen extends ConsumerStatefulWidget {
  const WeeklyReportScreen({super.key});

  @override
  ConsumerState<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends ConsumerState<WeeklyReportScreen> {
  bool _isGenerating = false;
  String _reportContent = '';
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 7)),
    end: DateTime.now(),
  );
  List<SavedReport> _savedReports = [];
  bool _isLoadingSaved = true;
  late AppLocalizations _l10n;

  @override
  void initState() {
    super.initState();
    _loadSavedReports();
  }

  Future<void> _loadSavedReports() async {
    final reports = await StorageService.getSavedReports();
    if (mounted) {
      setState(() {
        _savedReports = reports;
        _isLoadingSaved = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_l10n.smartWeeklyReport),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateRangePicker(theme),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generateReport,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.auto_awesome),
                label: Text(_isGenerating ? _l10n.generating : _l10n.generateWeeklyReport),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_reportContent.isNotEmpty) _buildReportContent(theme),
            if (_reportContent.isEmpty && !_isGenerating)
              _buildEmptyState(theme),
            const SizedBox(height: 24),
            _buildSavedReportsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangePicker(ThemeData theme) {
    final startStr = '${_dateRange.start.month}/${_dateRange.start.day}';
    final endStr = '${_dateRange.end.month}/${_dateRange.end.day}';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    Text(_l10n.timeRange,
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text('$startStr - $endStr（${_dateRange.duration.inDays}${_l10n.days}）',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportContent(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.description, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Text(_l10n.weeklyReportContent,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.save_outlined, size: 20),
              onPressed: _saveReport,
              tooltip: _l10n.saveButton,
            ),
            IconButton(
              icon: const Icon(Icons.share_outlined, size: 20),
              onPressed: _shareReport,
              tooltip: _l10n.share,
            ),
            IconButton(
              icon: const Icon(Icons.copy, size: 20),
              onPressed: _copyReport,
              tooltip: _l10n.copy,
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
            _reportContent,
            style: const TextStyle(fontSize: 14, height: 1.8),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(Icons.summarize_outlined,
                size: 64, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text(_l10n.selectDateRangeToGenerateReport,
                style: TextStyle(color: AppColors.textTertiary, fontSize: 16)),
            const SizedBox(height: 8),
            Text(_l10n.aiWillSummarizeRecords,
                style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
          ],
        ),
      ),
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

  Future<void> _generateReport() async {
    setState(() => _isGenerating = true);

    try {
      final apiConfig = await StorageService.getApiConfig();
      if (apiConfig == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(_l10n.pleaseConfigureApiKey), backgroundColor: AppColors.error),
          );
        }
        return;
      }

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
                content: Text(_l10n.noRecordsInTimeRange), backgroundColor: AppColors.warning),
          );
        }
        return;
      }

      final buffer = StringBuffer();
      buffer.writeln(
          '以下是 ${_dateRange.start.month}月${_dateRange.start.day}日 到 ${_dateRange.end.month}月${_dateRange.end.day}日 的工作记录：');
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

      // 获取用户设置的默认周报模板
      final templateConfig = await StorageService.getAnalysisTemplates();
      String systemPrompt = '''你是一位高效的个人助理。请根据以下工作记录，生成一份结构化的周报。

请按以下格式输出：

## 本周成果
- 列出本周完成的主要工作（3-5条）

## 关键数据
- 提取记录中的关键数字：客户数、收入、用户反馈等

## 遇到的问题
- 本周遇到的主要障碍和挑战

## 学到的经验
- 从本周工作中获得的有价值的认知

## 下周计划
- 基于本周情况，下周最重要的3件事是什么？为什么？

## 需要关注的风险
- 可能影响后续进展的风险点

请语言简洁，重点突出，适合发给投资人或合作伙伴。''';

      // 查找用户自定义模板
      final customTemplate = templateConfig.customTemplates
          .where((t) =>
              t.id == templateConfig.defaultWeeklyReportTemplateId &&
              t.type == 'weekly_report')
          .firstOrNull;
      if (customTemplate != null) {
        systemPrompt = customTemplate.systemPrompt;
      } else if (templateConfig.defaultWeeklyReportTemplateId ==
          'builtin_weekly_executive') {
        systemPrompt = '''你是一位CEO助理。请根据以下工作记录，生成一份高管级别的周报简报。

请按以下格式输出：

## 本周关键进展（3条以内）
- 只写最重要的，每条不超过30字

## 关键数据变化
- 环比变化：收入、用户、效率等核心指标

## 需要决策的事项
- 需要我拍板的事情，附建议方案

## 风险预警
- 可能出问题的地方，提前预警

## 下周必做（3件）
- 优先级最高的3件事

请极度简洁，每部分不超过5条，适合3分钟阅读完毕。''';
      } else if (templateConfig.defaultWeeklyReportTemplateId ==
          'builtin_weekly_detailed') {
        systemPrompt = '''你是一位严谨的项目管理助理。请根据以下工作记录，生成一份详细的工作周报。

请按以下格式输出：

## 本周完成工作清单
| 序号 | 工作内容 | 完成度 | 耗时 | 备注 |
|------|----------|--------|------|------|

## 各项目进展
### 项目A
- 本周进展
- 遇到的问题
- 下一步计划

### 项目B
- 本周进展
- 遇到的问题
- 下一步计划

## 时间分配分析
- 各类工作占比
- 时间使用效率评估

## 待解决问题清单
- 问题描述
- 优先级
- 预计解决时间

## 下周详细计划
| 日期 | 计划内容 | 预计产出 |
|------|----------|----------|

请详细、结构化，适合存档和复盘。''';
      }

      final apiService = ApiService();
      final report = await apiService.chatCompletionWithSystem(
        buffer.toString(),
        systemPrompt: systemPrompt,
      );

      if (mounted) {
        setState(() => _reportContent = report);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_l10n.generationFailed}: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<void> _saveReport() async {
    if (_reportContent.isEmpty) return;

    final nameController = TextEditingController(
      text:
          '${_dateRange.start.month}${_l10n.month}${_dateRange.start.day}${_l10n.day}-${_dateRange.end.month}${_l10n.month}${_dateRange.end.day}${_l10n.day}${_l10n.weeklyReport}',
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_l10n.saveWeeklyReport),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: _l10n.reportName,
            hintText: _l10n.inputReportName,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_l10n.cancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(_l10n.saveButton),
          ),
        ],
      ),
    );

    if (confirmed == true && nameController.text.trim().isNotEmpty) {
      final report = SavedReport(
        id: const Uuid().v4(),
        title: nameController.text.trim(),
        content: _reportContent,
        startDate: _dateRange.start,
        endDate: _dateRange.end,
        createdAt: DateTime.now(),
      );
      await StorageService.saveWeeklyReport(report);
      await _loadSavedReports();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(_l10n.weeklyReportSaved), backgroundColor: AppColors.success),
        );
      }
    }
  }

  void _shareReport() {
    if (_reportContent.isEmpty) return;

    final shareText =
        '''${_dateRange.start.month}${_l10n.month}${_dateRange.start.day}${_l10n.day}-${_dateRange.end.month}${_l10n.month}${_dateRange.end.day}${_l10n.day} ${_l10n.weeklyReport}

$_reportContent

${_l10n.fromAppName(_l10n.appName)}''';

    Share.share(shareText, subject: _l10n.smartWeeklyReport);
  }

  Future<void> _copyReport() async {
    if (_reportContent.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _reportContent));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(_l10n.copiedToClipboard), backgroundColor: AppColors.success),
      );
    }
  }

  Widget _buildSavedReportsSection() {
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
            Text(_l10n.savedWeeklyReports,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const Spacer(),
            Text('${_savedReports.length} ${_l10n.reports}',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 8),
        if (_savedReports.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(_l10n.noSavedReports,
                style: TextStyle(color: AppColors.textSecondary)),
          )
        else
          ..._savedReports.map((report) => _buildSavedReportCard(report)),
      ],
    );
  }

  Widget _buildSavedReportCard(SavedReport report) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _showSavedReportDetail(report),
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
                      report.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${report.startDate.month}/${report.startDate.day} - ${report.endDate.month}/${report.endDate.day}',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: AppColors.error),
                onPressed: () => _deleteSavedReport(report.id),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSavedReportDetail(SavedReport report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(report.title),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(
              report.content,
              style: const TextStyle(fontSize: 14, height: 1.8),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_l10n.close),
          ),
          TextButton(
            onPressed: () {
              final shareText = '''${report.title}

${report.content}

来自畅记 App''';
              Share.share(shareText, subject: report.title);
            },
            child: Text(_l10n.share),
          ),
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: report.content));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(_l10n.copiedToClipboard),
                      backgroundColor: AppColors.success),
                );
              }
            },
            child: Text(_l10n.copy),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSavedReport(String id) async {
    await StorageService.deleteSavedReport(id);
    await _loadSavedReports();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(_l10n.deleted), backgroundColor: AppColors.success),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
