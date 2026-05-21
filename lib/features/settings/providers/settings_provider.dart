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

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final mode = await StorageService.getThemeMode();
    state = mode;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await StorageService.saveThemeMode(mode);
    state = mode;
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('en')) {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final locale = await StorageService.getLocale();
    state = locale;
  }

  Future<void> setLocale(Locale locale) async {
    await StorageService.saveLocale(locale);
    state = locale;
  }
}

class SettingsNotifier extends StateNotifier<AsyncValue<void>> {
  final ApiService _apiService;

  SettingsNotifier(this._apiService) : super(const AsyncValue.data(null));

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
    state = const AsyncValue.loading();
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

      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      AppLogger().e('Settings', 'Save API config failed: $e');
      state = AsyncValue.error(e, stack);
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

final settingsNotifierProvider = StateNotifierProvider<SettingsNotifier, AsyncValue<void>>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return SettingsNotifier(apiService);
});
