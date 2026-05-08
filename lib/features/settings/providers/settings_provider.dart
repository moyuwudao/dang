import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/ai_model_config.dart';
import '../../../core/services/api_service.dart';
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
  }) async {
    try {
      final config = AiModelConfig.getConfig(provider);
      _apiService.configure(
        apiKey: apiKey,
        config: config,
        customBaseUrl: baseUrl,
      );
      
      final isValid = await _apiService.validateApiKey();
      return isValid;
    } catch (e) {
      debugPrint('API Key验证失败: $e');
      return false;
    }
  }

  Future<bool> saveApiConfig({
    required String apiKey,
    required String provider,
    String? baseUrl,
    required String model,
  }) async {
    state = const AsyncValue.loading();
    try {
      debugPrint('Saving API config: provider=$provider, model=$model, baseUrl=$baseUrl');
      
      final config = ApiConfigModel(
        id: 1,
        provider: provider,
        apiKey: apiKey,
        baseUrl: baseUrl,
        model: model,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await StorageService.saveApiConfig(config);
      
      // Verify save
      final savedConfig = await StorageService.getApiConfig();
      debugPrint('Saved config verified: provider=${savedConfig?.provider}, model=${savedConfig?.model}');
      
      // 配置API服务
      final providerConfig = AiModelConfig.getConfigByName(provider);
      if (providerConfig != null) {
        _apiService.configure(
          apiKey: apiKey,
          config: providerConfig,
          customBaseUrl: baseUrl,
        );
      }

      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      debugPrint('Save API config failed: $e');
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
