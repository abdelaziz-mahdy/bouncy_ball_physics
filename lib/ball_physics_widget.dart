import 'dart:math';

import 'package:bouncy_ball_physics/ball.dart';
import 'package:bouncy_ball_physics/common_classes.dart';
import 'package:bouncy_ball_physics/trail_shape_selector.dart';
import 'package:bouncy_ball_physics/worker/worker.dart';
import 'package:flutter/material.dart';
import 'package:squadron/squadron.dart';

import 'ball_painter.dart';

class BallPhysicsWidget extends StatefulWidget {
  const BallPhysicsWidget({super.key});

  @override
  BallPhysicsWidgetState createState() => BallPhysicsWidgetState();
}

class BallPhysicsWidgetState extends State<BallPhysicsWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<Ball> balls = [];
  Random random = Random();
  ValueNotifier<int> ballCountNotifier = ValueNotifier(1);
  ValueNotifier<double> fpsNotifier = ValueNotifier(0.0);
  ValueNotifier<TrailShape> trailShapeNotifier = ValueNotifier(TrailShape.line);
  DateTime? lastFrameTime;
  static const int fpsAverageCount = 60; // Average over 60 frames
  final List<double> _fpsValues = [];
  int ballLimit = 1000;
  int speed = 10;
  int tailLength = 100;
  Duration noSpawnDuration = const Duration(milliseconds: 100);
  MyPhysicsWorkerWorkerPool worker = MyPhysicsWorkerWorkerPool(concurrencySettings: ConcurrencySettings.oneCpuThread);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 16))
      ..repeat();
    // resetBalls();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    resetBalls(); // Reset balls when dependencies change
  }

  resetBalls() {
    Size size =
        MediaQuery.of(context).size; // Get the size of the current context
    balls = [_createBall(size, speed)]; // Pass this size to _createBall
    ballCountNotifier.value = balls.length;
  }

  Ball _createBall(Size size, int speed) {
    Random random = Random();
    return Ball(
      position: CustomOffset(size.width / 2,
          size.height / 2), // Set position to center of provided size
      velocity: CustomOffset(
          random.nextDouble() * speed - 2, random.nextDouble() * speed - 2),
      color: [
          random.nextInt(256), random.nextInt(256), random.nextInt(256), 1],
      radius: 20,
    );
  }

  void frameCounter() {
    DateTime now = DateTime.now();

    if (lastFrameTime != null) {
      double delta = now.difference(lastFrameTime!).inMilliseconds.toDouble();
      if (delta > 0) {
        double fps = 1000 / delta;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _updateFpsAverage(fps);
          }
        });
      }
    }
    lastFrameTime = now;
  }

  Future<void> _updatePhysics(BuildContext context) async {
    Size size = MediaQuery.of(context).size;
    balls = await worker.updatePhysics(
        balls, CustomSize(size.width, size.height), tailLength, ballLimit, noSpawnDuration, speed);

    // Schedule the update to occur after the build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ballCountNotifier.value = balls.length;
      }
    });
  }

  void _updateFpsAverage(double newFps) {
    _fpsValues.add(newFps);
    if (_fpsValues.length > fpsAverageCount) {
      _fpsValues.removeAt(0);
    }
    double averageFps = _fpsValues.reduce((a, b) => a + b) / _fpsValues.length;
    fpsNotifier.value = averageFps;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
                flex: 2,
                child:
                    TrailShapeSelector(trailShapeNotifier: trailShapeNotifier)),
            Expanded(
              child: ValueListenableBuilder<int>(
                valueListenable: ballCountNotifier,
                builder: (context, count, child) {
                  return Text(
                    'Balls: $count',
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  );
                },
              ),
            ),
            Expanded(
              child: ValueListenableBuilder<double>(
                valueListenable: fpsNotifier,
                builder: (context, fps, child) {
                  return Text(
                    'FPS: ${fps.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  );
                },
              ),
            ),
          ],
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
                // color: Colors.black,
                border: Border.all()),
            child: ValueListenableBuilder<TrailShape>(
                valueListenable: trailShapeNotifier,
                builder: (context, trailShape, child) {
                  return AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      _updatePhysics(context);
                      frameCounter();
                      return CustomPaint(
                        painter:
                            BallPainter(balls: balls, trailShape: trailShape),
                        child: Container(),
                      );
                    },
                  );
                }),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    ballCountNotifier.dispose();
    super.dispose();
  }
}
