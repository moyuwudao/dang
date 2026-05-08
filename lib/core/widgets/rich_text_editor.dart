import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class RichTextEditor extends StatefulWidget {
  final TextEditingController controller;
  final String? hintText;
  final int? minLines;
  final int? maxLines;
  final bool expands;

  const RichTextEditor({
    super.key,
    required this.controller,
    this.hintText,
    this.minLines,
    this.maxLines,
    this.expands = false,
  });

  @override
  State<RichTextEditor> createState() => _RichTextEditorState();
}

class _RichTextEditorState extends State<RichTextEditor> {
  bool _showToolbar = false;

  void _insertText(String before, {String? after}) {
    final text = widget.controller.text;
    final selection = widget.controller.selection;
    final selectedText = selection.isCollapsed
        ? ''
        : text.substring(selection.start, selection.end);

    final newText = text.substring(0, selection.start) +
        before +
        (selectedText.isEmpty ? '' : selectedText) +
        (after ?? before) +
        text.substring(selection.end);

    widget.controller.text = newText;
    widget.controller.selection = TextSelection.collapsed(
      offset: selection.start +
          before.length +
          (selectedText.isEmpty ? 0 : selectedText.length) +
          (after ?? before).length,
    );
  }

  void _insertLinePrefix(String prefix) {
    final text = widget.controller.text;
    final selection = widget.controller.selection;
    final beforeCursor = text.substring(0, selection.start);
    final afterCursor = text.substring(selection.start);

    // Find the start of current line
    final lineStart = beforeCursor.lastIndexOf('\n') + 1;
    final currentLine = beforeCursor.substring(lineStart);

    String newLine;
    if (currentLine.startsWith(prefix)) {
      newLine = currentLine.substring(prefix.length);
    } else {
      newLine = prefix + currentLine;
    }

    final newText = beforeCursor.substring(0, lineStart) +
        newLine +
        afterCursor;

    widget.controller.text = newText;
    widget.controller.selection = TextSelection.collapsed(
      offset: lineStart + newLine.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Expand/Collapse toolbar button
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => setState(() => _showToolbar = !_showToolbar),
            icon: Icon(
              _showToolbar ? Icons.expand_less : Icons.format_color_text,
              size: 16,
            ),
            label: Text(_showToolbar ? '收起工具栏' : '展开工具栏'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
        // Toolbar
        if (_showToolbar)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _ToolbarButton(
                    icon: Icons.format_bold,
                    tooltip: '粗体',
                    onPressed: () => _insertText('**'),
                  ),
                  _ToolbarButton(
                    icon: Icons.format_italic,
                    tooltip: '斜体',
                    onPressed: () => _insertText('*'),
                  ),
                  _ToolbarButton(
                    icon: Icons.format_strikethrough,
                    tooltip: '删除线',
                    onPressed: () => _insertText('~~'),
                  ),
                  _ToolbarButton(
                    icon: Icons.format_underlined,
                    tooltip: '下划线',
                    onPressed: () => _insertText('<u>', after: '</u>'),
                  ),
                  const VerticalDivider(width: 16),
                  _ToolbarButton(
                    icon: Icons.format_list_bulleted,
                    tooltip: '无序列表',
                    onPressed: () => _insertLinePrefix('- '),
                  ),
                  _ToolbarButton(
                    icon: Icons.format_list_numbered,
                    tooltip: '有序列表',
                    onPressed: () => _insertLinePrefix('1. '),
                  ),
                  const VerticalDivider(width: 16),
                  _ToolbarButton(
                    icon: Icons.format_quote,
                    tooltip: '引用',
                    onPressed: () => _insertLinePrefix('> '),
                  ),
                  _ToolbarButton(
                    icon: Icons.code,
                    tooltip: '代码块',
                    onPressed: () => _insertText('```\n', after: '\n```'),
                  ),
                  _ToolbarButton(
                    icon: Icons.link,
                    tooltip: '链接',
                    onPressed: () => _insertText('[', after: '](url)'),
                  ),
                  const VerticalDivider(width: 16),
                  _ToolbarButton(
                    icon: Icons.title,
                    tooltip: '标题',
                    onPressed: () => _insertLinePrefix('## '),
                  ),
                  _ToolbarButton(
                    icon: Icons.text_fields,
                    tooltip: '正文',
                    onPressed: () {
                      final text = widget.controller.text;
                      final selection = widget.controller.selection;
                      final beforeCursor = text.substring(0, selection.start);
                      final lineStart = beforeCursor.lastIndexOf('\n') + 1;
                      final currentLine = beforeCursor.substring(lineStart);
                      if (currentLine.startsWith('#')) {
                        final newLine = currentLine.replaceFirst(RegExp(r'^#+\s*'), '');
                        final newText = beforeCursor.substring(0, lineStart) +
                            newLine +
                            text.substring(selection.start);
                        widget.controller.text = newText;
                        widget.controller.selection = TextSelection.collapsed(
                          offset: lineStart + newLine.length,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        // Text field
        TextField(
          controller: widget.controller,
          maxLines: widget.maxLines,
          minLines: widget.minLines,
          expands: widget.expands,
          keyboardType: TextInputType.multiline,
          decoration: InputDecoration(
            hintText: widget.hintText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.vertical(
                top: _showToolbar ? Radius.zero : const Radius.circular(8),
                bottom: const Radius.circular(8),
              ),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 18, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
