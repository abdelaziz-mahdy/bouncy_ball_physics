import 'package:bouncy_ball_physics/trail_shape_selector.dart';
import 'package:flutter/material.dart';

import 'ball_painter.dart';

import 'package:bouncy_ball_physics/ball_physics_manager.dart';

class BallPhysicsWidget extends StatefulWidget {
  const BallPhysicsWidget({super.key});

  @override
  BallPhysicsWidgetState createState() => BallPhysicsWidgetState();
}

class BallPhysicsWidgetState extends State<BallPhysicsWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final BallPhysicsManager manager = BallPhysicsManager();
  final ValueNotifier<TrailShape> trailShapeNotifier =
      ValueNotifier(TrailShape.line);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 16))
      ..repeat();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => manager.resetBalls(MediaQuery.of(context).size));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: TrailShapeSelector(trailShapeNotifier: trailShapeNotifier),
            ),
            Expanded(
              child: ValueListenableBuilder<int>(
                valueListenable: manager.ballCountNotifier,
                builder: (context, count, child) {
                  return Text(
                    'Balls: $count',
                    style: Theme.of(context).textTheme.titleLarge,
                  );
                },
              ),
            ),
            Expanded(
              child: ValueListenableBuilder<double>(
                valueListenable: manager.fpsNotifier,
                builder: (context, fps, child) {
                  return Text(
                    'FPS: ${fps.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleLarge,
                  );
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => _showSettingsPanel(context),
            ),
          ],
        ),
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(border: Border.all()),
            child: LayoutBuilder(builder: (context, constraints) {
              return ValueListenableBuilder<TrailShape>(
                valueListenable: trailShapeNotifier,
                builder: (context, trailShape, child) {
                  return AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      manager.updatePhysics(context, constraints.biggest);
                      return CustomPaint(
                        painter: BallPainter(
                            balls: manager.balls, trailShape: trailShape),
                        child: Container(),
                      );
                    },
                  );
                },
              );
            }),
          ),
        ),
      ],
    );
  }

  void _showSettingsPanel(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Settings"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Balls Limit"),
              ValueListenableBuilder(
                  valueListenable: manager.ballLimitNotifier,
                  builder: (BuildContext context, int value, Widget? child) {
                    return Slider(
                      value: manager.ballLimitNotifier.value.toDouble(),
                      min: manager.slidersBallsMinValue,
                      max: manager.slidersBallsMaxValue,
                      divisions: (manager.slidersBallsMaxValue -
                              manager.slidersBallsMinValue)
                          .toInt(),
                      label: manager.ballLimitNotifier.value.toString(),
                      onChanged: (double value) {
                        manager.ballLimitNotifier.value = value.toInt();
                      },
                    );
                  }),
              const Text("Tail Length"),
              ValueListenableBuilder(
                  valueListenable: manager.tailLengthNotifier,
                  builder: (BuildContext context, int value, Widget? child) {
                    return Slider(
                        value: manager.tailLengthNotifier.value.toDouble(),
                        min: manager.slidersTailMinValue,
                        max: manager.slidersTailMaxValue,
                        divisions: (manager.slidersTailMaxValue -
                                manager.slidersTailMinValue)
                            .toInt(),
                        label: manager.tailLengthNotifier.value.toString(),
                        onChanged: (double value) {
                          manager.tailLengthNotifier.value = value.toInt();
                        });
                  })
            ],
          ),
          actions: [
            TextButton(
              child: const Text("Close"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
