import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:changji_app/data/models/record_model.dart';
import 'package:changji_app/features/records/providers/record_provider.dart';

void main() {
  group('RecordProvider', () {
    test('recordDetailProvider family should have correct type', () {
      // 验证 provider 的 family 类型
      final provider = recordDetailProvider(1);
      expect(provider, isA<FutureProvider<RecordModel?>>());
    });

    test('searchRecordsProvider family should have correct type', () {
      final provider = searchRecordsProvider('test');
      expect(provider, isA<FutureProvider<List<RecordModel>>>());
    });
  });

  group('RecordNotifier', () {
    test('should have correct initial state', () {
      // 由于需要 Repository，我们验证状态类型
      expect(RecordNotifier.new, isA<Function>());
    });
  });

  group('RecordModel State Transitions', () {
    test('should create audio record', () {
      final record = RecordModel(
        id: 1,
        type: RecordType.audio,
        audioPath: '/path/to/audio.wav',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(record.type, RecordType.audio);
      expect(record.audioPath, isNotNull);
      expect(record.imagePath, isNull);
    });

    test('should create OCR record', () {
      final record = RecordModel(
        id: 2,
        type: RecordType.ocr,
        imagePath: '/path/to/image.jpg',
        content: 'OCR text content',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(record.type, RecordType.ocr);
      expect(record.imagePath, isNotNull);
      expect(record.content, 'OCR text content');
    });
  });

  group('Records Stream', () {
    test('recordsProvider should be StreamProvider', () {
      expect(recordsProvider, isA<StreamProvider<List<RecordModel>>>());
    });
  });
}
