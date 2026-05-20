import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/record_model.dart';
import '../../../data/repositories/record_repository.dart';

class QuickNoteState {
  final bool isSaving;
  final bool saved;
  final String? error;

  const QuickNoteState({
    this.isSaving = false,
    this.saved = false,
    this.error,
  });

  QuickNoteState copyWith({
    bool? isSaving,
    bool? saved,
    String? error,
  }) {
    return QuickNoteState(
      isSaving: isSaving ?? this.isSaving,
      saved: saved ?? this.saved,
      error: error,
    );
  }
}

class QuickNoteNotifier extends StateNotifier<QuickNoteState> {
  final RecordRepository _repository;

  QuickNoteNotifier(this._repository) : super(const QuickNoteState());

  Future<void> saveNote(String content, List<String> tags) async {
    if (content.trim().isEmpty) {
      state = state.copyWith(error: '内容不能为空');
      return;
    }
    state = state.copyWith(isSaving: true, error: null);
    try {
      await _repository.createRecordFromFields(
        type: RecordType.text,
        content: content,
        tags: tags,
        transcriptionStatus: TranscriptionStatus.none,
      );
      state = state.copyWith(isSaving: false, saved: true);
    } catch (e) {
      state = state.copyWith(isSaving: false, error: '保存失败: $e');
    }
  }
}

final quickNoteProvider = StateNotifierProvider<QuickNoteNotifier, QuickNoteState>((ref) {
  final repository = ref.watch(recordRepositoryProvider);
  return QuickNoteNotifier(repository);
});
