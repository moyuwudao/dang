import 'dart:convert';

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
import 'core/services/daily_usage_reset_scheduler.dart';
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

    // A2 阶段：启动每日用量重置调度器
    ref.read(dailyUsageResetSchedulerProvider).start();
    AppLogger().i('App', '每日用量重置调度器已启动');
  }

  /// 启动时清理云端配置：未登录则清除，已登录则保留
  ///
  /// 核心逻辑：检查 SharedPreferences 中的 cloud_access_token
  /// - 未登录（无 token）→ 清除所有云端配置条目和 SecureStorage 云端数据
  /// - 已登录（有 token）→ 保留云端配置（登录时会从服务器自动同步）
  ///
  /// 这比版本标记更可靠，因为某些 Android 设备重装后 SharedPreferences 不被清除，
  /// 导致版本标记仍存在，清理逻辑不触发。
  Future<void> _cleanupResidualCloudData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasToken = prefs.getString('cloud_access_token') != null;

      if (!hasToken) {
        // 未登录 → 清除所有云端配置
        AppLogger().i('App', '未登录状态，清除云端配置数据');

        // 1. 清除 SecureStorage 中的云端数据（flutter_secure_storage 在卸载后仍保留）
        await SecureStorageService().delete('cloud_api_config');
        await SecureStorageService().deleteCloudApiEnabled();

        // 2. 清除 SharedPreferences 中 multi_api_config_v2 的云端条目
        try {
          final multiConfigJson = await StorageService.getString('multi_api_config_v2');
          if (multiConfigJson != null) {
            final multiConfig = MultiApiConfig.fromJson(
              jsonDecode(multiConfigJson) as Map<String, dynamic>,
            );
            final localConfigs = multiConfig.configs.where((c) => !c.isCloudConfig).toList();
            final cloudCount = multiConfig.configs.length - localConfigs.length;

            if (cloudCount > 0) {
              final localAssignments = multiConfig.functionAssignments
                  .where((a) {
                    if (a.configId == null) return false;
                    final config = multiConfig.getConfigById(a.configId!);
                    return config != null && !config.isCloudConfig;
                  })
                  .toList();
              final cleanedConfig = MultiApiConfig(
                configs: localConfigs,
                functionAssignments: localAssignments,
                defaultConfigId: localConfigs.isNotEmpty ? localConfigs.first.id : null,
              );
              await StorageService.saveMultiApiConfig(cleanedConfig);
              AppLogger().i('App', '已清除 $cloudCount 个云端配置条目');
            }
          }
        } catch (e) {
          await prefs.remove('multi_api_config_v2');
          AppLogger().w('App', 'multi_api_config_v2 解析失败，已删除: $e');
        }
      } else {
        AppLogger().i('App', '已登录状态，保留云端配置');
      }
    } catch (e) {
      AppLogger().e('App', '清理云端配置失败: $e');
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