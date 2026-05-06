import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:changji_app/features/recording/screens/recording_screen.dart';

void main() {
  group('RecordingScreen', () {
    testWidgets('should render recording UI', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: RecordingScreen(),
          ),
        ),
      );

      // 只 pump 一次
      await tester.pump();

      // 验证基本组件存在
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should have close button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: RecordingScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('should have record button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: RecordingScreen(),
          ),
        ),
      );

      await tester.pump();

      // 查找麦克风图标（录音按钮）
      expect(find.byIcon(Icons.mic), findsOneWidget);
    });
  });

  group('WaveformPainter', () {
    test('shouldRepaint should return false for same amplitudes', () {
      final painter1 = WaveformPainter(
        amplitudes: [1.0, 2.0, 3.0],
        color: Colors.blue,
      );

      final painter2 = WaveformPainter(
        amplitudes: [1.0, 2.0, 3.0],
        color: Colors.blue,
      );

      expect(painter1.shouldRepaint(painter2), isFalse);
    });

    test('shouldRepaint should return true for different amplitudes', () {
      final painter1 = WaveformPainter(
        amplitudes: [1.0, 2.0, 3.0],
        color: Colors.blue,
      );

      final painter2 = WaveformPainter(
        amplitudes: [1.0, 2.5, 3.0],
        color: Colors.blue,
      );

      expect(painter1.shouldRepaint(painter2), isTrue);
    });

    test('shouldRepaint should return true for different length', () {
      final painter1 = WaveformPainter(
        amplitudes: [1.0, 2.0],
        color: Colors.blue,
      );

      final painter2 = WaveformPainter(
        amplitudes: [1.0, 2.0, 3.0],
        color: Colors.blue,
      );

      expect(painter1.shouldRepaint(painter2), isTrue);
    });
  });
}
