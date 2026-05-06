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
      transcriptionStatus: const Value('pending'),
      transcriptionError: const Value.absent(),
      isFavorite: const Value(false),
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

  Future<void> deleteRecord(int id) async {
    await _database.deleteRecord(id);
  }

  Stream<List<RecordModel>> watchAllRecords() {
    return _database.watchAllRecords().map(
          (records) => records.map(_mapToModel).toList(),
        );
  }

  Future<List<RecordModel>> searchRecords(String query) async {
    final records = await _database.searchRecords(query);
    return records.map(_mapToModel).toList();
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
        orElse: () => TranscriptionStatus.pending,
      ),
      transcriptionError: record.transcriptionError,
      isFavorite: record.isFavorite,
    );
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
