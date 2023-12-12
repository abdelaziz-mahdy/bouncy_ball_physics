import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:bouncy_ball_physics/main.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding();
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  group('Test App', () {
    testWidgets('Test with take screenshot', (tester) async {
      Widget App= MyApp();
      await tester.pumpFrames(App, Duration(seconds: 5));

      // Define the labels for the ChoiceChips
      var labels = ['Line', 'Single Triangle', 'Multiple Triangles'];

      // Tap each ChoiceChip and check if the trailShapeNotifier updates correctly
      for (var label in labels) {
        await tester.tap(find.text(label),warnIfMissed: false);
      await tester.pumpFrames(App, Duration(seconds: 1));

        await takeScreenshot("test-${label}".replaceAll(" ", "-"),tester, binding);
      }
    });
  });
}

takeScreenshot(name,tester, binding) async {
  if (kIsWeb) {
    await binding.takeScreenshot(name);
    return;
  } else if (Platform.isAndroid) {
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
  }
  await binding.takeScreenshot(name);
}
