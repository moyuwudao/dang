import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  List<String> _allExistingTags = [];

  @override
  void initState() {
    super.initState();
    _loadExistingTags();
  }

  Future<void> _loadExistingTags() async {
    final records = await ref.read(recordRepositoryProvider).getAllRecords();
    final tagUsage = <String, int>{};
    final tagLastUsed = <String, DateTime>{};

    for (final record in records) {
      for (final tag in record.tags) {
        tagUsage[tag] = (tagUsage[tag] ?? 0) + 1;
        if (tagLastUsed[tag] == null ||
            record.createdAt.isAfter(tagLastUsed[tag]!)) {
          tagLastUsed[tag] = record.createdAt;
        }
      }
    }

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

  void _addTag(String tag) {
    final trimmed = tag.trim();
    if (trimmed.isNotEmpty && !widget.selectedTags.contains(trimmed)) {
      widget.onTagsChanged([...widget.selectedTags, trimmed]);
      if (!_allExistingTags.contains(trimmed)) {
        setState(() {
          _allExistingTags = [trimmed, ..._allExistingTags];
        });
      }
    }
  }

  void _addTagFromSheet(String tag) {
    final trimmed = tag.trim();
    if (trimmed.isNotEmpty && !widget.selectedTags.contains(trimmed)) {
      widget.onTagsChanged([...widget.selectedTags, trimmed]);
      if (!_allExistingTags.contains(trimmed)) {
        setState(() {
          _allExistingTags = [trimmed, ..._allExistingTags];
        });
      }
    }
  }

  void _removeTag(String tag) {
    widget.onTagsChanged(
      widget.selectedTags.where((t) => t != tag).toList(),
    );
  }

  void _showTagSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _TagSheet(
        allTags: _allExistingTags,
        selectedTags: widget.selectedTags,
        onAddTag: (tag) {
          _addTag(tag);
          // 强制刷新 sheet 中的标签列表
          (context as Element).markNeedsBuild();
        },
        onRemoveTag: _removeTag,
      ),
    ).then((_) => _loadExistingTags());
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showTagSheet,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.edit,
              size: 16,
              color: AppColors.primary.withOpacity(0.7),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                widget.selectedTags.isEmpty ? '标签' : widget.selectedTags.join(', '),
                style: TextStyle(
                  color: widget.selectedTags.isEmpty
                      ? AppColors.textSecondary
                      : AppColors.primary,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagSheet extends StatefulWidget {
  final List<String> allTags;
  final List<String> selectedTags;
  final ValueChanged<String> onAddTag;
  final ValueChanged<String> onRemoveTag;

  const _TagSheet({
    required this.allTags,
    required this.selectedTags,
    required this.onAddTag,
    required this.onRemoveTag,
  });

  @override
  State<_TagSheet> createState() => _TagSheetState();
}

class _TagSheetState extends State<_TagSheet> {
  final _newTagController = TextEditingController();
  bool _showNewTagInput = false;

  @override
  void dispose() {
    _newTagController.dispose();
    super.dispose();
  }

  void _submitNewTag() {
    final tag = _newTagController.text.trim();
    if (tag.isNotEmpty) {
      widget.onAddTag(tag);
      _newTagController.clear();
      setState(() {
        _showNewTagInput = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '选择标签',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_showNewTagInput) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newTagController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: '输入新标签',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        suffixIcon: IconButton(
                          onPressed: _submitNewTag,
                          icon: const Icon(Icons.check, color: AppColors.primary),
                        ),
                      ),
                      onSubmitted: (_) => _submitNewTag(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            // 标签列表：新增标签 + 已有标签 在同一行
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // 新增标签按钮
                  if (!_showNewTagInput)
                    GestureDetector(
                      onTap: () => setState(() => _showNewTagInput = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, color: AppColors.primary, size: 16),
                            SizedBox(width: 4),
                            Text(
                              '新增标签',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // 已有标签
                  ...widget.allTags.map((tag) {
                    final isSelected = widget.selectedTags.contains(tag);
                    return GestureDetector(
                      onTap: () {
                        if (isSelected) {
                          widget.onRemoveTag(tag);
                        } else {
                          widget.onAddTag(tag);
                        }
                        setState(() {});
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withOpacity(0.2)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: isSelected
                              ? Border.all(
                                  color: AppColors.primary.withOpacity(0.5),
                                )
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected) ...[
                              const Icon(
                                Icons.check,
                                size: 14,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              tag,
                              style: TextStyle(
                                fontSize: 13,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
