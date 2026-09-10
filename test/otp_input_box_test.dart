import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gruve_app/features/auth/presentation/widgets/otp_input_box.dart';

void main() {
  group('OtpInputBox digit formatter', () {
    late TextEditingController controller;
    late FocusNode focusNode;
    late List<String> changedValues;
    late int backspaceCalls;

    setUp(() {
      controller = TextEditingController();
      focusNode = FocusNode();
      changedValues = [];
      backspaceCalls = 0;
    });

    tearDown(() {
      controller.dispose();
      focusNode.dispose();
    });

    Future<void> pumpBox(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OtpInputBox(
              controller: controller,
              focusNode: focusNode,
              onChanged: (val) => changedValues.add(val),
              onBackspace: () => backspaceCalls++,
            ),
          ),
        ),
      );
    }

    testWidgets('normal single keystroke sets exactly one digit', (
      tester,
    ) async {
      await pumpBox(tester);

      await tester.enterText(find.byType(TextField), '7');
      await tester.pump();

      expect(controller.text, '7');
      expect(changedValues, ['7']);
    });

    testWidgets(
      'a stray keystroke landing on an already-filled box does not '
      'accumulate characters (regression test for the focus-jump bug)',
      (tester) async {
        await pumpBox(tester);

        // First keystroke.
        await tester.enterText(find.byType(TextField), '7');
        await tester.pump();

        // Simulate a second keystroke arriving before the app moved focus
        // away, i.e. the IME reports the box's value as "75" instead of a
        // fresh empty field receiving "5".
        await tester.enterText(find.byType(TextField), '75');
        await tester.pump();

        // The box must still hold a single digit, never both.
        expect(controller.text.length, 1);
        expect(controller.text, '5');
      },
    );

    testWidgets('a genuine multi-digit paste passes through untouched', (
      tester,
    ) async {
      await pumpBox(tester);

      await tester.enterText(find.byType(TextField), '1234');
      await tester.pump();

      expect(changedValues, ['1234']);
    });

    testWidgets('clearing the box triggers onBackspace', (tester) async {
      await pumpBox(tester);

      await tester.enterText(find.byType(TextField), '7');
      await tester.pump();
      await tester.enterText(find.byType(TextField), '');
      await tester.pump();

      expect(backspaceCalls, 1);
    });
  });
}
