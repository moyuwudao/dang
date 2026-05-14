
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class RecordFilterSection extends StatefulWidget {
  final DateTimeRange? dateRange;
  final bool includeAiAnalysis;
  final ValueChanged<DateTimeRange?> onDateRangeChanged;
  final ValueChanged<bool> onIncludeAiAnalysisChanged;

  const RecordFilterSection({
    super.key,
    this.dateRange,
    this.includeAiAnalysis = true,
    required this.onDateRangeChanged,
    required this.onIncludeAiAnalysisChanged,
  });

  @override
  State<RecordFilterSection> createState() => _RecordFilterSectionState();
}

class _RecordFilterSectionState extends State<RecordFilterSection> {
  DateTimeRange _currentDateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 7)),
    end: DateTime.now(),
  );

  @override
  void initState() {
    super.initState();
    if (widget.dateRange != null) {
      _currentDateRange = widget.dateRange!;
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: _currentDateRange,
    );
    if (picked != null) {
      setState(() => _currentDateRange = picked);
      widget.onDateRangeChanged(picked);
    }
  }

  String _formatDateRange(DateTimeRange range) {
    final startStr = '${range.start.month}/${range.start.day}';
    final endStr = '${range.end.month}/${range.end.day}';
    final days = range.duration.inDays;
    return '$startStr - $endStr（$days天）';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Card(
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
                          const Text(
                            '时间范围',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDateRange(_currentDateRange),
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('包含AI分析结果'),
            subtitle: const Text('将记录的AI分析内容也作为输入数据'),
            value: widget.includeAiAnalysis,
            onChanged: widget.onIncludeAiAnalysisChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}