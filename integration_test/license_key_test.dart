import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const licenseKey = 'ce8d3bb0-40f4-4d68-84c2-1388e5263051';
const licenseKeyInvalid = '6f95fe90-cdfc-4054-9515-84bba62f7f1d';

Future<void> test(WidgetTester tester, Database db) async {
  await tester.pumpAndSettle();

  // ===========================================================================
  // Setting a valid license key
  // ===========================================================================
  // Find and click the File menu
  final fileMenu = find.text('File');
  await tester.tap(fileMenu);
  await tester.pumpAndSettle();

  // Find and click the Settings menu item
  final settingsMenuItem = find.text('Settings');
  await tester.tap(settingsMenuItem);
  await tester.pumpAndSettle();

  // Find the license key text field by key and enter "test"
  final textField = find.byKey(const Key('license-key-input'));
  await tester.enterText(textField, licenseKey);
  await tester.pumpAndSettle();

  // Find and click the Verify button
  final verifyButton = find.text('Verify');
  await tester.tap(verifyButton);
  await tester.pumpAndSettle();

  expect(find.textContaining('valid'), findsOne);

  // Click the Close button
  final closeButton = find.text('Close');
  await tester.tap(closeButton);
  await tester.pumpAndSettle();

  expect(find.textContaining('Licensed'), findsOne);

  // Find and click the File menu
  await tester.tap(fileMenu);
  await tester.pumpAndSettle();

  // Find and click the Settings menu item
  await tester.tap(settingsMenuItem);
  await tester.pumpAndSettle();

  // Find the license key text field by key and enter "test"
  final textField2 = find.byKey(const Key('license-key-input'));
  expect((tester.widget(textField2) as TextField).controller?.text, licenseKey);

  // ===========================================================================
  // Setting an invalid license key
  // ===========================================================================
  // Enter the invalid license key
  await tester.enterText(textField, licenseKeyInvalid);
  await tester.pumpAndSettle();

  // Find and click the Verify button
  await tester.tap(verifyButton);
  await tester.pumpAndSettle();

  expect(find.textContaining('invalid'), findsOne);

  // Click the Close button
  await tester.tap(closeButton);
  await tester.pumpAndSettle();

  expect(find.textContaining('Unlicensed'), findsOne);
}
