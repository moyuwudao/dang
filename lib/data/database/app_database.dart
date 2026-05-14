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
  BoolColumn get isRealtime => boolean().withDefault(const Constant(false))();
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

class ToolOutputs extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get toolId => text()(); // 工具ID
  TextColumn get title => text()(); // 标题
  TextColumn get content => text()(); // 输出内容
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get tags => text().withDefault(const Constant('[]'))();
  TextColumn get sourceRecordIds =>
      text().withDefault(const Constant('[]'))(); // 关联的记录ID列表
  TextColumn get templateId => text().nullable()(); // 使用的模板ID
  IntColumn get usageCount =>
      integer().withDefault(const Constant(0))(); // 使用次数
  BoolColumn get isFavorite =>
      boolean().withDefault(const Constant(false))(); // 是否收藏
}

@DriftDatabase(tables: [Records, ApiConfigs, ToolOutputs])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase._withExecutor(super.executor);

  @override
  int get schemaVersion => 6;

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
        if (from <= 3) {
          await m.createTable(toolOutputs);
        }
        if (from <= 4) {
          await m.addColumn(toolOutputs, toolOutputs.isFavorite);
        }
        if (from <= 5) {
          await m.addColumn(records, records.isRealtime);
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

  Future<List<Record>> getRecordsByTags(List<String> tags) async {
    if (tags.isEmpty) return [];
    final query = select(records);
    for (final tag in tags) {
      query.where((r) => r.tags.like('%$tag%'));
    }
    return query.get();
  }

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

  Future<List<Record>> searchRecordsWithTags(
      String query, List<String> tags) async {
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

  // 工具输出相关操作
  Future<List<ToolOutput>> getAllToolOutputs() =>
      (select(toolOutputs)..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  Future<List<ToolOutput>> getToolOutputsByToolId(String toolId) =>
      (select(toolOutputs)
            ..where((t) => t.toolId.equals(toolId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  Future<ToolOutput?> getToolOutputById(String id) =>
      (select(toolOutputs)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertToolOutput(ToolOutputsCompanion output) =>
      into(toolOutputs).insert(output);

  Future<bool> updateToolOutput(ToolOutputsCompanion output) =>
      update(toolOutputs).replace(output);

  Future<int> updateToolOutputUsageCount(String id) {
    return (update(toolOutputs)..where((t) => t.id.equals(id))).write(
      ToolOutputsCompanion(
        usageCount: const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> updateToolOutputFavorite(String id, bool isFavorite) {
    return (update(toolOutputs)..where((t) => t.id.equals(id))).write(
      ToolOutputsCompanion(
        isFavorite: Value(isFavorite),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> deleteToolOutput(String id) =>
      (delete(toolOutputs)..where((t) => t.id.equals(id))).go();

  Future<List<ToolOutput>> searchToolOutputs(String query) async {
    return (select(toolOutputs)
          ..where((t) => t.title.like('%$query%') | t.content.like('%$query%'))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  Future<int> getToolOutputCount() async {
    final count = await (selectOnly(toolOutputs)
          ..addColumns([toolOutputs.id.count()]))
        .map((row) => row.read(toolOutputs.id.count()))
        .getSingle();
    return count ?? 0;
  }

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
