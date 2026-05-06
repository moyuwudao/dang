import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:changji_app/core/theme/app_theme.dart';
import 'package:changji_app/core/theme/app_colors.dart';

void main() {
  group('AppTheme', () {
    test('lightTheme should be valid ThemeData', () {
      final theme = AppTheme.lightTheme;
      expect(theme, isA<ThemeData>());
      expect(theme.brightness, Brightness.light);
    });

    test('darkTheme should be valid ThemeData', () {
      final theme = AppTheme.darkTheme;
      expect(theme, isA<ThemeData>());
      expect(theme.brightness, Brightness.dark);
    });

    test('lightTheme should use Material 3', () {
      final theme = AppTheme.lightTheme;
      expect(theme.useMaterial3, isTrue);
    });

    test('darkTheme should use Material 3', () {
      final theme = AppTheme.darkTheme;
      expect(theme.useMaterial3, isTrue);
    });
  });

  group('AppColors', () {
    test('should have primary color', () {
      expect(AppColors.primary, isA<Color>());
    });

    test('should have secondary color', () {
      expect(AppColors.secondary, isA<Color>());
    });

    test('should have error color', () {
      expect(AppColors.error, isA<Color>());
    });

    test('should have success color', () {
      expect(AppColors.success, isA<Color>());
    });

    test('should have warning color', () {
      expect(AppColors.warning, isA<Color>());
    });

    test('should have info color', () {
      expect(AppColors.info, isA<Color>());
    });

    test('should have text colors', () {
      expect(AppColors.textPrimary, isA<Color>());
      expect(AppColors.textSecondary, isA<Color>());
      expect(AppColors.textTertiary, isA<Color>());
    });

    test('should have background colors', () {
      expect(AppColors.background, isA<Color>());
      expect(AppColors.surface, isA<Color>());
      expect(AppColors.darkBackground, isA<Color>());
    });
  });
}
