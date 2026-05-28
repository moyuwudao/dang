import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/models/ai_model_config.dart';
import 'core/models/api_config.dart';
import 'core/services/api_service.dart';
import 'core/services/app_logger.dart';
import 'core/services/cloud_api_service.dart';
import 'core/services/secure_storage_service.dart';
import 'core/services/storage_service.dart';
import 'core/services/transcription_queue_service.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/providers/settings_provider.dart';
import 'l10n/generated/app_localizations.dart';
import 'routes/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AppLogger().i('App', '应用启动');

  runApp(
    const ProviderScope(
      child: ChangjiApp(),
    ),
  );
}

class ChangjiApp extends ConsumerStatefulWidget {
  const ChangjiApp({super.key});

  @override
  ConsumerState<ChangjiApp> createState() => _ChangjiAppState();
}

class _ChangjiAppState extends ConsumerState<ChangjiApp> {
  @override
  void initState() {
    super.initState();
    _initializeApi();
  }

  Future<void> _initializeApi() async {
    // 0. 首次安装/重装检测：清除残留云端数据
    await _cleanupResidualCloudData();

    try {
      final apiService = ApiService();

      final multiConfig = await StorageService.getMultiApiConfig();
      if (multiConfig.hasAnyConfig) {
        final defaultEntry = multiConfig.defaultConfigId != null
            ? multiConfig.getConfigById(multiConfig.defaultConfigId!)
            : multiConfig.activeConfigs.firstOrNull;

        if (defaultEntry != null) {
          final providerConfig = AiModelConfig.getConfig(defaultEntry.provider);
          apiService.configure(
            apiKey: defaultEntry.apiKey,
            config: providerConfig,
            customBaseUrl: defaultEntry.baseUrl,
            appId: defaultEntry.appId,
          );
          AppLogger().i('App', 'API初始化: provider=${defaultEntry.provider.name}');
        }
      } else {
        final config = await StorageService.getApiConfig();
        if (config != null) {
          final providerConfig = AiModelConfig.getConfigByName(config.provider);
          if (providerConfig != null) {
            apiService.configure(
              apiKey: config.apiKey,
              config: providerConfig,
              customBaseUrl: config.baseUrl,
            );
            AppLogger().i('App', 'API初始化(legacy): provider=${config.provider}');
          }
        }
      }
    } catch (e) {
      AppLogger().e('App', 'API初始化失败: $e');
    }

    // 初始化云端API服务
    try {
      await CloudApiService.instance.initialize();
      AppLogger().i('App', '云端API服务已初始化');
    } catch (e) {
      AppLogger().e('App', '云端API服务初始化失败: $e');
    }

    ref.read(transcriptionQueueProvider).start();
    AppLogger().i('App', '转写队列已启动');
  }

  /// 检测是否首次安装/重装，如果是则只清除云端相关数据
  /// 原理：flutter_secure_storage 的数据在 APP 卸载后仍然保留（Android Keystore）
  /// 因此需要在首次启动时检测并清理云端数据
  /// 注意：本地登录状态和本地API配置保留，不清理
  Future<void> _cleanupResidualCloudData() async {
    try {
      const installFlagKey = 'app_installed_version';
      final prefs = await SharedPreferences.getInstance();
      final lastVersion = prefs.getString(installFlagKey);

      // 获取当前版本（从 pubspec.yaml）
      const currentVersion = '1.0.0'; // TODO: 从 package_info_plus 获取实际版本

      if (lastVersion == null) {
        // 首次安装或重装（无版本标记）
        AppLogger().i('App', '检测到首次安装/重装，清除残留云端数据（保留本地配置和登录状态）');

        // 只清除云端相关的 SecureStorage 数据
        // 本地登录状态（cloud_access_token/refresh_token 在 SharedPreferences 中，重装后自动清除）
        // 本地API配置（multi_api_config_v2 在 SharedPreferences 中，重装后自动清除）
        // 但 flutter_secure_storage 的数据（cloud_api_config、cloud_api_enabled）会保留，需要手动清除
        await SecureStorageService().delete('cloud_api_config');
        await SecureStorageService().deleteCloudApiEnabled();

        // 标记已安装（重新写入版本标记）
        await prefs.setString(installFlagKey, currentVersion);
        AppLogger().i('App', '已清除残留云端数据并标记版本: $currentVersion');
      }
    } catch (e) {
      AppLogger().e('App', '清除残留云端数据失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themeModeAsync = ref.watch(themeModeProvider);
    final themeMode = themeModeAsync.valueOrNull ?? ThemeMode.system;
    final localeAsync = ref.watch(localeProvider);
    final locale = localeAsync.valueOrNull ?? const Locale('zh');

    return MaterialApp.router(
      title: 'Changji',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      locale: locale ?? const Locale('zh'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh'),
        Locale('en'),
      ],
    );
  }
}