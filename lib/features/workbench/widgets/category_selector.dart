
import 'package:flutter/material.dart';
import '../models/data_source_selection.dart';

class CategorySelector extends StatelessWidget {
  final List<DataSourceCategory> selectedCategories;
  final ValueChanged<List<DataSourceCategory>> onChanged;

  const CategorySelector({
    super.key,
    required this.selectedCategories,
    required this.onChanged,
  });

  void _toggleCategory(DataSourceCategory category) {
    final newSelection = List<DataSourceCategory>.from(selectedCategories);
    if (newSelection.contains(category)) {
      newSelection.remove(category);
    } else {
      newSelection.add(category);
    }
    onChanged(newSelection);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            '选择数据源类型',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            children: DataSourceCategory.values.map((category) {
              final isSelected = selectedCategories.contains(category);
              return FilterChip(
                avatar: Icon(category.icon, size: 18),
                label: Text(category.label),
                selected: isSelected,
                onSelected: (_) => _toggleCategory(category),
                selectedColor: Theme.of(context).primaryColor.withOpacity(0.1),
                checkmarkColor: Theme.of(context).primaryColor,
                backgroundColor: Colors.grey[100],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}