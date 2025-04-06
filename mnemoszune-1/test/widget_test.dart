import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mnemoszune/main.dart';

void main() {
  testWidgets('App starts and displays home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Verify that the home screen is displayed
    expect(find.text('Flutter Demo Home Page'), findsOneWidget);
  });

  testWidgets('Increment button works', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Verify initial counter value
    expect(find.text('0'), findsOneWidget);

    // Tap the increment button
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify counter value incremented
    expect(find.text('1'), findsOneWidget);
  });
}