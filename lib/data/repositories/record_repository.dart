import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../models/record_model.dart';

final recordRepositoryProvider = Provider<RecordRepository>((ref) {
  return RecordRepository(ref.watch(databaseProvider));
});

final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

class RecordRepository {
  final AppDatabase _database;

  RecordRepository(this._database);

  Future<List<RecordModel>> getAllRecords() async {
    final records = await _database.getAllRecords();
    return records.map(_mapToModel).toList();
  }

  Future<List<RecordModel>> getRecordsByTags(List<String> tags) async {
    final records = await _database.getRecordsByTags(tags);
    return records.map(_mapToModel).toList();
  }

  Future<RecordModel?> getRecordById(int id) async {
    final record = await _database.getRecordById(id);
    return record != null ? _mapToModel(record) : null;
  }

  Future<int> createRecord({
    required RecordType type,
    String? content,
    String? audioPath,
    String? imagePath,
    List<String> tags = const [],
    TranscriptionStatus? transcriptionStatus,
    bool isRealtime = false,
  }) async {
    final now = DateTime.now();
    final companion = RecordsCompanion(
      type: Value(type.name),
      content: Value(content),
      audioPath: Value(audioPath),
      imagePath: Value(imagePath),
      createdAt: Value(now),
      updatedAt: Value(now),
      tags: Value(jsonEncode(tags)),
      transcriptionStatus: Value(transcriptionStatus?.name ?? 'pending'),
      transcriptionError: const Value.absent(),
      isFavorite: const Value(false),
      isRealtime: Value(isRealtime),
    );
    return await _database.insertRecord(companion);
  }

  Future<void> updateRecordContent(int id, String content) async {
    await _database.updateRecordContent(id, content);
  }

  Future<void> updateTranscriptionStatus(
    int id,
    TranscriptionStatus status, {
    String? error,
  }) async {
    await _database.updateTranscriptionStatus(id, status.name, error: error);
  }

  Future<void> updateTags(int id, List<String> tags) async {
    await _database.updateTags(id, jsonEncode(tags));
  }

  Future<void> toggleFavorite(int id, bool isFavorite) async {
    await _database.updateFavorite(id, isFavorite);
  }

  Future<void> addAiAnalysis(int id, AiAnalysisResult result) async {
    final record = await _database.getRecordById(id);
    if (record == null) return;

    final results = _parseAiAnalysis(record.aiAnalysis ?? '');
    
    final existingIndex = results.indexWhere((r) => r.roleId == result.roleId);
    if (existingIndex >= 0) {
      results[existingIndex] = result;
    } else {
      results.add(result);
    }

    await _database.updateAiAnalysis(id, jsonEncode(results.map((r) => r.toJson()).toList()));
  }

  Future<void> removeAiAnalysis(int id, String roleId) async {
    final record = await _database.getRecordById(id);
    if (record == null) return;

    final results = _parseAiAnalysis(record.aiAnalysis ?? '');
    results.removeWhere((r) => r.roleId == roleId);

    await _database.updateAiAnalysis(id, jsonEncode(results.map((r) => r.toJson()).toList()));
  }

  Future<void> updateSupplements(int id, List<SupplementItem> supplements) async {
    final supplementsJson = supplements.map((s) => s.toJson()).toList();
    await _database.updateSupplements(id, jsonEncode(supplementsJson));
  }

  Future<void> updateRecordType(int id, RecordType type) async {
    await _database.updateRecordType(id, type.name);
  }

  Future<void> deleteRecord(int id) async {
    await _database.deleteRecord(id);
  }

  Stream<List<RecordModel>> watchAllRecords() {
    return _database.watchAllRecords().map(
          (records) => records.map(_mapToModel).toList(),
        );
  }

  Stream<List<RecordModel>> watchFavoriteRecords() {
    return _database.watchFavoriteRecords().map(
          (records) => records.map(_mapToModel).toList(),
        );
  }

  Future<List<RecordModel>> getRecordsWithPagination(int offset, int limit) async {
    final records = await _database.getRecordsWithPagination(offset, limit);
    return records.map(_mapToModel).toList();
  }

  Future<int> getRecordCount() async {
    return await _database.getRecordCount();
  }

  Future<List<RecordModel>> searchRecords(String query) async {
    final records = await _database.searchRecords(query);
    return records.map(_mapToModel).toList();
  }

  Future<List<RecordModel>> searchRecordsWithTags(String query, List<String> tags) async {
    final records = await _database.searchRecordsWithTags(query, tags);
    return records.map(_mapToModel).toList();
  }

  Future<List<String>> getAllTags() async {
    final records = await _database.getAllRecords();
    final tags = <String>{};
    for (final record in records) {
      tags.addAll(_parseTags(record.tags));
    }
    return tags.toList()..sort();
  }

  RecordModel _mapToModel(Record record) {
    return RecordModel(
      id: record.id,
      type: RecordType.values.firstWhere(
        (e) => e.name == record.type,
        orElse: () => RecordType.audio,
      ),
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

  List<AiAnalysisResult> _parseAiAnalysis(String aiAnalysisString) {
    if (aiAnalysisString.isEmpty) return [];
    
    try {
      final dynamic decoded = jsonDecode(aiAnalysisString);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map((item) => AiAnalysisResult.fromJson(item))
            .toList();
      }
      // 兼容旧格式（单个字符串）
      if (aiAnalysisString.isNotEmpty && 
          !aiAnalysisString.startsWith('[') && 
          !aiAnalysisString.startsWith('{')) {
        return [AiAnalysisResult(
          roleId: 'default',
          roleName: '默认分析',
          content: aiAnalysisString,
          createdAt: DateTime.now(),
        )];
      }
    } catch (e) {
      // 解析失败，尝试兼容旧格式
      if (aiAnalysisString.isNotEmpty && 
          !aiAnalysisString.startsWith('[') && 
          !aiAnalysisString.startsWith('{')) {
        return [AiAnalysisResult(
          roleId: 'default',
          roleName: '默认分析',
          content: aiAnalysisString,
          createdAt: DateTime.now(),
        )];
      }
    }
    return [];
  }

  List<SupplementItem> _parseSupplements(String supplementsString) {
    try {
      final dynamic decoded = jsonDecode(supplementsString);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map((item) => SupplementItem.fromJson(item))
            .toList();
      }
    } catch (e) {
      // 如果解析失败，返回空列表
    }
    return [];
  }

  List<String> _parseTags(String tagsString) {
    try {
      final dynamic decoded = jsonDecode(tagsString);
      if (decoded is List) {
        return decoded
            .whereType<String>()
            .where((tag) => tag.isNotEmpty)
            .toList();
      }
    } catch (e) {
      // 如果解析失败，回退到简单的字符串处理
    }
    // 回退处理：兼容旧格式
    if (tagsString.isEmpty || tagsString == '[]') return [];
    return tagsString
        .replaceAll('[', '')
        .replaceAll(']', '')
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
}
