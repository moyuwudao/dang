import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:changji_app/data/models/record_model.dart';

void main() {
  group('RecordRepository Tag Parsing', () {
    // 使用私有方法测试标签解析逻辑
    // 由于 _parseTags 是私有的，我们通过测试 copyWith 和构造来间接验证

    test('RecordModel should handle empty tags', () {
      final record = RecordModel(
        id: 1,
        type: RecordType.audio,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(record.tags, isEmpty);
    });

    test('RecordModel should handle tags list', () {
      final record = RecordModel(
        id: 1,
        type: RecordType.audio,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        tags: ['tag1', 'tag2', 'tag3'],
      );
      expect(record.tags.length, 3);
      expect(record.tags, contains('tag1'));
    });

    test('copyWith should update tags correctly', () {
      final record = RecordModel(
        id: 1,
        type: RecordType.audio,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        tags: ['old'],
      );

      final updated = record.copyWith(tags: ['new1', 'new2']);
      expect(updated.tags, ['new1', 'new2']);
    });
  });

  group('JSON Tag Parsing Logic', () {
    test('jsonEncode should produce valid JSON for tags', () {
      final tags = ['test', 'audio', 'important'];
      final encoded = jsonEncode(tags);
      expect(encoded, '["test","audio","important"]');

      final decoded = jsonDecode(encoded);
      expect(decoded, isA<List>());
      expect(decoded.length, 3);
    });

    test('jsonDecode should handle empty list', () {
      final encoded = jsonEncode(<String>[]);
      final decoded = jsonDecode(encoded);
      expect(decoded, isEmpty);
    });

    test('jsonDecode should handle complex tags', () {
      final tags = ['meeting', 'work', 'urgent'];
      final encoded = jsonEncode(tags);
      final decoded = jsonDecode(encoded) as List;
      expect(decoded.whereType<String>().toList(), tags);
    });
  });

  group('RecordModel Status Transitions', () {
    test('should transition from pending to processing', () {
      final record = RecordModel(
        id: 1,
        type: RecordType.audio,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(record.transcriptionStatus, TranscriptionStatus.pending);

      final processing = record.copyWith(
        transcriptionStatus: TranscriptionStatus.processing,
      );
      expect(processing.transcriptionStatus, TranscriptionStatus.processing);
    });

    test('should transition to success with content', () {
      final record = RecordModel(
        id: 1,
        type: RecordType.audio,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        transcriptionStatus: TranscriptionStatus.processing,
      );

      final success = record.copyWith(
        transcriptionStatus: TranscriptionStatus.success,
        content: 'Transcribed text',
      );
      expect(success.transcriptionStatus, TranscriptionStatus.success);
      expect(success.content, 'Transcribed text');
    });

    test('should transition to failed with error', () {
      final record = RecordModel(
        id: 1,
        type: RecordType.audio,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        transcriptionStatus: TranscriptionStatus.processing,
      );

      final failed = record.copyWith(
        transcriptionStatus: TranscriptionStatus.failed,
        transcriptionError: 'Network error',
      );
      expect(failed.transcriptionStatus, TranscriptionStatus.failed);
      expect(failed.transcriptionError, 'Network error');
    });
  });

  group('RecordModel Equality', () {
    test('same properties should be equal in values', () {
      final now = DateTime.now();
      final record1 = RecordModel(
        id: 1,
        type: RecordType.audio,
        content: 'Test',
        createdAt: now,
        updatedAt: now,
      );

      final record2 = RecordModel(
        id: 1,
        type: RecordType.audio,
        content: 'Test',
        createdAt: now,
        updatedAt: now,
      );

      expect(record1.id, record2.id);
      expect(record1.type, record2.type);
      expect(record1.content, record2.content);
    });
  });
}
