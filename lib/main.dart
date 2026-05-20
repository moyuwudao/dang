import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/models/ai_model_config.dart';
import 'core/models/api_config.dart';
import 'core/services/api_service.dart';
import 'core/services/app_logger.dart';
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
    try {
      final apiService = ref.read(apiServiceProvider);

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

    ref.read(transcriptionQueueProvider).start();
    AppLogger().i('App', '转写队列已启动');
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'Changji',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('zh'),
      ],
    );
  }
}