import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/prompt_template_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';

class PromptTemplateManagementScreen extends ConsumerStatefulWidget {
  const PromptTemplateManagementScreen({super.key});

  @override
  ConsumerState<PromptTemplateManagementScreen> createState() =>
      _PromptTemplateManagementScreenState();
}

class _PromptTemplateManagementScreenState
    extends ConsumerState<PromptTemplateManagementScreen> {
  List<PromptTemplate> _templates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    final service = ref.read(promptTemplateServiceProvider);
    await service.initialize();
    setState(() {
      _templates = service.getAllTemplates();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.promptTemplateManagement),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _templates.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _templates.length,
                  itemBuilder: (context, index) {
                    final template = _templates[index];
                    return _buildTemplateCard(template);
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTemplateDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            l10n.noPromptTemplates,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.addPromptTemplateHint,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(PromptTemplate template) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          _getCategoryIcon(template.category),
          color: AppColors.primary,
        ),
        title: Text(template.name),
        subtitle: Text(
          template.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (template.isBuiltIn)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  l10n.defaultTemplate,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _showEditTemplateDialog(template),
            ),
            if (!template.isBuiltIn)
              IconButton(
                icon: const Icon(Icons.delete, size: 20, color: AppColors.error),
                onPressed: () => _showDeleteConfirm(template),
              ),
          ],
        ),
        onTap: () => _showEditTemplateDialog(template),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'analysis':
        return Icons.psychology;
      case 'summary':
        return Icons.summarize;
      case 'chat':
        return Icons.chat;
      case 'custom':
        return Icons.tune;
      default:
        return Icons.description;
    }
  }

  void _showAddTemplateDialog() {
    _showTemplateDialog();
  }

  void _showEditTemplateDialog(PromptTemplate template) {
    _showTemplateDialog(template: template);
  }

  void _showTemplateDialog({PromptTemplate? template}) {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = template != null;
    final nameController = TextEditingController(text: template?.name ?? '');
    final descriptionController =
        TextEditingController(text: template?.description ?? '');
    final promptController = TextEditingController(text: template?.template ?? '');
    String selectedCategory = template?.category ?? 'custom';

    final categories = [
      _CategoryOption('analysis', l10n.analysis, Icons.psychology),
      _CategoryOption('summary', l10n.summary, Icons.summarize),
      _CategoryOption('chat', l10n.chat, Icons.chat),
      _CategoryOption('custom', l10n.custom, Icons.tune),
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEditing ? l10n.editPromptTemplate : l10n.addPromptTemplate),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: l10n.templateName,
                    hintText: l10n.templateNameHint,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: l10n.templateDescription,
                    hintText: l10n.templateDescriptionHint,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.category,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: categories.map((cat) {
                    final isSelected = selectedCategory == cat.value;
                    return ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(cat.icon, size: 16),
                          const SizedBox(width: 4),
                          Text(cat.label),
                        ],
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => selectedCategory = cat.value);
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: promptController,
                  decoration: InputDecoration(
                    labelText: l10n.promptContent,
                    hintText: l10n.promptContentHint,
                    alignLabelWithHint: true,
                  ),
                  maxLines: 5,
                ),
              ],
            ),
          ),
          actions: [
            if (isEditing && !template.isBuiltIn)
              TextButton(
                onPressed: () async {
                  final service = ref.read(promptTemplateServiceProvider);
                  await service.deleteTemplate(template.id);
                  if (mounted) {
                    Navigator.pop(context);
                    _loadTemplates();
                  }
                },
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: Text(l10n.deleteButton),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () async {
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.templateNameRequired)),
                  );
                  return;
                }

                final service = ref.read(promptTemplateServiceProvider);
                final newTemplate = PromptTemplate(
                  id: isEditing ? template.id : DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text,
                  description: descriptionController.text,
                  template: promptController.text,
                  category: selectedCategory,
                  createdAt: isEditing ? template.createdAt : DateTime.now(),
                  updatedAt: DateTime.now(),
                );
                if (isEditing) {
                  await service.updateTemplate(newTemplate);
                } else {
                  await service.addTemplate(newTemplate);
                }

                if (mounted) {
                  Navigator.pop(context);
                  _loadTemplates();
                }
              },
              child: Text(l10n.saveButton),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirm(PromptTemplate template) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDelete),
        content: Text(l10n.confirmDeleteTemplateMessage(template.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final service = ref.read(promptTemplateServiceProvider);
              await service.deleteTemplate(template.id);
              if (mounted) {
                Navigator.pop(context);
                _loadTemplates();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(l10n.deleteButton),
          ),
        ],
      ),
    );
  }
}

class _CategoryOption {
  final String value;
  final String label;
  final IconData icon;

  const _CategoryOption(this.value, this.label, this.icon);
}
