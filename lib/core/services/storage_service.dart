import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/record_model.dart';

class StorageService {
  static const String _apiConfigKey = 'api_config';
  static const String _themeModeKey = 'theme_mode';
  static const String _firstLaunchKey = 'first_launch';
  static const String _recordingQualityKey = 'recording_quality';
  static const String _localeKey = 'locale';

  static Future<SharedPreferences> get _prefs async => await SharedPreferences.getInstance();

  // API配置
  static Future<void> saveApiConfig(ApiConfigModel config) async {
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
    await prefs.setString(_apiConfigKey, configJson);
  }

  static Future<ApiConfigModel?> getApiConfig() async {
    final prefs = await _prefs;
    final configJson = prefs.getString(_apiConfigKey);
    if (configJson == null) return null;

    try {
      final configMap = jsonDecode(configJson) as Map<String, dynamic>;
      return ApiConfigModel(
        id: configMap['id'] ?? 1,
        provider: configMap['provider'] ?? 'openai',
        apiKey: configMap['apiKey'] ?? '',
        baseUrl: configMap['baseUrl'],
        model: configMap['model'] ?? 'whisper-1',
        createdAt: DateTime.parse(configMap['createdAt']),
        updatedAt: DateTime.parse(configMap['updatedAt']),
      );
    } catch (e) {
      debugPrint('解析API配置失败: $e');
      return null;
    }
  }

  static Future<void> clearApiConfig() async {
    final prefs = await _prefs;
    await prefs.remove(_apiConfigKey);
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

  static Future<void> incrementUsageStat(String provider, String feature, {int tokens = 0}) async {
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

      stats[providerKey]['callCount'] = (stats[providerKey]['callCount'] ?? 0) + 1;
      stats[providerKey]['tokenCount'] = (stats[providerKey]['tokenCount'] ?? 0) + tokens;
      stats[providerKey]['lastUsed'] = DateTime.now().toIso8601String();

      final featureKey = feature;
      if (!stats[providerKey]['features'].containsKey(featureKey)) {
        stats[providerKey]['features'][featureKey] = 0;
      }
      stats[providerKey]['features'][featureKey] = (stats[providerKey]['features'][featureKey] ?? 0) + 1;

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
}
