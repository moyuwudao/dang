import 'package:flutter/material.dart';
import 'simple_rich_text_editor.dart';

class ExpandableTextField extends StatefulWidget {
  final TextEditingController controller;
  final String? hintText;
  final String? labelText;
  final int minLines;
  final int maxLines;
  final bool showExpandButton;
  final String expandTooltip;

  const ExpandableTextField({
    super.key,
    required this.controller,
    this.hintText,
    this.labelText,
    this.minLines = 3,
    this.maxLines = 6,
    this.showExpandButton = true,
    this.expandTooltip = '使用富文本编辑器',
  });

  @override
  State<ExpandableTextField> createState() => _ExpandableTextFieldState();
}

class _ExpandableTextFieldState extends State<ExpandableTextField> {
  void _openFullScreenEditor() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => FullScreenEditorScreen(
          controller: widget.controller,
          hintText: widget.hintText,
          title: widget.labelText ?? '编辑内容',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showExpandButton)
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: _openFullScreenEditor,
              icon: const Icon(Icons.open_in_full, size: 18),
              tooltip: widget.expandTooltip,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ),
        TextField(
          controller: widget.controller,
          minLines: widget.minLines,
          maxLines: widget.maxLines,
          keyboardType: TextInputType.multiline,
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
            alignLabelWithHint: true,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }
}

class FullScreenEditorScreen extends StatefulWidget {
  final TextEditingController controller;
  final String? hintText;
  final String title;

  const FullScreenEditorScreen({
    super.key,
    required this.controller,
    this.hintText,
    required this.title,
  });

  @override
  State<FullScreenEditorScreen> createState() => _FullScreenEditorScreenState();
}

class _FullScreenEditorScreenState extends State<FullScreenEditorScreen> {
  late String _serializedContent;

  @override
  void initState() {
    super.initState();
    _serializedContent = widget.controller.text;
  }

  void _save() {
    widget.controller.text = _serializedContent;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              onPressed: _save,
              child: const Text('保存'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SimpleRichTextEditor(
          initialText: widget.controller.text,
          hintText: widget.hintText,
          onChanged: (serialized) {
            _serializedContent = serialized;
          },
        ),
      ),
    );
  }
}
