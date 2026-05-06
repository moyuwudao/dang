import 'package:flutter/material.dart';
import '../../../core/models/ai_role.dart';
import '../../../core/services/role_service.dart';
import '../../../core/theme/app_colors.dart';

class RoleManagementScreen extends StatefulWidget {
  const RoleManagementScreen({super.key});

  @override
  State<RoleManagementScreen> createState() => _RoleManagementScreenState();
}

class _RoleManagementScreenState extends State<RoleManagementScreen> {
  List<AiRole> _builtInRoles = [];
  List<AiRole> _customRoles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  Future<void> _loadRoles() async {
    setState(() {
      _isLoading = true;
    });

    final customRoles = await RoleService.getCustomRoles();

    setState(() {
      _builtInRoles = AiRole.builtInRoles;
      _customRoles = customRoles;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI分析角色'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddRoleDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Built-in roles section
                Text(
                  '系统角色（不可删除）',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 8),
                ..._builtInRoles.map((role) => _buildRoleCard(role, false)),

                const SizedBox(height: 24),

                // Custom roles section
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '自定义角色',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _showAddRoleDialog(),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('新建'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_customRoles.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.psychology_outlined,
                          size: 48,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '暂无自定义角色',
                          style: TextStyle(color: AppColors.textTertiary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '点击右上角 + 创建你的专属AI角色',
                          style: TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ..._customRoles.map((role) => _buildRoleCard(role, true)),
              ],
            ),
    );
  }

  Widget _buildRoleCard(AiRole role, bool isCustom) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _showRoleDetail(role, isCustom),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isCustom ? Icons.person_outline : Icons.verified,
                    color: isCustom ? AppColors.primary : AppColors.success,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      role.name,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  if (isCustom)
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showEditRoleDialog(role);
                        } else if (value == 'delete') {
                          _showDeleteConfirm(role);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 18),
                              SizedBox(width: 8),
                              Text('编辑'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text('删除', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                role.description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRoleDetail(AiRole role, bool isCustom) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        role.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  role.description,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                Text(
                  '提示词（Prompt）',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: SelectableText(
                        role.systemPrompt,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddRoleDialog() {
    _showRoleEditorDialog(null);
  }

  void _showEditRoleDialog(AiRole role) {
    _showRoleEditorDialog(role);
  }

  void _showRoleEditorDialog(AiRole? existingRole) {
    final nameController = TextEditingController(text: existingRole?.name ?? '');
    final descController = TextEditingController(text: existingRole?.description ?? '');
    final promptController = TextEditingController(text: existingRole?.systemPrompt ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existingRole == null ? '新建角色' : '编辑角色'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '角色名称',
                  hintText: '例如：产品经理',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: '角色描述',
                  hintText: '简要说明这个角色的用途',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: promptController,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: '系统提示词（Prompt）',
                  hintText: '输入系统提示词，定义AI的角色和行为...',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final desc = descController.text.trim();
              final prompt = promptController.text.trim();

              if (name.isEmpty || prompt.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('名称和提示词不能为空')),
                );
                return;
              }

              if (existingRole != null) {
                await RoleService.updateCustomRole(
                  existingRole.copyWith(
                    name: name,
                    description: desc,
                    systemPrompt: prompt,
                  ),
                );
              } else {
                await RoleService.addCustomRole(
                  AiRole(
                    id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                    name: name,
                    description: desc,
                    systemPrompt: prompt,
                    isBuiltIn: false,
                    createdAt: DateTime.now(),
                  ),
                );
              }

              if (mounted) {
                Navigator.pop(context);
                _loadRoles();
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(AiRole role) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除角色「${role.name}」吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              await RoleService.deleteCustomRole(role.id);
              if (mounted) {
                Navigator.pop(context);
                _loadRoles();
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
