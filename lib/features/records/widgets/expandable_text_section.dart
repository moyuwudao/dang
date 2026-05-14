import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/markdown_viewer.dart';
import '../../../core/widgets/expandable_text_field.dart';

class ExpandableTextSection extends StatefulWidget {
  final String title;
  final String? content;
  final IconData icon;
  final Color? iconColor;
  final bool initiallyExpanded;
  final bool editable;
  final ValueChanged<String>? onContentChanged;
  final int? maxLines;
  final bool directEdit;

  const ExpandableTextSection({
    super.key,
    required this.title,
    this.content,
    required this.icon,
    this.iconColor,
    this.initiallyExpanded = true,
    this.editable = false,
    this.onContentChanged,
    this.maxLines,
    this.directEdit = false,
  });

  @override
  State<ExpandableTextSection> createState() => _ExpandableTextSectionState();
}

class _ExpandableTextSectionState extends State<ExpandableTextSection> {
  late bool _isExpanded;
  late bool _isEditing;
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _isEditing = false;
    _textController = TextEditingController(text: widget.content ?? '');
  }

  @override
  void didUpdateWidget(covariant ExpandableTextSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content) {
      _textController.text = widget.content ?? '';
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _showFullScreen() {
    if (widget.content == null || widget.content!.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FullScreenTextView(
          title: widget.title,
          content: widget.content!,
          editable: widget.editable,
          onContentChanged: widget.onContentChanged,
        ),
      ),
    );
  }

  void _showDirectEditDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => FullScreenEditorScreen(
          controller: _textController,
          hintText: '输入内容...',
          title: '编辑${widget.title}',
        ),
      ),
    );
  }

  Widget _buildContentText(BuildContext context) {
    final text = widget.content!;
    if (widget.maxLines != null && !_isExpanded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: Theme.of(context).textTheme.bodyLarge,
            maxLines: widget.maxLines,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: () => setState(() => _isExpanded = true),
            icon: const Icon(Icons.expand_more, size: 16),
            label: const Text('展开查看更多'),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      );
    }
    return MarkdownViewer(content: text);
  }

  void _saveEdit() {
    if (widget.onContentChanged != null) {
      widget.onContentChanged!(_textController.text);
    }
    setState(() {
      _isEditing = false;
    });
  }

  void _cancelEdit() {
    _textController.text = widget.content ?? '';
    setState(() {
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasContent = widget.content != null && widget.content!.isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  widget.icon,
                  size: 20,
                  color: widget.iconColor ?? AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                if (hasContent && !_isEditing)
                  IconButton(
                    icon: const Icon(Icons.fullscreen, size: 20),
                    onPressed: _showFullScreen,
                    tooltip: '全屏查看',
                  ),
                if (widget.editable)
                  _isEditing
                      ? Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: _cancelEdit,
                              tooltip: '取消',
                            ),
                            IconButton(
                              icon: const Icon(Icons.check,
                                  size: 20, color: AppColors.success),
                              onPressed: _saveEdit,
                              tooltip: '保存',
                            ),
                          ],
                        )
                      : IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: () {
                            if (widget.directEdit) {
                              _showDirectEditDialog();
                            } else {
                              setState(() => _isEditing = true);
                            }
                          },
                          tooltip: '编辑',
                        ),
                IconButton(
                  icon: Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () => setState(() => _isExpanded = !_isExpanded),
                ),
              ],
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: hasContent || _isEditing
                  ? _isEditing
                      ? ExpandableTextField(
                          controller: _textController,
                          hintText: '输入内容...',
                          minLines: 5,
                          maxLines: 15,
                        )
                      : _buildContentText(context)
                  : const Text(
                      '暂无内容',
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
            ),
        ],
      ),
    );
  }
}

class _FullScreenTextView extends StatefulWidget {
  final String title;
  final String content;
  final bool editable;
  final ValueChanged<String>? onContentChanged;

  const _FullScreenTextView({
    required this.title,
    required this.content,
    this.editable = false,
    this.onContentChanged,
  });

  @override
  State<_FullScreenTextView> createState() => _FullScreenTextViewState();
}

class _FullScreenTextViewState extends State<_FullScreenTextView> {
  late bool _isEditing;
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _isEditing = false;
    _textController = TextEditingController(text: widget.content);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _saveEdit() {
    if (widget.onContentChanged != null) {
      widget.onContentChanged!(_textController.text);
    }
    setState(() {
      _isEditing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('保存成功'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _cancelEdit() {
    _textController.text = widget.content;
    setState(() {
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (widget.editable)
            _isEditing
                ? Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: _cancelEdit,
                      ),
                      IconButton(
                        icon: const Icon(Icons.check, color: AppColors.success),
                        onPressed: _saveEdit,
                      ),
                    ],
                  )
                : IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => setState(() => _isEditing = true),
                  ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {},
          ),
        ],
      ),
      body: _isEditing
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _textController,
                maxLines: null,
                expands: true,
                keyboardType: TextInputType.multiline,
                textAlignVertical: TextAlignVertical.top,
                autofocus: true,
                cursorColor: Theme.of(context).colorScheme.primary,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: '输入内容...',
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: 0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: MarkdownViewer(content: widget.content),
            ),
    );
  }
}
