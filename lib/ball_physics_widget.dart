import 'dart:math';

import 'package:bouncy_ball_physics/ball.dart';
import 'package:bouncy_ball_physics/trail_shape_selector.dart';
import 'package:flutter/material.dart';

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
  int ballLimit = 100;
  int speed = 10;
  int tailLength = 100;
  Duration noSpawnDuration = const Duration(milliseconds: 100);
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
    balls = [_createBall(size)]; // Pass this size to _createBall
    ballCountNotifier.value = balls.length;
  }

  Ball _createBall(Size size) {
    return Ball(
      position: Offset(size.width / 2,
          size.height / 2), // Set position to center of provided size
      velocity: Offset(
          random.nextDouble() * speed - 2, random.nextDouble() * speed - 2),
      color: Color.fromRGBO(
          random.nextInt(256), random.nextInt(256), random.nextInt(256), 1),
      radius: 20,
    );
  }

  void _updatePhysics(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    List<Ball> newBalls = [];
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
    for (var ball in balls) {
      ball.position += ball.velocity;

      // Update the trail
      ball.trail.add(ball.position);
      if (ball.trail.length > tailLength) {
        ball.trail.removeAt(0);
      }

      // Check for cooldown
      bool canSpawn =
          DateTime.now().difference(ball.creationTime) > noSpawnDuration &&
              ballCountNotifier.value < ballLimit;

      // Check for boundary collisions
      if (ball.position.dx - ball.radius < 0 ||
          ball.position.dx + ball.radius > size.width) {
        ball.velocity = Offset(-ball.velocity.dx, ball.velocity.dy);
        ball.position = Offset(
            ball.radius + (ball.position.dx - ball.radius).abs() % size.width,
            ball.position.dy);
        if (canSpawn) newBalls.add(_createBall(size));
      }
      if (ball.position.dy - ball.radius < 0 ||
          ball.position.dy + ball.radius > size.height) {
        ball.velocity = Offset(ball.velocity.dx, -ball.velocity.dy);
        ball.position = Offset(ball.position.dx,
            ball.radius + (ball.position.dy - ball.radius).abs() % size.height);
        if (canSpawn) newBalls.add(_createBall(size));
      }
    }

    if (newBalls.isNotEmpty) {
      balls.addAll(newBalls);
      // Schedule the update to occur after the build phase
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ballCountNotifier.value = balls.length;
        }
      });
    }
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
