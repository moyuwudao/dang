import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ai_model_config.dart';
import 'app_logger.dart';

class ModelConfigUpdateService extends ChangeNotifier {
  static const String _remoteConfigUrl = 'https://api.example.com/changji/model-config';
  static const String _configCacheKey = 'model_config_cache';
  static const String _lastUpdateKey = 'model_config_last_update';
  static const Duration _updateInterval = Duration(days: 1);

  List<AiModelConfig> _cachedConfigs = AiModelConfig.allProviders;
  bool _isUpdating = false;
  DateTime? _lastUpdateTime;

  List<AiModelConfig> get configs => _cachedConfigs;
  bool get isUpdating => _isUpdating;

  Future<void> init() async {
    await _loadCachedConfig();
    await checkForUpdates();
  }

  Future<void> _loadCachedConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_configCacheKey);
    final lastUpdate = prefs.getString(_lastUpdateKey);

    if (cached != null) {
      try {
        _cachedConfigs = _parseConfigJson(cached);
      } catch (e) {
        AppLogger().e('ModelConfig', 'Failed to parse cached config: $e');
        _cachedConfigs = AiModelConfig.allProviders;
      }
    }

    if (lastUpdate != null) {
      try {
        _lastUpdateTime = DateTime.parse(lastUpdate);
      } catch (e) {
        _lastUpdateTime = null;
      }
    }
  }

  Future<void> checkForUpdates({bool force = false}) async {
    if (_isUpdating) return;

    final shouldUpdate = force || _shouldCheckForUpdates();
    if (!shouldUpdate) return;

    _isUpdating = true;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse(_remoteConfigUrl));
      
      if (response.statusCode == 200) {
        final newConfigs = _parseConfigJson(response.body);
        
        if (_isConfigDifferent(newConfigs)) {
          _cachedConfigs = newConfigs;
          await _saveConfig(newConfigs);
          notifyListeners();
        }
        
        _lastUpdateTime = DateTime.now();
        await _saveLastUpdateTime();
      }
    } catch (e) {
      AppLogger().e('ModelConfig', 'Failed to fetch remote config: $e');
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  bool _shouldCheckForUpdates() {
    if (_lastUpdateTime == null) return true;
    return DateTime.now().difference(_lastUpdateTime!) > _updateInterval;
  }

  bool _isConfigDifferent(List<AiModelConfig> newConfigs) {
    if (_cachedConfigs.length != newConfigs.length) return true;
    
    for (var i = 0; i < _cachedConfigs.length; i++) {
      if (_cachedConfigs[i].name != newConfigs[i].name) return true;
      if (_cachedConfigs[i].availableModels.length != newConfigs[i].availableModels.length) return true;
    }
    
    return false;
  }

  List<AiModelConfig> _parseConfigJson(String jsonString) {
    final data = jsonDecode(jsonString) as List;
    return data.map((item) => _parseConfigItem(item as Map<String, dynamic>)).toList();
  }

  AiModelConfig _parseConfigItem(Map<String, dynamic> item) {
    return AiModelConfig(
      provider: _parseProvider(item['provider']),
      name: item['name'] as String,
      displayName: item['displayName'] as String,
      baseUrl: item['baseUrl'] as String,
      defaultModel: item['defaultModel'] as String,
      availableModels: (item['availableModels'] as List).cast<String>(),
      supportsTranscription: item['supportsTranscription'] as bool? ?? false,
      supportsRealtimeTranscription: item['supportsRealtimeTranscription'] as bool? ?? false,
      supportsChat: item['supportsChat'] as bool? ?? true,
      supportsTextAnalysis: item['supportsTextAnalysis'] as bool? ?? true,
      supportsOCR: item['supportsOCR'] as bool? ?? false,
      visionModel: item['visionModel'] as String? ?? '',
      apiKeyPrefix: item['apiKeyPrefix'] as String?,
      description: item['description'] as String,
      transcriptionMethod: _parseTranscriptionMethod(item['transcriptionMethod']),
      realtimeTranscriptionMethod: item['realtimeTranscriptionMethod'] != null
          ? _parseTranscriptionMethod(item['realtimeTranscriptionMethod'])
          : null,
      asrModel: item['asrModel'] as String? ?? '',
      asrDescription: item['asrDescription'] as String? ?? '',
      realtimeAsrModel: item['realtimeAsrModel'] as String? ?? '',
      realtimeAsrDescription: item['realtimeAsrDescription'] as String? ?? '',
      limitationNote: item['limitationNote'] as String? ?? '',
      pricingNote: item['pricingNote'] as String? ?? '',
    );
  }

  AiProvider _parseProvider(String? name) {
    if (name == null) return AiProvider.openAI;
    try {
      return AiProvider.values.firstWhere((p) => p.name == name);
    } catch (_) {
      return AiProvider.custom;
    }
  }

  TranscriptionMethod _parseTranscriptionMethod(String? name) {
    if (name == null) return TranscriptionMethod.whisperApi;
    try {
      return TranscriptionMethod.values.firstWhere((m) => m.name == name);
    } catch (_) {
      return TranscriptionMethod.whisperApi;
    }
  }

  Future<void> _saveConfig(List<AiModelConfig> configs) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(configs.map(_configToJson).toList());
    await prefs.setString(_configCacheKey, jsonString);
  }

  Map<String, dynamic> _configToJson(AiModelConfig config) {
    return {
      'provider': config.provider.name,
      'name': config.name,
      'displayName': config.displayName,
      'baseUrl': config.baseUrl,
      'defaultModel': config.defaultModel,
      'availableModels': config.availableModels,
      'supportsTranscription': config.supportsTranscription,
      'supportsRealtimeTranscription': config.supportsRealtimeTranscription,
      'supportsChat': config.supportsChat,
      'supportsTextAnalysis': config.supportsTextAnalysis,
      'supportsOCR': config.supportsOCR,
      'visionModel': config.visionModel,
      'apiKeyPrefix': config.apiKeyPrefix,
      'description': config.description,
      'transcriptionMethod': config.transcriptionMethod.name,
      'realtimeTranscriptionMethod': config.realtimeTranscriptionMethod?.name,
      'asrModel': config.asrModel,
      'asrDescription': config.asrDescription,
      'realtimeAsrModel': config.realtimeAsrModel,
      'realtimeAsrDescription': config.realtimeAsrDescription,
      'limitationNote': config.limitationNote,
      'pricingNote': config.pricingNote,
    };
  }

  Future<void> _saveLastUpdateTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastUpdateKey, _lastUpdateTime!.toIso8601String());
  }

  AiModelConfig getConfig(AiProvider provider) {
    return _cachedConfigs.firstWhere(
      (config) => config.provider == provider,
      orElse: () => AiModelConfig.openAI,
    );
  }

  AiModelConfig? getConfigByName(String name) {
    return _cachedConfigs.firstWhere(
      (config) => config.name == name,
      orElse: () => AiModelConfig.custom,
    );
  }

  List<AiModelConfig> get domesticProviders => _cachedConfigs.where((p) => 
    ['deepseek', 'qwen', 'ernie', 'zhipu', 'kimi', 'spark'].contains(p.name)
  ).toList();

  List<AiModelConfig> get internationalProviders => _cachedConfigs.where((p) => 
    ['openai', 'claude', 'gemini', 'grok'].contains(p.name)
  ).toList();

  List<AiModelConfig> get transcriptionProviders => _cachedConfigs
      .where((p) => p.supportsTranscription)
      .toList();

  List<AiModelConfig> get realtimeTranscriptionProviders => _cachedConfigs
      .where((p) => p.supportsRealtimeTranscription)
      .toList();

  List<AiModelConfig> get textAnalysisProviders => _cachedConfigs
      .where((p) => p.supportsTextAnalysis)
      .toList();

  List<AiModelConfig> get ocrProviders => _cachedConfigs
      .where((p) => p.supportsOCR)
      .toList();
}