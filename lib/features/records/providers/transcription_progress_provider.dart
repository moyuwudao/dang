import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/transcription_progress.dart';

final transcriptionProgressProvider = StateNotifierProvider<TranscriptionProgressNotifier, Map<int, TranscriptionProgress>>((ref) {
  return TranscriptionProgressNotifier();
});

class TranscriptionProgressNotifier extends StateNotifier<Map<int, TranscriptionProgress>> {
  TranscriptionProgressNotifier() : super({});

  void startTranscription(int recordId, {int totalChunks = 1}) {
    state = {
      ...state,
      recordId: TranscriptionProgress(
        totalChunks: totalChunks,
        completedChunks: 0,
        currentAction: '准备转写...',
        steps: [
          TranscriptionStep(name: 'read', description: '读取音频文件'),
          TranscriptionStep(name: 'split', description: '音频分片处理'),
          TranscriptionStep(name: 'upload', description: '上传音频到AI模型'),
          TranscriptionStep(name: 'process', description: 'AI转写处理'),
          TranscriptionStep(name: 'merge', description: '合并转写结果'),
          TranscriptionStep(name: 'save', description: '保存到本地'),
        ],
      ),
    };
  }

  void updateStep(int recordId, String stepName, TranscriptionStepStatus status, {String? detail}) {
    final current = state[recordId];
    if (current == null) return;

    final updatedSteps = current.steps.map((s) {
      if (s.name == stepName) {
        return TranscriptionStep(
          name: s.name,
          description: s.description,
          status: status,
          detail: detail ?? s.detail,
        );
      }
      return s;
    }).toList();

    state = {
      ...state,
      recordId: current.copyWith(steps: updatedSteps),
    };
  }

  void setCurrentAction(int recordId, String action) {
    final current = state[recordId];
    if (current == null) return;

    state = {
      ...state,
      recordId: current.copyWith(currentAction: action),
    };
  }

  void updateChunkProgress(int recordId, int completedChunks) {
    final current = state[recordId];
    if (current == null) return;

    state = {
      ...state,
      recordId: current.copyWith(completedChunks: completedChunks),
    };
  }

  void setTotalChunks(int recordId, int totalChunks) {
    final current = state[recordId];
    if (current == null) return;

    state = {
      ...state,
      recordId: current.copyWith(totalChunks: totalChunks),
    };
  }

  void setError(int recordId, String error) {
    final current = state[recordId];
    if (current == null) return;

    state = {
      ...state,
      recordId: current.copyWith(error: error),
    };
  }

  void updatePartialContent(int recordId, String content) {
    final current = state[recordId];
    if (current == null) return;

    final existingContent = current.partialContent ?? '';
    final newContent = existingContent.isEmpty ? content : '$existingContent\n$content';

    state = {
      ...state,
      recordId: current.copyWith(partialContent: newContent),
    };
  }

  void clear(int recordId) {
    final newState = Map<int, TranscriptionProgress>.from(state);
    newState.remove(recordId);
    state = newState;
  }
}
