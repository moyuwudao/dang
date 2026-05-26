import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/record_model.dart';
import 'app_logger.dart';

final statsServiceProvider = AsyncNotifierProvider<StatsNotifier, UsageStats>(() {
  return StatsNotifier();
});

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
  final int apiTextCalls;
  final int apiVoiceCalls;
  final int apiImageCalls;
  final int apiSuccessCalls;
  final int apiFailedCalls;
  final Map<String, int> apiCallsPerDay;
  final Map<String, int> apiCallsByTool;

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
    this.apiTextCalls = 0,
    this.apiVoiceCalls = 0,
    this.apiImageCalls = 0,
    this.apiSuccessCalls = 0,
    this.apiFailedCalls = 0,
    this.apiCallsPerDay = const {},
    this.apiCallsByTool = const {},
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
    int? apiTextCalls,
    int? apiVoiceCalls,
    int? apiImageCalls,
    int? apiSuccessCalls,
    int? apiFailedCalls,
    Map<String, int>? apiCallsPerDay,
    Map<String, int>? apiCallsByTool,
  }) {
    return UsageStats(
      totalRecords: totalRecords ?? this.totalRecords,
      audioRecords: audioRecords ?? this.audioRecords,
      ocrRecords: ocrRecords ?? this.ocrRecords,
      textRecords: textRecords ?? this.textRecords,
      successfulTranscriptions:
          successfulTranscriptions ?? this.successfulTranscriptions,
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
      apiTextCalls: apiTextCalls ?? this.apiTextCalls,
      apiVoiceCalls: apiVoiceCalls ?? this.apiVoiceCalls,
      apiImageCalls: apiImageCalls ?? this.apiImageCalls,
      apiSuccessCalls: apiSuccessCalls ?? this.apiSuccessCalls,
      apiFailedCalls: apiFailedCalls ?? this.apiFailedCalls,
      apiCallsPerDay: apiCallsPerDay ?? this.apiCallsPerDay,
      apiCallsByTool: apiCallsByTool ?? this.apiCallsByTool,
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
      'apiTextCalls': apiTextCalls,
      'apiVoiceCalls': apiVoiceCalls,
      'apiImageCalls': apiImageCalls,
      'apiSuccessCalls': apiSuccessCalls,
      'apiFailedCalls': apiFailedCalls,
      'apiCallsPerDay': apiCallsPerDay,
      'apiCallsByTool': apiCallsByTool,
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
      apiTextCalls: json['apiTextCalls'] as int? ?? 0,
      apiVoiceCalls: json['apiVoiceCalls'] as int? ?? 0,
      apiImageCalls: json['apiImageCalls'] as int? ?? 0,
      apiSuccessCalls: json['apiSuccessCalls'] as int? ?? 0,
      apiFailedCalls: json['apiFailedCalls'] as int? ?? 0,
      apiCallsPerDay:
          (json['apiCallsPerDay'] as Map?)?.cast<String, int>() ?? {},
      apiCallsByTool:
          (json['apiCallsByTool'] as Map?)?.cast<String, int>() ?? {},
    );
  }

  int get totalApiCalls => apiTextCalls + apiVoiceCalls + apiImageCalls;
  double get apiSuccessRate =>
      totalApiCalls > 0 ? (apiSuccessCalls / totalApiCalls) * 100 : 0;
}

class StatsNotifier extends AsyncNotifier<UsageStats> {
  static const String _statsKey = 'usage_stats';

  @override
  Future<UsageStats> build() async {
    final stats = await _loadStats();
    return _updateLastUseDate(stats);
  }

  Future<UsageStats> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    final statsJson = prefs.getString(_statsKey);

    if (statsJson != null) {
      try {
        final data = jsonDecode(statsJson) as Map<String, dynamic>;
        return UsageStats.fromJson(data);
      } catch (e) {
        AppLogger().e('Stats', 'Failed to load stats: $e');
      }
    }
    return UsageStats(
      firstUseDate: DateTime.now(),
      lastUseDate: DateTime.now(),
    );
  }

  Future<void> _saveStats(UsageStats stats) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_statsKey, jsonEncode(stats.toJson()));
  }

  UsageStats _updateLastUseDate(UsageStats stats) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastUse = DateTime(stats.lastUseDate.year, stats.lastUseDate.month,
        stats.lastUseDate.day);

    if (today.isAfter(lastUse)) {
      final newStats = stats.copyWith(
        lastUseDate: now,
        daysUsed: stats.daysUsed + 1,
      );
      _saveStats(newStats);
      return newStats;
    }
    return stats;
  }

  Future<void> recordCreated(RecordType type) async {
    final now = DateTime.now();
    final dateKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final newRecordsPerDay = Map<String, int>.from(state.valueOrNull!.recordsPerDay);
    newRecordsPerDay[dateKey] = (newRecordsPerDay[dateKey] ?? 0) + 1;

    final newStats = state.valueOrNull!.copyWith(
      totalRecords: state.valueOrNull!.totalRecords + 1,
      audioRecords: type == RecordType.audio
          ? state.valueOrNull!.audioRecords + 1
          : state.valueOrNull!.audioRecords,
      ocrRecords:
          type == RecordType.ocr ? state.valueOrNull!.ocrRecords + 1 : state.valueOrNull!.ocrRecords,
      textRecords:
          type == RecordType.text ? state.valueOrNull!.textRecords + 1 : state.valueOrNull!.textRecords,
      lastUseDate: now,
      recordsPerDay: newRecordsPerDay,
    );

    state = AsyncData(newStats);
    await _saveStats(newStats);
  }

  Future<void> transcriptionCompleted(bool success) async {
    final newStats = state.valueOrNull!.copyWith(
      successfulTranscriptions: success
          ? state.valueOrNull!.successfulTranscriptions + 1
          : state.valueOrNull!.successfulTranscriptions,
      failedTranscriptions: success
          ? state.valueOrNull!.failedTranscriptions
          : state.valueOrNull!.failedTranscriptions + 1,
    );
    state = AsyncData(newStats);
    await _saveStats(newStats);
  }

  Future<void> favoriteToggled(bool isFavorite) async {
    final newStats = state.valueOrNull!.copyWith(
      favoriteRecords:
          isFavorite ? state.valueOrNull!.favoriteRecords + 1 : state.valueOrNull!.favoriteRecords - 1,
    );
    state = AsyncData(newStats);
    await _saveStats(newStats);
  }

  Future<void> tagsAdded(List<String> tags) async {
    final newTagsFrequency = Map<String, int>.from(state.valueOrNull!.tagsFrequency);

    for (final tag in tags) {
      newTagsFrequency[tag] = (newTagsFrequency[tag] ?? 0) + 1;
    }

    final newStats = state.valueOrNull!.copyWith(
      totalTags: state.valueOrNull!.totalTags + tags.length,
      tagsFrequency: newTagsFrequency,
    );
    state = AsyncData(newStats);
    await _saveStats(newStats);
  }

  Future<void> aiSummaryGenerated() async {
    final newStats = state.valueOrNull!.copyWith(
      aiSummaryCount: state.valueOrNull!.aiSummaryCount + 1,
    );
    state = AsyncData(newStats);
    await _saveStats(newStats);
  }

  Future<void> exportTriggered() async {
    final newStats = state.valueOrNull!.copyWith(
      exportCount: state.valueOrNull!.exportCount + 1,
    );
    state = AsyncData(newStats);
    await _saveStats(newStats);
  }

  Future<void> shareTriggered() async {
    final newStats = state.valueOrNull!.copyWith(
      shareCount: state.valueOrNull!.shareCount + 1,
    );
    state = AsyncData(newStats);
    await _saveStats(newStats);
  }

  Future<void> apiTextCallCompleted(bool success, {String? toolId}) async {
    await _recordApiCall(
      apiTextCalls: state.valueOrNull!.apiTextCalls + 1,
      apiSuccessCalls:
          success ? state.valueOrNull!.apiSuccessCalls + 1 : state.valueOrNull!.apiSuccessCalls,
      apiFailedCalls:
          success ? state.valueOrNull!.apiFailedCalls : state.valueOrNull!.apiFailedCalls + 1,
      toolId: toolId,
    );
  }

  Future<void> apiVoiceCallCompleted(bool success) async {
    await _recordApiCall(
      apiVoiceCalls: state.valueOrNull!.apiVoiceCalls + 1,
      apiSuccessCalls:
          success ? state.valueOrNull!.apiSuccessCalls + 1 : state.valueOrNull!.apiSuccessCalls,
      apiFailedCalls:
          success ? state.valueOrNull!.apiFailedCalls : state.valueOrNull!.apiFailedCalls + 1,
    );
  }

  Future<void> apiImageCallCompleted(bool success) async {
    await _recordApiCall(
      apiImageCalls: state.valueOrNull!.apiImageCalls + 1,
      apiSuccessCalls:
          success ? state.valueOrNull!.apiSuccessCalls + 1 : state.valueOrNull!.apiSuccessCalls,
      apiFailedCalls:
          success ? state.valueOrNull!.apiFailedCalls : state.valueOrNull!.apiFailedCalls + 1,
    );
  }

  Future<void> _recordApiCall({
    int? apiTextCalls,
    int? apiVoiceCalls,
    int? apiImageCalls,
    required int apiSuccessCalls,
    required int apiFailedCalls,
    String? toolId,
  }) async {
    final now = DateTime.now();
    final dateKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final newApiCallsPerDay = Map<String, int>.from(state.valueOrNull!.apiCallsPerDay);
    newApiCallsPerDay[dateKey] = (newApiCallsPerDay[dateKey] ?? 0) + 1;

    final newApiCallsByTool = Map<String, int>.from(state.valueOrNull!.apiCallsByTool);
    if (toolId != null) {
      newApiCallsByTool[toolId] = (newApiCallsByTool[toolId] ?? 0) + 1;
    }

    final newStats = state.valueOrNull!.copyWith(
      apiTextCalls: apiTextCalls ?? state.valueOrNull!.apiTextCalls,
      apiVoiceCalls: apiVoiceCalls ?? state.valueOrNull!.apiVoiceCalls,
      apiImageCalls: apiImageCalls ?? state.valueOrNull!.apiImageCalls,
      apiSuccessCalls: apiSuccessCalls,
      apiFailedCalls: apiFailedCalls,
      apiCallsPerDay: newApiCallsPerDay,
      apiCallsByTool: newApiCallsByTool,
    );

    state = AsyncData(newStats);
    await _saveStats(newStats);
  }

  Future<void> resetStats() async {
    final newStats = UsageStats(
      firstUseDate: DateTime.now(),
      lastUseDate: DateTime.now(),
    );
    state = AsyncData(newStats);
    await _saveStats(newStats);
  }
}