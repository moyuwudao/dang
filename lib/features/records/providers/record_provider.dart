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

final paginatedRecordsProvider = AsyncNotifierProvider<PaginatedRecordsNotifier, List<RecordModel>>(() {
  return PaginatedRecordsNotifier();
});

class PaginatedRecordsNotifier extends AsyncNotifier<List<RecordModel>> {
  final int _pageSize = 20;
  int _currentPage = 0;
  bool _hasMore = true;
  bool _isLoading = false;
  bool _isResetting = false;

  RecordRepository get _repository => ref.read(recordRepositoryProvider);

  @override
  Future<List<RecordModel>> build() async {
    _currentPage = 0;
    _hasMore = true;
    _isLoading = false;
    return _fetchPage(0);
  }

  Future<List<RecordModel>> _fetchPage(int page) async {
    if (_isLoading || !_hasMore) return state.valueOrNull ?? [];

    _isLoading = true;

    try {
      final newRecords = await _repository.getRecordsWithPagination(
        page * _pageSize,
        _pageSize,
      );

      if (newRecords.length < _pageSize) {
        _hasMore = false;
      }

      _currentPage = page + 1;
      return newRecords;
    } catch (e, stack) {
      throw AsyncError(e, stack);
    } finally {
      _isLoading = false;
    }
  }

  Future<List<RecordModel>> _loadMoreInternal() async {
    if (_isLoading || !_hasMore) return state.valueOrNull ?? [];

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
      _currentPage++;
      return [...currentData, ...newRecords];
    } catch (e, stack) {
      throw AsyncError(e, stack);
    } finally {
      _isLoading = false;
    }
  }

  Future<void> loadMore() async {
    if (_isLoading || !_hasMore) return;

    state = const AsyncLoading();
    try {
      final newRecords = await _repository.getRecordsWithPagination(
        _currentPage * _pageSize,
        _pageSize,
      );

      if (newRecords.length < _pageSize) {
        _hasMore = false;
      }

      final currentData = state.valueOrNull ?? [];
      _currentPage++;
      state = AsyncData([...currentData, ...newRecords]);
    } catch (e, stack) {
      state = AsyncError(e, stack);
    } finally {
      _isLoading = false;
    }
  }

  bool get hasMore => _hasMore;
  bool get isLoading => _isLoading;

  Future<void> reset() async {
    if (_isResetting) return;
    _isResetting = true;
    state = const AsyncLoading();
    try {
      _currentPage = 0;
      _hasMore = true;
      _isLoading = false;
      final records = await _fetchPage(0);
      state = AsyncData(records);
    } catch (e, stack) {
      state = AsyncError(e, stack);
    } finally {
      _isResetting = false;
    }
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

class RecordNotifier extends AsyncNotifier<void> {
  RecordRepository get _repository => ref.read(recordRepositoryProvider);

  @override
  Future<void> build() async {
    // 不需要初始化状态
    return;
  }

  Future<void> createAudioRecord(String audioPath) async {
    state = const AsyncLoading();
    try {
      await _repository.createRecordFromFields(
        type: RecordType.audio,
        audioPath: audioPath,
      );
      state = const AsyncData(null);
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  Future<void> createOCRRecord(String imagePath, String content) async {
    state = const AsyncLoading();
    try {
      await _repository.createRecordFromFields(
        type: RecordType.ocr,
        imagePath: imagePath,
        content: content,
      );
      state = const AsyncData(null);
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  Future<void> updateRecordContent(int id, String content) async {
    try {
      await _repository.updateRecordContent(id, content);
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  Future<void> updateTags(int id, List<String> tags) async {
    try {
      await _repository.updateTags(id, tags);
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  Future<void> toggleFavorite(int id, bool isFavorite) async {
    try {
      await _repository.toggleFavorite(id, isFavorite);
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  Future<void> deleteRecord(int id) async {
    try {
      await _repository.deleteRecord(id);
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  Future<void> addAiAnalysis(int id, AiAnalysisResult result) async {
    try {
      await _repository.addAiAnalysis(id, result);
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  Future<void> removeAiAnalysis(int id, String roleId) async {
    try {
      await _repository.removeAiAnalysis(id, roleId);
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  Future<void> updateSupplements(int id, List<SupplementItem> supplements) async {
    try {
      await _repository.updateSupplements(id, supplements);
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  Future<void> updateRecordType(int id, RecordType type) async {
    try {
      await _repository.updateRecordType(id, type);
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }
}

final recordNotifierProvider = AsyncNotifierProvider<RecordNotifier, void>(() {
  return RecordNotifier();
});
