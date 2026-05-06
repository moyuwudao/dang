import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

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
  TextColumn get transcriptionStatus => text().withDefault(const Constant('pending'))();
  TextColumn get transcriptionError => text().nullable()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
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

  @override
  int get schemaVersion => 1;

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

  Future<int> insertRecord(RecordsCompanion record) => into(records).insert(record);

  Future<bool> updateRecord(RecordsCompanion record) => update(records).replace(record);

  Future<int> updateRecordContent(int id, String content) {
    return (update(records)..where((r) => r.id.equals(id))).write(
      RecordsCompanion(
        content: Value(content),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> updateTranscriptionStatus(int id, String status, {String? error}) {
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

  Future<int> deleteRecord(int id) => (delete(records)..where((r) => r.id.equals(id))).go();

  Stream<List<Record>> watchAllRecords() => select(records).watch();

  Future<List<Record>> searchRecords(String query) {
    return (select(records)
          ..where((r) => r.content.contains(query) | r.tags.contains(query)))
        .get();
  }

  // API配置相关操作
  Future<ApiConfig?> getApiConfig() => select(apiConfigs).getSingleOrNull();

  Future<int> insertApiConfig(ApiConfigsCompanion config) => into(apiConfigs).insert(config);

  Future<bool> updateApiConfig(ApiConfigsCompanion config) => update(apiConfigs).replace(config);
}
