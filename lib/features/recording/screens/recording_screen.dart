import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/notification_service.dart';
import '../providers/recording_provider.dart';

class RecordingScreen extends ConsumerWidget {
  const RecordingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordingState = ref.watch(recordingStateProvider);
    final recordingNotifier = ref.read(recordingStateProvider.notifier);

    // 监听录音状态，显示通知
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
            if (recordingState.isRecording) {
              recordingNotifier.cancelRecording();
            }
            context.pop();
          },
        ),
      ),
      body: Column(
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
          const SizedBox(height: 48),
          
          // 波形可视化
          if (recordingState.isRecording)
            SizedBox(
              height: 100,
              child: CustomPaint(
                size: const Size(double.infinity, 100),
                painter: WaveformPainter(
                  amplitudes: recordingState.amplitudes,
                  color: AppColors.primary,
                ),
              ),
            )
          else
            const SizedBox(height: 100),
            
          const SizedBox(height: 48),
          
          // 控制按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 删除/取消按钮
              if (recordingState.isRecording)
                _buildControlButton(
                  icon: Icons.delete_outline,
                  onPressed: () => recordingNotifier.cancelRecording(),
                  color: Colors.white54,
                )
              else
                const SizedBox(width: 64),
                
              const SizedBox(width: 24),
              
              // 录音/停止按钮
              GestureDetector(
                onTap: () {
                  if (recordingState.isRecording) {
                    recordingNotifier.stopRecording();
                  } else {
                    recordingNotifier.startRecording();
                  }
                },
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: recordingState.isRecording ? AppColors.error : AppColors.primary,
                    boxShadow: [
                      BoxShadow(
                        color: (recordingState.isRecording ? AppColors.error : AppColors.primary)
                            .withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    recordingState.isRecording ? Icons.stop : Icons.mic,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
              
              const SizedBox(width: 24),
              
              // 暂停按钮
              if (recordingState.isRecording)
                _buildControlButton(
                  icon: recordingState.isPaused ? Icons.play_arrow : Icons.pause,
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
                const SizedBox(width: 64),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // 提示文字
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
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.2),
      ),
      child: IconButton(
        icon: Icon(icon, color: color),
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
    // 只有当 amplitudes 列表内容变化时才重绘
    if (oldDelegate.amplitudes.length != amplitudes.length) return true;
    for (int i = 0; i < amplitudes.length; i++) {
      if (oldDelegate.amplitudes[i] != amplitudes[i]) return true;
    }
    return false;
  }
}
