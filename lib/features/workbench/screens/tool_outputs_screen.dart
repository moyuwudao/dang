import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/tag_selector.dart';
import '../../../data/models/tool_output_model.dart';
import '../../../data/repositories/record_repository.dart';
import '../../../data/repositories/tool_output_repository.dart';

class ToolOutputsScreen extends ConsumerStatefulWidget {
  const ToolOutputsScreen({super.key});

  @override
  ConsumerState<ToolOutputsScreen> createState() => _ToolOutputsScreenState();
}

class _ToolOutputsScreenState extends ConsumerState<ToolOutputsScreen> {
  List<ToolOutputModel> _outputs = [];
  List<ToolOutputModel> _filteredOutputs = [];
  bool _isLoading = true;
  String? _editingId;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final repository = ref.read(toolOutputRepositoryProvider);
      _outputs = await repository.getAllToolOutputs();
      _applyFilters();
    } catch (e) {
      _outputs = [];
      _filteredOutputs = [];
    }
    setState(() => _isLoading = false);
  }

  void _applyFilters() {
    var result = List<ToolOutputModel>.from(_outputs);

    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result.where((o) {
        return o.title.toLowerCase().contains(query) ||
            o.content.toLowerCase().contains(query);
      }).toList();
    }

    setState(() => _filteredOutputs = result);
  }

  Future<void> _deleteOutput(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('删除后无法恢复，是否继续？'),
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

    if (confirmed == true) {
      final repository = ref.read(toolOutputRepositoryProvider);
      await repository.deleteToolOutput(id);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已删除'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _updateOutput(String id, List<String> tags) async {
    final repository = ref.read(toolOutputRepositoryProvider);
    await repository.updateToolOutput(
      id: id,
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      tags: tags,
    );
    await _loadData();
    setState(() => _editingId = null);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已保存'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _toggleFavorite(String id, bool current) async {
    final repository = ref.read(toolOutputRepositoryProvider);
    await repository.updateFavorite(id, !current);
    await _loadData();
  }

  Future<void> _showTagSelector(String id, List<String> currentTags) async {
    final recordRepo = ref.read(recordRepositoryProvider);
    final allExistingTags = await recordRepo.getAllTags();
    final localAllTags = {...allExistingTags, ...currentTags}.toList();

    if (!mounted) return;

    final selectedTags = List<String>.from(currentTags);
    final tagController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              top: 16,
              left: 16,
              right: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '标签管理',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: tagController,
                        decoration: InputDecoration(
                          hintText: '输入新标签',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              final newTag = tagController.text.trim();
                              if (newTag.isNotEmpty &&
                                  !selectedTags.contains(newTag)) {
                                setModalState(() {
                                  selectedTags.add(newTag);
                                  if (!localAllTags.contains(newTag)) {
                                    localAllTags.add(newTag);
                                  }
                                });
                                tagController.clear();
                              }
                            },
                          ),
                        ),
                        onSubmitted: (value) {
                          final newTag = value.trim();
                          if (newTag.isNotEmpty &&
                              !selectedTags.contains(newTag)) {
                            setModalState(() {
                              selectedTags.add(newTag);
                              if (!localAllTags.contains(newTag)) {
                                localAllTags.add(newTag);
                              }
                            });
                            tagController.clear();
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (selectedTags.isNotEmpty) ...[
                  const Text(
                    '已选标签',
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: selectedTags.map((tag) {
                      return FilterChip(
                        label: Text(tag),
                        selected: true,
                        onSelected: (_) {
                          setModalState(() {
                            selectedTags.remove(tag);
                          });
                        },
                        selectedColor: AppColors.primary.withOpacity(0.15),
                        checkmarkColor: AppColors.primary,
                        backgroundColor: Colors.grey[100],
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                if (localAllTags.any((t) => !selectedTags.contains(t))) ...[
                  const Text(
                    '可选标签',
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: localAllTags
                        .where((t) => !selectedTags.contains(t))
                        .map((tag) {
                      return ActionChip(
                        label: Text(tag),
                        onPressed: () {
                          setModalState(() {
                            selectedTags.add(tag);
                          });
                        },
                        backgroundColor: Colors.grey[100],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final repository =
                          ref.read(toolOutputRepositoryProvider);
                      await repository.updateToolOutput(
                        id: id,
                        tags: selectedTags,
                      );
                      await _loadData();
                      if (mounted) Navigator.pop(context);
                    },
                    child: const Text('保存'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    tagController.dispose();
  }

  void _startEditing(ToolOutputModel output) {
    _titleController.text = output.title;
    _contentController.text = output.content;
    setState(() => _editingId = output.id);
  }

  void _showDetail(ToolOutputModel output) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              output.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.share_outlined),
                            onPressed: () {
                              Share.share(
                                '${output.title}\n\n${output.content}\n\n来自畅记 App',
                                subject: output.title,
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy_outlined),
                            onPressed: () async {
                              await Clipboard.setData(
                                ClipboardData(text: output.content),
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('已复制到剪贴板')),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${output.createdAt.year}/${output.createdAt.month.toString().padLeft(2, '0')}/${output.createdAt.day.toString().padLeft(2, '0')} ${output.createdAt.hour.toString().padLeft(2, '0')}:${output.createdAt.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (output.tags.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
                      spacing: 8,
                      children: output.tags.map((tag) {
                        return Chip(
                          label: Text(tag),
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          labelStyle: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                          ),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        );
                      }).toList(),
                    ),
                  ),
                const Divider(),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    child: SelectableText(
                      output.content,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.8,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: InputDecoration(
                  hintText: '搜索输出内容...',
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _applyFilters();
                    },
                  ),
                ),
                onChanged: (_) => _applyFilters(),
                autofocus: true,
              )
            : const Text('工具台输出'),
        centerTitle: !_isSearching,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _applyFilters();
                }
              });
            },
          ),
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadData,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredOutputs.isEmpty
              ? _buildEmptyView()
              : _buildListView(),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _outputs.isEmpty ? '暂无工具输出' : '没有符合条件的输出',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _outputs.isEmpty ? '使用工具后保存的内容会显示在这里' : '尝试调整搜索条件',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredOutputs.length,
      itemBuilder: (context, index) {
        final output = _filteredOutputs[index];
        final isEditing = _editingId == output.id;

        if (isEditing) {
          return _buildEditingCard(output);
        }

        return _buildOutputCard(output);
      },
    );
  }

  Widget _buildOutputCard(ToolOutputModel output) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetail(output),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.description_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      output.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (output.isFavorite)
                    const Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 18,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                output.content.length > 120
                    ? '${output.content.substring(0, 120)}...'
                    : output.content,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              if (output.tags.isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: output.tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildActionButton(
                    icon: output.isFavorite
                        ? Icons.star
                        : Icons.star_border,
                    color: output.isFavorite ? Colors.amber : Colors.grey,
                    onPressed: () => _toggleFavorite(output.id, output.isFavorite),
                    tooltip: output.isFavorite ? '取消收藏' : '收藏',
                  ),
                  _buildActionButton(
                    icon: Icons.edit_outlined,
                    onPressed: () => _startEditing(output),
                    tooltip: '编辑',
                  ),
                  _buildActionButton(
                    icon: Icons.label_outlined,
                    onPressed: () => _showTagSelector(output.id, output.tags),
                    tooltip: '标签',
                  ),
                  _buildActionButton(
                    icon: Icons.delete_outline,
                    color: AppColors.error,
                    onPressed: () => _deleteOutput(output.id),
                    tooltip: '删除',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    Color? color,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              size: 20,
              color: color ?? Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditingCard(ToolOutputModel output) {
    final List<String> editTags = List.from(output.tags);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '标题',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: '内容',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: null,
              minLines: 6,
              textAlignVertical: TextAlignVertical.top,
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '添加标签（可选）',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: SingleChildScrollView(
                child: TagSelector(
                  selectedTags: editTags,
                  onTagsChanged: (tags) {
                    setState(() {
                      editTags.clear();
                      editTags.addAll(tags);
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => setState(() => _editingId = null),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _updateOutput(output.id, editTags),
                  child: const Text('保存'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
