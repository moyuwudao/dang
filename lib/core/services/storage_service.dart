import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ai_model_config.dart';
import '../models/api_config.dart';
import '../../data/models/record_model.dart';

class StorageService {
  static const String _apiConfigKey = 'api_config';
  static const String _multiApiConfigKey = 'multi_api_config_v2';
  static const String _transcriptionConfigKey = 'transcription_config';
  static const String _themeModeKey = 'theme_mode';
  static const String _firstLaunchKey = 'first_launch';
  static const String _recordingQualityKey = 'recording_quality';
  static const String _localeKey = 'locale';
  static const String _autoAnalysisKey = 'auto_analysis_config';
  static const String _savedReportsKey = 'saved_reports';
  static const String _savedMindMapsKey = 'saved_mindmaps';
  static const String _analysisTemplatesKey = 'analysis_templates_v1';
  static const String _recycleBinKey = 'recycle_bin_v1';
  static const String _hiddenRelatedRecordsKey = 'hidden_related_records_v1';

  static Future<SharedPreferences> get _prefs async =>
      await SharedPreferences.getInstance();

  // API配置 - 简化版本，不使用加密
  static Future<void> saveApiConfig(ApiConfigModel config) async {
    try {
      final prefs = await _prefs;

      final configJson = jsonEncode({
        'id': config.id,
        'provider': config.provider,
        'apiKey': config.apiKey,
        'baseUrl': config.baseUrl,
        'model': config.model,
        'createdAt': config.createdAt.toIso8601String(),
        'updatedAt': config.updatedAt.toIso8601String(),
      });

      debugPrint(
          'Saving API config: provider=${config.provider}, model=${config.model}');
      await prefs.setString(_apiConfigKey, configJson);
      debugPrint('API config saved successfully');
    } catch (e, stack) {
      debugPrint('Failed to save API config: $e');
      debugPrint('Stack: $stack');
      rethrow;
    }
  }

  static Future<ApiConfigModel?> getApiConfig() async {
    try {
      final prefs = await _prefs;
      final configJson = prefs.getString(_apiConfigKey);
      if (configJson == null) {
        debugPrint('No API config found');
        return null;
      }

      final configMap = jsonDecode(configJson) as Map<String, dynamic>;

      return ApiConfigModel(
        id: configMap['id'] ?? 1,
        provider: configMap['provider'] ?? 'openai',
        apiKey: configMap['apiKey'] ?? '',
        baseUrl: configMap['baseUrl'],
        model: configMap['model'] ?? 'whisper-1',
        createdAt:
            DateTime.tryParse(configMap['createdAt'] ?? '') ?? DateTime.now(),
        updatedAt:
            DateTime.tryParse(configMap['updatedAt'] ?? '') ?? DateTime.now(),
      );
    } catch (e) {
      debugPrint('Failed to get API config: $e');
      return null;
    }
  }

  static Future<void> clearApiConfig() async {
    final prefs = await _prefs;
    await prefs.remove(_apiConfigKey);
  }

  // Multi-API Configuration (v2)
  static Future<void> saveMultiApiConfig(MultiApiConfig config) async {
    try {
      final prefs = await _prefs;
      await prefs.setString(_multiApiConfigKey, jsonEncode(config.toJson()));
      debugPrint('Multi-API config saved: ${config.configs.length} configs');
    } catch (e, stack) {
      debugPrint('Failed to save multi-API config: $e');
      debugPrint('Stack: $stack');
      rethrow;
    }
  }

  static Future<MultiApiConfig> getMultiApiConfig() async {
    try {
      final prefs = await _prefs;
      final configJson = prefs.getString(_multiApiConfigKey);
      if (configJson == null) {
        // Migrate from old single config if exists
        final oldConfig = await getApiConfig();
        if (oldConfig != null) {
          final migrated = MultiApiConfig(
            configs: [
              ApiConfigEntry(
                id: 'legacy_${DateTime.now().millisecondsSinceEpoch}',
                name: '默认配置',
                provider: AiProvider.values.firstWhere(
                  (p) => p.name == oldConfig.provider,
                  orElse: () => AiProvider.openAI,
                ),
                apiKey: oldConfig.apiKey,
                baseUrl: oldConfig.baseUrl,
                model: oldConfig.model,
                functions: const [
                  ApiFunctionType.text,
                  ApiFunctionType.voice,
                  ApiFunctionType.image,
                ],
                isActive: true,
                createdAt: oldConfig.createdAt,
                updatedAt: oldConfig.updatedAt,
              ),
            ],
            functionAssignments: const [
              ApiFunctionAssignment(
                  functionType: ApiFunctionType.text, configId: null),
              ApiFunctionAssignment(
                  functionType: ApiFunctionType.voice, configId: null),
              ApiFunctionAssignment(
                  functionType: ApiFunctionType.image, configId: null),
            ],
            defaultConfigId: null,
          );
          await saveMultiApiConfig(migrated);
          return migrated;
        }
        return const MultiApiConfig();
      }
      return MultiApiConfig.fromJson(jsonDecode(configJson));
    } catch (e) {
      debugPrint('Failed to get multi-API config: $e');
      return const MultiApiConfig();
    }
  }

  static Future<void> clearMultiApiConfig() async {
    final prefs = await _prefs;
    await prefs.remove(_multiApiConfigKey);
  }

  static Future<void> saveTranscriptionConfig(ApiConfigModel config) async {
    try {
      final prefs = await _prefs;
      final configJson = jsonEncode({
        'id': config.id,
        'provider': config.provider,
        'apiKey': config.apiKey,
        'baseUrl': config.baseUrl,
        'model': config.model,
        'createdAt': config.createdAt.toIso8601String(),
        'updatedAt': config.updatedAt.toIso8601String(),
      });
      await prefs.setString(_transcriptionConfigKey, configJson);
    } catch (e) {
      debugPrint('Failed to save transcription config: $e');
      rethrow;
    }
  }

  static Future<ApiConfigModel?> getTranscriptionConfig() async {
    try {
      final prefs = await _prefs;
      final configJson = prefs.getString(_transcriptionConfigKey);
      if (configJson == null) return null;

      final configMap = jsonDecode(configJson) as Map<String, dynamic>;
      return ApiConfigModel(
        id: configMap['id'] ?? 2,
        provider: configMap['provider'] ?? 'qwen',
        apiKey: configMap['apiKey'] ?? '',
        baseUrl: configMap['baseUrl'],
        model: configMap['model'] ?? 'qwen3-asr-flash',
        createdAt:
            DateTime.tryParse(configMap['createdAt'] ?? '') ?? DateTime.now(),
        updatedAt:
            DateTime.tryParse(configMap['updatedAt'] ?? '') ?? DateTime.now(),
      );
    } catch (e) {
      debugPrint('Failed to get transcription config: $e');
      return null;
    }
  }

  static Future<void> clearTranscriptionConfig() async {
    final prefs = await _prefs;
    await prefs.remove(_transcriptionConfigKey);
  }

  // 主题模式
  static Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await _prefs;
    await prefs.setString(_themeModeKey, mode.name);
  }

  static Future<ThemeMode> getThemeMode() async {
    final prefs = await _prefs;
    final modeName = prefs.getString(_themeModeKey);

    switch (modeName) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  // 首次启动
  static Future<bool> isFirstLaunch() async {
    final prefs = await _prefs;
    return prefs.getBool(_firstLaunchKey) ?? true;
  }

  static Future<void> setFirstLaunch(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_firstLaunchKey, value);
  }

  // 录音质量
  static Future<void> saveRecordingQuality(String quality) async {
    final prefs = await _prefs;
    await prefs.setString(_recordingQualityKey, quality);
  }

  static Future<String> getRecordingQuality() async {
    final prefs = await _prefs;
    return prefs.getString(_recordingQualityKey) ?? 'high';
  }

  // 语言设置
  static Future<void> saveLocale(Locale locale) async {
    final prefs = await _prefs;
    await prefs.setString(_localeKey, locale.languageCode);
  }

  static Future<Locale> getLocale() async {
    final prefs = await _prefs;
    final languageCode = prefs.getString(_localeKey);

    switch (languageCode) {
      case 'zh':
        return const Locale('zh');
      case 'en':
      default:
        return const Locale('en');
    }
  }

  // 模型用量统计
  static const String _usageStatsKey = 'usage_stats';

  static Future<void> incrementUsageStat(String provider, String feature,
      {int tokens = 0}) async {
    try {
      final prefs = await _prefs;
      final statsJson = prefs.getString(_usageStatsKey);
      Map<String, dynamic> stats = {};

      if (statsJson != null) {
        try {
          stats = jsonDecode(statsJson) as Map<String, dynamic>;
        } catch (e) {
          debugPrint('解析用量统计失败: $e');
        }
      }

      final providerKey = provider;
      if (!stats.containsKey(providerKey)) {
        stats[providerKey] = {
          'callCount': 0,
          'tokenCount': 0,
          'features': {},
          'lastUsed': DateTime.now().toIso8601String(),
        };
      }

      stats[providerKey]['callCount'] =
          (stats[providerKey]['callCount'] ?? 0) + 1;
      stats[providerKey]['tokenCount'] =
          (stats[providerKey]['tokenCount'] ?? 0) + tokens;
      stats[providerKey]['lastUsed'] = DateTime.now().toIso8601String();

      final featureKey = feature;
      if (!stats[providerKey]['features'].containsKey(featureKey)) {
        stats[providerKey]['features'][featureKey] = 0;
      }
      stats[providerKey]['features'][featureKey] =
          (stats[providerKey]['features'][featureKey] ?? 0) + 1;

      await prefs.setString(_usageStatsKey, jsonEncode(stats));
    } catch (e) {
      debugPrint('保存用量统计失败: $e');
    }
  }

  static Future<Map<String, dynamic>> getUsageStats() async {
    final prefs = await _prefs;
    final statsJson = prefs.getString(_usageStatsKey);

    if (statsJson == null) return {};

    try {
      return jsonDecode(statsJson) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('解析用量统计失败: $e');
      return {};
    }
  }

  static Future<void> clearUsageStats() async {
    final prefs = await _prefs;
    await prefs.remove(_usageStatsKey);
  }

  // 清除所有数据
  static Future<void> clearAllData() async {
    final prefs = await _prefs;
    await prefs.clear();
  }

  // ========== 保存周报 ==========
  static Future<void> saveWeeklyReport(SavedReport report) async {
    final prefs = await _prefs;
    final reportsJson = prefs.getStringList(_savedReportsKey) ?? [];
    reportsJson.add(jsonEncode(report.toJson()));
    await prefs.setStringList(_savedReportsKey, reportsJson);
  }

  static Future<List<SavedReport>> getSavedReports() async {
    final prefs = await _prefs;
    final reportsJson = prefs.getStringList(_savedReportsKey) ?? [];
    return reportsJson
        .map((json) {
          try {
            return SavedReport.fromJson(
                jsonDecode(json) as Map<String, dynamic>);
          } catch (e) {
            return null;
          }
        })
        .whereType<SavedReport>()
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static Future<void> deleteSavedReport(String id) async {
    final prefs = await _prefs;
    final reportsJson = prefs.getStringList(_savedReportsKey) ?? [];
    final reports = reportsJson
        .map((json) =>
            SavedReport.fromJson(jsonDecode(json) as Map<String, dynamic>))
        .where((r) => r.id != id)
        .toList();
    await prefs.setStringList(
      _savedReportsKey,
      reports.map((r) => jsonEncode(r.toJson())).toList(),
    );
  }

  // ========== 保存脑图 ==========
  static Future<void> saveMindMap(SavedMindMap mindMap) async {
    final prefs = await _prefs;
    final mindMapsJson = prefs.getStringList(_savedMindMapsKey) ?? [];
    mindMapsJson.add(jsonEncode(mindMap.toJson()));
    await prefs.setStringList(_savedMindMapsKey, mindMapsJson);
  }

  static Future<List<SavedMindMap>> getSavedMindMaps() async {
    final prefs = await _prefs;
    final mindMapsJson = prefs.getStringList(_savedMindMapsKey) ?? [];
    return mindMapsJson
        .map((json) {
          try {
            return SavedMindMap.fromJson(
                jsonDecode(json) as Map<String, dynamic>);
          } catch (e) {
            return null;
          }
        })
        .whereType<SavedMindMap>()
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static Future<void> deleteSavedMindMap(String id) async {
    final prefs = await _prefs;
    final mindMapsJson = prefs.getStringList(_savedMindMapsKey) ?? [];
    final mindMaps = mindMapsJson
        .map((json) =>
            SavedMindMap.fromJson(jsonDecode(json) as Map<String, dynamic>))
        .where((m) => m.id != id)
        .toList();
    await prefs.setStringList(
      _savedMindMapsKey,
      mindMaps.map((m) => jsonEncode(m.toJson())).toList(),
    );
  }

  // ========== 分析模板（周报/脑图） ==========
  static Future<void> saveAnalysisTemplates(
      AnalysisTemplateConfig config) async {
    final prefs = await _prefs;
    await prefs.setString(_analysisTemplatesKey, jsonEncode(config.toJson()));
  }

  static Future<AnalysisTemplateConfig> getAnalysisTemplates() async {
    final prefs = await _prefs;
    final json = prefs.getString(_analysisTemplatesKey);
    if (json == null) {
      return AnalysisTemplateConfig.defaultConfig();
    }
    try {
      return AnalysisTemplateConfig.fromJson(
          jsonDecode(json) as Map<String, dynamic>);
    } catch (e) {
      return AnalysisTemplateConfig.defaultConfig();
    }
  }

  // 自动分析配置
  static Future<void> saveAutoAnalysisConfig(AutoAnalysisConfig config) async {
    final prefs = await _prefs;
    await prefs.setString(_autoAnalysisKey, jsonEncode(config.toJson()));
  }

  static Future<AutoAnalysisConfig> getAutoAnalysisConfig() async {
    final prefs = await _prefs;
    final configJson = prefs.getString(_autoAnalysisKey);

    if (configJson == null) {
      return const AutoAnalysisConfig(
        enabled: false,
        defaultRoleId: '',
        selectedRoleIds: [],
        savedTemplates: [],
      );
    }

    try {
      final configMap = jsonDecode(configJson) as Map<String, dynamic>;
      final savedTemplates = (configMap['savedTemplates'] as List<dynamic>?)
              ?.map((e) =>
                  SavedTemplateConfig.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      return AutoAnalysisConfig(
        enabled: configMap['enabled'] ?? false,
        defaultRoleId: configMap['defaultRoleId'] ?? '',
        selectedRoleIds: List<String>.from(configMap['selectedRoleIds'] ?? []),
        savedTemplates: savedTemplates,
      );
    } catch (e) {
      return const AutoAnalysisConfig(
        enabled: false,
        defaultRoleId: '',
        selectedRoleIds: [],
        savedTemplates: [],
      );
    }
  }
}

class SavedTemplateConfig {
  final String templateId;
  final String name;
  final String description;
  final String systemPrompt;
  final String category;

  const SavedTemplateConfig({
    required this.templateId,
    required this.name,
    required this.description,
    required this.systemPrompt,
    required this.category,
  });

  Map<String, dynamic> toJson() {
    return {
      'templateId': templateId,
      'name': name,
      'description': description,
      'systemPrompt': systemPrompt,
      'category': category,
    };
  }

  factory SavedTemplateConfig.fromJson(Map<String, dynamic> json) {
    return SavedTemplateConfig(
      templateId: json['templateId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      systemPrompt: json['systemPrompt'] ?? '',
      category: json['category'] ?? '',
    );
  }
}

class AutoAnalysisConfig {
  final bool enabled;
  final String defaultRoleId;
  final List<String> selectedRoleIds;
  final List<SavedTemplateConfig> savedTemplates;

  const AutoAnalysisConfig({
    required this.enabled,
    required this.defaultRoleId,
    required this.selectedRoleIds,
    required this.savedTemplates,
  });

  AutoAnalysisConfig copyWith({
    bool? enabled,
    String? defaultRoleId,
    List<String>? selectedRoleIds,
    List<SavedTemplateConfig>? savedTemplates,
  }) {
    return AutoAnalysisConfig(
      enabled: enabled ?? this.enabled,
      defaultRoleId: defaultRoleId ?? this.defaultRoleId,
      selectedRoleIds: selectedRoleIds ?? this.selectedRoleIds,
      savedTemplates: savedTemplates ?? this.savedTemplates,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'defaultRoleId': defaultRoleId,
      'selectedRoleIds': selectedRoleIds,
      'savedTemplates': savedTemplates.map((t) => t.toJson()).toList(),
    };
  }
}

// ========== 数据模型 ==========
class SavedReport {
  final String id;
  final String title;
  final String content;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;

  const SavedReport({
    required this.id,
    required this.title,
    required this.content,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SavedReport.fromJson(Map<String, dynamic> json) {
    return SavedReport(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      startDate:
          DateTime.parse(json['startDate'] ?? DateTime.now().toIso8601String()),
      endDate:
          DateTime.parse(json['endDate'] ?? DateTime.now().toIso8601String()),
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class SavedMindMap {
  final String id;
  final String name;
  final String content;
  final DateTime createdAt;

  const SavedMindMap({
    required this.id,
    required this.name,
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SavedMindMap.fromJson(Map<String, dynamic> json) {
    return SavedMindMap(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      content: json['content'] ?? '',
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

// ========== 分析模板配置 ==========
class AnalysisTemplate {
  final String id;
  final String name;
  final String description;
  final String type; // 'weekly_report' or 'mindmap'
  final String systemPrompt;
  final bool isBuiltIn;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AnalysisTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.systemPrompt,
    required this.isBuiltIn,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type,
      'systemPrompt': systemPrompt,
      'isBuiltIn': isBuiltIn,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AnalysisTemplate.fromJson(Map<String, dynamic> json) {
    return AnalysisTemplate(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      type: json['type'] ?? 'weekly_report',
      systemPrompt: json['systemPrompt'] ?? '',
      isBuiltIn: json['isBuiltIn'] ?? false,
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt:
          DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  AnalysisTemplate copyWith({
    String? id,
    String? name,
    String? description,
    String? type,
    String? systemPrompt,
    bool? isBuiltIn,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AnalysisTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class AnalysisTemplateConfig {
  final String defaultWeeklyReportTemplateId;
  final String defaultMindMapTemplateId;
  final List<AnalysisTemplate> customTemplates;

  const AnalysisTemplateConfig({
    required this.defaultWeeklyReportTemplateId,
    required this.defaultMindMapTemplateId,
    required this.customTemplates,
  });

  static AnalysisTemplateConfig defaultConfig() {
    return const AnalysisTemplateConfig(
      defaultWeeklyReportTemplateId: 'builtin_weekly_default',
      defaultMindMapTemplateId: 'builtin_mindmap_default',
      customTemplates: [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'defaultWeeklyReportTemplateId': defaultWeeklyReportTemplateId,
      'defaultMindMapTemplateId': defaultMindMapTemplateId,
      'customTemplates': customTemplates.map((t) => t.toJson()).toList(),
    };
  }

  factory AnalysisTemplateConfig.fromJson(Map<String, dynamic> json) {
    return AnalysisTemplateConfig(
      defaultWeeklyReportTemplateId:
          json['defaultWeeklyReportTemplateId'] ?? 'builtin_weekly_default',
      defaultMindMapTemplateId:
          json['defaultMindMapTemplateId'] ?? 'builtin_mindmap_default',
      customTemplates: (json['customTemplates'] as List<dynamic>? ?? [])
          .map((t) => AnalysisTemplate.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }

  AnalysisTemplateConfig copyWith({
    String? defaultWeeklyReportTemplateId,
    String? defaultMindMapTemplateId,
    List<AnalysisTemplate>? customTemplates,
  }) {
    return AnalysisTemplateConfig(
      defaultWeeklyReportTemplateId:
          defaultWeeklyReportTemplateId ?? this.defaultWeeklyReportTemplateId,
      defaultMindMapTemplateId:
          defaultMindMapTemplateId ?? this.defaultMindMapTemplateId,
      customTemplates: customTemplates ?? this.customTemplates,
    );
  }
}

// ========== 回收站 ==========
class RecycledRecord {
  final int originalId;
  final String type;
  final String? content;
  final String? audioPath;
  final String? imagePath;
  final DateTime createdAt;
  final DateTime deletedAt;
  final List<String> tags;
  final List<AiAnalysisResult> aiAnalysisResults;
  final List<SupplementItem> supplements;

  const RecycledRecord({
    required this.originalId,
    required this.type,
    this.content,
    this.audioPath,
    this.imagePath,
    required this.createdAt,
    required this.deletedAt,
    required this.tags,
    required this.aiAnalysisResults,
    required this.supplements,
  });

  Map<String, dynamic> toJson() {
    return {
      'originalId': originalId,
      'type': type,
      'content': content,
      'audioPath': audioPath,
      'imagePath': imagePath,
      'createdAt': createdAt.toIso8601String(),
      'deletedAt': deletedAt.toIso8601String(),
      'tags': tags,
      'aiAnalysisResults': aiAnalysisResults.map((r) => r.toJson()).toList(),
      'supplements': supplements.map((s) => s.toJson()).toList(),
    };
  }

  factory RecycledRecord.fromJson(Map<String, dynamic> json) {
    return RecycledRecord(
      originalId: json['originalId'] as int,
      type: json['type'] ?? 'audio',
      content: json['content'] as String?,
      audioPath: json['audioPath'] as String?,
      imagePath: json['imagePath'] as String?,
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      deletedAt:
          DateTime.parse(json['deletedAt'] ?? DateTime.now().toIso8601String()),
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      aiAnalysisResults: (json['aiAnalysisResults'] as List<dynamic>? ?? [])
          .map((r) => AiAnalysisResult.fromJson(r as Map<String, dynamic>))
          .toList(),
      supplements: (json['supplements'] as List<dynamic>? ?? [])
          .map((s) => SupplementItem.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }

  bool get isExpired {
    return DateTime.now().difference(deletedAt).inDays >= 7;
  }
}

// StorageService 扩展方法
extension StorageServiceRecycleBin on StorageService {
  static Future<void> addToRecycleBin(RecordModel record) async {
    final prefs = await StorageService._prefs;
    final itemsJson = prefs.getStringList(StorageService._recycleBinKey) ?? [];
    final recycled = RecycledRecord(
      originalId: record.id,
      type: record.type.name,
      content: record.content,
      audioPath: record.audioPath,
      imagePath: record.imagePath,
      createdAt: record.createdAt,
      deletedAt: DateTime.now(),
      tags: record.tags,
      aiAnalysisResults: record.aiAnalysisResults,
      supplements: record.supplements,
    );
    itemsJson.add(jsonEncode(recycled.toJson()));
    await prefs.setStringList(StorageService._recycleBinKey, itemsJson);
  }

  static Future<List<RecycledRecord>> getRecycleBinItems() async {
    final prefs = await StorageService._prefs;
    final itemsJson = prefs.getStringList(StorageService._recycleBinKey) ?? [];
    final items = itemsJson
        .map((json) {
          try {
            return RecycledRecord.fromJson(
                jsonDecode(json) as Map<String, dynamic>);
          } catch (e) {
            return null;
          }
        })
        .whereType<RecycledRecord>()
        .toList();
    // 自动清理过期记录
    final validItems = items.where((item) => !item.isExpired).toList();
    if (validItems.length < items.length) {
      await prefs.setStringList(
        StorageService._recycleBinKey,
        validItems.map((r) => jsonEncode(r.toJson())).toList(),
      );
    }
    return validItems..sort((a, b) => b.deletedAt.compareTo(a.deletedAt));
  }

  static Future<void> permanentDeleteFromRecycleBin(int originalId) async {
    final prefs = await StorageService._prefs;
    final itemsJson = prefs.getStringList(StorageService._recycleBinKey) ?? [];
    final items = itemsJson
        .map((json) =>
            RecycledRecord.fromJson(jsonDecode(json) as Map<String, dynamic>))
        .where((r) => r.originalId != originalId)
        .toList();
    await prefs.setStringList(
      StorageService._recycleBinKey,
      items.map((r) => jsonEncode(r.toJson())).toList(),
    );
  }

  static Future<void> clearRecycleBin() async {
    final prefs = await StorageService._prefs;
    await prefs.remove(StorageService._recycleBinKey);
  }

  static Future<int> getRecycleBinCount() async {
    final items = await getRecycleBinItems();
    return items.length;
  }
}

// ========== 隐藏的相关记录 ==========
extension StorageServiceHiddenRecords on StorageService {
  static Future<List<int>> getHiddenRelatedRecords(int recordId) async {
    final prefs = await StorageService._prefs;
    final key = '${StorageService._hiddenRelatedRecordsKey}_$recordId';
    final hiddenJson = prefs.getString(key);
    if (hiddenJson == null) return [];
    try {
      return (jsonDecode(hiddenJson) as List<dynamic>).cast<int>();
    } catch (e) {
      return [];
    }
  }

  static Future<void> hideRelatedRecord(
      int recordId, int relatedRecordId) async {
    final prefs = await StorageService._prefs;
    final key = '${StorageService._hiddenRelatedRecordsKey}_$recordId';
    final hidden = await getHiddenRelatedRecords(recordId);
    if (!hidden.contains(relatedRecordId)) {
      hidden.add(relatedRecordId);
      await prefs.setString(key, jsonEncode(hidden));
    }
  }

  static Future<void> unhideRelatedRecord(
      int recordId, int relatedRecordId) async {
    final prefs = await StorageService._prefs;
    final key = '${StorageService._hiddenRelatedRecordsKey}_$recordId';
    final hidden = await getHiddenRelatedRecords(recordId);
    hidden.remove(relatedRecordId);
    if (hidden.isEmpty) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, jsonEncode(hidden));
    }
  }
}
