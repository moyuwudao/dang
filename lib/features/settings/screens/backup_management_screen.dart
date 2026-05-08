import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/services/backup_service.dart';
import '../../../core/theme/app_colors.dart';

final backupListProvider = FutureProvider<List<BackupInfo>>((ref) async {
  return await BackupService.getBackupList();
});

class BackupManagementScreen extends ConsumerStatefulWidget {
  const BackupManagementScreen({super.key});

  @override
  ConsumerState<BackupManagementScreen> createState() {
    return _BackupManagementScreenState();
  }
}

class _BackupManagementScreenState
    extends ConsumerState<BackupManagementScreen> {
  bool _isCreating = false;
  bool _isRestoring = false;

  @override
  Widget build(BuildContext context) {
    final backupsAsync = ref.watch(backupListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('本地备份管理'),
      ),
      body: Column(
        children: [
          _buildActionButtons(),
          const Divider(),
          Expanded(
            child: backupsAsync.when(
              data: (backups) {
                if (backups.isEmpty) {
                  return _buildEmptyState();
                }
                return _buildBackupList(backups);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(child: Text('加载失败')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isCreating ? null : _createBackup,
                  icon: _isCreating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.backup),
                  label: Text(_isCreating ? '创建中...' : '立即备份'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _importBackup,
                  icon: const Icon(Icons.file_download),
                  label: const Text('导入备份'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isRestoring ? null : _restoreFromFile,
                  icon: _isRestoring
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.restore),
                  label: Text(_isRestoring ? '恢复中...' : '从文件恢复'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.backup_outlined,
            size: 64,
            color: AppColors.textTertiary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无备份',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击"立即备份"创建您的第一个备份',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textTertiary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupList(List<BackupInfo> backups) {
    return ListView.builder(
      itemCount: backups.length,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemBuilder: (context, index) {
        final backup = backups[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: const Icon(Icons.backup, color: AppColors.primary),
            ),
            title: Text(backup.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  '${_formatDate(backup.createdAt)} · ${backup.recordCount} 条记录 · ${backup.formattedSize}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  backup.contentDescription,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) => _onMenuSelected(value, backup),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'restore',
                  child: Row(
                    children: [
                      Icon(Icons.restore, size: 20),
                      SizedBox(width: 8),
                      Text('恢复此备份'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(Icons.share, size: 20),
                      SizedBox(width: 8),
                      Text('分享备份'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline,
                          size: 20, color: AppColors.error),
                      SizedBox(width: 8),
                      Text('删除',
                          style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _createBackup() async {
    final result = await showDialog<({String? name, BackupOptions options})>(
      context: context,
      builder: (context) => const BackupOptionsDialog(),
    );
    if (result == null) return;

    setState(() => _isCreating = true);

    try {
      final backupResult = await BackupService.createBackup(
        name: result.name?.isEmpty == true ? null : result.name,
        options: result.options,
      );

      if (mounted) {
        if (backupResult.success && backupResult.backupInfo != null) {
          ref.invalidate(backupListProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '备份成功：${backupResult.backupInfo!.name} (${backupResult.backupInfo!.formattedSize})'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('备份失败：${backupResult.error}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  Future<void> _importBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final filePath = result.files.first.path;
      if (filePath == null) return;

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      final importResult = await BackupService.importBackup(filePath);

      if (mounted) {
        Navigator.pop(context);
        ref.invalidate(backupListProvider);

        if (importResult.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('导入成功：${importResult.restoredRecordCount} 条记录'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('导入失败：${importResult.error}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导入失败：$e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _restoreFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final filePath = result.files.first.path;
      if (filePath == null) return;

      final confirmed = await _showRestoreConfirmDialog();
      if (!confirmed) return;

      setState(() => _isRestoring = true);

      final restoreResult = await BackupService.importBackup(filePath);

      if (!restoreResult.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('恢复失败：${restoreResult.error}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        setState(() => _isRestoring = false);
        return;
      }

      final finalResult = await BackupService.restoreBackup(
        'imported_${restoreResult.restoredRecordCount}',
      );

      if (mounted) {
        if (finalResult.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('恢复成功：${finalResult.restoredRecordCount} 条记录'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('恢复失败：${finalResult.error}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('恢复失败：$e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRestoring = false);
      }
    }
  }

  Future<void> _onMenuSelected(String value, BackupInfo backup) async {
    switch (value) {
      case 'restore':
        await _restoreBackup(backup);
        break;
      case 'share':
        await _shareBackup(backup);
        break;
      case 'delete':
        await _deleteBackup(backup);
        break;
    }
  }

  Future<void> _restoreBackup(BackupInfo backup) async {
    final confirmed = await _showRestoreConfirmDialog();
    if (!confirmed) return;

    setState(() => _isRestoring = true);

    try {
      final result = await BackupService.restoreBackup(backup.id);

      if (mounted) {
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('恢复成功：${result.restoredRecordCount} 条记录'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('恢复失败：${result.error}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('恢复失败：$e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRestoring = false);
      }
    }
  }

  Future<bool> _showRestoreConfirmDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: AppColors.warning),
            SizedBox(width: 8),
            Text('确认恢复'),
          ],
        ),
        content: const Text(
          '恢复备份将覆盖当前所有数据（包括记录、设置等）。\n\n此操作不可撤销，是否继续？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('确认恢复'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _shareBackup(BackupInfo backup) async {
    final filePath = await BackupService.exportBackup(backup.id);
    if (filePath == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('备份文件不存在'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    await Share.shareXFiles(
      [XFile(filePath)],
      text: '畅记备份: ${backup.name}',
    );
  }

  Future<void> _deleteBackup(BackupInfo backup) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除备份'),
        content: Text('确定要删除备份 "${backup.name}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await BackupService.deleteBackup(backup.id);
    if (mounted) {
      ref.invalidate(backupListProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? '备份已删除' : '删除失败',
          ),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class BackupOptionsDialog extends StatefulWidget {
  const BackupOptionsDialog({super.key});

  @override
  State<BackupOptionsDialog> createState() => _BackupOptionsDialogState();
}

class _BackupOptionsDialogState extends State<BackupOptionsDialog> {
  final _nameController = TextEditingController();
  final Set<BackupContentType> _selectedTypes = {
    BackupContentType.records,
    BackupContentType.apiConfigs,
  };
  bool _includeMedia = true;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('创建备份'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '备份名称（可选）',
                hintText: '留空将使用默认名称',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            const Text(
              '选择备份内容',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildOptionTile(
              title: '记录数据',
              subtitle: '所有录音记录、文本、标签、周报、脑图等',
              icon: Icons.library_books,
              type: BackupContentType.records,
            ),
            if (_selectedTypes.contains(BackupContentType.records))
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 8),
                child: CheckboxListTile(
                  value: _includeMedia,
                  onChanged: (value) {
                    setState(() {
                      _includeMedia = value ?? true;
                    });
                  },
                  title: const Text('包含媒体文件'),
                  subtitle: const Text(
                    '音频、图片等附件（会显著增加备份大小）',
                    style: TextStyle(fontSize: 12),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                ),
              ),
            _buildOptionTile(
              title: 'AI 配置',
              subtitle: 'API密钥、AI角色、Prompt模板、分析模板、自动分析设置',
              icon: Icons.auto_fix_high,
              type: BackupContentType.apiConfigs,
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
          onPressed: _selectedTypes.isEmpty
              ? null
              : () {
                  Navigator.pop(context, (
                    name: _nameController.text.trim(),
                    options: BackupOptions(
                      selectedTypes: _selectedTypes,
                      includeMedia: _includeMedia,
                    ),
                  ));
                },
          child: const Text('创建'),
        ),
      ],
    );
  }

  Widget _buildOptionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required BackupContentType type,
  }) {
    final isSelected = _selectedTypes.contains(type);
    return CheckboxListTile(
      value: isSelected,
      onChanged: (value) {
        setState(() {
          if (value == true) {
            _selectedTypes.add(type);
          } else {
            _selectedTypes.remove(type);
          }
        });
      },
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: AppColors.textTertiary,
        ),
      ),
      secondary: Icon(icon, color: isSelected ? AppColors.primary : AppColors.textTertiary),
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
    );
  }
}
