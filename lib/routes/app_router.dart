import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/home/screens/home_screen.dart';
import '../features/recording/screens/recording_screen.dart';
import '../features/records/screens/record_detail_screen.dart';
import '../features/records/screens/favorite_records_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/settings/screens/api_key_config_screen.dart';
import '../features/settings/screens/api_key_wizard_screen.dart';
import '../features/settings/screens/multi_api_config_screen.dart';
import '../features/settings/screens/prompt_template_management_screen.dart';
import '../features/settings/screens/privacy_policy_screen.dart';
import '../features/settings/screens/terms_of_service_screen.dart';
import '../features/settings/screens/role_management_screen.dart';
import '../features/ocr/screens/ocr_screen.dart';
import '../features/splash/screens/splash_screen.dart';
import '../features/quick_note/screens/quick_note_screen.dart';
import '../features/statistics/screens/statistics_screen.dart';
import '../features/reminders/screens/reminders_screen.dart';
import '../features/settings/screens/auto_analysis_settings_screen.dart';
import '../features/settings/screens/analysis_template_settings_screen.dart';
import '../features/settings/screens/backup_management_screen.dart';
import '../features/settings/screens/recycle_bin_screen.dart';
import '../features/mindmap/screens/mindmap_screen.dart';
import '../features/reports/screens/weekly_report_screen.dart';

enum AppRoute {
  splash,
  home,
  recording,
  recordDetail,
  favorites,
  settings,
  apiKeyConfig,
  apiKeyWizard,
  multiApiConfig,
  promptTemplates,
  privacyPolicy,
  termsOfService,
  roleManagement,
  ocr,
  quickNote,
  statistics,
  reminders,
  weeklyReport,
  analysisTemplates,
  backupManagement,
  recycleBin,
}

Page _fadeTransitionPage(Widget child, GoRouterState state) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}

Page _slideUpTransitionPage(Widget child, GoRouterState state) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.0, 0.3);
      const end = Offset.zero;
      const curve = Curves.easeOut;

      final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}

Page _slideLeftTransitionPage(Widget child, GoRouterState state) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.easeOut;

      final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}

Page _fadeScaleTransitionPage(Widget child, GoRouterState state) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return ScaleTransition(
        scale: Tween<double>(
          begin: 0.9,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        )),
        child: FadeTransition(
          opacity: animation,
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 350),
  );
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/splash',
        name: AppRoute.splash.name,
        pageBuilder: (context, state) => _fadeScaleTransitionPage(const SplashScreen(), state),
      ),
      GoRoute(
        path: '/',
        name: AppRoute.home.name,
        pageBuilder: (context, state) => _fadeTransitionPage(const HomeScreen(), state),
      ),
      GoRoute(
        path: '/recording',
        name: AppRoute.recording.name,
        pageBuilder: (context, state) => _slideUpTransitionPage(const RecordingScreen(), state),
      ),
      GoRoute(
        path: '/record/:id',
        name: AppRoute.recordDetail.name,
        pageBuilder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return _slideLeftTransitionPage(RecordDetailScreen(recordId: id), state);
        },
      ),
      GoRoute(
        path: '/favorites',
        name: AppRoute.favorites.name,
        pageBuilder: (context, state) => _slideLeftTransitionPage(const FavoriteRecordsScreen(), state),
      ),
      GoRoute(
        path: '/settings',
        name: AppRoute.settings.name,
        pageBuilder: (context, state) => _slideLeftTransitionPage(const SettingsScreen(), state),
      ),
      GoRoute(
        path: '/settings/api-key',
        name: AppRoute.apiKeyConfig.name,
        pageBuilder: (context, state) => _slideUpTransitionPage(const ApiKeyConfigScreen(), state),
      ),
      GoRoute(
        path: '/settings/api-key-wizard',
        name: AppRoute.apiKeyWizard.name,
        pageBuilder: (context, state) => _slideUpTransitionPage(const ApiKeyWizardScreen(isFromSettings: true), state),
      ),
      GoRoute(
        path: '/settings/multi-api',
        name: AppRoute.multiApiConfig.name,
        pageBuilder: (context, state) => _slideUpTransitionPage(const MultiApiConfigScreen(), state),
      ),
      GoRoute(
        path: '/settings/prompt-templates',
        name: AppRoute.promptTemplates.name,
        pageBuilder: (context, state) => _slideUpTransitionPage(const PromptTemplateManagementScreen(), state),
      ),
      GoRoute(
        path: '/privacy-policy',
        name: AppRoute.privacyPolicy.name,
        pageBuilder: (context, state) => _fadeScaleTransitionPage(const PrivacyPolicyScreen(), state),
      ),
      GoRoute(
        path: '/terms-of-service',
        name: AppRoute.termsOfService.name,
        pageBuilder: (context, state) => _fadeScaleTransitionPage(const TermsOfServiceScreen(), state),
      ),
      GoRoute(
        path: '/ocr',
        name: AppRoute.ocr.name,
        pageBuilder: (context, state) => _slideUpTransitionPage(const OCRScreen(), state),
      ),
      GoRoute(
        path: '/settings/roles',
        name: AppRoute.roleManagement.name,
        pageBuilder: (context, state) => _slideUpTransitionPage(const RoleManagementScreen(), state),
      ),
      GoRoute(
        path: '/settings/auto-analysis',
        pageBuilder: (context, state) => _slideUpTransitionPage(const AutoAnalysisSettingsScreen(), state),
      ),
      GoRoute(
        path: '/settings/analysis-templates',
        name: AppRoute.analysisTemplates.name,
        pageBuilder: (context, state) => _slideUpTransitionPage(const AnalysisTemplateSettingsScreen(), state),
      ),
      GoRoute(
        path: '/quick-note',
        name: AppRoute.quickNote.name,
        pageBuilder: (context, state) => _slideUpTransitionPage(const QuickNoteScreen(), state),
      ),
      GoRoute(
        path: '/statistics',
        name: AppRoute.statistics.name,
        pageBuilder: (context, state) => _slideLeftTransitionPage(const StatisticsScreen(), state),
      ),
      GoRoute(
        path: '/reminders',
        name: AppRoute.reminders.name,
        pageBuilder: (context, state) => _slideLeftTransitionPage(const RemindersScreen(), state),
      ),
      GoRoute(
        path: '/weekly-report',
        name: AppRoute.weeklyReport.name,
        pageBuilder: (context, state) => _slideLeftTransitionPage(const WeeklyReportScreen(), state),
      ),
      GoRoute(
        path: '/mindmap',
        pageBuilder: (context, state) => _slideLeftTransitionPage(const MindMapScreen(), state),
      ),
      GoRoute(
        path: '/settings/backup',
        name: AppRoute.backupManagement.name,
        pageBuilder: (context, state) => _slideLeftTransitionPage(const BackupManagementScreen(), state),
      ),
      GoRoute(
        path: '/settings/recycle-bin',
        name: AppRoute.recycleBin.name,
        pageBuilder: (context, state) => _slideLeftTransitionPage(const RecycleBinScreen(), state),
      ),
    ],
  );
});