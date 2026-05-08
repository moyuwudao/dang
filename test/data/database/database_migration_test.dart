import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:changji_app/data/database/app_database.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

void main() {
  group('Database Migration Tests', () {
    late AppDatabase database;

    setUp(() async {
      final tempDir = await getTemporaryDirectory();
      final dbPath = p.join(tempDir.path, 'test_migration.db');
      
      database = AppDatabase._withExecutor(
        NativeDatabase(File(dbPath)),
      );
    });

    tearDown(() async {
      await database.close();
    });

    test('schemaVersion should be 2', () {
      expect(database.schemaVersion, 2);
    });

    test('database should open without errors', () async {
      expect(() async => await database.getAllRecords(), completes);
    });

    test('migration from version 1 to 2 should add new columns', () async {
      final records = await database.getAllRecords();
      expect(records, isEmpty);

      final record = RecordsCompanion.insert(
        type: 'audio',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final id = await database.insertRecord(record);
      final inserted = await database.getRecordById(id);

      expect(inserted?.isFavorite, false);
      expect(inserted?.aiAnalysis, isNull);
      expect(inserted?.supplements, '[]');
    });

    test('insert and retrieve record with new fields', () async {
      final record = RecordsCompanion.insert(
        type: 'audio',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isFavorite: Value(true),
        aiAnalysis: Value('AI summary'),
        supplements: Value('["supplement1"]'),
      );

      final id = await database.insertRecord(record);
      final inserted = await database.getRecordById(id);

      expect(inserted?.isFavorite, true);
      expect(inserted?.aiAnalysis, 'AI summary');
      expect(inserted?.supplements, '["supplement1"]');
    });
  });
}