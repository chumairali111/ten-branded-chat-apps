import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whatsapp_clone_client/features/chat_lock/password_dialog.dart';

void main() {
  testWidgets('wrong password stays visible; successful retry closes safely', (
    tester,
  ) async {
    bool? unlocked;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                unlocked = await showDialog<bool>(
                  context: context,
                  builder: (_) => ChatPasswordDialog(
                    title: 'Unlock chat',
                    actionLabel: 'Unlock',
                    submit: (password) async {
                      if (password != 'correct')
                        throw StateError('Incorrect password');
                    },
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'wrong');
    await tester.tap(find.text('Unlock'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Incorrect password'), findsOneWidget);
    expect(unlocked, isNull);
    await tester.enterText(find.byType(TextField), 'correct');
    await tester.tap(find.text('Unlock'));
    await tester.pumpAndSettle();
    expect(unlocked, isTrue);
    expect(find.byType(ChatPasswordDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
