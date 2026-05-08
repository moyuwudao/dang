import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class AiAnalysisCard extends StatefulWidget {
  final String roleName;
  final String content;
  final String roleId;
  final VoidCallback onDelete;

  const AiAnalysisCard({
    super.key,
    required this.roleName,
    required this.content,
    required this.roleId,
    required this.onDelete,
  });

  @override
  State<AiAnalysisCard> createState() => _AiAnalysisCardState();
}

class _AiAnalysisCardState extends State<AiAnalysisCard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = false;
  }

  String get _previewContent {
    final lines = widget.content.split('\n');
    if (lines.length <= 3) {
      return widget.content;
    }
    return lines.take(3).join('\n') + '\n...';
  }

  void _showFullScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FullScreenAnalysisView(
          roleName: widget.roleName,
          content: widget.content,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                const Icon(Icons.psychology, size: 18, color: AppColors.secondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.roleName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.fullscreen, size: 18),
                  onPressed: _showFullScreen,
                  tooltip: '全屏查看',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                  onPressed: widget.onDelete,
                  tooltip: '删除',
                ),
                IconButton(
                  icon: Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () => setState(() => _isExpanded = !_isExpanded),
                  tooltip: _isExpanded ? '收起' : '展开',
                ),
              ],
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 400),
                child: Scrollbar(
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SelectableText(
                      widget.content,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
                    ),
                  ),
                ),
              ),
            ),
          if (!_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                _previewContent,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}

class _FullScreenAnalysisView extends StatelessWidget {
  final String roleName;
  final String content;

  const _FullScreenAnalysisView({
    required this.roleName,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(roleName),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {},
          ),
        ],
      ),
      body: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SelectableText(
            content,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.8),
          ),
        ),
      ),
    );
  }
}
