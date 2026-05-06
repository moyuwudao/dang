import 'package:flutter_test/flutter_test.dart';
import 'package:changji_app/data/models/record_model.dart';

void main() {
  group('RecordModel', () {
    final testRecord = RecordModel(
      id: 1,
      type: RecordType.audio,
      content: 'Test content',
      audioPath: '/path/to/audio.wav',
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
      tags: ['test', 'audio'],
      transcriptionStatus: TranscriptionStatus.success,
      isFavorite: true,
    );

    test('should create record with correct properties', () {
      expect(testRecord.id, 1);
      expect(testRecord.type, RecordType.audio);
      expect(testRecord.content, 'Test content');
      expect(testRecord.audioPath, '/path/to/audio.wav');
      expect(testRecord.tags, ['test', 'audio']);
      expect(testRecord.transcriptionStatus, TranscriptionStatus.success);
      expect(testRecord.isFavorite, isTrue);
    });

    test('should create record with default values', () {
      final record = RecordModel(
        id: 2,
        type: RecordType.ocr,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(record.content, isNull);
      expect(record.audioPath, isNull);
      expect(record.imagePath, isNull);
      expect(record.tags, isEmpty);
      expect(record.transcriptionStatus, TranscriptionStatus.pending);
      expect(record.transcriptionError, isNull);
      expect(record.isFavorite, isFalse);
    });

    group('copyWith', () {
      test('should copy with new content', () {
        final updated = testRecord.copyWith(content: 'Updated content');
        expect(updated.content, 'Updated content');
        expect(updated.id, testRecord.id);
        expect(updated.type, testRecord.type);
      });

      test('should copy with new status', () {
        final updated = testRecord.copyWith(
          transcriptionStatus: TranscriptionStatus.failed,
          transcriptionError: 'Error message',
        );
        expect(updated.transcriptionStatus, TranscriptionStatus.failed);
        expect(updated.transcriptionError, 'Error message');
      });

      test('should copy with new tags', () {
        final updated = testRecord.copyWith(tags: ['new', 'tags']);
        expect(updated.tags, ['new', 'tags']);
      });

      test('should copy with favorite toggled', () {
        final updated = testRecord.copyWith(isFavorite: false);
        expect(updated.isFavorite, isFalse);
      });

      test('should keep original values when not specified', () {
        final updated = testRecord.copyWith();
        expect(updated.id, testRecord.id);
        expect(updated.content, testRecord.content);
        expect(updated.type, testRecord.type);
      });
    });

    group('RecordType', () {
      test('should have audio and ocr types', () {
        expect(RecordType.values.length, 2);
        expect(RecordType.values, contains(RecordType.audio));
        expect(RecordType.values, contains(RecordType.ocr));
      });
    });

    group('TranscriptionStatus', () {
      test('should have all statuses', () {
        expect(TranscriptionStatus.values.length, 4);
        expect(TranscriptionStatus.values, contains(TranscriptionStatus.pending));
        expect(TranscriptionStatus.values, contains(TranscriptionStatus.processing));
        expect(TranscriptionStatus.values, contains(TranscriptionStatus.success));
        expect(TranscriptionStatus.values, contains(TranscriptionStatus.failed));
      });
    });
  });

  group('ApiConfigModel', () {
    test('should create with required fields', () {
      final config = ApiConfigModel(
        id: 1,
        provider: 'openai',
        apiKey: 'sk-test123',
        model: 'gpt-4o-mini',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      expect(config.id, 1);
      expect(config.provider, 'openai');
      expect(config.apiKey, 'sk-test123');
      expect(config.model, 'gpt-4o-mini');
      expect(config.baseUrl, isNull);
    });

    test('should create with optional baseUrl', () {
      final config = ApiConfigModel(
        id: 1,
        provider: 'custom',
        apiKey: 'key123',
        baseUrl: 'https://custom.api.com',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(config.baseUrl, 'https://custom.api.com');
    });
  });
}
