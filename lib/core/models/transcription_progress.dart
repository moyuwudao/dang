class TranscriptionStep {
  final String name;
  final String description;
  TranscriptionStepStatus status;
  String? detail;

  TranscriptionStep({
    required this.name,
    required this.description,
    this.status = TranscriptionStepStatus.pending,
    this.detail,
  });
}

enum TranscriptionStepStatus {
  pending,
  running,
  success,
  failed,
}

class TranscriptionProgress {
  final int totalChunks;
  int completedChunks;
  final List<TranscriptionStep> steps;
  String? currentAction;
  String? error;
  String? partialContent;

  TranscriptionProgress({
    this.totalChunks = 1,
    this.completedChunks = 0,
    List<TranscriptionStep>? steps,
    this.currentAction,
    this.error,
    this.partialContent,
  }) : steps = steps ?? [];

  double get progressPercent => totalChunks > 0 ? completedChunks / totalChunks : 0;

  bool get isCompleted => completedChunks >= totalChunks;

  TranscriptionProgress copyWith({
    int? totalChunks,
    int? completedChunks,
    List<TranscriptionStep>? steps,
    String? currentAction,
    String? error,
    String? partialContent,
  }) {
    return TranscriptionProgress(
      totalChunks: totalChunks ?? this.totalChunks,
      completedChunks: completedChunks ?? this.completedChunks,
      steps: steps ?? this.steps,
      currentAction: currentAction ?? this.currentAction,
      error: error ?? this.error,
      partialContent: partialContent ?? this.partialContent,
    );
  }
}
