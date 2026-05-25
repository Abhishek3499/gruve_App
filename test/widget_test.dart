import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gruve_app/main.dart';

void main() {
  testWidgets('App builds smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
