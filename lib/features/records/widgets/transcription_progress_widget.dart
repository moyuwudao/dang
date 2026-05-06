import 'package:flutter/material.dart';
import '../../../core/models/transcription_progress.dart';
import '../../../core/theme/app_colors.dart';

class TranscriptionProgressWidget extends StatelessWidget {
  final TranscriptionProgress progress;

  const TranscriptionProgressWidget({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sync, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '转写进度',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                if (progress.isCompleted)
                  Icon(Icons.check_circle, color: AppColors.success, size: 20)
                else if (progress.error != null)
                  Icon(Icons.error, color: AppColors.error, size: 20)
                else
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Progress bar
            if (progress.totalChunks > 1) ...[
              LinearProgressIndicator(
                value: progress.progressPercent,
                backgroundColor: Colors.grey.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress.error != null ? AppColors.error : AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '分片进度: ${progress.completedChunks}/${progress.totalChunks}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
            ],

            // Current action
            if (progress.currentAction != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        progress.currentAction!,
                        style: TextStyle(color: AppColors.primary, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Error message
            if (progress.error != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, size: 16, color: AppColors.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        progress.error!,
                        style: TextStyle(color: AppColors.error, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Steps
            ...progress.steps.map((step) => _buildStepItem(context, step)),
          ],
        ),
      ),
    );
  }

  Widget _buildStepItem(BuildContext context, TranscriptionStep step) {
    IconData icon;
    Color color;

    switch (step.status) {
      case TranscriptionStepStatus.pending:
        icon = Icons.circle_outlined;
        color = Colors.grey;
        break;
      case TranscriptionStepStatus.running:
        icon = Icons.sync;
        color = AppColors.info;
        break;
      case TranscriptionStepStatus.success:
        icon = Icons.check_circle;
        color = AppColors.success;
        break;
      case TranscriptionStepStatus.failed:
        icon = Icons.error;
        color = AppColors.error;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              step.description,
              style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: step.status == TranscriptionStepStatus.running ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
          if (step.detail != null)
            Text(
              step.detail!,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
        ],
      ),
    );
  }
}
