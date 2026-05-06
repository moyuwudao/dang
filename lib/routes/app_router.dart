import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/home/screens/home_screen.dart';
import '../features/recording/screens/recording_screen.dart';
import '../features/records/screens/record_detail_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/settings/screens/api_key_config_screen.dart';
import '../features/settings/screens/privacy_policy_screen.dart';
import '../features/settings/screens/terms_of_service_screen.dart';
import '../features/settings/screens/role_management_screen.dart';
import '../features/ocr/screens/ocr_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/recording',
        builder: (context, state) => const RecordingScreen(),
      ),
      GoRoute(
        path: '/record/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return RecordDetailScreen(recordId: id);
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/settings/api-key',
        builder: (context, state) => const ApiKeyConfigScreen(),
      ),
      GoRoute(
        path: '/privacy-policy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/terms-of-service',
        builder: (context, state) => const TermsOfServiceScreen(),
      ),
      GoRoute(
        path: '/ocr',
        builder: (context, state) => const OCRScreen(),
      ),
      GoRoute(
        path: '/settings/roles',
        builder: (context, state) => const RoleManagementScreen(),
      ),
    ],
  );
});
