import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';

class AnalysisTemplateSettingsScreen extends ConsumerStatefulWidget {
  const AnalysisTemplateSettingsScreen({super.key});

  @override
  ConsumerState<AnalysisTemplateSettingsScreen> createState() =>
      _AnalysisTemplateSettingsScreenState();
}

class _AnalysisTemplateSettingsScreenState
    extends ConsumerState<AnalysisTemplateSettingsScreen> {
  List<AnalysisTemplate> _templates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    final templates = await StorageService.getAnalysisTemplateList();
    setState(() {
      _templates = templates;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.analysisTemplate),
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
          Icon(Icons.description_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            l10n.noAnalysisTemplates,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.addAnalysisTemplateHint,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(AnalysisTemplate template) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.description, color: AppColors.primary),
        title: Text(template.name),
        subtitle: Text(
          template.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (template.isDefault)
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
            if (!template.isDefault)
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

  void _showAddTemplateDialog() {
    _showTemplateDialog();
  }

  void _showEditTemplateDialog(AnalysisTemplate template) {
    _showTemplateDialog(template: template);
  }

  void _showTemplateDialog({AnalysisTemplate? template}) {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = template != null;
    final nameController = TextEditingController(text: template?.name ?? '');
    final descriptionController =
        TextEditingController(text: template?.description ?? '');
    final promptController = TextEditingController(text: template?.prompt ?? '');
    bool isDefault = template?.isDefault ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEditing ? l10n.editTemplate : l10n.addTemplate),
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
                TextField(
                  controller: promptController,
                  decoration: InputDecoration(
                    labelText: l10n.templatePrompt,
                    hintText: l10n.templatePromptHint,
                    alignLabelWithHint: true,
                  ),
                  maxLines: 5,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: Text(l10n.setAsDefault),
                  subtitle: Text(l10n.setAsDefaultDesc),
                  value: isDefault,
                  onChanged: (value) => setState(() => isDefault = value),
                ),
              ],
            ),
          ),
          actions: [
            if (isEditing && !template.isDefault)
              TextButton(
                onPressed: () async {
                  final newTemplates =
                      _templates.where((t) => t.id != template.id).toList();
                  await StorageService.saveAnalysisTemplateList(newTemplates);
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

                final newTemplate = AnalysisTemplate(
                  id: isEditing ? template.id : DateTime.now().toString(),
                  name: nameController.text,
                  description: descriptionController.text,
                  type: 'custom',
                  systemPrompt: promptController.text,
                  isBuiltIn: isDefault,
                  createdAt: isEditing ? template.createdAt : DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                final newTemplates = List<AnalysisTemplate>.from(_templates);
                if (isEditing) {
                  final index = newTemplates.indexWhere((t) => t.id == template.id);
                  if (index >= 0) {
                    newTemplates[index] = newTemplate;
                  }
                } else {
                  newTemplates.add(newTemplate);
                }

                // 如果设置为默认，取消其他默认
                if (isDefault) {
                  for (var i = 0; i < newTemplates.length; i++) {
                    if (newTemplates[i].id != newTemplate.id) {
                      newTemplates[i] = newTemplates[i].copyWith(isDefault: false);
                    }
                  }
                }

                await StorageService.saveAnalysisTemplateList(newTemplates);
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

  void _showDeleteConfirm(AnalysisTemplate template) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDeleteTemplate),
        content: Text(l10n.confirmDeleteTemplateNamed(template.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final newTemplates =
                  _templates.where((t) => t.id != template.id).toList();
              await StorageService.saveAnalysisTemplateList(newTemplates);
              if (mounted) {
                Navigator.pop(context);
                _loadTemplates();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: Text(l10n.deleteButton),
          ),
        ],
      ),
    );
  }
}
