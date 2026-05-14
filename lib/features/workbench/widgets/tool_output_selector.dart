
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/tool_output_repository.dart';
import '../../../data/models/tool_output_model.dart';

class ToolOutputSelector extends ConsumerStatefulWidget {
  final String? selectedToolId;
  final List<String> selectedOutputIds;
  final ValueChanged<List<String>> onSelected;

  const ToolOutputSelector({
    super.key,
    this.selectedToolId,
    required this.selectedOutputIds,
    required this.onSelected,
  });

  @override
  ConsumerState<ToolOutputSelector> createState() => _ToolOutputSelectorState();
}

class _ToolOutputSelectorState extends ConsumerState<ToolOutputSelector> {
  List<ToolOutputModel> _outputs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOutputs();
  }

  Future<void> _loadOutputs() async {
    setState(() => _isLoading = true);
    try {
      final repository = ref.read(toolOutputRepositoryProvider);
      if (widget.selectedToolId != null) {
        _outputs = await repository.getToolOutputsByToolId(widget.selectedToolId!);
      } else {
        _outputs = await repository.getAllToolOutputs();
      }
    } catch (e) {
      _outputs = [];
    }
    setState(() => _isLoading = false);
  }

  void _toggleSelection(String outputId) {
    final newSelection = List<String>.from(widget.selectedOutputIds);
    if (newSelection.contains(outputId)) {
      newSelection.remove(outputId);
    } else {
      newSelection.add(outputId);
    }
    widget.onSelected(newSelection);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_outputs.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          '暂无工具输出数据',
          style: TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      children: _outputs.map((output) {
        final isSelected = widget.selectedOutputIds.contains(output.id);
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => _toggleSelection(output.id),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Checkbox(
                    value: isSelected,
                    onChanged: (_) => _toggleSelection(output.id),
                    activeColor: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          output.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${output.createdAt.month}/${output.createdAt.day} ${output.createdAt.hour}:${output.createdAt.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12),
                        ),
                        if (output.sourceRecordIds.isNotEmpty)
                          Text(
                            '关联 ${output.sourceRecordIds.length} 条记录',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 11),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}