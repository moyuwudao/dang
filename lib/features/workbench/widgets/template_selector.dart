import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/tool_template.dart';

class TemplateSelector extends StatelessWidget {
  final List<ToolTemplate> templates;
  final ToolTemplate? selectedTemplate;
  final ValueChanged<ToolTemplate> onSelected;

  const TemplateSelector({
    super.key,
    required this.templates,
    this.selectedTemplate,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_fix_high, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            const Text(
              '选择模板',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            if (selectedTemplate != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  selectedTemplate!.name,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: templates.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final template = templates[index];
              final isSelected = selectedTemplate?.id == template.id;
              return _TemplateCard(
                template: template,
                isSelected: isSelected,
                onTap: () => onSelected(template),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final ToolTemplate template;
  final bool isSelected;
  final VoidCallback onTap;

  const _TemplateCard({
    required this.template,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.surface,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    template.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (template.isBuiltIn)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '内置',
                      style: TextStyle(fontSize: 9, color: AppColors.secondary),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              template.description,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            if (isSelected)
              const Row(
                children: [
                  Icon(Icons.check_circle, size: 14, color: AppColors.primary),
                  SizedBox(width: 4),
                  Text(
                    '已选择',
                    style: TextStyle(fontSize: 11, color: AppColors.primary),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
