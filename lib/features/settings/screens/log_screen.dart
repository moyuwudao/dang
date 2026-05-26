import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/app_logger.dart';
import '../../../core/theme/app_colors.dart';

class LogScreen extends StatefulWidget {
  const LogScreen({super.key});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  final AppLogger _logger = AppLogger();
  final TextEditingController _searchController = TextEditingController();
  LogLevel _filterLevel = LogLevel.debug;
  String _searchKeyword = '';
  String? _filterTag;
  bool _showTagFilter = false;

  @override
  void initState() {
    super.initState();
    _logger.addListener(_onNewLog);
  }

  @override
  void dispose() {
    _logger.removeListener(_onNewLog);
    _searchController.dispose();
    super.dispose();
  }

  void _onNewLog(LogEntry entry) {
    if (mounted) {
      setState(() {});
    }
  }

  Set<String> get _availableTags {
    return _logger.entries.map((e) => e.tag).toSet();
  }

  List<LogEntry> get _filteredEntries {
    var entries = _logger.entries;

    // 按级别筛选
    if (_filterLevel != LogLevel.debug) {
      entries = entries.where((e) => e.level.index >= _filterLevel.index).toList();
    }

    // 按标签筛选
    if (_filterTag != null && _filterTag!.isNotEmpty) {
      entries = entries.where((e) => e.tag == _filterTag).toList();
    }

    // 按关键词搜索
    if (_searchKeyword.isNotEmpty) {
      final lower = _searchKeyword.toLowerCase();
      entries = entries.where((e) =>
        e.message.toLowerCase().contains(lower) ||
        e.tag.toLowerCase().contains(lower)
      ).toList();
    }

    return entries.reversed.toList();
  }

  Color _getLevelColor(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Colors.grey;
      case LogLevel.info:
        return Colors.blue;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = _filteredEntries;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text('运行日志', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy, color: Colors.white),
            tooltip: '复制筛选后的日志',
            onPressed: () {
              final text = entries.map((e) => e.displayText).join('\n');
              Clipboard.setData(ClipboardData(text: text));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('筛选后的日志已复制到剪贴板')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.copy_all, color: Colors.white),
            tooltip: '复制全部日志',
            onPressed: () {
              final text = _logger.exportAll();
              Clipboard.setData(ClipboardData(text: text));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('全部日志已复制到剪贴板')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            tooltip: '清空日志',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('确认清空'),
                  content: const Text('确定要清空所有日志吗？'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () {
                        _logger.clear();
                        setState(() {});
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(foregroundColor: AppColors.error),
                      child: const Text('清空'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(140),
          child: Column(
            children: [
              // 搜索框
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: '搜索日志...',
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchKeyword.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchKeyword = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFF3D3D3D),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (value) => setState(() => _searchKeyword = value),
                ),
              ),
              // 标签筛选
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() => _showTagFilter = !_showTagFilter);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3D3D3D),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.label, color: Colors.grey, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                _filterTag != null
                                    ? '标签: $_filterTag'
                                    : '选择标签筛选',
                                style: TextStyle(
                                  color: _filterTag != null
                                      ? Colors.cyan
                                      : Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                _showTagFilter
                                    ? Icons.arrow_drop_up
                                    : Icons.arrow_drop_down,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // 标签列表（展开时显示）
              if (_showTagFilter && _availableTags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ActionChip(
                          label: const Text('全部标签'),
                          onPressed: () {
                            setState(() {
                              _filterTag = null;
                              _showTagFilter = false;
                            });
                          },
                          backgroundColor: _filterTag == null
                              ? AppColors.primary.withOpacity(0.3)
                              : const Color(0xFF3D3D3D),
                          labelStyle: TextStyle(
                            color: _filterTag == null
                                ? AppColors.primary
                                : Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ..._availableTags.map((tag) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ActionChip(
                                label: Text(tag),
                                onPressed: () {
                                  setState(() {
                                    _filterTag = tag;
                                    _showTagFilter = false;
                                  });
                                },
                                backgroundColor: _filterTag == tag
                                    ? Colors.cyan.withOpacity(0.3)
                                    : const Color(0xFF3D3D3D),
                                labelStyle: TextStyle(
                                  color: _filterTag == tag
                                      ? Colors.cyan
                                      : Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            )),
                      ],
                    ),
                  ),
                ),
              // 级别筛选
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    _buildFilterChip('全部', LogLevel.debug),
                    const SizedBox(width: 8),
                    _buildFilterChip('信息', LogLevel.info),
                    const SizedBox(width: 8),
                    _buildFilterChip('警告', LogLevel.warning),
                    const SizedBox(width: 8),
                    _buildFilterChip('错误', LogLevel.error),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: entries.isEmpty
          ? const Center(
              child: Text(
                '暂无日志',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                return _buildLogItem(entry);
              },
            ),
      bottomNavigationBar: Container(
        color: const Color(0xFF2D2D2D),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SafeArea(
          child: Row(
            children: [
              Text(
                '显示 ${entries.length} 条',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const Spacer(),
              Text(
                '总计 ${_logger.entries.length} 条',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, LogLevel level) {
    final isSelected = _filterLevel == level;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _filterLevel = level);
        }
      },
      backgroundColor: const Color(0xFF3D3D3D),
      selectedColor: _getLevelColor(level).withValues(alpha: 0.3),
      labelStyle: TextStyle(
        color: isSelected ? _getLevelColor(level) : Colors.grey,
        fontSize: 12,
      ),
      side: BorderSide(
        color: isSelected ? _getLevelColor(level) : Colors.transparent,
      ),
    );
  }

  Widget _buildLogItem(LogEntry entry) {
    return InkWell(
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: entry.displayText));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已复制单条日志')),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
          ),
        ),
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '${entry.formattedTime} ',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
              TextSpan(
                text: '[${entry.levelString}] ',
                style: TextStyle(
                  color: _getLevelColor(entry.level),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
              TextSpan(
                text: '[${entry.tag}] ',
                style: const TextStyle(
                  color: Colors.cyan,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
              TextSpan(
                text: entry.message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
