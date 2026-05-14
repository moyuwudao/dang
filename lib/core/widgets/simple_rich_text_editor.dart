import 'package:flutter/material.dart';
import 'rich_text_controller.dart';

class SimpleRichTextEditor extends StatefulWidget {
  final String initialText;
  final String? hintText;
  final String? labelText;
  final ValueChanged<String>? onChanged;

  const SimpleRichTextEditor({
    super.key,
    this.initialText = '',
    this.hintText,
    this.labelText,
    this.onChanged,
  });

  @override
  State<SimpleRichTextEditor> createState() => _SimpleRichTextEditorState();
}

class _SimpleRichTextEditorState extends State<SimpleRichTextEditor> {
  late RichTextController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = RichTextController();
    _controller.loadFromSerialized(widget.initialText);
    _controller.addListener(_onControllerChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  void _onControllerChanged() {
    widget.onChanged?.call(_controller.serialize());
    if (mounted) setState(() {});
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _toggleFormat(String format) {
    final sel = _controller.selection;
    if (sel.isCollapsed) {
      _controller.setTypingFormat(format);
    } else {
      _controller.toggleFormat(format, sel.start, sel.end);
    }
    _focusNode.requestFocus();
  }

  void _insertOrderedList() {
    final sel = _controller.selection;
    if (sel.isCollapsed) {
      _controller.setTypingFormat('ordered');
      _insertListPrefix('ordered');
    } else {
      _controller.toggleFormat('ordered', sel.start, sel.end);
    }
    _focusNode.requestFocus();
  }

  void _insertUnorderedList() {
    final sel = _controller.selection;
    if (sel.isCollapsed) {
      _controller.setTypingFormat('unordered');
      _insertListPrefix('unordered');
    } else {
      _controller.toggleFormat('unordered', sel.start, sel.end);
    }
    _focusNode.requestFocus();
  }

  void _insertListPrefix(String listType) {
    final text = _controller.text;
    final pos = _controller.selection.start;

    final lineStart = text.lastIndexOf('\n', pos == 0 ? 0 : pos - 1) + 1;
    final lineEnd = text.indexOf('\n', pos);
    final currentLine = text.substring(lineStart, lineEnd == -1 ? text.length : lineEnd);

    String insertText;

    if (listType == 'ordered') {
      final listPattern = RegExp(r'^(\d+)\.\s');
      final match = listPattern.firstMatch(currentLine);
      if (match != null) {
        final currentNum = int.parse(match.group(1)!);
        final nextNum = currentNum + 1;
        if (pos > 0 && text[pos - 1] != '\n') {
          insertText = '\n$nextNum. ';
        } else {
          insertText = '$nextNum. ';
        }
      } else {
        if (pos > 0 && text[pos - 1] != '\n') {
          insertText = '\n1. ';
        } else {
          insertText = '1. ';
        }
      }
    } else {
      if (pos > 0 && text[pos - 1] != '\n') {
        insertText = '\n• ';
      } else {
        insertText = '• ';
      }
    }

    final newPos = pos + insertText.length;
    final newText = text.substring(0, pos) + insertText + text.substring(pos);
    _controller.text = newText;
    _controller.selection = TextSelection.collapsed(offset: newPos);
  }

  Set<String> _currentFormats() {
    final sel = _controller.selection;
    if (sel.isCollapsed) {
      return _controller.typingFormat;
    }
    return _controller.getFormatsAt(sel.start);
  }

  double _getCursorHeight() {
    final formats = _controller.typingFormat;
    if (formats.contains('h1')) return 34;
    if (formats.contains('h2')) return 28;
    if (formats.contains('code')) return 20;
    return 22;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Column(
      children: [
        _buildToolbar(theme, primaryColor),
        const Divider(height: 1),
        Expanded(
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            maxLines: null,
            expands: true,
            keyboardType: TextInputType.multiline,
            textAlignVertical: TextAlignVertical.top,
            autofocus: true,
            cursorColor: primaryColor,
            cursorHeight: _getCursorHeight(),
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 16,
              height: 1.6,
            ),
            decoration: InputDecoration(
              hintText: widget.hintText ?? '输入内容...',
              hintStyle: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                fontSize: 16,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar(ThemeData theme, Color primaryColor) {
    final formats = _currentFormats();
    final surfaceColor = theme.colorScheme.surface;

    return Container(
      width: double.infinity,
      color: surfaceColor,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _ToolbarButton(
              label: 'B',
              tooltip: '加粗',
              isActive: formats.contains('bold'),
              labelStyle: const TextStyle(fontWeight: FontWeight.w900),
              onPressed: () => _toggleFormat('bold'),
            ),
            const SizedBox(width: 4),
            _ToolbarButton(
              label: 'I',
              tooltip: '斜体',
              isActive: formats.contains('italic'),
              labelStyle: const TextStyle(fontStyle: FontStyle.italic),
              onPressed: () => _toggleFormat('italic'),
            ),
            const SizedBox(width: 4),
            _ToolbarButton(
              label: 'U',
              tooltip: '下划线',
              isActive: formats.contains('underline'),
              labelStyle: const TextStyle(decoration: TextDecoration.underline),
              onPressed: () => _toggleFormat('underline'),
            ),
            const SizedBox(width: 4),
            _ToolbarButton(
              label: 'S',
              tooltip: '删除线',
              isActive: formats.contains('strikethrough'),
              labelStyle:
                  const TextStyle(decoration: TextDecoration.lineThrough),
              onPressed: () => _toggleFormat('strikethrough'),
            ),
            _buildDivider(theme),
            _ToolbarButton(
              label: 'H1',
              tooltip: '大标题',
              isActive: formats.contains('h1'),
              labelStyle:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              onPressed: () => _toggleFormat('h1'),
            ),
            const SizedBox(width: 4),
            _ToolbarButton(
              label: 'H2',
              tooltip: '小标题',
              isActive: formats.contains('h2'),
              labelStyle:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              onPressed: () => _toggleFormat('h2'),
            ),
            _buildDivider(theme),
            _ToolbarButton(
              icon: Icons.format_list_numbered,
              tooltip: '有序列表',
              isActive: formats.contains('ordered'),
              onPressed: _insertOrderedList,
            ),
            const SizedBox(width: 4),
            _ToolbarButton(
              icon: Icons.format_list_bulleted,
              tooltip: '无序列表',
              isActive: formats.contains('unordered'),
              onPressed: _insertUnorderedList,
            ),
            _buildDivider(theme),
            _ToolbarButton(
              icon: Icons.code,
              tooltip: '行内代码',
              isActive: formats.contains('code'),
              onPressed: () => _toggleFormat('code'),
            ),
            _buildDivider(theme),
            _ToolbarButton(
              icon: Icons.emoji_emotions_outlined,
              tooltip: '表情符号',
              isActive: false,
              onPressed: _openEmojiKeyboard,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        width: 1,
        height: 20,
        color: theme.colorScheme.outline.withValues(alpha: 0.2),
      ),
    );
  }

  void _openEmojiKeyboard() {
    _focusNode.requestFocus();
  }
}

class _ToolbarButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final String tooltip;
  final bool isActive;
  final TextStyle? labelStyle;
  final VoidCallback onPressed;

  const _ToolbarButton({
    this.label,
    this.icon,
    required this.tooltip,
    required this.isActive,
    this.labelStyle,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    final bgColor = isActive ? primaryColor : Colors.transparent;
    final fgColor = isActive
        ? Colors.white
        : theme.colorScheme.onSurface.withValues(alpha: 0.7);

    return Tooltip(
      message: tooltip,
      preferBelow: false,
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: 34,
            height: 32,
            alignment: Alignment.center,
            child: label != null
                ? Text(
                    label!,
                    style: TextStyle(
                      color: fgColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ).merge(labelStyle),
                  )
                : Icon(icon, size: 17, color: fgColor),
          ),
        ),
      ),
    );
  }
}
