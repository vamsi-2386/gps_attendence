// Basic smoke test for the Lumenor HRMS app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lumenor_hrms_flutter/main.dart';

void main() {
  testWidgets('App boots to the splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const LumenorHRMSApp());

    // The splash screen shows the app name.
    expect(find.text('Lumenor HRMS'), findsOneWidget);
  });
}
