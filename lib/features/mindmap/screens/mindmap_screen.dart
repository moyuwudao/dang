import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/transcription_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/record_model.dart';
import '../../../data/repositories/record_repository.dart';
import '../models/mindmap_plan.dart';
import '../services/mindmap_service.dart';
import '../services/mindmap_ai_service.dart';

final mindMapAiServiceProvider = Provider<MindMapAiService>((ref) {
  return MindMapAiService(
    ref.watch(transcriptionServiceProvider),
    ref.watch(recordRepositoryProvider),
  );
});

class MindMapScreen extends ConsumerStatefulWidget {
  const MindMapScreen({super.key});

  @override
  ConsumerState<MindMapScreen> createState() => _MindMapScreenState();
}

class _MindMapScreenState extends ConsumerState<MindMapScreen> {
  bool _isLoading = true;
  bool _isAiGenerating = false;
  List<MindMapNode> _nodes = [];
  MindMapViewType _viewType = MindMapViewType.byTag;
  final Map<String, bool> _expandedTags = {};
  List<SavedMindMap> _savedMindMaps = [];
  bool _isLoadingSaved = true;

  @override
  void initState() {
    super.initState();
    _loadMindMap();
    _loadSavedMindMaps();
  }

  Future<void> _loadSavedMindMaps() async {
    final mindMaps = await StorageService.getSavedMindMaps();
    if (mounted) {
      setState(() {
        _savedMindMaps = mindMaps;
        _isLoadingSaved = false;
      });
    }
  }

  Future<void> _loadMindMap() async {
    setState(() {
      _isLoading = true;
    });

    final service = ref.read(mindMapServiceProvider);
    _nodes = _viewType == MindMapViewType.byTag
        ? await service.generateMindMapByTag()
        : _viewType == MindMapViewType.byDate
            ? await service.generateMindMapByDate()
            : _viewType == MindMapViewType.outline
                ? await service.generateMindMapByTag()
                : [];

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _generateAiMindMap() async {
    // 获取所有标签供用户选择
    final allRecords = await ref.read(recordRepositoryProvider).getAllRecords();
    final allTags = <String>{};
    for (final record in allRecords) {
      allTags.addAll(record.tags);
    }

    List<String>? selectedTags;
    if (allTags.isNotEmpty && mounted) {
      final tagSelections = Map<String, bool>.fromEntries(
        allTags.map((tag) => MapEntry(tag, true)),
      );

      final result = await showDialog<List<String>>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) {
            final selectedCount = tagSelections.values.where((v) => v).length;
            return AlertDialog(
              title: const Text('选择标签'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('已选择 $selectedCount 个标签'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: tagSelections.keys.map((tag) {
                        final isSelected = tagSelections[tag] ?? false;
                        return FilterChip(
                          label: Text(
                            tag,
                            style: const TextStyle(fontSize: 12),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setDialogState(() {
                              tagSelections[tag] = selected;
                            });
                          },
                          selectedColor:
                              AppColors.primary.withValues(alpha: 0.2),
                          checkmarkColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          visualDensity: VisualDensity.compact,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        setDialogState(() {
                          for (final key in tagSelections.keys) {
                            tagSelections[key] = false;
                          }
                        });
                      },
                      child: const Text('清空'),
                    ),
                    TextButton(
                      onPressed: () {
                        setDialogState(() {
                          for (final key in tagSelections.keys) {
                            tagSelections[key] = true;
                          }
                        });
                      },
                      child: const Text('全选'),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.pop(context, null),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () {
                        final selected = tagSelections.entries
                            .where((e) => e.value)
                            .map((e) => e.key)
                            .toList();
                        Navigator.pop(context, selected);
                      },
                      child: const Text('确认'),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );

      if (result == null) return;
      selectedTags = result;
    }

    setState(() {
      _isAiGenerating = true;
    });

    try {
      final aiService = ref.read(mindMapAiServiceProvider);
      final nodes =
          await aiService.generateAiMindMap(selectedTags: selectedTags);

      if (mounted) {
        if (nodes.isNotEmpty) {
          setState(() {
            _viewType = MindMapViewType.aiGenerated;
            _nodes = nodes;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('AI脑图生成成功'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('AI脑图生成失败，请检查API配置'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI脑图生成失败: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAiGenerating = false;
        });
      }
    }
  }

  void _toggleExpand(String tag) {
    setState(() {
      _expandedTags[tag] = !(_expandedTags[tag] ?? false);
    });
  }

  void _navigateToRecord(int recordId) {
    if (recordId > 0) {
      context.push('/record/$recordId');
    }
  }

  void _showSaveOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.save, color: AppColors.primary),
              title: const Text('保存临时方案'),
              subtitle: const Text('将当前脑图保存为临时方案'),
              onTap: () {
                Navigator.pop(context);
                _showSavePlanDialog();
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.folder_copy, color: AppColors.secondary),
              title: const Text('按标签归档'),
              subtitle: const Text('将脑图内容按标签归档到记录'),
              onTap: () {
                Navigator.pop(context);
                _showArchiveByTagDialog();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showSavePlanDialog() {
    final nameController = TextEditingController();
    final contentController = TextEditingController(
      text: _buildMindMapContent(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('保存临时方案'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '方案名称',
                  hintText: '输入方案名称',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(
                  labelText: '方案内容',
                  hintText: '输入方案内容',
                ),
                maxLines: 5,
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
            onPressed: () {
              final name = nameController.text.trim();
              final content = contentController.text.trim();
              if (name.isNotEmpty && content.isNotEmpty) {
                _savePlan(name, content);
                Navigator.pop(context);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  String _buildMindMapContent() {
    final buffer = StringBuffer();
    for (final node in _nodes) {
      buffer.writeln('## ${node.label}');
      for (final child in node.children) {
        buffer.writeln('- ${child.label}');
        if (child.content != null && child.content!.isNotEmpty) {
          buffer.writeln('  ${child.content}');
        }
      }
      buffer.writeln();
    }
    return buffer.toString().trim();
  }

  void _showArchiveByTagDialog() {
    final tagSelections = <String, bool>{};
    for (final node in _nodes) {
      tagSelections[node.label] = true;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('按标签归档'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('选择要归档的标签：'),
                const SizedBox(height: 12),
                ...tagSelections.keys.map((tag) {
                  return CheckboxListTile(
                    title: Text(tag),
                    value: tagSelections[tag],
                    onChanged: (value) {
                      setDialogState(() {
                        tagSelections[tag] = value ?? false;
                      });
                    },
                    dense: true,
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                final selectedTags = tagSelections.entries
                    .where((e) => e.value)
                    .map((e) => e.key)
                    .toList();
                if (selectedTags.isNotEmpty) {
                  _archiveByTags(selectedTags);
                  Navigator.pop(context);
                }
              },
              child: const Text('归档'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _archiveByTags(List<String> selectedTags) async {
    try {
      final repository = ref.read(recordRepositoryProvider);
      int archivedCount = 0;

      for (final node in _nodes) {
        if (!selectedTags.contains(node.label)) continue;

        for (final child in node.children) {
          if (child.recordId > 0) {
            final record = await repository.getRecordById(child.recordId);
            if (record != null) {
              final newTags = [...record.tags];
              if (!newTags.contains(node.label)) {
                newTags.add(node.label);
              }
              await repository.updateTags(child.recordId, newTags);
              archivedCount++;
            }
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已归档 $archivedCount 条记录'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('归档失败: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('知识脑图'),
        actions: [
          if (_nodes.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.save_outlined),
              tooltip: '保存方案/归档',
              onPressed: _showSaveOptions,
            ),
          if (_isAiGenerating)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.auto_awesome),
              tooltip: 'AI生成关联脑图',
              onPressed: _generateAiMindMap,
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: DropdownButton<MindMapViewType>(
              value: _viewType == MindMapViewType.aiGenerated
                  ? MindMapViewType.byTag
                  : _viewType,
              dropdownColor: Theme.of(context).colorScheme.surface,
              underline: const SizedBox(),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              style: const TextStyle(color: Colors.white),
              items: const [
                DropdownMenuItem(
                  value: MindMapViewType.byTag,
                  child: Text('按标签'),
                ),
                DropdownMenuItem(
                  value: MindMapViewType.byDate,
                  child: Text('按日期'),
                ),
                DropdownMenuItem(
                  value: MindMapViewType.outline,
                  child: Text('大纲视图'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _viewType = value;
                  });
                  _loadMindMap();
                }
              },
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _nodes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.map_outlined,
                        size: 64,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '暂无数据，请先添加带有标签的记录',
                        style: TextStyle(color: AppColors.textTertiary),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _isAiGenerating ? null : _generateAiMindMap,
                        icon: _isAiGenerating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.auto_awesome),
                        label: const Text('AI生成关联脑图'),
                      ),
                    ],
                  ),
                )
              : _viewType == MindMapViewType.outline
                  ? _buildOutlineView()
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (_viewType == MindMapViewType.aiGenerated)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                const Chip(
                                  avatar: Icon(Icons.auto_awesome,
                                      size: 16, color: Colors.white),
                                  label: Text('AI智能生成'),
                                  backgroundColor: AppColors.secondary,
                                  labelStyle: TextStyle(color: Colors.white),
                                ),
                                const Spacer(),
                                TextButton.icon(
                                  onPressed: _showSaveOptions,
                                  icon: const Icon(Icons.save, size: 16),
                                  label: const Text('保存'),
                                ),
                              ],
                            ),
                          ),
                        ..._nodes.map((node) => _buildTagNode(node)),
                        const SizedBox(height: 24),
                        _buildSavedMindMapsSection(),
                      ],
                    ),
    );
  }

  Widget _buildTagNode(MindMapNode node) {
    final isExpanded = _expandedTags[node.id] ?? true;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Column(
        children: [
          InkWell(
            onTap: () => _toggleExpand(node.id),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: node.color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      node.label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  Text(
                    '${node.children.length} 条',
                    style: const TextStyle(color: AppColors.textTertiary),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Divider(
              color: node.color.withOpacity(0.3),
              height: 1,
            ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: node.children
                    .map((child) => _buildRecordChip(child))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecordChip(MindMapNode node) {
    final isClickable = node.recordId > 0;

    return InkWell(
      onTap: isClickable ? () => _navigateToRecord(node.recordId) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: node.color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              node.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (isClickable) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: Colors.white70,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOutlineView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _nodes.length,
      itemBuilder: (context, index) {
        final node = _nodes[index];
        return _buildOutlineNode(node, 0);
      },
    );
  }

  Widget _buildOutlineNode(MindMapNode node, int depth) {
    final indent = depth * 24.0;
    final hasChildren = node.children.isNotEmpty;
    final isExpanded = _expandedTags[node.label] ?? true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: hasChildren
              ? () => setState(() => _expandedTags[node.label] = !isExpanded)
              : () => _navigateToRecordFromOutline(node),
          child: Padding(
            padding: EdgeInsets.only(left: indent),
            child: Row(
              children: [
                if (hasChildren)
                  Icon(
                    isExpanded ? Icons.expand_more : Icons.chevron_right,
                    size: 20,
                    color: AppColors.textTertiary,
                  )
                else
                  const SizedBox(width: 20),
                const SizedBox(width: 4),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color:
                        depth == 0 ? AppColors.primary : AppColors.textTertiary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        node.label,
                        style: TextStyle(
                          fontWeight:
                              depth == 0 ? FontWeight.w600 : FontWeight.normal,
                          fontSize: depth == 0 ? 16 : 14,
                        ),
                      ),
                      if (node.content != null && node.content!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          node.content!.length > 80
                              ? '${node.content!.substring(0, 80)}...'
                              : node.content!,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right,
                    size: 16, color: AppColors.textTertiary),
              ],
            ),
          ),
        ),
        if (hasChildren && isExpanded)
          ...node.children.map((child) => _buildOutlineNode(child, depth + 1)),
        if (depth == 0) const Divider(height: 24),
      ],
    );
  }

  void _navigateToRecordFromOutline(MindMapNode node) {
    context.push('/record/${node.recordId}');
  }

  // ========== 已保存脑图 ==========
  Widget _buildSavedMindMapsSection() {
    if (_isLoadingSaved) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.folder_open, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            const Text('已保存的脑图',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const Spacer(),
            Text('${_savedMindMaps.length} 份',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 8),
        if (_savedMindMaps.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('暂无保存的脑图',
                style: TextStyle(color: AppColors.textSecondary)),
          )
        else
          ..._savedMindMaps.map((mindMap) => _buildSavedMindMapCard(mindMap)),
      ],
    );
  }

  Widget _buildSavedMindMapCard(SavedMindMap mindMap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _showSavedMindMapDetail(mindMap),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.map, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mindMap.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${mindMap.createdAt.month}/${mindMap.createdAt.day} ${mindMap.createdAt.hour}:${mindMap.createdAt.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: AppColors.error),
                onPressed: () => _deleteSavedMindMap(mindMap.id),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSavedMindMapDetail(SavedMindMap mindMap) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(mindMap.name),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(
              mindMap.content,
              style: const TextStyle(fontSize: 14, height: 1.8),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: mindMap.content));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('已复制到剪贴板'),
                      backgroundColor: AppColors.success),
                );
              }
            },
            child: const Text('复制'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSavedMindMap(String id) async {
    await StorageService.deleteSavedMindMap(id);
    await _loadSavedMindMaps();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('已删除'), backgroundColor: AppColors.success),
      );
    }
  }

  // 修改保存方案逻辑，同时保存到StorageService
  Future<void> _savePlan(String name, String content) async {
    try {
      final plan = MindMapPlan(
        id: const Uuid().v4(),
        name: name,
        content: content,
        createdAt: DateTime.now(),
      );

      final prefs = await SharedPreferences.getInstance();
      final plansJson = prefs.getStringList('mindmap_plans') ?? [];
      plansJson.add(jsonEncode(plan.toJson()));
      await prefs.setStringList('mindmap_plans', plansJson);

      // 同时保存到新的存储
      final savedMindMap = SavedMindMap(
        id: plan.id,
        name: name,
        content: content,
        createdAt: DateTime.now(),
      );
      await StorageService.saveMindMap(savedMindMap);
      await _loadSavedMindMaps();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('方案已保存'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

enum MindMapViewType {
  byTag,
  byDate,
  aiGenerated,
  outline,
}
