import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/tag_selector.dart';
import '../providers/ocr_provider.dart';

class OCRScreen extends ConsumerStatefulWidget {
  const OCRScreen({super.key});

  @override
  ConsumerState<OCRScreen> createState() => _OCRScreenState();
}

class _OCRScreenState extends ConsumerState<OCRScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  String? _recognizedText;
  bool _isProcessing = false;
  final List<String> _tags = [];

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _isProcessing = true;
        });

        await _recognizeText(File(image.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('选择图片失败: $e')),
      );
    }
  }

  Future<void> _recognizeText(File imageFile) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final result = await apiService.recognizeImage(imageFile.path);

      setState(() {
        _recognizedText = result;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('文字识别失败: $e')),
      );
    }
  }

  Future<void> _saveRecord() async {
    if (_recognizedText == null || _selectedImage == null) return;

    try {
      await ref.read(ocrNotifierProvider.notifier).saveOCRRecord(
        imagePath: _selectedImage!.path,
        content: _recognizedText!,
        tags: _tags,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('记录已保存'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('拍照识别'),
        actions: [
          if (_recognizedText != null)
            TextButton.icon(
              onPressed: _saveRecord,
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text(
                '保存',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _selectedImage == null
          ? _buildImagePicker()
          : _buildResultView(),
    );
  }

  Widget _buildImagePicker() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            onPressed: () => _pickImage(ImageSource.camera),
            icon: const Icon(Icons.camera_alt),
            label: const Text('拍照'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(200, 50),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _pickImage(ImageSource.gallery),
            icon: const Icon(Icons.photo_library),
            label: const Text('从相册选择'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(200, 50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 图片预览
          LayoutBuilder(
            builder: (context, constraints) {
              final cacheWidth = (constraints.maxWidth * MediaQuery.of(context).devicePixelRatio).toInt().clamp(100, 1920);
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _selectedImage!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  cacheWidth: cacheWidth,
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // 识别结果
          if (_isProcessing)
            const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 8),
                  Text('正在识别文字...'),
                ],
              ),
            )
          else if (_recognizedText != null) ...[
            Row(
              children: [
                const Icon(Icons.text_fields, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  '识别结果',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: SelectableText(_recognizedText!),
            ),
            const SizedBox(height: 16),

            // 标签选择
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '标签',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                ),
                const SizedBox(height: 8),
                TagSelector(
                  selectedTags: _tags,
                  onTagsChanged: (tags) {
                    setState(() {
                      _tags.clear();
                      _tags.addAll(tags);
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 重新选择按钮
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('重新拍照'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('从相册选择'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 保存按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveRecord,
                icon: const Icon(Icons.save),
                label: const Text('保存记录'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
