import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dory_ukraine/main.dart';
import 'package:dory_ukraine/providers/alphabet_provider.dart';

void main() {
  testWidgets('App loads and shows the first letter', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AlphabetProvider(),
        child: const UaAlphabetApp(),
      ),
    );

    // Verify app title
    expect(find.text('Українська абетка'), findsOneWidget);

    // Verify first letter 'а' is present (since vowels are first)
    expect(find.text('а'), findsOneWidget);

    // Verify task icons are present
    expect(find.byIcon(Icons.mic), findsOneWidget);
    expect(find.byIcon(Icons.edit), findsOneWidget);
    expect(find.byIcon(Icons.search), findsOneWidget);
  });
}
