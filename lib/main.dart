import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/models/ai_model_config.dart';
import 'core/services/api_service.dart';
import 'core/services/storage_service.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/providers/settings_provider.dart';
import 'l10n/generated/app_localizations.dart';
import 'routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize API service before app starts
  await _initializeApiService();
  
  runApp(
    const ProviderScope(
      child: ChangjiApp(),
    ),
  );
}

Future<void> _initializeApiService() async {
  try {
    final config = await StorageService.getApiConfig();
    if (config != null) {
      final providerConfig = AiModelConfig.getConfigByName(config.provider);
      if (providerConfig != null) {
        // We can't use ref here, so we'll initialize lazily
        debugPrint('API config found: ${config.provider}, will initialize on first use');
      }
    }
  } catch (e) {
    debugPrint('API service pre-initialization failed: $e');
  }
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
      final config = await StorageService.getApiConfig();
      if (config != null) {
        final providerConfig = AiModelConfig.getConfigByName(config.provider);
        if (providerConfig != null) {
          apiService.configure(
            apiKey: config.apiKey,
            config: providerConfig,
            customBaseUrl: config.baseUrl,
          );
          debugPrint('API service initialized: ${apiService.configInfo}');
        }
      }
    } catch (e) {
      debugPrint('API service initialization failed: $e');
    }
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
