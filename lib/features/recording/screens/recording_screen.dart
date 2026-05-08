import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/widgets/tag_selector.dart';
import '../providers/recording_provider.dart';

class RecordingScreen extends ConsumerStatefulWidget {
  const RecordingScreen({super.key});

  @override
  ConsumerState<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends ConsumerState<RecordingScreen> {
  final List<String> _tags = [];

  @override
  Widget build(BuildContext context) {
    final recordingState = ref.watch(recordingStateProvider);
    final recordingNotifier = ref.read(recordingStateProvider.notifier);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleRecordingNotification(recordingState);
    });

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            if (recordingState.isRecording || recordingState.isTranscribing) {
              recordingNotifier.cancelRecording();
            }
            if (context.mounted) {
              context.pop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 上半部分：录音控制
            Expanded(
              flex: 1,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 录音时长
                  Text(
                    _formatDuration(recordingState.duration),
                    style: const TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.w200,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 波形可视化
                  if (recordingState.isRecording)
                    SizedBox(
                      height: 80,
                      child: CustomPaint(
                        size: const Size(double.infinity, 80),
                        painter: WaveformPainter(
                          amplitudes: recordingState.amplitudes,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 80),

                  const SizedBox(height: 24),

                  // 转写进度显示
                  if (recordingState.isTranscribing) ...[
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      recordingState.transcriptionProgress ?? '正在处理...',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ]
                  else
                    // 控制按钮 - 放大录音键
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 删除/取消按钮
                        if (recordingState.isRecording)
                          _buildControlButton(
                            icon: Icons.delete_outline,
                            onPressed: () {
                              recordingNotifier.cancelRecording();
                              if (context.mounted) {
                                context.pop();
                              }
                            },
                            color: Colors.white54,
                          )
                        else
                          const SizedBox(width: 72),

                        const SizedBox(width: 32),

                        // 录音/停止按钮 - 放大到 110
                        GestureDetector(
                          onTap: () {
                            if (recordingState.isRecording) {
                              recordingNotifier.stopRecording(tags: _tags);
                            } else {
                              recordingNotifier.startRecording();
                            }
                          },
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: recordingState.isRecording
                                  ? AppColors.error
                                  : AppColors.primary,
                              boxShadow: [
                                BoxShadow(
                                  color: (recordingState.isRecording
                                          ? AppColors.error
                                          : AppColors.primary)
                                      .withOpacity(0.35),
                                  blurRadius: 28,
                                  spreadRadius: 8,
                                ),
                              ],
                            ),
                            child: Icon(
                              recordingState.isRecording
                                  ? Icons.stop
                                  : Icons.mic,
                              color: Colors.white,
                              size: 44,
                            ),
                          ),
                        ),

                        const SizedBox(width: 32),

                        // 暂停按钮
                        if (recordingState.isRecording)
                          _buildControlButton(
                            icon: recordingState.isPaused
                                ? Icons.play_arrow
                                : Icons.pause,
                            onPressed: () {
                              if (recordingState.isPaused) {
                                recordingNotifier.resumeRecording();
                              } else {
                                recordingNotifier.pauseRecording();
                              }
                            },
                            color: Colors.white54,
                          )
                        else
                          const SizedBox(width: 72),
                      ],
                    ),

                  const SizedBox(height: 16),

                  // 提示文字
                  if (!recordingState.isTranscribing)
                    Text(
                      recordingState.isRecording
                          ? (recordingState.isPaused ? '已暂停' : '点击停止录音')
                          : '点击开始录音',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 16,
                      ),
                    ),

                  // 错误提示
                  if (recordingState.error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        recordingState.error!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // 下半部分：标签选择（当页可见，不需要下拉）
            if (!recordingState.isRecording && !recordingState.isTranscribing)
              Container(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.label_outline,
                            color: Colors.white70, size: 16),
                        SizedBox(width: 6),
                        Text(
                          '添加标签（可选）',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.22,
                      ),
                      child: SingleChildScrollView(
                        child: TagSelector(
                          selectedTags: _tags,
                          onTagsChanged: (tags) {
                            setState(() {
                              _tags.clear();
                              _tags.addAll(tags);
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.2),
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 24),
        onPressed: onPressed,
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _handleRecordingNotification(RecordingState state) async {
    final notificationService = NotificationService();
    await notificationService.initialize();

    if (state.isRecording && !state.isPaused) {
      await notificationService.showRecordingNotification();
    } else {
      await notificationService.cancelNotification(0);
    }
  }
}

class WaveformPainter extends CustomPainter {
  final List<double> amplitudes;
  final Color color;

  WaveformPainter({required this.amplitudes, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (amplitudes.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final width = size.width;
    final height = size.height;
    final centerY = height / 2;
    final barWidth = width / 50;

    for (int i = 0; i < amplitudes.length; i++) {
      final amplitude = amplitudes[i].abs();
      final barHeight = (amplitude / 100).clamp(0.0, 1.0) * height * 0.8;
      final x = i * barWidth;

      canvas.drawLine(
        Offset(x, centerY - barHeight / 2),
        Offset(x, centerY + barHeight / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) {
    if (oldDelegate.amplitudes.length != amplitudes.length) return true;
    for (int i = 0; i < amplitudes.length; i++) {
      if (oldDelegate.amplitudes[i] != amplitudes[i]) return true;
    }
    return false;
  }
}
