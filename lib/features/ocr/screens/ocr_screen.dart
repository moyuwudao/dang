import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/ocr_provider.dart';

class OCRScreen extends ConsumerStatefulWidget {
  const OCRScreen({super.key});

  @override
  ConsumerState<OCRScreen> createState() => _OCRScreenState();
}

class _OCRScreenState extends ConsumerState<OCRScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer();
  bool _isProcessing = false;
  String? _recognizedText;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _requestPermission();
  }

  Future<void> _requestPermission() async {
    await Permission.camera.request();
    await Permission.photos.request();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _isProcessing = true;
          _recognizedText = null;
        });

        await _recognizeText(File(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择图片失败: $e')),
        );
      }
    }
  }

  Future<void> _recognizeText(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      setState(() {
        _recognizedText = recognizedText.text;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('文字识别失败: $e')),
        );
      }
    }
  }

  Future<void> _saveRecord() async {
    if (_recognizedText == null || _selectedImage == null) return;

    try {
      await ref.read(ocrNotifierProvider.notifier).saveOCRRecord(
            imagePath: _selectedImage!.path,
            content: _recognizedText!,
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
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OCR识别'),
        actions: [
          if (_recognizedText != null)
            TextButton(
              onPressed: _saveRecord,
              child: const Text('保存'),
            ),
        ],
      ),
      body: Column(
        children: [
          // 图片预览区域
          Expanded(
            flex: 2,
            child: _buildImagePreview(),
          ),

          // 识别结果区域
          Expanded(
            flex: 3,
            child: _buildResultArea(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildImagePreview() {
    if (_selectedImage == null) {
      return Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.textTertiary.withOpacity(0.3),
            style: BorderStyle.solid,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_outlined,
                size: 48,
                color: AppColors.textTertiary,
              ),
              SizedBox(height: 8),
              Text(
                '选择或拍摄图片',
                style: TextStyle(color: AppColors.textTertiary),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
          image: FileImage(_selectedImage!),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildResultArea() {
    if (_isProcessing) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在识别文字...'),
          ],
        ),
      );
    }

    if (_recognizedText == null) {
      return const Center(
        child: Text(
          '识别结果将显示在这里',
          style: TextStyle(color: AppColors.textTertiary),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '识别结果',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              IconButton(
                icon: const Icon(Icons.copy_outlined),
                onPressed: () {
                  // TODO: 复制到剪贴板
                },
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: SingleChildScrollView(
              child: Text(_recognizedText!),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('拍照'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('相册'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
