import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'app_logger.dart';
import '../../../data/models/record_model.dart';
import '../../../data/repositories/record_repository.dart';

final knowledgeGraphServiceProvider =
    Provider((ref) => KnowledgeGraphService(ref));

class Keyword {
  final String text;
  final double score;
  final int frequency;

  Keyword({
    required this.text,
    required this.score,
    required this.frequency,
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'score': score,
      'frequency': frequency,
    };
  }
}

class RelatedRecord {
  final RecordModel record;
  final double similarity;
  final List<String> sharedKeywords;

  RelatedRecord({
    required this.record,
    required this.similarity,
    required this.sharedKeywords,
  });
}

class KnowledgeGraphService {
  final Ref ref;
  final Map<int, List<Keyword>> _recordKeywords = {};
  static const _storageKey = 'knowledge_graph_keywords';
  bool _loaded = false;

  KnowledgeGraphService(this.ref);

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);
      if (jsonStr != null) {
        final Map<String, dynamic> decoded = jsonDecode(jsonStr);
        for (final entry in decoded.entries) {
          final recordId = int.tryParse(entry.key);
          if (recordId == null) continue;
          final List<dynamic> kwList = entry.value as List<dynamic>;
          _recordKeywords[recordId] = kwList
              .map((item) {
                final map = item as Map<String, dynamic>;
                return Keyword(
                  text: map['text'] ?? '',
                  score: (map['score'] as num?)?.toDouble() ?? 0,
                  frequency: (map['frequency'] as num?)?.toInt() ?? 1,
                );
              })
              .where((k) => k.text.isNotEmpty)
              .toList();
        }
      }
    } catch (e) {
      AppLogger().e('KnowledgeGraph', '加载关键词数据失败: $e');
    }
  }

  Future<void> _persistKeywords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> data = {};
      for (final entry in _recordKeywords.entries) {
        data[entry.key.toString()] =
            entry.value.map((k) => k.toJson()).toList();
      }
      await prefs.setString(_storageKey, jsonEncode(data));
    } catch (e) {
      AppLogger().e('KnowledgeGraph', '持久化关键词数据失败: $e');
    }
  }

  Future<List<Keyword>> extractKeywords(String content) async {
    final apiService = ApiService();

    final prompt = '''
请从以下文本中提取关键词，按照重要性排序：

$content

请按照JSON格式输出，包含以下字段：
- text: 关键词文本
- score: 重要性分数（0-1）
- frequency: 在文本中出现的次数

示例格式：
[
  {"text": "人工智能", "score": 0.9, "frequency": 5}
]
''';

    final response = await apiService.completeChat([
      {'role': 'system', 'content': '你是一个专业的关键词提取助手。请根据文本内容提取最重要的关键词。'},
      {'role': 'user', 'content': prompt},
    ]);

    return _parseKeywords(response);
  }

  Future<void> analyzeRecord(int recordId) async {
    await _ensureLoaded();
    final repository = ref.read(recordRepositoryProvider);
    final record = await repository.getRecordById(recordId);

    if (record == null || record.content == null) return;

    final keywords = await extractKeywords(record.content!);
    _recordKeywords[recordId] = keywords;
    await _persistKeywords();
  }

  Future<void> analyzeAllRecords() async {
    await _ensureLoaded();
    final repository = ref.read(recordRepositoryProvider);
    final records = await repository.getAllRecords();

    for (final record in records) {
      if (record.content != null) {
        await analyzeRecord(record.id);
      }
    }
  }

  Future<List<RelatedRecord>> findRelatedRecords(int recordId,
      {int limit = 5}) async {
    await _ensureLoaded();
    final repository = ref.read(recordRepositoryProvider);
    final currentRecord = await repository.getRecordById(recordId);

    if (currentRecord == null) return [];

    final allRecords = await repository.getAllRecords();
    final filtered = allRecords.where((r) => r.id != recordId).toList();

    if (!_recordKeywords.containsKey(recordId)) {
      await analyzeRecord(recordId);
    }

    final currentKeywords = _recordKeywords[recordId] ?? [];
    final currentKeywordSet =
        currentKeywords.map((k) => k.text.toLowerCase()).toSet();

    final related = <RelatedRecord>[];

    for (final record in filtered) {
      if (!_recordKeywords.containsKey(record.id) && record.content != null) {
        await analyzeRecord(record.id);
      }

      final recordKeywords = _recordKeywords[record.id] ?? [];
      final recordKeywordSet =
          recordKeywords.map((k) => k.text.toLowerCase()).toSet();

      final shared = currentKeywordSet.intersection(recordKeywordSet).toList();
      final unionSize = currentKeywordSet.length + recordKeywordSet.length - shared.length;
      final similarity = unionSize == 0 ? 0.0 : shared.length / unionSize;

      if (similarity > 0 && shared.isNotEmpty) {
        related.add(RelatedRecord(
          record: record,
          similarity: similarity,
          sharedKeywords: shared,
        ));
      }
    }

    related.sort((a, b) => b.similarity.compareTo(a.similarity));
    return related.take(limit).toList();
  }

  Future<List<Keyword>> getTrendingKeywords({int limit = 10}) async {
    await _ensureLoaded();
    final allKeywords = <Keyword>[];

    for (final keywords in _recordKeywords.values) {
      allKeywords.addAll(keywords);
    }

    final frequencyMap = <String, int>{};
    final scoreMap = <String, double>{};

    for (final keyword in allKeywords) {
      frequencyMap[keyword.text] =
          (frequencyMap[keyword.text] ?? 0) + keyword.frequency;
      scoreMap[keyword.text] =
          ((scoreMap[keyword.text] ?? 0) + keyword.score) / 2;
    }

    final trending = frequencyMap.entries
        .map((entry) => Keyword(
              text: entry.key,
              score: scoreMap[entry.key] ?? 0,
              frequency: entry.value,
            ))
        .toList();

    trending.sort((a, b) {
      final scoreCompare = b.score.compareTo(a.score);
      if (scoreCompare != 0) return scoreCompare;
      return b.frequency.compareTo(a.frequency);
    });

    return trending.take(limit).toList();
  }

  Future<List<RecordModel>> searchByKeyword(String keyword,
      {int limit = 10}) async {
    final repository = ref.read(recordRepositoryProvider);
    final records = await repository.getAllRecords();

    final lowerKeyword = keyword.toLowerCase();
    final matched = <RecordModel>[];

    for (final record in records) {
      if (record.content?.toLowerCase().contains(lowerKeyword) ?? false) {
        matched.add(record);
      } else if (record.tags
          .any((tag) => tag.toLowerCase().contains(lowerKeyword))) {
        matched.add(record);
      }
    }

    return matched.take(limit).toList();
  }

  List<Keyword> _parseKeywords(String response) {
    try {
      final jsonStart = response.indexOf('[');
      final jsonEnd = response.lastIndexOf(']');

      if (jsonStart == -1 || jsonEnd == -1) {
        return _parsePlainTextKeywords(response);
      }

      final jsonStr = response.substring(jsonStart, jsonEnd + 1);
      final List<dynamic> jsonList = jsonDecode(jsonStr);

      return jsonList
          .map((item) {
            final map = item as Map<String, dynamic>;
            return Keyword(
              text: map['text'] ?? '',
              score: (map['score'] as num?)?.toDouble() ?? 0,
              frequency: (map['frequency'] as num?)?.toInt() ?? 1,
            );
          })
          .where((k) => k.text.isNotEmpty)
          .toList();
    } catch (e) {
      return _parsePlainTextKeywords(response);
    }
  }

  List<Keyword> _parsePlainTextKeywords(String response) {
    final keywords = <Keyword>{};
    final lines = response.split('\n');

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      final match = RegExp(r'^[\d\-\*]+[\.\s]+(.+)').firstMatch(trimmed);
      if (match != null) {
        keywords.add(Keyword(
          text: match.group(1)!.trim(),
          score: 0.5,
          frequency: 1,
        ));
      }
    }

    return keywords.toList();
  }
}
