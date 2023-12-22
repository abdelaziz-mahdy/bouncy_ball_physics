import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:bouncy_ball_physics/main.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding();
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const String screenshotMode =
      String.fromEnvironment('SCREENSHOT_MODE', defaultValue: 'desktop');

  group('Test App', () {
    // Test for 'Line' Dropdown
    testWidgets('Test with take screenshot for Line', (tester) async {
      Widget app = MyApp();
      await tester.pumpFrames(app, const Duration(seconds: 5));

      // Open the dropdown
      await tester.tap(find.byType(DropdownButton));
      await tester.pumpFrames(
          app, const Duration(milliseconds: 500)); // Adjust time as needed

      var label = 'Line';
      await tester.tap(find.text(label).last);
      await tester.pumpFrames(
          app, const Duration(milliseconds: 500)); // Adjust time as needed

      await takeScreenshot(app,
          "test-$label-$screenshotMode".replaceAll(" ", "-"), tester, binding);
    });

    // Test for 'Single Triangle' Dropdown
    testWidgets('Test with take screenshot for Single Triangle',
        (tester) async {
      Widget app = MyApp();
      await tester.pumpFrames(app, const Duration(seconds: 5));

      // Open the dropdown
      await tester.tap(find.byType(DropdownButton));
      await tester.pumpFrames(app, const Duration(milliseconds: 500));

      var label = 'Single Triangle';
      await tester.tap(find.text(label).last);
      await tester.pumpFrames(app, const Duration(milliseconds: 500));

      await takeScreenshot(app,
          "test-$label-$screenshotMode".replaceAll(" ", "-"), tester, binding);
    });

    // Test for 'Multiple Triangles' Dropdown
    testWidgets('Test with take screenshot for Multiple Triangles',
        (tester) async {
      Widget app = MyApp();
      await tester.pumpFrames(app, const Duration(seconds: 5));

      // Open the dropdown
      await tester.tap(find.byType(DropdownButton));
      await tester.pumpFrames(app, const Duration(milliseconds: 500));

      var label = 'Multiple Triangles';
      await tester.tap(find.text(label).last);
      await tester.pumpFrames(app, const Duration(milliseconds: 500));

      await takeScreenshot(app,
          "test-$label-$screenshotMode".replaceAll(" ", "-"), tester, binding);
    });
  });
}

Future<void> takeScreenshot(
  Widget app,
  String name,
  WidgetTester tester,
  IntegrationTestWidgetsFlutterBinding binding,
) async {
  await tester.pumpFrames(app, const Duration(seconds: 1));
  if (kIsWeb) {
    await binding.takeScreenshot(name);
  } else {
    if (Platform.isAndroid) {
      await binding.convertFlutterSurfaceToImage();
      await tester.pumpFrames(app, const Duration(seconds: 1));
      await binding.takeScreenshot(name);
    } else {
      await binding.takeScreenshot(name);
    }
  }
  print("Took screenshot: $name");
}
