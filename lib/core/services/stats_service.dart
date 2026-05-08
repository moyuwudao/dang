import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/record_model.dart';

class UsageStats {
  final int totalRecords;
  final int audioRecords;
  final int ocrRecords;
  final int textRecords;
  final int successfulTranscriptions;
  final int failedTranscriptions;
  final int favoriteRecords;
  final int totalTags;
  final int aiSummaryCount;
  final int exportCount;
  final int shareCount;
  final DateTime firstUseDate;
  final DateTime lastUseDate;
  final int daysUsed;
  final Map<String, int> recordsPerDay;
  final Map<String, int> tagsFrequency;

  const UsageStats({
    this.totalRecords = 0,
    this.audioRecords = 0,
    this.ocrRecords = 0,
    this.textRecords = 0,
    this.successfulTranscriptions = 0,
    this.failedTranscriptions = 0,
    this.favoriteRecords = 0,
    this.totalTags = 0,
    this.aiSummaryCount = 0,
    this.exportCount = 0,
    this.shareCount = 0,
    required this.firstUseDate,
    required this.lastUseDate,
    this.daysUsed = 0,
    this.recordsPerDay = const {},
    this.tagsFrequency = const {},
  });

  UsageStats copyWith({
    int? totalRecords,
    int? audioRecords,
    int? ocrRecords,
    int? textRecords,
    int? successfulTranscriptions,
    int? failedTranscriptions,
    int? favoriteRecords,
    int? totalTags,
    int? aiSummaryCount,
    int? exportCount,
    int? shareCount,
    DateTime? firstUseDate,
    DateTime? lastUseDate,
    int? daysUsed,
    Map<String, int>? recordsPerDay,
    Map<String, int>? tagsFrequency,
  }) {
    return UsageStats(
      totalRecords: totalRecords ?? this.totalRecords,
      audioRecords: audioRecords ?? this.audioRecords,
      ocrRecords: ocrRecords ?? this.ocrRecords,
      textRecords: textRecords ?? this.textRecords,
      successfulTranscriptions: successfulTranscriptions ?? this.successfulTranscriptions,
      failedTranscriptions: failedTranscriptions ?? this.failedTranscriptions,
      favoriteRecords: favoriteRecords ?? this.favoriteRecords,
      totalTags: totalTags ?? this.totalTags,
      aiSummaryCount: aiSummaryCount ?? this.aiSummaryCount,
      exportCount: exportCount ?? this.exportCount,
      shareCount: shareCount ?? this.shareCount,
      firstUseDate: firstUseDate ?? this.firstUseDate,
      lastUseDate: lastUseDate ?? this.lastUseDate,
      daysUsed: daysUsed ?? this.daysUsed,
      recordsPerDay: recordsPerDay ?? this.recordsPerDay,
      tagsFrequency: tagsFrequency ?? this.tagsFrequency,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalRecords': totalRecords,
      'audioRecords': audioRecords,
      'ocrRecords': ocrRecords,
      'textRecords': textRecords,
      'successfulTranscriptions': successfulTranscriptions,
      'failedTranscriptions': failedTranscriptions,
      'favoriteRecords': favoriteRecords,
      'totalTags': totalTags,
      'aiSummaryCount': aiSummaryCount,
      'exportCount': exportCount,
      'shareCount': shareCount,
      'firstUseDate': firstUseDate.toIso8601String(),
      'lastUseDate': lastUseDate.toIso8601String(),
      'daysUsed': daysUsed,
      'recordsPerDay': recordsPerDay,
      'tagsFrequency': tagsFrequency,
    };
  }

  static UsageStats fromJson(Map<String, dynamic> json) {
    return UsageStats(
      totalRecords: json['totalRecords'] as int? ?? 0,
      audioRecords: json['audioRecords'] as int? ?? 0,
      ocrRecords: json['ocrRecords'] as int? ?? 0,
      textRecords: json['textRecords'] as int? ?? 0,
      successfulTranscriptions: json['successfulTranscriptions'] as int? ?? 0,
      failedTranscriptions: json['failedTranscriptions'] as int? ?? 0,
      favoriteRecords: json['favoriteRecords'] as int? ?? 0,
      totalTags: json['totalTags'] as int? ?? 0,
      aiSummaryCount: json['aiSummaryCount'] as int? ?? 0,
      exportCount: json['exportCount'] as int? ?? 0,
      shareCount: json['shareCount'] as int? ?? 0,
      firstUseDate: DateTime.parse(json['firstUseDate'] as String),
      lastUseDate: DateTime.parse(json['lastUseDate'] as String),
      daysUsed: json['daysUsed'] as int? ?? 0,
      recordsPerDay: (json['recordsPerDay'] as Map?)?.cast<String, int>() ?? {},
      tagsFrequency: (json['tagsFrequency'] as Map?)?.cast<String, int>() ?? {},
    );
  }
}

class StatsService extends ChangeNotifier {
  static const String _statsKey = 'usage_stats';
  
  UsageStats _stats = UsageStats(
    firstUseDate: DateTime.now(),
    lastUseDate: DateTime.now(),
  );

  UsageStats get stats => _stats;

  Future<void> init() async {
    await _loadStats();
    _updateLastUseDate();
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    final statsJson = prefs.getString(_statsKey);
    
    if (statsJson != null) {
      try {
        final data = jsonDecode(statsJson) as Map<String, dynamic>;
        _stats = UsageStats.fromJson(data);
      } catch (e) {
        debugPrint('Failed to load stats: $e');
      }
    }
  }

  Future<void> _saveStats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_statsKey, jsonEncode(_stats.toJson()));
    notifyListeners();
  }

  void _updateLastUseDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastUse = DateTime(_stats.lastUseDate.year, _stats.lastUseDate.month, _stats.lastUseDate.day);
    
    if (today.isAfter(lastUse)) {
      _stats = _stats.copyWith(
        lastUseDate: now,
        daysUsed: _stats.daysUsed + 1,
      );
      _saveStats();
    }
  }

  void recordCreated(RecordType type) {
    final now = DateTime.now();
    final dateKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    
    final newRecordsPerDay = Map<String, int>.from(_stats.recordsPerDay);
    newRecordsPerDay[dateKey] = (newRecordsPerDay[dateKey] ?? 0) + 1;
    
    _stats = _stats.copyWith(
      totalRecords: _stats.totalRecords + 1,
      audioRecords: type == RecordType.audio ? _stats.audioRecords + 1 : _stats.audioRecords,
      ocrRecords: type == RecordType.ocr ? _stats.ocrRecords + 1 : _stats.ocrRecords,
      textRecords: type == RecordType.text ? _stats.textRecords + 1 : _stats.textRecords,
      lastUseDate: now,
      recordsPerDay: newRecordsPerDay,
    );
    
    _saveStats();
  }

  void transcriptionCompleted(bool success) {
    _stats = _stats.copyWith(
      successfulTranscriptions: success ? _stats.successfulTranscriptions + 1 : _stats.successfulTranscriptions,
      failedTranscriptions: success ? _stats.failedTranscriptions : _stats.failedTranscriptions + 1,
    );
    _saveStats();
  }

  void favoriteToggled(bool isFavorite) {
    _stats = _stats.copyWith(
      favoriteRecords: isFavorite ? _stats.favoriteRecords + 1 : _stats.favoriteRecords - 1,
    );
    _saveStats();
  }

  void tagsAdded(List<String> tags) {
    final newTagsFrequency = Map<String, int>.from(_stats.tagsFrequency);
    
    for (final tag in tags) {
      newTagsFrequency[tag] = (newTagsFrequency[tag] ?? 0) + 1;
    }
    
    _stats = _stats.copyWith(
      totalTags: _stats.totalTags + tags.length,
      tagsFrequency: newTagsFrequency,
    );
    _saveStats();
  }

  void aiSummaryGenerated() {
    _stats = _stats.copyWith(
      aiSummaryCount: _stats.aiSummaryCount + 1,
    );
    _saveStats();
  }

  void exportTriggered() {
    _stats = _stats.copyWith(
      exportCount: _stats.exportCount + 1,
    );
    _saveStats();
  }

  void shareTriggered() {
    _stats = _stats.copyWith(
      shareCount: _stats.shareCount + 1,
    );
    _saveStats();
  }

  void resetStats() {
    _stats = UsageStats(
      firstUseDate: DateTime.now(),
      lastUseDate: DateTime.now(),
    );
    _saveStats();
  }
}