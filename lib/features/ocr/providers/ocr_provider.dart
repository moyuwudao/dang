import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/record_model.dart';
import '../../../data/repositories/record_repository.dart';

class OCRNotifier extends StateNotifier<AsyncValue<void>> {
  final RecordRepository _repository;

  OCRNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> saveOCRRecord({
    required String imagePath,
    required String content,
    List<String> tags = const [],
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.createRecord(
        type: RecordType.ocr,
        imagePath: imagePath,
        content: content,
        tags: tags,
        transcriptionStatus: TranscriptionStatus.none,
      );
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final ocrNotifierProvider = StateNotifierProvider<OCRNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(recordRepositoryProvider);
  return OCRNotifier(repository);
});
