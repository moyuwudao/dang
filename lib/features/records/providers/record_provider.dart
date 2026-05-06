import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/record_model.dart';
import '../../../data/repositories/record_repository.dart';

final recordsProvider = StreamProvider<List<RecordModel>>((ref) {
  final repository = ref.watch(recordRepositoryProvider);
  return repository.watchAllRecords();
});

final recordDetailProvider = FutureProvider.family<RecordModel?, int>((ref, id) {
  final repository = ref.watch(recordRepositoryProvider);
  return repository.getRecordById(id);
});

final searchRecordsProvider = FutureProvider.family<List<RecordModel>, String>((ref, query) {
  final repository = ref.watch(recordRepositoryProvider);
  return repository.searchRecords(query);
});

class RecordNotifier extends StateNotifier<AsyncValue<void>> {
  final RecordRepository _repository;

  RecordNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> createAudioRecord(String audioPath) async {
    state = const AsyncValue.loading();
    try {
      await _repository.createRecord(
        type: RecordType.audio,
        audioPath: audioPath,
      );
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> createOCRRecord(String imagePath, String content) async {
    state = const AsyncValue.loading();
    try {
      await _repository.createRecord(
        type: RecordType.ocr,
        imagePath: imagePath,
        content: content,
      );
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateRecordContent(int id, String content) async {
    try {
      await _repository.updateRecordContent(id, content);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateTags(int id, List<String> tags) async {
    try {
      await _repository.updateTags(id, tags);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> toggleFavorite(int id, bool isFavorite) async {
    try {
      await _repository.toggleFavorite(id, isFavorite);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteRecord(int id) async {
    try {
      await _repository.deleteRecord(id);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final recordNotifierProvider = StateNotifierProvider<RecordNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(recordRepositoryProvider);
  return RecordNotifier(repository);
});
