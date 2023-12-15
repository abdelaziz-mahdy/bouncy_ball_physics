import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:integration_test/src/channel.dart';

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

Future<void> takeScreenshotForAndroid(
    IntegrationTestWidgetsFlutterBinding binding, String name) async {
  await integrationTestChannel.invokeMethod<void>(
    'convertFlutterSurfaceToImage',
    null,
  );
  binding.reportData ??= <String, dynamic>{};
  binding.reportData!['screenshots'] ??= <dynamic>[];
  integrationTestChannel.setMethodCallHandler((MethodCall call) async {
    switch (call.method) {
      case 'scheduleFrame':
        PlatformDispatcher.instance.scheduleFrame();
        break;
    }
    return null;
  });
  final List<int>? rawBytes =
      await integrationTestChannel.invokeMethod<List<int>>(
    'captureScreenshot',
    <String, dynamic>{'name': name},
  );
  if (rawBytes == null) {
    throw StateError(
        'Expected a list of bytes, but instead captureScreenshot returned null');
  }
  final Map<String, dynamic> data = {
    'screenshotName': name,
    'bytes': rawBytes,
  };
  assert(data.containsKey('bytes'));
  (binding.reportData!['screenshots'] as List<dynamic>).add(data);

  await integrationTestChannel.invokeMethod<void>(
    'revertFlutterImage',
    null,
  );
}

Future<void> takeScreenshot(
  Widget app,
  String name,
  WidgetTester tester,
  IntegrationTestWidgetsFlutterBinding binding,
) async {
  await tester.pumpFrames(app, const Duration(seconds: 1));
  if (Platform.isAndroid) {
    await takeScreenshotForAndroid(binding, name);
  } else {
    await binding.takeScreenshot(name);
  }
  print("Took screenshot: $name");
}
