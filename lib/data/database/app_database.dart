import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class Records extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()(); // 'audio' or 'ocr'
  TextColumn get content => text().nullable()();
  TextColumn get audioPath => text().nullable()();
  TextColumn get imagePath => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get tags => text().withDefault(const Constant('[]'))();
  TextColumn get transcriptionStatus =>
      text().withDefault(const Constant('none'))();
  TextColumn get transcriptionError => text().nullable()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  TextColumn get aiAnalysis => text().nullable()();
  TextColumn get supplements => text().withDefault(const Constant('[]'))();
}

class ApiConfigs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get provider => text()(); // 'openai' or 'custom'
  TextColumn get apiKey => text()();
  TextColumn get baseUrl => text().nullable()();
  TextColumn get model => text().withDefault(const Constant('whisper-1'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

@DriftDatabase(tables: [Records, ApiConfigs])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase._withExecutor(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await _createFtsTable();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from == 1) {
          await m.addColumn(records, records.isFavorite);
          await m.addColumn(records, records.aiAnalysis);
          await m.addColumn(records, records.supplements);
        }
        if (from <= 2) {
          await _createFtsTable();
        }
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _createFtsTable() async {
    await customStatement('''
      CREATE VIRTUAL TABLE IF NOT EXISTS records_fts 
      USING fts5(content, tags, content_rowid=id)
    ''');
    await customStatement('''
      INSERT INTO records_fts(records_fts) VALUES('rebuild')
    ''');
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'changji_database',
      native: const DriftNativeOptions(),
    );
  }

  // 记录相关操作
  Future<List<Record>> getAllRecords() => select(records).get();

  Future<Record?> getRecordById(int id) {
    return (select(records)..where((r) => r.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertRecord(RecordsCompanion record) =>
      into(records).insert(record);

  Future<bool> updateRecord(RecordsCompanion record) =>
      update(records).replace(record);

  Future<int> updateRecordContent(int id, String content) {
    return (update(records)..where((r) => r.id.equals(id))).write(
      RecordsCompanion(
        content: Value(content),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> updateTranscriptionStatus(int id, String status,
      {String? error}) {
    return (update(records)..where((r) => r.id.equals(id))).write(
      RecordsCompanion(
        transcriptionStatus: Value(status),
        transcriptionError: Value(error),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> updateTags(int id, String tags) {
    return (update(records)..where((r) => r.id.equals(id))).write(
      RecordsCompanion(
        tags: Value(tags),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> updateFavorite(int id, bool isFavorite) {
    return (update(records)..where((r) => r.id.equals(id))).write(
      RecordsCompanion(
        isFavorite: Value(isFavorite),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> updateAiAnalysis(int id, String aiAnalysis) {
    return (update(records)..where((r) => r.id.equals(id))).write(
      RecordsCompanion(
        aiAnalysis: Value(aiAnalysis),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> updateSupplements(int id, String supplements) {
    return (update(records)..where((r) => r.id.equals(id))).write(
      RecordsCompanion(
        supplements: Value(supplements),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> updateRecordType(int id, String type) {
    return (update(records)..where((r) => r.id.equals(id))).write(
      RecordsCompanion(
        type: Value(type),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> deleteRecord(int id) =>
      (delete(records)..where((r) => r.id.equals(id))).go();

  Stream<List<Record>> watchAllRecords() =>
      (select(records)..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  Stream<List<Record>> watchFavoriteRecords() => (select(records)
        ..where((t) => t.isFavorite.equals(true))
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .watch();

  Future<List<Record>> getRecordsWithPagination(int offset, int limit) {
    return (select(records)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit, offset: offset))
        .get();
  }

  Future<int> getRecordCount() async {
    final count = await (selectOnly(records)..addColumns([records.id.count()]))
        .map((row) => row.read(records.id.count()))
        .getSingle();
    return count ?? 0;
  }

  Future<List<Record>> searchRecords(String query) async {
    final result = await customSelect(
      '''
      SELECT r.* FROM records r
      JOIN records_fts fts ON r.id = fts.content_rowid
      WHERE fts MATCH ?
      ORDER BY rank
      ''',
      variables: [Variable<String>(query)],
      readsFrom: {records},
    ).get();

    return result.map((row) => records.map(row.data)).toList();
  }

  Future<List<Record>> searchRecordsWithTags(String query, List<String> tags) async {
    final queryBuilder = select(records);

    if (query.isNotEmpty) {
      queryBuilder.where(
        (r) => r.content.like('%$query%') | r.tags.like('%$query%'),
      );
    }

    if (tags.isNotEmpty) {
      for (final tag in tags) {
        queryBuilder.where((r) => r.tags.like('%$tag%'));
      }
    }

    queryBuilder.orderBy([(t) => OrderingTerm.desc(t.createdAt)]);

    return await queryBuilder.get();
  }

  Future<void> _updateFtsIndex(int id, String content, String tags) async {
    await customStatement(
      'INSERT OR REPLACE INTO records_fts(content_rowid, content, tags) VALUES (?, ?, ?)',
      [id, content ?? '', tags],
    );
  }

  Future<void> _deleteFtsIndex(int id) async {
    await customStatement(
      'DELETE FROM records_fts WHERE content_rowid = ?',
      [id],
    );
  }

  // API配置相关操作
  Future<ApiConfig?> getApiConfig() => select(apiConfigs).getSingleOrNull();

  Future<int> insertApiConfig(ApiConfigsCompanion config) =>
      into(apiConfigs).insert(config);

  Future<bool> updateApiConfig(ApiConfigsCompanion config) =>
      update(apiConfigs).replace(config);

  // 数据库备份与恢复
  Future<String> backupDatabase(String backupPath) async {
    final dbPath = await _getDatabasePath();
    final input = File(dbPath);
    final output = File(backupPath);
    await output.writeAsBytes(await input.readAsBytes());
    return backupPath;
  }

  Future<bool> restoreDatabase(String backupPath) async {
    final input = File(backupPath);
    if (!await input.exists()) {
      return false;
    }

    await close();

    final dbPath = await _getDatabasePath();
    final output = File(dbPath);
    await output.writeAsBytes(await input.readAsBytes());
    return true;
  }

  Future<String> _getDatabasePath() async {
    final dbDir = await getApplicationDocumentsDirectory();
    return '${dbDir.path}/changji_database.sqlite';
  }

  static Future<String> getDatabasePath() async {
    final dbDir = await getApplicationDocumentsDirectory();
    return '${dbDir.path}/changji_database.sqlite';
  }
}
