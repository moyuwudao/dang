import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/record_model.dart';
import '../../../data/repositories/record_repository.dart';

class OCRNotifier extends AsyncNotifier<void> {
  RecordRepository get _repository => ref.read(recordRepositoryProvider);

  @override
  Future<void> build() async {
    return;
  }

  Future<void> saveOCRRecord({
    required String imagePath,
    required String content,
    List<String> tags = const [],
  }) async {
    state = const AsyncLoading();
    try {
      await _repository.createRecordFromFields(
        type: RecordType.ocr,
        imagePath: imagePath,
        content: content,
        tags: tags,
        transcriptionStatus: TranscriptionStatus.none,
      );
      state = const AsyncData(null);
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }
}

final ocrNotifierProvider = AsyncNotifierProvider<OCRNotifier, void>(() {
  return OCRNotifier();
});
