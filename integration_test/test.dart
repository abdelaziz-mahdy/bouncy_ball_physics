import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:bouncy_ball_physics/main.dart';



void main() {
  final binding = IntegrationTestWidgetsFlutterBinding();
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  group('Test App', () {
    testWidgets('Test with take screenshot', (tester) async {
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();

      await takeScreenshot(tester, binding);
    });
  });
}
takeScreenshot(tester, binding) async {
  if (kIsWeb) {
    await binding.takeScreenshot('test-screenshot');
    return;
  } else if (Platform.isAndroid) {
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
  }
  await binding.takeScreenshot('test-screenshot');
}