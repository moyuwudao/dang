import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:changji_app/core/services/storage_service.dart';
import 'package:changji_app/data/models/record_model.dart';

void main() {
  group('StorageService', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    group('Theme Mode', () {
      test('should save and load light theme', () async {
        await StorageService.saveThemeMode(ThemeMode.light);
        final mode = await StorageService.getThemeMode();
        expect(mode, ThemeMode.light);
      });

      test('should save and load dark theme', () async {
        await StorageService.saveThemeMode(ThemeMode.dark);
        final mode = await StorageService.getThemeMode();
        expect(mode, ThemeMode.dark);
      });

      test('should default to system theme', () async {
        final mode = await StorageService.getThemeMode();
        expect(mode, ThemeMode.system);
      });
    });

    group('Locale', () {
      test('should save and load Chinese locale', () async {
        await StorageService.saveLocale(const Locale('zh'));
        final locale = await StorageService.getLocale();
        expect(locale.languageCode, 'zh');
      });

      test('should save and load English locale', () async {
        await StorageService.saveLocale(const Locale('en'));
        final locale = await StorageService.getLocale();
        expect(locale.languageCode, 'en');
      });

      test('should default to English', () async {
        final locale = await StorageService.getLocale();
        expect(locale.languageCode, 'en');
      });
    });

    group('First Launch', () {
      test('should be true by default', () async {
        final isFirst = await StorageService.isFirstLaunch();
        expect(isFirst, isTrue);
      });

      test('should be false after setting', () async {
        await StorageService.setFirstLaunch(false);
        final isFirst = await StorageService.isFirstLaunch();
        expect(isFirst, isFalse);
      });
    });

    group('Recording Quality', () {
      test('should default to high', () async {
        final quality = await StorageService.getRecordingQuality();
        expect(quality, 'high');
      });

      test('should save custom quality', () async {
        await StorageService.saveRecordingQuality('medium');
        final quality = await StorageService.getRecordingQuality();
        expect(quality, 'medium');
      });
    });

    group('API Config', () {
      test('should return null when not set', () async {
        final config = await StorageService.getApiConfig();
        expect(config, isNull);
      });

      test('should save and load API config', () async {
        final config = ApiConfigModel(
          id: 1,
          provider: 'openai',
          apiKey: 'sk-test123',
          model: 'gpt-4o-mini',
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        );

        await StorageService.saveApiConfig(config);
        final loaded = await StorageService.getApiConfig();

        expect(loaded, isNotNull);
        expect(loaded!.provider, 'openai');
        expect(loaded.apiKey, 'sk-test123');
        expect(loaded.model, 'gpt-4o-mini');
      });

      test('should clear API config', () async {
        final config = ApiConfigModel(
          id: 1,
          provider: 'openai',
          apiKey: 'sk-test123',
          model: 'gpt-4o-mini',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await StorageService.saveApiConfig(config);
        await StorageService.clearApiConfig();

        final loaded = await StorageService.getApiConfig();
        expect(loaded, isNull);
      });
    });

    group('Usage Stats', () {
      test('should return empty stats by default', () async {
        final stats = await StorageService.getUsageStats();
        expect(stats, isEmpty);
      });

      test('should increment usage stats', () async {
        await StorageService.incrementUsageStat('openai', 'transcription', tokens: 100);
        final stats = await StorageService.getUsageStats();

        expect(stats, isNotEmpty);
        expect(stats['openai'], isNotNull);
        expect(stats['openai']['callCount'], 1);
        expect(stats['openai']['tokenCount'], 100);
      });

      test('should accumulate multiple calls', () async {
        await StorageService.incrementUsageStat('openai', 'transcription', tokens: 100);
        await StorageService.incrementUsageStat('openai', 'transcription', tokens: 200);

        final stats = await StorageService.getUsageStats();
        expect(stats['openai']['callCount'], 2);
        expect(stats['openai']['tokenCount'], 300);
      });

      test('should track different features', () async {
        await StorageService.incrementUsageStat('openai', 'transcription');
        await StorageService.incrementUsageStat('openai', 'chat');

        final stats = await StorageService.getUsageStats();
        final features = stats['openai']['features'] as Map<String, dynamic>;
        expect(features['transcription'], 1);
        expect(features['chat'], 1);
      });

      test('should clear usage stats', () async {
        await StorageService.incrementUsageStat('openai', 'transcription');
        await StorageService.clearUsageStats();

        final stats = await StorageService.getUsageStats();
        expect(stats, isEmpty);
      });
    });

    group('Clear All Data', () {
      test('should clear all preferences', () async {
        await StorageService.saveThemeMode(ThemeMode.dark);
        await StorageService.setFirstLaunch(false);

        await StorageService.clearAllData();

        final theme = await StorageService.getThemeMode();
        final isFirst = await StorageService.isFirstLaunch();

        expect(theme, ThemeMode.system); // 默认值
        expect(isFirst, isTrue); // 默认值
      });
    });
  });
}
