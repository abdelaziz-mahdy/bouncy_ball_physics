import 'dart:io';

import 'package:flutter/foundation.dart';
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
    testWidgets('Test with take screenshot', (tester) async {
      Widget app = MyApp();
      await tester.pumpFrames(app, const Duration(seconds: 5));

      // Define the labels for the ChoiceChips
      var labels = ['Line', 'Single Triangle', 'Multiple Triangles'];

      // Tap each ChoiceChip and check if the trailShapeNotifier updates correctly
      for (var label in labels) {
        await tester.tap(find.text(label), warnIfMissed: false);
        await tester.pumpFrames(app, const Duration(seconds: 1));

        await takeScreenshot(
            app,
            "test-$label-$screenshotMode".replaceAll(" ", "-"),
            tester,
            binding);
      }
    });
  });
}

takeScreenshot(Widget app, String name, WidgetTester tester,
    IntegrationTestWidgetsFlutterBinding binding) async {
  if (kIsWeb) {
    await binding.takeScreenshot(name);
    return;
  } else if (Platform.isAndroid) {
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpFrames(app, const Duration(seconds: 1));
  }
  await binding.takeScreenshot(name);
}
