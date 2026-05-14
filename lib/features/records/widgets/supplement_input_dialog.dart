import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/expandable_text_field.dart';
import '../../../data/models/record_model.dart';
import '../../recording/providers/recording_provider.dart';

enum SupplementType { text, audio, image }

class SupplementInputDialog extends ConsumerStatefulWidget {
  const SupplementInputDialog({super.key});

  @override
  ConsumerState<SupplementInputDialog> createState() => _SupplementInputDialogState();
}

class _SupplementInputDialogState extends ConsumerState<SupplementInputDialog> {
  SupplementType _selectedType = SupplementType.text;
  final TextEditingController _textController = TextEditingController();
  String? _audioPath;
  String? _imagePath;
  bool _isRecording = false;

  Future<void> _startRecording() async {
    try {
      final recordingService = ref.read(recordingServiceProvider);
      await recordingService.startRecording();
      setState(() {
        _isRecording = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('开始录音失败: $e')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      final recordingService = ref.read(recordingServiceProvider);
      final path = await recordingService.stopRecording();
      setState(() {
        _isRecording = false;
        _audioPath = path;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('停止录音失败: $e')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    // TODO: 实现图片选择
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('图片选择功能待实现')),
    );
  }

  SupplementItem? _buildResult() {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final now = DateTime.now();

    switch (_selectedType) {
      case SupplementType.text:
        final text = _textController.text.trim();
        if (text.isEmpty) return null;
        return SupplementItem(
          id: id,
          type: 'text',
          content: text,
          createdAt: now,
        );
      case SupplementType.audio:
        if (_audioPath == null) return null;
        return SupplementItem(
          id: id,
          type: 'audio',
          content: _audioPath!,
          createdAt: now,
        );
      case SupplementType.image:
        if (_imagePath == null) return null;
        return SupplementItem(
          id: id,
          type: 'image',
          content: _imagePath!,
          createdAt: now,
        );
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('补充完善想法'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 输入类型选择
            SegmentedButton<SupplementType>(
              segments: const [
                ButtonSegment(
                  value: SupplementType.text,
                  label: Text('文本'),
                  icon: Icon(Icons.text_fields),
                ),
                ButtonSegment(
                  value: SupplementType.audio,
                  label: Text('录音'),
                  icon: Icon(Icons.mic),
                ),
                ButtonSegment(
                  value: SupplementType.image,
                  label: Text('图片'),
                  icon: Icon(Icons.image),
                ),
              ],
              selected: {_selectedType},
              onSelectionChanged: (Set<SupplementType> newSelection) {
                setState(() {
                  _selectedType = newSelection.first;
                });
              },
            ),
            const SizedBox(height: 16),
            // 根据类型显示不同的输入界面
            _buildInputArea(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            final result = _buildResult();
            if (result != null) {
              Navigator.pop(context, result);
            }
          },
          child: const Text('保存'),
        ),
      ],
    );
  }

  Widget _buildInputArea() {
    switch (_selectedType) {
      case SupplementType.text:
        return ExpandableTextField(
          controller: _textController,
          hintText: '在此补充你的想法...',
          minLines: 4,
          maxLines: 6,
        );
      case SupplementType.audio:
        return Column(
          children: [
            if (_audioPath != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.success),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '录音已保存',
                        style: TextStyle(color: AppColors.success),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: AppColors.error),
                      onPressed: () {
                        setState(() {
                          _audioPath = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ] else
              ElevatedButton.icon(
                onPressed: _isRecording ? _stopRecording : _startRecording,
                icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                label: Text(_isRecording ? '停止录音' : '开始录音'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRecording ? AppColors.error : AppColors.primary,
                ),
              ),
          ],
        );
      case SupplementType.image:
        return Column(
          children: [
            if (_imagePath != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.success),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '图片已选择',
                        style: TextStyle(color: AppColors.success),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: AppColors.error),
                      onPressed: () {
                        setState(() {
                          _imagePath = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ] else
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image),
                label: const Text('选择图片'),
              ),
          ],
        );
    }
  }
}