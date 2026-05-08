import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/prompt_template_service.dart';
import '../../../core/theme/app_colors.dart';

final templateListProvider = FutureProvider<List<PromptTemplate>>((ref) async {
  final service = ref.read(promptTemplateServiceProvider);
  await service.initialize();
  return service.getAllTemplates();
});

class PromptTemplateManagementScreen extends ConsumerStatefulWidget {
  const PromptTemplateManagementScreen({super.key});

  @override
  ConsumerState<PromptTemplateManagementScreen> createState() => _PromptTemplateManagementScreenState();
}

class _PromptTemplateManagementScreenState extends ConsumerState<PromptTemplateManagementScreen> {
  String _selectedCategory = 'all';

  static const _categoryConfig = {
    'all': {'label': '全部', 'icon': Icons.apps},
    'solopreneur': {'label': '一人公司', 'icon': Icons.person},
    'business': {'label': '商业', 'icon': Icons.business_center},
    'productivity': {'label': '效率', 'icon': Icons.speed},
    'creative': {'label': '创意', 'icon': Icons.palette},
    'learning': {'label': '学习', 'icon': Icons.school},
    'life': {'label': '生活', 'icon': Icons.favorite},
    'fun': {'label': '趣味', 'icon': Icons.emoji_emotions},
    'general': {'label': '通用', 'icon': Icons.category},
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final templatesAsync = ref.watch(templateListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prompt模板管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showTemplateEditor(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCategoryTabs(theme),
          Expanded(
            child: templatesAsync.when(
              data: (templates) {
                final filtered = _selectedCategory == 'all'
                    ? templates
                    : templates.where((t) => t.category == _selectedCategory).toList();
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.description_outlined, size: 64, color: AppColors.textTertiary),
                        const SizedBox(height: 16),
                        Text('暂无模板', style: TextStyle(color: AppColors.textTertiary, fontSize: 16)),
                        const SizedBox(height: 8),
                        Text('点击右上角 + 创建新模板', style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) => _buildTemplateCard(filtered[index]),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('加载失败: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(ThemeData theme) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: _categoryConfig.entries.map((entry) {
          final isSelected = _selectedCategory == entry.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              avatar: Icon(entry.value['icon'] as IconData, size: 16),
              label: Text(entry.value['label'] as String),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedCategory = entry.key),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTemplateCard(PromptTemplate template) {
    final categoryLabel = _categoryConfig[template.category]?['label'] as String? ?? template.category;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showTemplateDetail(context, template),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          template.name,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: template.isBuiltIn ? AppColors.info.withOpacity(0.1) : AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            template.isBuiltIn ? '内置' : '自定义',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: template.isBuiltIn ? AppColors.info : AppColors.success,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            categoryLabel,
                            style: TextStyle(fontSize: 10, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!template.isBuiltIn)
                    PopupMenuButton<String>(
                      onSelected: (action) {
                        if (action == 'edit') {
                          _showTemplateEditor(context, template: template);
                        } else if (action == 'delete') {
                          _confirmDelete(template);
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'edit', child: Text('编辑')),
                        const PopupMenuItem(value: 'delete', child: Text('删除')),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                template.description,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                template.template.length > 80
                    ? '${template.template.substring(0, 80)}...'
                    : template.template,
                style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTemplateDetail(BuildContext context, PromptTemplate template) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(template.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(template.description, style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              const Text('模板内容', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SelectableText(
                  template.template,
                  style: const TextStyle(fontSize: 13, height: 1.6),
                ),
              ),
              if (!template.isBuiltIn) ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showTemplateEditor(context, template: template);
                        },
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('编辑'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _confirmDelete(template);
                        },
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('删除'),
                        style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showTemplateEditor(BuildContext context, {PromptTemplate? template}) {
    final isEditing = template != null;
    final nameController = TextEditingController(text: template?.name ?? '');
    final descController = TextEditingController(text: template?.description ?? '');
    final contentController = TextEditingController(text: template?.template ?? '');
    String selectedCategory = template?.category ?? 'solopreneur';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isEditing ? '编辑模板' : '创建新模板',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: '模板名称',
                    hintText: '如：客户沟通复盘',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: InputDecoration(
                    labelText: '简短描述',
                    hintText: '一句话描述模板用途',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: InputDecoration(
                    labelText: '分类',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: _categoryConfig.entries
                      .where((e) => e.key != 'all')
                      .map((e) => DropdownMenuItem(
                            value: e.key,
                            child: Row(
                              children: [
                                Icon(e.value['icon'] as IconData, size: 16),
                                const SizedBox(width: 8),
                                Text(e.value['label'] as String),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: (v) => setModalState(() => selectedCategory = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentController,
                  maxLines: 10,
                  decoration: InputDecoration(
                    labelText: '模板内容',
                    hintText: '使用 {{content}} 作为内容占位符',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '提示：使用 {{content}} 表示用户录音/笔记内容的位置',
                  style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (nameController.text.isEmpty || contentController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('请填写模板名称和内容')),
                        );
                        return;
                      }
                      final service = ref.read(promptTemplateServiceProvider);
                      final now = DateTime.now();
                      final newTemplate = PromptTemplate(
                        id: isEditing ? template!.id : 'custom_${now.millisecondsSinceEpoch}',
                        name: nameController.text,
                        description: descController.text,
                        template: contentController.text,
                        category: selectedCategory,
                        isBuiltIn: false,
                        createdAt: isEditing ? template!.createdAt : now,
                        updatedAt: now,
                      );
                      if (isEditing) {
                        service.updateTemplate(newTemplate);
                      } else {
                        service.addTemplate(newTemplate);
                      }
                      ref.invalidate(templateListProvider);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(isEditing ? '模板已更新' : '模板已创建')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(isEditing ? '保存修改' : '创建模板'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(PromptTemplate template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除模板「${template.name}」吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final service = ref.read(promptTemplateServiceProvider);
              service.deleteTemplate(template.id);
              ref.invalidate(templateListProvider);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('模板已删除')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
