import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/ai_model_config.dart';
import '../../../core/models/api_config.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/app_logger.dart';
import '../../../core/services/storage_service.dart';
import '../../../data/models/record_model.dart';

final autoAnalysisConfigProvider = FutureProvider<AutoAnalysisConfig>((ref) async {
  return await StorageService.getAutoAnalysisConfig();
});

final apiConfigProvider = FutureProvider<ApiConfigModel?>((ref) async {
  return await StorageService.getApiConfig();
});

final configuredProviderProvider = FutureProvider<AiProvider?>((ref) async {
  final config = await StorageService.getApiConfig();
  if (config == null) return null;
  final providerConfig = AiModelConfig.getConfigByName(config.provider);
  return providerConfig?.provider;
});

final usageStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return await StorageService.getUsageStats();
});

final themeModeProvider = AsyncNotifierProvider<ThemeModeNotifier, ThemeMode>(() {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends AsyncNotifier<ThemeMode> {
  @override
  Future<ThemeMode> build() async {
    return await StorageService.getThemeMode();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = const AsyncLoading();
    try {
      await StorageService.saveThemeMode(mode);
      state = AsyncData(mode);
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }
}

final localeProvider = AsyncNotifierProvider<LocaleNotifier, Locale>(() {
  return LocaleNotifier();
});

class LocaleNotifier extends AsyncNotifier<Locale> {
  @override
  Future<Locale> build() async {
    return await StorageService.getLocale();
  }

  Future<void> setLocale(Locale locale) async {
    state = const AsyncLoading();
    try {
      await StorageService.saveLocale(locale);
      state = AsyncData(locale);
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }
}

class SettingsNotifier extends AsyncNotifier<void> {
  ApiService get _apiService => ApiService();

  @override
  Future<void> build() async {
    return;
  }

  Future<bool> testApiKey({
    required String apiKey,
    required AiProvider provider,
    String? baseUrl,
    required String model,
    String? appId,
    String? accessKeySecret,
  }) async {
    try {
      final config = AiModelConfig.getConfig(provider);
      _apiService.configure(
        apiKey: apiKey,
        config: config,
        customBaseUrl: baseUrl,
        appId: appId,
        accessKeySecret: accessKeySecret,
      );
      
      final isValid = await _apiService.validateApiKey();
      return isValid;
    } catch (e) {
      AppLogger().e('Settings', 'API Key验证失败: $e');
      return false;
    }
  }

  Future<bool> saveApiConfig({
    required String apiKey,
    required String provider,
    String? baseUrl,
    required String model,
    String? appId,
    String? accessKeySecret,
  }) async {
    state = const AsyncLoading();
    try {
      final config = ApiConfigModel(
        id: 1,
        provider: provider,
        apiKey: apiKey,
        appId: appId,
        baseUrl: baseUrl,
        model: model,
        accessKeySecret: accessKeySecret,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await StorageService.saveApiConfig(config);

      // Verify save
      final savedConfig = await StorageService.getApiConfig();

      // 配置API服务
      final providerConfig = AiModelConfig.getConfigByName(provider);
      if (providerConfig != null) {
        _apiService.configure(
          apiKey: apiKey,
          config: providerConfig,
          customBaseUrl: baseUrl,
          accessKeySecret: accessKeySecret,
        );
      }

      // 同步到 MultiApiConfig
      try {
        final multiConfig = await StorageService.getMultiApiConfig();
        final providerEnum = AiProvider.values.firstWhere(
          (p) => p.name == provider,
          orElse: () => AiProvider.openAI,
        );
        final entryId = 'default_${providerEnum.name}';
        final existingIndex = multiConfig.configs.indexWhere((c) => c.id == entryId);
        final newEntry = ApiConfigEntry(
          id: entryId,
          name: '默认${providerConfig?.displayName ?? provider}',
          provider: providerEnum,
          apiKey: apiKey,
          appId: appId,
          baseUrl: baseUrl,
          model: model,
          accessKeySecret: accessKeySecret,
          functions: const [
            ApiFunctionType.text,
            ApiFunctionType.voice,
            ApiFunctionType.voiceRealtime,
            ApiFunctionType.image,
          ],
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        List<ApiConfigEntry> updatedConfigs;
        if (existingIndex >= 0) {
          updatedConfigs = [...multiConfig.configs];
          updatedConfigs[existingIndex] = newEntry;
        } else {
          updatedConfigs = [...multiConfig.configs, newEntry];
        }

        final updatedMultiConfig = multiConfig.copyWith(
          configs: updatedConfigs,
          defaultConfigId: entryId,
        );
        await StorageService.saveMultiApiConfig(updatedMultiConfig);
        AppLogger().i('Settings', 'Synced to MultiApiConfig: ${updatedConfigs.length} configs');
      } catch (e) {
        AppLogger().e('Settings', 'Failed to sync to MultiApiConfig: $e');
      }

      state = const AsyncData(null);
      return true;
    } catch (e, stack) {
      AppLogger().e('Settings', 'Save API config failed: $e');
      state = AsyncError(e, stack);
      return false;
    }
  }

  Future<void> clearApiConfig() async {
    await StorageService.clearApiConfig();
  }

  Future<void> clearAllData() async {
    await StorageService.clearAllData();
  }
}

final settingsNotifierProvider = AsyncNotifierProvider<SettingsNotifier, void>(() {
  return SettingsNotifier();
});
