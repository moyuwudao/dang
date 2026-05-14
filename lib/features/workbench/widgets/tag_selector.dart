import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/record_repository.dart';

class TagSelector extends ConsumerStatefulWidget {
  final List<String> selectedTags;
  final ValueChanged<List<String>> onSelected;

  const TagSelector({
    super.key,
    required this.selectedTags,
    required this.onSelected,
  });

  @override
  ConsumerState<TagSelector> createState() => _TagSelectorState();
}

class _TagSelectorState extends ConsumerState<TagSelector> {
  List<String> _allTags = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  Future<void> _loadTags() async {
    setState(() => _isLoading = true);
    try {
      final repository = ref.read(recordRepositoryProvider);
      _allTags = await repository.getAllTags();
    } catch (e) {
      _allTags = [];
    }
    setState(() => _isLoading = false);
  }

  void _toggleTag(String tag) {
    final newSelection = List<String>.from(widget.selectedTags);
    if (newSelection.contains(tag)) {
      newSelection.remove(tag);
    } else {
      newSelection.add(tag);
    }
    widget.onSelected(newSelection);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_allTags.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          '暂无标签',
          style: TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _allTags.map<Widget>((tag) {
          final isSelected = widget.selectedTags.contains(tag);
          return FilterChip(
            label: Text(tag),
            selected: isSelected,
            onSelected: (_) => _toggleTag(tag),
            selectedColor: Theme.of(context).primaryColor.withOpacity(0.15),
            checkmarkColor: Theme.of(context).primaryColor,
            backgroundColor: Colors.grey[100],
            labelStyle: TextStyle(
              color: isSelected ? Theme.of(context).primaryColor : Colors.black,
              fontSize: 13,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          );
        }).toList(),
      ),
    );
  }
}
