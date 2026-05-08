import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/record_model.dart';
import '../../data/repositories/record_repository.dart';
import '../theme/app_colors.dart';

class TagSelector extends ConsumerStatefulWidget {
  final List<String> selectedTags;
  final ValueChanged<List<String>> onTagsChanged;

  const TagSelector({
    super.key,
    required this.selectedTags,
    required this.onTagsChanged,
  });

  @override
  ConsumerState<TagSelector> createState() => _TagSelectorState();
}

class _TagSelectorState extends ConsumerState<TagSelector> {
  final _newTagController = TextEditingController();
  List<String> _allExistingTags = [];

  @override
  void initState() {
    super.initState();
    _loadExistingTags();
  }

  @override
  void dispose() {
    _newTagController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingTags() async {
    final records = await ref.read(recordRepositoryProvider).getAllRecords();
    final tagUsage = <String, int>{};
    final tagLastUsed = <String, DateTime>{};

    for (final record in records) {
      for (final tag in record.tags) {
        tagUsage[tag] = (tagUsage[tag] ?? 0) + 1;
        if (tagLastUsed[tag] == null || record.createdAt.isAfter(tagLastUsed[tag]!)) {
          tagLastUsed[tag] = record.createdAt;
        }
      }
    }

    // Sort by recent usage first, then by frequency
    final sortedTags = tagUsage.keys.toList()
      ..sort((a, b) {
        final timeCompare = (tagLastUsed[b] ?? DateTime(2000))
            .compareTo(tagLastUsed[a] ?? DateTime(2000));
        if (timeCompare != 0) return timeCompare;
        return (tagUsage[b] ?? 0).compareTo(tagUsage[a] ?? 0);
      });

    setState(() {
      _allExistingTags = sortedTags;
    });
  }

  void _addNewTag() {
    final tag = _newTagController.text.trim();
    if (tag.isNotEmpty && !widget.selectedTags.contains(tag)) {
      widget.onTagsChanged([...widget.selectedTags, tag]);
      _newTagController.clear();
      if (!_allExistingTags.contains(tag)) {
        setState(() {
          _allExistingTags = [tag, ..._allExistingTags];
        });
      }
    }
  }

  void _toggleTag(String tag) {
    if (widget.selectedTags.contains(tag)) {
      widget.onTagsChanged(
        widget.selectedTags.where((t) => t != tag).toList(),
      );
    } else {
      widget.onTagsChanged([...widget.selectedTags, tag]);
    }
  }

  void _removeTag(String tag) {
    widget.onTagsChanged(
      widget.selectedTags.where((t) => t != tag).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 下拉框选择标签
        _buildTagDropdown(),
        const SizedBox(height: 12),
        // 已选标签展示
        if (widget.selectedTags.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.selectedTags.map((tag) {
              return Chip(
                label: Text(tag),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () => _removeTag(tag),
                backgroundColor: AppColors.primary.withOpacity(0.1),
                labelStyle: const TextStyle(color: AppColors.primary),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildTagDropdown() {
    final dropdownItems = <DropdownMenuItem<String>>[
      const DropdownMenuItem(
        value: '__new__',
        child: Row(
          children: [
            Icon(Icons.add, size: 18, color: AppColors.primary),
            SizedBox(width: 8),
            Text('新增标签'),
          ],
        ),
      ),
      ..._allExistingTags.map((tag) => DropdownMenuItem(
        value: tag,
        child: Row(
          children: [
            Icon(
              widget.selectedTags.contains(tag) ? Icons.check_box : Icons.check_box_outline_blank,
              size: 18,
              color: widget.selectedTags.contains(tag) ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(tag),
          ],
        ),
      )),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: null,
            hint: const Text('选择或新增标签'),
            isExpanded: true,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
            items: dropdownItems,
            onChanged: (value) {
              if (value == '__new__') {
                _showNewTagDialog();
              } else if (value != null) {
                _toggleTag(value);
              }
            },
          ),
        ),
      ],
    );
  }

  void _showNewTagDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新增标签'),
        content: TextField(
          controller: _newTagController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '输入新标签名称',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) {
            _addNewTag();
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              _addNewTag();
              Navigator.pop(context);
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }
}
