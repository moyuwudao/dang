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
import '../features/settings/screens/tool_ai_config_screen.dart';
import '../features/statistics/screens/api_analysis_screen.dart';
import '../features/settings/screens/recycle_bin_screen.dart';
import '../features/settings/screens/log_screen.dart';
import '../features/workbench/screens/workbench_screen.dart';
import '../features/workbench/screens/tool_display_settings_screen.dart';
import '../features/workbench/screens/tool_data_confirm_screen.dart';
import '../features/workbench/screens/tool_outputs_screen.dart';
import '../features/workbench/tools/enhanced_ai_tool_screen.dart';
import '../features/workbench/tools/tool_configs.dart';

enum AppRoute {
  splash,
  home,
  workbench,
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
  logs,
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

      final tween =
          Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

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

      final tween =
          Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

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

GoRoute _toolRoute(String path, ToolConfig config) {
  return GoRoute(
    path: path,
    pageBuilder: (context, state) =>
        _slideLeftTransitionPage(ToolDataConfirmScreen(config: config), state),
  );
}

GoRoute _toolExecuteRoute() {
  return GoRoute(
    path: '/tool-execute',
    pageBuilder: (context, state) {
      final extra = state.extra as Map<String, dynamic>;
      return _slideLeftTransitionPage(
        EnhancedAiToolScreen(
          config: extra['config'] as ToolConfig,
          dataSource: extra['dataSource'],
          template: extra['template'],
        ),
        state,
      );
    },
  );
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/splash',
        name: AppRoute.splash.name,
        pageBuilder: (context, state) =>
            _fadeScaleTransitionPage(const SplashScreen(), state),
      ),
      GoRoute(
        path: '/',
        name: AppRoute.home.name,
        pageBuilder: (context, state) =>
            _fadeTransitionPage(const HomeScreen(), state),
      ),
      GoRoute(
        path: '/workbench',
        name: AppRoute.workbench.name,
        pageBuilder: (context, state) =>
            _slideLeftTransitionPage(const WorkbenchScreen(), state),
      ),
      GoRoute(
        path: '/workbench/tool-display-settings',
        pageBuilder: (context, state) =>
            _slideLeftTransitionPage(const ToolDisplaySettingsScreen(), state),
      ),
      GoRoute(
        path: '/workbench',
        name: AppRoute.workbench.name,
        pageBuilder: (context, state) => _slideLeftTransitionPage(const WorkbenchScreen(), state),
      ),
      GoRoute(
        path: '/recording',
        name: AppRoute.recording.name,
        pageBuilder: (context, state) =>
            _slideUpTransitionPage(const RecordingScreen(), state),
      ),
      GoRoute(
        path: '/record/:id',
        name: AppRoute.recordDetail.name,
        pageBuilder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return _slideLeftTransitionPage(
              RecordDetailScreen(recordId: id), state);
        },
      ),
      GoRoute(
        path: '/favorites',
        name: AppRoute.favorites.name,
        pageBuilder: (context, state) =>
            _slideLeftTransitionPage(const FavoriteRecordsScreen(), state),
      ),
      GoRoute(
        path: '/settings',
        name: AppRoute.settings.name,
        pageBuilder: (context, state) =>
            _slideLeftTransitionPage(const SettingsScreen(), state),
      ),
      GoRoute(
        path: '/settings/api-key',
        name: AppRoute.apiKeyConfig.name,
        pageBuilder: (context, state) =>
            _slideUpTransitionPage(const ApiKeyConfigScreen(), state),
      ),
      GoRoute(
        path: '/settings/api-key-wizard',
        name: AppRoute.apiKeyWizard.name,
        pageBuilder: (context, state) => _slideUpTransitionPage(
            const ApiKeyWizardScreen(isFromSettings: true), state),
      ),
      GoRoute(
        path: '/settings/multi-api',
        name: AppRoute.multiApiConfig.name,
        pageBuilder: (context, state) =>
            _slideUpTransitionPage(const MultiApiConfigScreen(), state),
      ),
      GoRoute(
        path: '/settings/prompt-templates',
        name: AppRoute.promptTemplates.name,
        pageBuilder: (context, state) => _slideUpTransitionPage(
            const PromptTemplateManagementScreen(), state),
      ),
      GoRoute(
        path: '/privacy-policy',
        name: AppRoute.privacyPolicy.name,
        pageBuilder: (context, state) =>
            _fadeScaleTransitionPage(const PrivacyPolicyScreen(), state),
      ),
      GoRoute(
        path: '/terms-of-service',
        name: AppRoute.termsOfService.name,
        pageBuilder: (context, state) =>
            _fadeScaleTransitionPage(const TermsOfServiceScreen(), state),
      ),
      GoRoute(
        path: '/ocr',
        name: AppRoute.ocr.name,
        pageBuilder: (context, state) =>
            _slideUpTransitionPage(const OCRScreen(), state),
      ),
      GoRoute(
        path: '/settings/roles',
        name: AppRoute.roleManagement.name,
        pageBuilder: (context, state) =>
            _slideUpTransitionPage(const RoleManagementScreen(), state),
      ),
      GoRoute(
        path: '/settings/auto-analysis',
        pageBuilder: (context, state) =>
            _slideUpTransitionPage(const AutoAnalysisSettingsScreen(), state),
      ),
      GoRoute(
        path: '/settings/analysis-templates',
        name: AppRoute.analysisTemplates.name,
        pageBuilder: (context, state) => _slideUpTransitionPage(
            const AnalysisTemplateSettingsScreen(), state),
      ),
      GoRoute(
        path: '/settings/tool-ai-config',
        pageBuilder: (context, state) =>
            _slideUpTransitionPage(const ToolAiConfigScreen(), state),
      ),
      GoRoute(
        path: '/statistics/api-analysis',
        pageBuilder: (context, state) =>
            _slideUpTransitionPage(const ApiAnalysisScreen(), state),
      ),
      GoRoute(
        path: '/quick-note',
        name: AppRoute.quickNote.name,
        pageBuilder: (context, state) =>
            _slideUpTransitionPage(const QuickNoteScreen(), state),
      ),
      GoRoute(
        path: '/statistics',
        name: AppRoute.statistics.name,
        pageBuilder: (context, state) =>
            _slideLeftTransitionPage(const StatisticsScreen(), state),
      ),
      GoRoute(
        path: '/reminders',
        name: AppRoute.reminders.name,
        pageBuilder: (context, state) =>
            _slideLeftTransitionPage(const RemindersScreen(), state),
      ),
      _toolRoute('/weekly-report', toolConfigs['weekly_report']!),
      _toolRoute('/mindmap', toolConfigs['mindmap']!),
      GoRoute(
        path: '/settings/backup',
        name: AppRoute.backupManagement.name,
        pageBuilder: (context, state) =>
            _slideLeftTransitionPage(const BackupManagementScreen(), state),
      ),
      GoRoute(
        path: '/settings/recycle-bin',
        name: AppRoute.recycleBin.name,
        pageBuilder: (context, state) =>
            _slideLeftTransitionPage(const RecycleBinScreen(), state),
      ),
      GoRoute(
        path: '/settings/logs',
        name: AppRoute.logs.name,
        pageBuilder: (context, state) =>
            _slideLeftTransitionPage(const LogScreen(), state),
      ),
      _toolRoute('/smart-todo', toolConfigs['smart_todo']!),
      _toolRoute('/meeting-minutes', toolConfigs['meeting_minutes']!),
      _toolRoute('/email-draft', toolConfigs['email_draft']!),
      _toolRoute('/multi-platform-copy', toolConfigs['multi_platform_copy']!),
      _toolRoute('/voice-diary', toolConfigs['voice_diary']!),
      _toolRoute('/quick-translate', toolConfigs['quick_translate']!),
      _toolRoute('/time-audit', toolConfigs['time_audit']!),
      _toolRoute('/project-review', toolConfigs['project_review']!),
      _toolRoute('/swot-analysis', toolConfigs['swot_analysis']!),
      _toolRoute('/customer-profile', toolConfigs['customer_profile']!),
      _toolRoute('/trend-insight', toolConfigs['trend_insight']!),
      _toolRoute('/competitor-radar', toolConfigs['competitor_radar']!),
      _toolRoute('/project-board', toolConfigs['project_board']!),
      _toolRoute('/lightweight-crm', toolConfigs['lightweight_crm']!),
      _toolRoute('/invoice-recognition', toolConfigs['invoice_recognition']!),
      _toolRoute('/contract-summary', toolConfigs['contract_summary']!),
      _toolRoute('/quotation', toolConfigs['quotation']!),
      _toolRoute('/knowledge-card', toolConfigs['knowledge_card']!),
      _toolRoute('/ai-advisor', toolConfigs['ai_advisor']!),
      _toolRoute('/creative-diverge', toolConfigs['creative_diverge']!),
      _toolRoute('/knowledge-qa', toolConfigs['knowledge_qa']!),
      _toolRoute('/decision-matrix', toolConfigs['decision_matrix']!),
      _toolRoute('/writing-workshop', toolConfigs['writing_workshop']!),
      _toolRoute(
          '/daily-three-questions', toolConfigs['daily_three_questions']!),
      GoRoute(
        path: '/tool-outputs',
        pageBuilder: (context, state) =>
            _slideLeftTransitionPage(const ToolOutputsScreen(), state),
      ),
      _toolExecuteRoute(),
    ],
  );
});
