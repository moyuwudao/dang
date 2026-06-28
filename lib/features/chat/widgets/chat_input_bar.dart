import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/app_logger.dart';
import '../../../core/services/toast_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/recording_service.dart';
import '../../../core/services/realtime_transcription_service.dart';
import '../../../core/services/transcription_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/widgets/expandable_text_field.dart';
import '../../../core/models/ai_model_config.dart';
import '../../../core/models/ai_role.dart';
import '../../../core/models/realtime_transcription_result.dart';
import '../../records/widgets/ai_role_picker.dart';
import '../../workbench/models/workbench_tool.dart';
import '../../workbench/providers/workbench_provider.dart';
import '../providers/chat_provider.dart';
import 'reference_selector.dart';

/// 对话输入栏：集成 Agent / Skill 选择、文本、录音、图片输入。
///
/// - 左下角固定 Agent + Skill 两个圆形入口
/// - 输入框内以 Chip 形式显示已选 Agent / Skill
/// - 右侧独立排列：图片、录音、发送
/// - 支持展开/收起多行输入
class ChatInputBar extends ConsumerStatefulWidget {
  final String? conversationId;
  final int? sourceRecordId;
  final String? contextSnapshot;
  final AiRole? selectedAgent;
  final WorkbenchTool? selectedSkill;
  final ValueChanged<AiRole?> onAgentChanged;
  final ValueChanged<WorkbenchTool?> onSkillChanged;
  final Future<String> Function()? onCreateConversation;

  const ChatInputBar({
    super.key,
    this.conversationId,
    this.sourceRecordId,
    this.contextSnapshot,
    required this.selectedAgent,
    required this.selectedSkill,
    required this.onAgentChanged,
    required this.onSkillChanged,
    this.onCreateConversation,
  });

  @override
  ConsumerState<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends ConsumerState<ChatInputBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _imagePicker = ImagePicker();

  bool _isComposing = false;
  bool _isRecording = false;
  bool _isTranscribing = false;
  Duration _recordingDuration = Duration.zero;
  String? _recordingError;

  final List<String> _selectedImages = [];
  String? _recordedAudioPath;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription? _realtimeSubscription;
  RecordingService? _recordingService;
  RealtimeTranscriptionService? _realtimeService;
  bool _isRealtimeEnabled = true; // 默认实时转写（用户偏好）
  bool _isRealtimeAvailable = false;
  String _realtimeFinalText = '';
  String _existingInputText = '';

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final composing = _controller.text.isNotEmpty;
      if (composing != _isComposing) {
        setState(() => _isComposing = composing);
      }
    });
    _realtimeService = ref.read(realtimeTranscriptionServiceProvider);
    _checkRealtimeSettings();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void didUpdateWidget(covariant ChatInputBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.conversationId != oldWidget.conversationId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    }
  }

  Future<void> _checkRealtimeSettings() async {
    final modeString = await StorageService.getRecordingLaunchMode();
    final isRealtimeMode = modeString.isEmpty || modeString == 'realtime';
    await _checkRealtimeAvailability();
    if (mounted) {
      setState(() {
        _isRealtimeEnabled = isRealtimeMode && _isRealtimeAvailable;
      });
    }
  }

  Future<void> _checkRealtimeAvailability() async {
    try {
      final multiConfig = await StorageService.getMultiApiConfig();
      if (multiConfig.hasAnyConfig) {
        final realtimeConfig = multiConfig.getConfigForFunction(ApiFunctionType.voiceRealtime);
        if (realtimeConfig != null && realtimeConfig.apiKey.isNotEmpty) {
          final providerConfig = AiModelConfig.getConfig(realtimeConfig.provider);
          if (providerConfig.supportsRealtimeTranscription) {
            _isRealtimeAvailable = true;
            return;
          }
        }
      }

      final singleConfig = await StorageService.getApiConfig();
      if (singleConfig != null && singleConfig.apiKey.isNotEmpty) {
        final provider = AiProvider.values.firstWhere(
          (p) => p.name.toLowerCase() == singleConfig.provider.toLowerCase(),
          orElse: () => AiProvider.deepSeek,
        );
        final providerConfig = AiModelConfig.getConfig(provider);
        _isRealtimeAvailable = providerConfig.supportsRealtimeTranscription;
      }
    } catch (e) {
      AppLogger().e('ChatInputBar', 'check realtime availability failed: $e');
      _isRealtimeAvailable = false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _durationSubscription?.cancel();
    _realtimeSubscription?.cancel();
    if (_isRecording) {
      _recordingService?.cancelRecording();
    }
    _recordingService?.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    var text = _controller.text.trim();
    if (text.isEmpty && _selectedImages.isEmpty && _recordedAudioPath == null) return;

    // 实时转写模式下，发送时自动停止录音并保留当前文本，直接发送
    if (_isRecording && _isRealtimeEnabled) {
      await _stopRealtimeAndKeepText();
      text = _controller.text.trim();
    }

    if (_isRecording || _isTranscribing) return;
    if (text.isEmpty && _selectedImages.isEmpty && _recordedAudioPath == null) return;

    final images = List<String>.from(_selectedImages);
    final audioPath = _recordedAudioPath;
    _controller.clear();
    _selectedImages.clear();
    _recordedAudioPath = null;
    _focusNode.requestFocus();
    if (mounted) setState(() {});

    // 若当前没有对话，先创建对话
    String conversationId;
    if (widget.conversationId == null) {
      if (widget.onCreateConversation == null) return;
      conversationId = await widget.onCreateConversation!();
    } else {
      conversationId = widget.conversationId!;
    }

    ref.read(sendMessageProvider.notifier).sendMessage(
          conversationId: conversationId,
          content: text.isEmpty && images.isNotEmpty ? '请描述这张图片' : text,
          sourceRecordId: widget.sourceRecordId,
          contextSnapshot: widget.contextSnapshot,
          imagePaths: images,
          audioPath: audioPath,
          agentSystemPrompt: widget.selectedAgent?.systemPrompt,
          skillSystemPrompt: widget.selectedSkill?.systemPrompt,
          selectedSkill: widget.selectedSkill,
        );
  }

  // ============ Agent / Skill 选择 ============

  void _showAgentPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => AiRolePicker(
        onRoleSelected: (role) {
          widget.onAgentChanged(role);
          if (mounted) {
            ToastService.showInfo(context, '已切换 Agent: ${role.name}');
          }
        },
      ),
    );
  }

  void _showSkillPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _SkillPickerSheet(
        onSkillSelected: (tool) {
          widget.onSkillChanged(tool);
          if (mounted) {
            ToastService.showInfo(
              context,
              tool != null ? '已选择 Skill: ${tool.name}' : '已清除 Skill',
            );
          }
        },
      ),
    );
  }

  void _showReferenceSelector() async {
    final conversationId = widget.conversationId;
    if (conversationId == null || conversationId.isEmpty) {
      _showReferenceHint();
      return;
    }

    final selection = await showModalBottomSheet<ReferenceSelection>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => ReferenceSelector(
        conversationId: conversationId,
      ),
    );

    if (selection == null || !mounted) return;

    final quoted = selection.content
        .split('\n')
        .map((line) => '> ${line.isEmpty ? ' ' : line}')
        .join('\n');
    final insertText = '【引用：${selection.title}】\n$quoted\n\n';

    final currentText = _controller.text;
    final cursorPos = _controller.selection.baseOffset;
    final effectiveCursor = cursorPos < 0 || cursorPos > currentText.length
        ? currentText.length
        : cursorPos;

    final newText = currentText.substring(0, effectiveCursor) +
        insertText +
        currentText.substring(effectiveCursor);

    _controller.text = newText;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: effectiveCursor + insertText.length),
    );
    _focusNode.requestFocus();
  }

  void _showReferenceHint() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.08),
      barrierDismissible: true,
      builder: (context) => Align(
        alignment: const Alignment(0, -0.3),
        child: Material(
          color: Colors.transparent,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.format_quote_outlined,
                    color: AppColors.secondary,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '引用功能',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '发送第一条消息后，可引用收藏的记录内容。',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('知道了'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============ 图片选择 ============

  Future<void> _pickImage(ImageSource source) async {
    try {
      if (source == ImageSource.camera) {
        final photo = await _imagePicker.pickImage(source: source, imageQuality: 80);
        if (photo != null) {
          setState(() => _selectedImages.add(photo.path));
        }
      } else {
        final images = await _imagePicker.pickMultiImage(imageQuality: 80);
        if (images.isNotEmpty) {
          setState(() {
            _selectedImages.addAll(images.map((f) => f.path));
          });
        }
      }
    } catch (e) {
      AppLogger().e('ChatInputBar', 'pick image failed: $e');
      if (mounted) {
        ToastService.showError(context, '选择图片失败: $e');
      }
    }
  }

  void _removeImage(int index) {
    setState(() => _selectedImages.removeAt(index));
  }

  // ============ 录音 ============

  Future<void> _toggleRecording() async {
    if (_isTranscribing) return;
    if (_isRecording) {
      await _stopRecordingAndTranscribe();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    setState(() => _recordingError = null);

    try {
      _recordingService ??= RecordingService();
      final hasPermission = await _recordingService!.hasPermission();
      if (!hasPermission) {
        setState(() => _recordingError = '需要麦克风权限');
        return;
      }

      final path = await _recordingService!.startRecording();
      _recordedAudioPath = path;
      _recordingDuration = Duration.zero;

      _durationSubscription?.cancel();
      _durationSubscription = _recordingService!.durationStream.listen((d) {
        if (mounted) setState(() => _recordingDuration = d);
      });

      setState(() {
        _isRecording = true;
      });

      if (_isRealtimeEnabled) {
        _startRealtimeTranscription();
      }
    } catch (e) {
      AppLogger().e('ChatInputBar', 'start recording failed: $e');
      setState(() => _recordingError = '开始录音失败: $e');
    }
  }

  void _startRealtimeTranscription() {
    try {
      _realtimeFinalText = '';
      _existingInputText = _controller.text;

      final audioStream = _recordingService?.audioStream;
      if (audioStream == null) {
        AppLogger().w('ChatInputBar', 'audio stream is null, skip realtime');
        return;
      }

      _realtimeSubscription?.cancel();
      _realtimeSubscription = _realtimeService?.transcribeRealtimeWithReconnect(
        audioStream: audioStream,
        onStatusChange: (status, detail) {
          AppLogger().i('ChatInputBar', 'realtime status: $status - $detail');
        },
      ).listen(
        _handleRealtimeResult,
        onError: (e) {
          AppLogger().e('ChatInputBar', 'realtime transcription error: $e');
          if (mounted) setState(() => _recordingError = '实时转写失败: $e');
        },
      );
    } catch (e) {
      AppLogger().e('ChatInputBar', 'start realtime transcription failed: $e');
    }
  }

  void _handleRealtimeResult(RealtimeTranscriptionResult result) {
    if (!mounted) return;
    if (result.text.isEmpty) return;

    AppLogger().i(
      'ChatInputBar',
      'realtime result: "${result.text}", isFinal: ${result.isFinal}',
    );

    if (result.isFinal) {
      final cleaned = result.text.replaceAll('\n', ' ').trim();
      if (cleaned.isEmpty) return;
      _realtimeFinalText = _realtimeFinalText.isEmpty
          ? cleaned
          : '$_realtimeFinalText $cleaned';
    }

    final realtimeText = _realtimeFinalText.replaceAll('\n', ' ');
    final newText = _existingInputText.isEmpty
        ? realtimeText
        : '$_existingInputText${realtimeText.isEmpty ? '' : ' $realtimeText'}';

    _controller.text = newText;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: newText.length),
    );
    _focusNode.requestFocus();
  }

  Future<void> _stopRecordingAndTranscribe() async {
    if (_recordingService == null) return;

    setState(() {
      _isRecording = false;
      _isTranscribing = true;
    });
    _durationSubscription?.cancel();
    await _realtimeSubscription?.cancel();
    _realtimeSubscription = null;

    try {
      final path = await _recordingService!.stopRecording();

      if (_isRealtimeEnabled && _realtimeFinalText.isNotEmpty) {
        _recordedAudioPath = null; // 实时模式不保留音频
        if (mounted) setState(() => _isTranscribing = false);
        return;
      }

      if (path == null || path.isEmpty) {
        setState(() {
          _isTranscribing = false;
          _recordingError = '录音文件为空';
        });
        return;
      }

      _recordedAudioPath = path; // 仅录音模式保留音频路径

      final transcriptionService = ref.read(transcriptionServiceProvider);
      final text = await transcriptionService.transcribeAudio(
        path,
        onProgress: (step, detail) {
          AppLogger().d('ChatInputBar', 'transcribe $step: $detail');
        },
      );

      if (mounted) {
        final existing = _controller.text;
        final newText = existing.isEmpty ? text : '$existing\n$text';
        _controller.text = newText;
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: newText.length),
        );
        _focusNode.requestFocus();
      }
    } catch (e) {
      AppLogger().e('ChatInputBar', 'transcribe failed: $e');
      if (mounted) {
        ToastService.showError(context, '转写失败: $e');
      }
    } finally {
      if (mounted) setState(() => _isTranscribing = false);
    }
  }

  Future<void> _stopRealtimeAndKeepText() async {
    if (_recordingService == null) return;

    setState(() {
      _isRecording = false;
      _isTranscribing = false;
    });
    _durationSubscription?.cancel();
    await _realtimeSubscription?.cancel();
    _realtimeSubscription = null;

    try {
      await _recordingService!.stopRecording();
      _recordedAudioPath = null; // 实时模式不保留音频文件
    } catch (e) {
      AppLogger().w('ChatInputBar', 'stop realtime recording ignored: $e');
    }
  }

  // ============ UI ============

  String _formatDuration(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isTyping = ref.watch(isTypingProvider);
    final webSearchEnabled = ref.watch(webSearchEnabledProvider);
    final disabled = isTyping || _isTranscribing;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border.withOpacity(0.5)),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_selectedImages.isNotEmpty) _buildImagePreview(),
            if (_isTranscribing && !_isRecording) _buildTranscribingBar(),
            if (_recordingError != null) _buildErrorBar(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildAgentButton(),
                const SizedBox(width: 6),
                _buildSkillButton(),
                const SizedBox(width: 6),
                _buildReferenceButton(),
                const SizedBox(width: 6),
                _buildWebSearchButton(),
                const SizedBox(width: 8),
                Expanded(child: _buildTextField(disabled, webSearchEnabled)),
                const SizedBox(width: 4),
                _buildImageButton(),
                _buildRecordButton(disabled),
                _buildSendButton(disabled),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgentButton() {
    final agent = widget.selectedAgent;
    return Tooltip(
      message: agent != null ? 'Agent: ${agent.name}' : '选择 Agent',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showAgentPicker,
          customBorder: const CircleBorder(),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: (agent?.color ?? AppColors.primary).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              agent?.icon ?? Icons.smart_toy_outlined,
              size: 18,
              color: agent?.color ?? AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkillButton() {
    final skill = widget.selectedSkill;
    return Tooltip(
      message: skill != null ? 'Skill: ${skill.name}' : '选择 Skill',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _showSkillPicker,
              customBorder: const CircleBorder(),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: (skill?.color ?? AppColors.warning).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  skill?.icon ?? Icons.dashboard_outlined,
                  size: 18,
                  color: skill?.color ?? AppColors.warning,
                ),
              ),
            ),
          ),
          if (skill != null)
            Positioned(
              right: -2,
              top: -2,
              child: GestureDetector(
                onTap: _clearSkill,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade600,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _clearSkill() {
    widget.onSkillChanged(null);
    if (mounted) {
      ToastService.showInfo(context, '已清除 Skill');
    }
  }

  Widget _buildReferenceButton() {
    return Tooltip(
      message: '引用收藏',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showReferenceSelector,
          customBorder: const CircleBorder(),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.format_quote_outlined,
              size: 18,
              color: AppColors.secondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWebSearchButton() {
    final isEnabled = ref.watch(webSearchEnabledProvider);
    return Tooltip(
      message: isEnabled ? '联网中' : '联网',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ref.read(webSearchEnabledProvider.notifier).state = !isEnabled;
          },
          customBorder: const CircleBorder(),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isEnabled
                  ? AppColors.info.withValues(alpha: 0.12)
                  : Colors.transparent,
              shape: BoxShape.circle,
              border: isEnabled
                  ? Border.all(color: AppColors.info.withValues(alpha: 0.3), width: 1)
                  : null,
            ),
            child: Icon(
              isEnabled ? Icons.language : Icons.language_outlined,
              size: 18,
              color: isEnabled ? AppColors.info : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      height: 88,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedImages.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final path = _selectedImages[index];
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(path),
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 2,
                right: 2,
                child: GestureDetector(
                  onTap: () => _removeImage(index),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTranscribingBar() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _isRealtimeEnabled ? '正在实时转写...' : '正在转写录音...',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBar() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 16, color: AppColors.error),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _recordingError!,
              style: TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _recordingError = null),
            child: Icon(Icons.close, size: 14, color: AppColors.error),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(bool disabled, bool webSearchEnabled) {
    final isRecording = _isRecording;
    final skill = widget.selectedSkill;

    String hintText;
    if (isRecording) {
      hintText = _isRealtimeEnabled
          ? '实时转写中 ${_formatDuration(_recordingDuration)} · 松开发送'
          : '录音中 ${_formatDuration(_recordingDuration)} · 点击停止';
    } else {
      hintText = webSearchEnabled ? '联网中 · 输入消息...' : '输入消息...';
    }

    return Container(
      padding: const EdgeInsets.only(left: 4, right: 4),
      decoration: BoxDecoration(
        color: isRecording ? Colors.red.withValues(alpha: 0.06) : AppColors.background,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isRecording
              ? Colors.red.withValues(alpha: 0.5)
              : AppColors.border.withOpacity(0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (webSearchEnabled && !isRecording)
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 12, bottom: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.language, size: 14, color: AppColors.info),
                  const SizedBox(width: 4),
                  Text(
                    '联网中',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.info,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 1,
                    height: 16,
                    color: AppColors.border,
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(
                  color: webSearchEnabled && !isRecording
                      ? AppColors.info.withValues(alpha: 0.7)
                      : AppColors.textTertiary,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                prefixIcon: skill != null
                    ? _buildSkillInlineIcon(skill)
                    : null,
                prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 32),
                suffixIcon: _buildExpandButton(),
                suffixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              style: const TextStyle(fontSize: 15),
              minLines: 1,
              maxLines: 5,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              onSubmitted: (_) => _handleSubmit(),
              enabled: !disabled || _controller.text.isNotEmpty,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillInlineIcon(WorkbenchTool skill) {
    return IconButton(
      icon: Icon(skill.icon, size: 18, color: skill.color),
      tooltip: 'Skill: ${skill.name}',
      onPressed: _showSkillPicker,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }

  Widget _buildExpandButton() {
    return IconButton(
      icon: Icon(
        Icons.open_in_full,
        size: 18,
        color: AppColors.textSecondary,
      ),
      tooltip: '展开编辑',
      onPressed: _openFullScreenEditor,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }

  void _openFullScreenEditor() {
    _focusNode.unfocus();
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => FullScreenEditorScreen(
          controller: _controller,
          hintText: '输入消息...',
          title: '编辑消息',
        ),
      ),
    );
  }

  Widget _buildImageButton() {
    return PopupMenuButton<ImageSource>(
      icon: Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary),
      tooltip: '图片',
      onSelected: (source) => _pickImage(source),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: ImageSource.gallery,
          child: Row(
            children: [
              Icon(Icons.photo_outlined),
              SizedBox(width: 8),
              Text('从相册选择'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: ImageSource.camera,
          child: Row(
            children: [
              Icon(Icons.camera_alt_outlined),
              SizedBox(width: 8),
              Text('拍照'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecordButton(bool disabled) {
    if (_isRecording) {
      return IconButton(
        icon: const Icon(Icons.stop, color: Colors.white, size: 20),
        tooltip: _isRealtimeEnabled ? '停止转写' : '停止录音',
        onPressed: _stopRecordingAndTranscribe,
        padding: const EdgeInsets.all(6),
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        style: IconButton.styleFrom(
          backgroundColor: Colors.red,
          shape: const CircleBorder(),
        ),
      );
    }

    return IconButton(
      icon: Icon(Icons.mic_none, color: disabled ? AppColors.textTertiary : AppColors.primary, size: 22),
      tooltip: _isRealtimeEnabled ? '实时转写' : '录音',
      onPressed: disabled ? null : _toggleRecording,
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
    );
  }

  Widget _buildSendButton(bool disabled) {
    final canSend = (_isComposing || _selectedImages.isNotEmpty) && !disabled;
    return IconButton(
      icon: Icon(Icons.send, color: canSend ? Colors.white : AppColors.textTertiary, size: 18),
      tooltip: '发送',
      onPressed: canSend ? _handleSubmit : null,
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      style: IconButton.styleFrom(
        backgroundColor: canSend ? AppColors.primary : AppColors.background,
        shape: const CircleBorder(),
      ),
    );
  }
}

// ========== Skill 选择 BottomSheet ==========
class _SkillPickerSheet extends ConsumerWidget {
  final ValueChanged<WorkbenchTool?> onSkillSelected;

  const _SkillPickerSheet({required this.onSkillSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workbenchAsync = ref.watch(workbenchProvider);

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '选择 Skill',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      onSkillSelected(null);
                      Navigator.pop(context);
                    },
                    child: const Text('清除'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: workbenchAsync.when(
                data: (state) {
                  final tools = state.visibleTools.where((t) => t.isEnabled).toList();
                  if (tools.isEmpty) {
                    return const Center(
                      child: Text('暂无可用 Skill', style: TextStyle(color: AppColors.textSecondary)),
                    );
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: tools.length,
                    itemBuilder: (context, index) {
                      final tool = tools[index];
                      return _buildToolItem(context, tool);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Text('加载失败: $error', style: TextStyle(color: AppColors.error)),
                ),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.add_circle_outline, color: AppColors.primary),
              title: const Text('创建自己的 SKILL'),
              subtitle: const Text('跳转到设置内的工具台进行管理'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                context.push('/settings/workbench');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolItem(BuildContext context, WorkbenchTool tool) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onSkillSelected(tool);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: tool.color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: tool.color.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(tool.icon, color: tool.color, size: 28),
            const SizedBox(height: 8),
            Text(
              tool.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: tool.color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              tool.description,
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

