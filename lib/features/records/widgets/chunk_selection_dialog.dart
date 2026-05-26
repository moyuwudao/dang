import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/audio_processor.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';

// l10n keys used: selectAll, cancelButton, transcribeTitle

class ChunkSelectionDialog extends StatefulWidget {
  final List<AudioChunkInfo> chunks;
  final String title;

  const ChunkSelectionDialog({
    super.key,
    required this.chunks,
    required this.title,
  });

  @override
  State<ChunkSelectionDialog> createState() => _ChunkSelectionDialogState();
}

class _ChunkSelectionDialogState extends State<ChunkSelectionDialog> {
  final Set<int> _selectedIndices = {};
  bool _selectAll = false;

  void _toggleSelectAll() {
    setState(() {
      _selectAll = !_selectAll;
      if (_selectAll) {
        _selectedIndices.addAll(widget.chunks.map((c) => c.index));
      } else {
        _selectedIndices.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title),
          const SizedBox(height: 8),
          Text(
            '${widget.chunks.length} / ${_selectedIndices.length}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            // 全选按钮
            CheckboxListTile(
              title: Text(l10n.selectAll),
              value: _selectAll,
              onChanged: (_) => _toggleSelectAll(),
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
            ),
            const Divider(),
            // 段落列表
            Expanded(
              child: ListView.builder(
                itemCount: widget.chunks.length,
                itemBuilder: (context, index) {
                  final chunk = widget.chunks[index];
                  final isSelected = _selectedIndices.contains(chunk.index);
                  return CheckboxListTile(
                    title: Text('${chunk.index + 1}'),
                    subtitle: Text(
                      '${chunk.durationText} (${(chunk.size / 1024).toStringAsFixed(0)} KB)',
                    ),
                    value: isSelected,
                    onChanged: (_) {
                      setState(() {
                        if (isSelected) {
                          _selectedIndices.remove(chunk.index);
                          _selectAll = false;
                        } else {
                          _selectedIndices.add(chunk.index);
                          if (_selectedIndices.length == widget.chunks.length) {
                            _selectAll = true;
                          }
                        }
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancelButton),
        ),
        ElevatedButton(
          onPressed: _selectedIndices.isEmpty
              ? null
              : () => Navigator.pop(context, _selectedIndices.toList()..sort()),
          child: Text(l10n.transcribeTitle),
        ),
      ],
    );
  }
}