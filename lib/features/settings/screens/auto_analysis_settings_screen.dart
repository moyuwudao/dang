import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/ai_role.dart';
import '../../../core/services/prompt_template_service.dart';
import '../../../core/services/role_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_colors.dart';

class AutoAnalysisSettingsScreen extends ConsumerStatefulWidget {
  const AutoAnalysisSettingsScreen({super.key});
     

  @override
  ConsumerState<AutoAnalysisSettingsScreen> createState() => _AutoAnalysisSettingsScreenState();
}

class _AutoAnalysisSettingsScreenState extends ConsumerState<AutoAnalysisSettingsScreen> {
  bool _isEnabled = false;
  String? _selectedRoleId;
  List<AiRole> _systemRoles = [];
  List<AiRole> _customRoles = [];
  List<SavedTemplateConfig> _savedTemplates = [];
  List<PromptTemplate> _allTemplates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

      
         

         
  Future<void> _loadData() async {
    final config = await StorageService.getAutoAnalysisConfig();
    final systemRoles = AiRole.builtInRoles;
    final customRoles = await RoleService.getCustomRoles();

    final templateService = ref.read(promptTemplateServiceProvider);
    await templateService.initialize();
    final allTemplates = templateService.getAllTemplates();

    setState(() {
      _isEnabled = config.enabled;
      _selectedRoleId = config.defaultRoleId.isNotEmpty ? config.defaultRoleId : null;
      _savedTemplates = config.savedTemplates;
      _systemRoles = systemRoles;
      _customRoles = customRoles;
      _allTemplates = allTemplates;
  _isLoading = false;
    });
  }

  Future<void> _saveConfig() async {
    final config = AutoAnalysisConfig(
      enabled: _isEnabled,
      defaultRoleId: _selectedRoleId ?? '',
      selectedRoleIds: _selectedRoleId != null ? [_selectedRoleId!] : [],
      savedTemplates: _savedTemplates,
    );
    await StorageService.saveAutoAnalysisConfig(config);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('设置已保存'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final allSelectableItems = _buildSelectableItems();

    return Scaffold(
      appBar: AppBar(
        title: const Text('自动分析设置'),
        actions: [
          TextButton(
            onPressed: _saveConfig,
            child: const Text('保存', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: const Text('启用自动分析'),
              subtitle: const Text('转写完成后自动进行AI分析'),
              value: _isEnabled,
              onChanged: (value) {
    setState(() => _isEnabled = value);
              },
            ),
            const SizedBox(height: 24),

            Text(
              '选择自动分析方案',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '选择转写后自动使用的分析角色或模板',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),

            if (!_isEnabled)
              Container(
                padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.textSecondary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '请先启用自动分析开关',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              )
            else if (allSelectableItems.isEmpty)
              _buildEmptyState()
            else
              ...allSelectableItems.map((item) => _buildSelectableItemTile(item)),

            const SizedBox(height: 24),
            _buildAddFromTemplateSection(),

            const SizedBox(height: 24),
            Card(
              color: Colors.grey[50],
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '说明',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('• 开启自动分析后，录音转写完成将自动使用所选方案进行分析'),
                    Text('• 自动分析会消耗API调用次数，请确保API配置正确'),
                    Text('• 可以从模板库添加方案，也可以直接使用系统或自定义角色'),
                    Text('• 保存的模板方案会独立存储，即使模板库更新也不会丢失'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_SelectableItem> _buildSelectableItems() {
    final items = <_SelectableItem>[];

    // 系统角色
    for (final role in _systemRoles) {
      items.add(_SelectableItem(
        id: role.id,
        name: role.name,
        description: role.description,
        type: _ItemType.systemRole,
        icon: Icons.verified,
        color: AppColors.success,
      ));
    }

    // 自定义角色
    for (final role in _customRoles) {
      items.add(_SelectableItem(
        id: role.id,
        name: role.name,
        description: role.description,
        type: _ItemType.customRole,
        icon: Icons.person_outline,
        color: AppColors.primary,
      ));
    }

    // 保存的模板方案
    for (final template in _savedTemplates) {
      items.add(_SelectableItem(
        id: template.templateId,
        name: template.name,
        description: template.description,
        type: _ItemType.savedTemplate,
        icon: Icons.auto_stories,
        color: AppColors.info,
      ));
    }

    return items;
  }

  Widget _buildSelectableItemTile(_SelectableItem item) {
    final isSelected = _selectedRoleId == item.id;
    final isDeletable = item.type == _ItemType.savedTemplate;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.grey[200]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: _isEnabled
            ? () {
                setState(() => _selectedRoleId = item.id);
              }
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(item.icon, color: item.color, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle, color: AppColors.success, size: 20),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isDeletable)
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                  onPressed: () => _removeSavedTemplate(item.id),
                  tooltip: '删除',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _removeSavedTemplate(String templateId) {
    setState(() {
      _savedTemplates.removeWhere((t) => t.templateId == templateId);
      // 如果删除的是当前选中的，清空选择
      if (_selectedRoleId == templateId) {
        _selectedRoleId = null;
      }
    });
  }

  Widget _buildAddFromTemplateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '从模板库添加方案',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        ..._allTemplates.take(5).map((template) => _buildTemplateAddTile(template)),
        if (_allTemplates.length > 5)
          TextButton(
            onPressed: () => _showTemplatePickerDialog(),
            child: const Text('查看更多模板...'),
          ),
      ],
    );
  }

  Widget _buildTemplateAddTile(PromptTemplate template) {
    final isAlreadySaved = _savedTemplates.any((t) => t.templateId == template.id);

    return ListTile(
      dense: true,
      leading: const Icon(Icons.auto_stories, color: AppColors.info, size: 20),
      title: Text(template.name, style: const TextStyle(fontSize: 14)),
      subtitle: Text(
        template.description,
        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: isAlreadySaved
          ? Chip(
              label: const Text('已添加', style: TextStyle(fontSize: 11)),
              backgroundColor: AppColors.success.withOpacity(0.1),
              side: BorderSide.none,
            )
          : TextButton(
              onPressed: () => _addTemplateToSaved(template),
              child: const Text('添加'),
            ),
    );
  }

  void _addTemplateToSaved(PromptTemplate template) {
    setState(() {
      _savedTemplates.add(SavedTemplateConfig(
        templateId: template.id,
        name: template.name,
        description: template.description,
        systemPrompt: template.template,
        category: template.category,
      ));
    });
  }

  void _showTemplatePickerDialog() {
    final templateService = ref.read(promptTemplateServiceProvider);
    final categories = templateService.getCategories();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择模板方案'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, catIndex) {
              final category = categories[catIndex];
              final categoryTemplates = _allTemplates
                  .where((t) => t.category == category)
                  .toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (catIndex > 0) const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      _getCategoryLabel(category),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  ...categoryTemplates.map((template) {
                    final isSaved = _savedTemplates.any((t) => t.templateId == template.id);
                    return ListTile(
                      dense: true,
                      title: Text(template.name),
                      subtitle: Text(
                        template.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: isSaved
                          ? const Icon(Icons.check, color: AppColors.success)
                          : TextButton(
                              onPressed: () {
                                _addTemplateToSaved(template);
                                Navigator.pop(context);
                              },
                              child: const Text('添加'),
                            ),
                    );
                  }),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  String _getCategoryLabel(String category) {
    const labels = {
      'frequently_used': '常用',
      'general': '通用',
      'solopreneur': '一人公司',
      'business': '商业',
      'productivity': '效率',
      'creative': '创意',
      'learning': '学习',
      'life': '生活',
      'fun': '趣味',
    };
    return labels[category] ?? category;
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.psychology_outlined, size: 32, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            '暂无可用角色',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

enum _ItemType { systemRole, customRole, savedTemplate }

class _SelectableItem {
  final String id;
  final String name;
  final String description;
  final _ItemType type;
  final IconData icon;
  final Color color;

  _SelectableItem({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.icon,
    required this.color,
  });
}
