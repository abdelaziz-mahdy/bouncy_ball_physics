// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:bouncy_ball_physics/ball_painter.dart';
import 'package:bouncy_ball_physics/ball_physics_manager.dart';
import 'package:bouncy_ball_physics/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

Future<void> main() async {
  await loadAppFonts();

  testGoldens('Line', (tester) async {
    String label = 'Line';
    BallPhysicsManager().startingBallCount = 100;
    Widget app = MyApp();
    await tester.pumpWidgetBuilder(app);
    await tester.pumpFrames(app, Duration(seconds: 5));
    // try to find the dropdown
    expect(find.byType(DropdownButton<TrailShape>), findsOneWidget);
    // Open the dropdown
    await tester.tap(find.byType(DropdownButton<TrailShape>));
    await tester
        .pump(const Duration(milliseconds: 500)); // Adjust time as needed

    await tester.tap(find.text(label).last);
    await tester
        .pump(const Duration(milliseconds: 500)); // Adjust time as needed

    await multiScreenGolden(tester, label.replaceAll(' ', '_').toLowerCase(),
        customPump: (tester) => tester.pumpFrames(
              app,
              Duration(seconds: 5),
            ),
        devices: [
          Device.phone,
          Device.tabletLandscape.copyWith(name: 'desktop'),
        ]);
  });
  testGoldens('Single Triangle', (tester) async {
    String label = 'Single Triangle';
    BallPhysicsManager().startingBallCount = 100;
    Widget app = MyApp();
    await tester.pumpWidgetBuilder(app);
    await tester.pumpFrames(app, Duration(seconds: 5));
    // try to find the dropdown
    expect(find.byType(DropdownButton<TrailShape>), findsOneWidget);
    // Open the dropdown
    await tester.tap(find.byType(DropdownButton<TrailShape>));
    await tester
        .pump(const Duration(milliseconds: 500)); // Adjust time as needed

    await tester.tap(find.text(label).last);
    await tester
        .pump(const Duration(milliseconds: 500)); // Adjust time as needed

    await multiScreenGolden(tester, label.replaceAll(' ', '_').toLowerCase(),
        customPump: (tester) => tester.pumpFrames(app, Duration(seconds: 5)),
        devices: [
          Device.phone,
          Device.tabletLandscape.copyWith(name: 'desktop'),
        ]);
  });
  testGoldens('Multiple Triangles', (tester) async {
    String label = 'Multiple Triangles';
    BallPhysicsManager().startingBallCount = 100;
    Widget app = MyApp();
    await tester.pumpWidgetBuilder(app);
    await tester.pumpFrames(app, Duration(seconds: 5));
    // try to find the dropdown
    expect(find.byType(DropdownButton<TrailShape>), findsOneWidget);
    // Open the dropdown
    await tester.tap(find.byType(DropdownButton<TrailShape>));
    await tester
        .pump(const Duration(milliseconds: 500)); // Adjust time as needed

    await tester.tap(find.text(label).last);
    await tester
        .pump(const Duration(milliseconds: 500)); // Adjust time as needed

    await multiScreenGolden(tester, label.replaceAll(' ', '_').toLowerCase(),
        customPump: (tester) => tester.pumpFrames(app, Duration(seconds: 5)),
        devices: [
          Device.phone,
          Device.tabletLandscape.copyWith(name: 'desktop'),
        ]);
  });
  // testGoldens('DeviceBuilder - multiple scenarios - with onCreate',
  //     (tester) async {
  //   final builder = DeviceBuilder()
  //     ..overrideDevicesForAllScenarios(devices: [
  //       Device.phone,
  //       Device.iphone11,
  //       Device.tabletPortrait,
  //       Device.tabletLandscape,
  //     ])
  //     ..addScenario(
  //       widget: app,
  //       name: 'Line',
  //       onCreate: (scenarioWidgetKey) async {
  //         final finderKey = find.byKey(scenarioWidgetKey);
  //         expect(finderKey, findsOneWidget);

  //         final finder = find.descendant(
  //           of: find.byKey(scenarioWidgetKey),
  //           matching: find.byType(DropdownButton<TrailShape>),
  //         );
  //         expect(finder, findsOneWidget);
  //         await tester.pumpFrames(
  //             app, const Duration(milliseconds: 500)); // Adjust time as needed

  //         var label = 'Line';
  //         await tester.tap(find.text(label).last);
  //         await tester.pumpFrames(
  //             app, const Duration(milliseconds: 500)); // Adjust time as needed

  //       },
  //     )
  //     ..addScenario(
  //       widget: app,
  //       name: 'Single Triangle',
  //       onCreate: (scenarioWidgetKey) async {
  //         final finder = find.descendant(
  //           of: find.byKey(scenarioWidgetKey),
  //           matching: find.byType(DropdownButton<TrailShape>),
  //         );
  //         expect(finder, findsOneWidget);
  //         await tester.pumpFrames(
  //             app, const Duration(milliseconds: 500)); // Adjust time as needed

  //         var label = 'Single Triangle';
  //         await tester.tap(find.text(label).last);
  //         await tester.pumpFrames(
  //             app, const Duration(milliseconds: 500)); // Adjust time as needed

  //       },
  //     )
  //     ..addScenario(
  //       widget: app,
  //       name: 'Multiple Triangles',
  //       onCreate: (scenarioWidgetKey) async {
  //         final finder = find.descendant(
  //           of: find.byKey(scenarioWidgetKey),
  //           matching: find.byType(DropdownButton<TrailShape>),
  //         );
  //         expect(finder, findsOneWidget);
  //         await tester.pumpFrames(
  //             app, const Duration(milliseconds: 500)); // Adjust time as needed

  //         var label = 'Multiple Triangles';
  //         await tester.tap(find.text(label).last);
  //         await tester.pumpFrames(
  //             app, const Duration(milliseconds: 500)); // Adjust time as needed

  //       },
  //     );
  //   await tester.pumpDeviceBuilder(builder);

  //   await screenMatchesGolden(tester, 'flutter_demo_page_multiple_scenarios');
  // });
}
