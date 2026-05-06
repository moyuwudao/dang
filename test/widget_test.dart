import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:changji_app/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    // Build our app with ProviderScope
    await tester.pumpWidget(
      const ProviderScope(
        child: ChangjiApp(),
      ),
    );

    // 只 pump 一次
    await tester.pump();

    // 验证应用构建成功
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
