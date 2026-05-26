import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/role.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';

class RoleManagementScreen extends ConsumerStatefulWidget {
  const RoleManagementScreen({super.key});

  @override
  ConsumerState<RoleManagementScreen> createState() =>
      _RoleManagementScreenState();
}

class _RoleManagementScreenState
    extends ConsumerState<RoleManagementScreen> {
  List<Role> _roles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  Future<void> _loadRoles() async {
    final roles = await StorageService.getRoles();
    setState(() {
      _roles = roles;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.roleManagement),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _roles.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _roles.length,
                  itemBuilder: (context, index) {
                    final role = _roles[index];
                    return _buildRoleCard(role);
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRoleDialog(),
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
          Icon(Icons.person_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            l10n.noRoles,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.addRoleHint,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard(Role role) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Icon(
            Icons.person,
            color: AppColors.primary,
          ),
        ),
        title: Text(role.name),
        subtitle: Text(
          role.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _showEditRoleDialog(role),
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20, color: AppColors.error),
              onPressed: () => _showDeleteConfirm(role),
            ),
          ],
        ),
        onTap: () => _showEditRoleDialog(role),
      ),
    );
  }

  void _showAddRoleDialog() {
    _showRoleDialog();
  }

  void _showEditRoleDialog(Role role) {
    _showRoleDialog(role: role);
  }

  void _showRoleDialog({Role? role}) {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = role != null;
    final nameController = TextEditingController(text: role?.name ?? '');
    final descriptionController =
        TextEditingController(text: role?.description ?? '');
    final promptController = TextEditingController(text: role?.prompt ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? l10n.editRole : l10n.addRole),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: l10n.roleName,
                  hintText: l10n.roleNameHint,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: l10n.roleDescription,
                  hintText: l10n.roleDescriptionHint,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: promptController,
                decoration: InputDecoration(
                  labelText: l10n.rolePrompt,
                  hintText: l10n.rolePromptHint,
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
              ),
            ],
          ),
        ),
        actions: [
          if (isEditing)
            TextButton(
              onPressed: () async {
                final newRoles = _roles.where((r) => r.id != role.id).toList();
                await StorageService.saveRoles(newRoles);
                if (mounted) {
                  Navigator.pop(context);
                  _loadRoles();
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
                  SnackBar(content: Text(l10n.roleNameRequired)),
                );
                return;
              }

              final newRole = Role(
                id: isEditing ? role.id : DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameController.text,
                description: descriptionController.text,
                systemPrompt: promptController.text,
                createdAt: isEditing ? role.createdAt : DateTime.now(),
                updatedAt: DateTime.now(),
              );

              final newRoles = List<Role>.from(_roles);
              if (isEditing) {
                final index = newRoles.indexWhere((r) => r.id == role.id);
                if (index >= 0) {
                  newRoles[index] = newRole;
                }
              } else {
                newRoles.add(newRole);
              }

              await StorageService.saveRoles(newRoles);
              if (mounted) {
                Navigator.pop(context);
                _loadRoles();
              }
            },
            child: Text(l10n.saveButton),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(Role role) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDeleteRole),
        content: Text(l10n.confirmDeleteRoleMessage(role.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final newRoles = _roles.where((r) => r.id != role.id).toList();
              await StorageService.saveRoles(newRoles);
              if (mounted) {
                Navigator.pop(context);
                _loadRoles();
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
