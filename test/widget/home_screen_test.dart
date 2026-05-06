import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:changji_app/features/home/screens/home_screen.dart';

void main() {
  group('HomeScreen', () {
    testWidgets('should render correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      // 只 pump 一次
      await tester.pump();

      // 验证基本组件存在
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should have search button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('should have settings button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    });
  });

  group('RecordSearchDelegate', () {
    testWidgets('should render search UI', (WidgetTester tester) async {
      final delegate = RecordSearchDelegate();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    showSearch(
                      context: context,
                      delegate: delegate,
                    );
                  },
                );
              },
            ),
          ),
        ),
      );

      // 点击搜索按钮
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // 验证搜索页面元素
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.byIcon(Icons.clear), findsOneWidget);
    });
  });
}
