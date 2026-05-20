import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

class Records extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()(); // 'audio', 'ocr', 'text'
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
  TextColumn get provider => text()();
  TextColumn get apiKey => text()();
  TextColumn get baseUrl => text().nullable()();
  TextColumn get model => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

class ToolOutputs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get toolId => text()();
  TextColumn get title => text()();
  TextColumn get content => text()();
  TextColumn get sourceRecordIds => text().withDefault(const Constant('[]'))();
  TextColumn get templateId => text().nullable()();
  TextColumn get tags => text().withDefault(const Constant('[]'))();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  IntColumn get usageCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

@DriftDatabase(tables: [Records, ApiConfigs, ToolOutputs])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 7;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'changji_database',
    );
  }

  static Future<String> getDatabasePath() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    return p.join(dbFolder.path, 'changji_database.sqlite');
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from <= 6) {
            await _addIsRealtimeColumnIfNotExists(m);
          }
        },
      );

  Future<void> _addIsRealtimeColumnIfNotExists(Migrator m) async {
    final result = await customSelect(
      '''
      SELECT COUNT(*) as count 
      FROM pragma_table_info('records') 
      WHERE name = 'is_realtime'
      ''',
      readsFrom: {records},
    ).getSingle();
    
    final columnExists = result.data['count'] as int? ?? 0;
    
    if (columnExists == 0) {
      await m.addColumn(records, records.isRealtime);
    }
  }

  // Records
  Future<List<Record>> getAllRecords() => select(records).get();

  Future<Record?> getRecord(int id) =>
      (select(records)..where((r) => r.id.equals(id))).getSingleOrNull();

  Future<int> insertRecord(RecordsCompanion record) =>
      into(records).insert(record);

  Future<bool> updateRecord(RecordsCompanion record) =>
      update(records).replace(record);

  Future<int> deleteRecord(int id) =>
      (delete(records)..where((r) => r.id.equals(id))).go();

  Future<void> updateRecordContent(int id, String content) async {
    await (update(records)..where((r) => r.id.equals(id))).write(
      RecordsCompanion(
        content: Value(content),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateTranscriptionStatus(
      int id, String status, String? error) async {
    await (update(records)..where((r) => r.id.equals(id))).write(
      RecordsCompanion(
        transcriptionStatus: Value(status),
        transcriptionError: error != null ? Value(error) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateAiAnalysis(int id, String? analysis) async {
    await (update(records)..where((r) => r.id.equals(id))).write(
      RecordsCompanion(
        aiAnalysis: analysis != null ? Value(analysis) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateRecordTags(int id, List<String> tags) async {
    await (update(records)..where((r) => r.id.equals(id))).write(
      RecordsCompanion(
        tags: Value(tags.join(',')),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateRecordFavorite(int id, bool isFavorite) async {
    await (update(records)..where((r) => r.id.equals(id))).write(
      RecordsCompanion(
        isFavorite: Value(isFavorite),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateRecordType(int id, String type) async {
    await (update(records)..where((r) => r.id.equals(id))).write(
      RecordsCompanion(
        type: Value(type),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // ApiConfigs
  Future<List<ApiConfig>> getAllApiConfigs() => select(apiConfigs).get();

  Future<ApiConfig?> getApiConfig(int id) =>
      (select(apiConfigs)..where((a) => a.id.equals(id))).getSingleOrNull();

  Future<ApiConfig?> getApiConfigByProvider(String provider) =>
      (select(apiConfigs)..where((a) => a.provider.equals(provider)))
          .getSingleOrNull();

  Future<int> insertApiConfig(ApiConfigsCompanion config) =>
      into(apiConfigs).insert(config);

  Future<bool> updateApiConfig(ApiConfigsCompanion config) =>
      update(apiConfigs).replace(config);

  Future<int> deleteApiConfig(int id) =>
      (delete(apiConfigs)..where((a) => a.id.equals(id))).go();

  // ToolOutputs
  Future<List<ToolOutput>> getAllToolOutputs() => select(toolOutputs).get();

  Future<ToolOutput?> getToolOutput(int id) =>
      (select(toolOutputs)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<ToolOutput>> getToolOutputsByToolId(String toolId) =>
      (select(toolOutputs)..where((t) => t.toolId.equals(toolId))).get();

  Future<int> insertToolOutput(ToolOutputsCompanion output) =>
      into(toolOutputs).insert(output);

  Future<bool> updateToolOutput(ToolOutputsCompanion output) =>
      update(toolOutputs).replace(output);

  Future<int> deleteToolOutputById(int id) =>
      (delete(toolOutputs)..where((t) => t.id.equals(id))).go();

  Future<ToolOutput?> getToolOutputById(int id) =>
      (select(toolOutputs)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> updateToolOutputUsageCount(int id) async {
    final output = await getToolOutputById(id);
    if (output != null) {
      final companion = ToolOutputsCompanion(
        id: Value(output.id),
        toolId: Value(output.toolId),
        title: Value(output.title),
        content: Value(output.content),
        createdAt: Value(output.createdAt),
        updatedAt: Value(DateTime.now()),
        tags: Value(output.tags),
        sourceRecordIds: Value(output.sourceRecordIds),
        templateId: Value(output.templateId),
        usageCount: Value(output.usageCount + 1),
        isFavorite: Value(output.isFavorite),
      );
      await updateToolOutput(companion);
    }
  }

  Future<void> updateSupplements(int id, String supplements) async {
    await (update(records)..where((r) => r.id.equals(id))).write(
      RecordsCompanion(
        supplements: Value(supplements),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateTags(int id, String tags) async {
    await (update(records)..where((r) => r.id.equals(id))).write(
      RecordsCompanion(
        tags: Value(tags),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateFavorite(int id, bool isFavorite) async {
    await (update(records)..where((r) => r.id.equals(id))).write(
      RecordsCompanion(
        isFavorite: Value(isFavorite),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
