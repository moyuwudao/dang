import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/record_model.dart';
import '../../../data/repositories/record_repository.dart';

final recordsProvider = StreamProvider<List<RecordModel>>((ref) {
  final repository = ref.watch(recordRepositoryProvider);
  return repository.watchAllRecords();
});

final favoriteRecordsProvider = StreamProvider<List<RecordModel>>((ref) {
  final repository = ref.watch(recordRepositoryProvider);
  return repository.watchFavoriteRecords();
});

final paginatedRecordsProvider = StateNotifierProvider<PaginatedRecordsNotifier, AsyncValue<List<RecordModel>>>((ref) {
  final notifier = PaginatedRecordsNotifier(ref.watch(recordRepositoryProvider));
  ref.listen(recordsProvider, (_, __) {
    notifier.reset();
  });
  return notifier;
});

class PaginatedRecordsNotifier extends StateNotifier<AsyncValue<List<RecordModel>>> {
  final RecordRepository _repository;
  final int _pageSize = 20;
  int _currentPage = 0;
  bool _hasMore = true;
  bool _isLoading = false;

  PaginatedRecordsNotifier(this._repository) : super(const AsyncValue.data([])) {
    loadMore();
  }

  Future<void> loadMore() async {
    if (_isLoading || !_hasMore) return;
    
    _isLoading = true;
    
    try {
      final newRecords = await _repository.getRecordsWithPagination(
        _currentPage * _pageSize,
        _pageSize,
      );
      
      if (newRecords.length < _pageSize) {
        _hasMore = false;
      }
      
      final currentData = state.valueOrNull ?? [];
      state = AsyncValue.data([...currentData, ...newRecords]);
      
      _currentPage++;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    } finally {
      _isLoading = false;
    }
  }

  bool get hasMore => _hasMore;
  bool get isLoading => _isLoading;

  void reset() {
    _currentPage = 0;
    _hasMore = true;
    _isLoading = false;
    state = const AsyncValue.data([]);
    loadMore();
  }
}

final recordDetailProvider = FutureProvider.family<RecordModel?, int>((ref, id) async {
  final repository = ref.watch(recordRepositoryProvider);
  
  // 监听数据库变化，自动刷新详情
  ref.watch(recordsProvider);
  
  return repository.getRecordById(id);
});

final searchRecordsProvider = FutureProvider.family<List<RecordModel>, String>((ref, query) {
  final repository = ref.watch(recordRepositoryProvider);
  return repository.searchRecords(query);
});

final searchRecordsWithTagsProvider = FutureProvider.family<List<RecordModel>, ({String query, List<String> tags})>((ref, params) {
  final repository = ref.watch(recordRepositoryProvider);
  return repository.searchRecordsWithTags(params.query, params.tags);
});

final allTagsProvider = FutureProvider<List<String>>((ref) {
  final repository = ref.watch(recordRepositoryProvider);
  return repository.getAllTags();
});

class RecordNotifier extends StateNotifier<AsyncValue<void>> {
  final RecordRepository _repository;

  RecordNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> createAudioRecord(String audioPath) async {
    state = const AsyncValue.loading();
    try {
      await _repository.createRecordFromFields(
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
      await _repository.createRecordFromFields(
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

  Future<void> addAiAnalysis(int id, AiAnalysisResult result) async {
    try {
      await _repository.addAiAnalysis(id, result);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> removeAiAnalysis(int id, String roleId) async {
    try {
      await _repository.removeAiAnalysis(id, roleId);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateSupplements(int id, List<SupplementItem> supplements) async {
    try {
      await _repository.updateSupplements(id, supplements);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateRecordType(int id, RecordType type) async {
    try {
      await _repository.updateRecordType(id, type);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final recordNotifierProvider = StateNotifierProvider<RecordNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(recordRepositoryProvider);
  return RecordNotifier(repository);
});
