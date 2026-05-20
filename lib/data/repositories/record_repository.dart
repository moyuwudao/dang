import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../models/record_model.dart';

final recordRepositoryProvider = Provider<RecordRepository>((ref) {
  return RecordRepository(ref.watch(appDatabaseProvider));
});

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

class RecordRepository {
  final AppDatabase _database;

  RecordRepository(this._database);

  Future<List<RecordModel>> getAllRecords() async {
    final records = await _database.getAllRecords();
    return records.map((record) => _mapToModel(record)).toList();
  }

  Future<List<RecordModel>> getRecordsWithPagination(int offset, int limit) async {
    final query = _database.select(_database.records)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(limit, offset: offset);
    final records = await query.get();
    return records.map(_mapToModel).toList();
  }

  Future<RecordModel?> getRecord(int id) async {
    final record = await _database.getRecord(id);
    if (record == null) return null;
    return _mapToModel(record);
  }

  Future<int> createRecord(RecordModel record) async {
    return await _database.insertRecord(
      RecordsCompanion(
        type: Value(record.type.name),
        content: Value(record.content),
        audioPath: Value(record.audioPath),
        imagePath: Value(record.imagePath),
        createdAt: Value(record.createdAt),
        updatedAt: Value(record.updatedAt),
        tags: Value(jsonEncode(record.tags)),
        transcriptionStatus: Value(record.transcriptionStatus.name),
        transcriptionError: Value(record.transcriptionError),
        isFavorite: Value(record.isFavorite),
        aiAnalysis: Value(record.aiAnalysis != null
            ? jsonEncode(record.aiAnalysisResults.map((r) => r.toJson()).toList())
            : null),
        supplements: Value(jsonEncode(record.supplements.map((s) => s.toJson()).toList())),
        isRealtime: Value(record.isRealtime),
      ),
    );
  }

  /// Convenience method to create a record with individual fields
  Future<int> createRecordFromFields({
    required RecordType type,
    String? content,
    String? audioPath,
    String? imagePath,
    List<String> tags = const [],
    TranscriptionStatus transcriptionStatus = TranscriptionStatus.none,
    String? transcriptionError,
    bool isRealtime = false,
  }) async {
    final record = RecordModel(
      id: 0, // Will be auto-generated
      type: type,
      content: content,
      audioPath: audioPath,
      imagePath: imagePath,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      tags: tags,
      transcriptionStatus: transcriptionStatus,
      transcriptionError: transcriptionError,
      isRealtime: isRealtime,
    );
    return createRecord(record);
  }

  Future<void> updateRecord(RecordModel record) async {
    await _database.updateRecord(
      RecordsCompanion(
        id: Value(record.id),
        type: Value(record.type.name),
        content: Value(record.content),
        audioPath: Value(record.audioPath),
        imagePath: Value(record.imagePath),
        createdAt: Value(record.createdAt),
        updatedAt: Value(record.updatedAt),
        tags: Value(jsonEncode(record.tags)),
        transcriptionStatus: Value(record.transcriptionStatus.name),
        transcriptionError: Value(record.transcriptionError),
        isFavorite: Value(record.isFavorite),
        aiAnalysis: Value(record.aiAnalysisResults.isNotEmpty
            ? jsonEncode(record.aiAnalysisResults.map((r) => r.toJson()).toList())
            : null),
        supplements: Value(jsonEncode(record.supplements.map((s) => s.toJson()).toList())),
        isRealtime: Value(record.isRealtime),
      ),
    );
  }

  Future<void> updateRecordContent(int id, String content) async {
    await _database.updateRecordContent(id, content);
  }

  Future<void> updateTranscriptionStatus(
      int id, TranscriptionStatus status, String? error) async {
    await _database.updateTranscriptionStatus(id, status.name, error);
  }

  Future<void> addAiAnalysis(int id, AiAnalysisResult analysis) async {
    final record = await getRecord(id);
    if (record == null) return;

    final updatedResults = [...record.aiAnalysisResults, analysis];
    await _database.updateAiAnalysis(
      id,
      jsonEncode(updatedResults.map((r) => r.toJson()).toList()),
    );
  }

  Future<void> removeAiAnalysis(int id, String roleId) async {
    final record = await getRecord(id);
    if (record == null) return;

    final updatedResults = record.aiAnalysisResults
        .where((r) => r.roleId != roleId)
        .toList();
    await _database.updateAiAnalysis(
      id,
      updatedResults.isNotEmpty
          ? jsonEncode(updatedResults.map((r) => r.toJson()).toList())
          : null,
    );
  }

  Future<void> updateRecordTags(int id, List<String> tags) async {
    await _database.updateRecordTags(id, tags);
  }

  Future<void> updateRecordFavorite(int id, bool isFavorite) async {
    await _database.updateRecordFavorite(id, isFavorite);
  }

  Future<void> updateRecordType(int id, RecordType type) async {
    await _database.updateRecordType(id, type.name);
  }

  Future<void> deleteRecord(int id) async {
    await _database.deleteRecord(id);
  }

  Future<void> updateSupplements(int id, List<SupplementItem> supplements) async {
    await _database.updateSupplements(
      id,
      jsonEncode(supplements.map((s) => s.toJson()).toList()),
    );
  }

  Future<void> updateTags(int id, List<String> tags) async {
    await _database.updateTags(id, jsonEncode(tags));
  }

  Future<void> toggleFavorite(int id, bool isFavorite) async {
    await _database.updateFavorite(id, isFavorite);
  }

  Stream<List<RecordModel>> watchAllRecords() {
    return _database.select(_database.records)
        .watch()
        .map((records) => records.map(_mapToModel).toList());
  }

  Stream<List<RecordModel>> watchFavoriteRecords() {
    return (_database.select(_database.records)
          ..where((r) => r.isFavorite.equals(true)))
        .watch()
        .map((records) => records.map(_mapToModel).toList());
  }

  Future<RecordModel?> getRecordById(int id) async {
    return getRecord(id);
  }

  Future<List<RecordModel>> searchRecords(String query) async {
    final allRecords = await getAllRecords();
    final lowerQuery = query.toLowerCase();
    return allRecords.where((r) {
      return (r.content?.toLowerCase().contains(lowerQuery) ?? false) ||
          r.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  Future<List<RecordModel>> searchRecordsWithTags(String query, List<String> tags) async {
    final allRecords = await getAllRecords();
    final lowerQuery = query.toLowerCase();
    return allRecords.where((r) {
      final matchesQuery = (r.content?.toLowerCase().contains(lowerQuery) ?? false) ||
          r.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
      final matchesTags = tags.isEmpty || tags.any((tag) => r.tags.contains(tag));
      return matchesQuery && matchesTags;
    }).toList();
  }

  RecordModel _mapToModel(Record record) {
    return RecordModel(
      id: record.id,
      type: RecordType.values.firstWhere((e) => e.name == record.type),
      content: record.content,
      audioPath: record.audioPath,
      imagePath: record.imagePath,
      createdAt: record.createdAt,
      updatedAt: record.updatedAt,
      tags: _parseTags(record.tags),
      transcriptionStatus: TranscriptionStatus.values.firstWhere(
        (e) => e.name == record.transcriptionStatus,
        orElse: () => TranscriptionStatus.none,
      ),
      transcriptionError: record.transcriptionError,
      isFavorite: record.isFavorite,
      aiAnalysisResults: _parseAiAnalysis(record.aiAnalysis ?? ''),
      supplements: _parseSupplements(record.supplements),
      isRealtime: record.isRealtime,
    );
  }

  List<String> _parseTags(String tagsString) {
    try {
      final dynamic decoded = jsonDecode(tagsString);
      if (decoded is List) {
        return decoded.cast<String>();
      }
    } catch (e) {
      // 如果解析失败，尝试按逗号分割
      return tagsString.split(',').where((s) => s.isNotEmpty).toList();
    }
    return [];
  }

  List<AiAnalysisResult> _parseAiAnalysis(String analysisString) {
    try {
      final dynamic decoded = jsonDecode(analysisString);
      if (decoded is List) {
        return decoded
            .map((item) => AiAnalysisResult.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      // 如果解析失败，返回空列表
    }
    return [];
  }

  List<SupplementItem> _parseSupplements(String supplementsString) {
    try {
      final dynamic decoded = jsonDecode(supplementsString);
      if (decoded is List) {
        return decoded
            .map((item) => SupplementItem.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      // 如果解析失败，返回空列表
    }
    return [];
  }

  Future<List<String>> getAllTags() async {
    final records = await getAllRecords();
    final allTags = <String>{};
    for (final record in records) {
      allTags.addAll(record.tags);
    }
    return allTags.toList()..sort();
  }
}
