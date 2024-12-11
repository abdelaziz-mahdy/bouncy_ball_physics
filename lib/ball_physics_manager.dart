import 'dart:math';
import 'package:bouncy_ball_physics/ball.dart';
import 'package:flutter/material.dart';

class BallPhysicsManager {
  static final BallPhysicsManager _instance = BallPhysicsManager._internal();

  factory BallPhysicsManager() => _instance;

  BallPhysicsManager._internal();

  final Random random = Random();
  final List<Ball> balls = [];
  final ValueNotifier<int> ballCountNotifier = ValueNotifier(1);
  final ValueNotifier<double> fpsNotifier = ValueNotifier(0.0);
  final ValueNotifier<int> ballLimitNotifier = ValueNotifier(100);
  final ValueNotifier<int> tailLengthNotifier = ValueNotifier(100);
  double slidersBallsMaxValue = 5000;
  double slidersBallsMinValue = 1;
  double slidersTailMaxValue = 500;
  double slidersTailMinValue = 1;
  static const int fpsAverageCount = 60;
  final List<double> _fpsValues = [];

  int speed = 10;
  Duration noSpawnDuration = const Duration(milliseconds: 100);
  DateTime? lastFrameTime;

  int startingBallCount = 1;

  void resetBalls(Size size) {
    balls.clear();
    for (int i = 0; i < startingBallCount; i++) {
      balls.add(_createBall(size));
    }
    ballCountNotifier.value = balls.length;
  }

  Ball _createBall(Size size) {
    return Ball(
      position: Offset(size.width / 2, size.height / 2),
      velocity: Offset(
          random.nextDouble() * speed - 2, random.nextDouble() * speed - 2),
      color: Color.fromRGBO(
          random.nextInt(256), random.nextInt(256), random.nextInt(256), 1),
      radius: 20,
    );
  }

  void updatePhysics(BuildContext context, Size widgetSize) {
    List<Ball> newBalls = [];
    DateTime now = DateTime.now();

    if (lastFrameTime != null) {
      double delta = now.difference(lastFrameTime!).inMilliseconds.toDouble();
      if (delta > 0) {
        double fps = 1000 / delta;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            updateFpsAverage(fps);
          }
        });
      }
    }
    lastFrameTime = now;
    if (balls.length > ballLimitNotifier.value) {
      balls.removeRange(0, balls.length - ballLimitNotifier.value);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          ballCountNotifier.value = balls.length;
        }
      });
    }
    for (var ball in balls) {
      ball.position += ball.velocity;

      // Update the trail
      ball.trail.add(ball.position);
      if (ball.trail.length > tailLengthNotifier.value) {
        ball.trail.removeRange(0, ball.trail.length - tailLengthNotifier.value);
      }

      // Check for cooldown and balls limit
      bool canSpawn = DateTime.now().difference(ball.creationTime) >
              noSpawnDuration &&
          (ballCountNotifier.value + newBalls.length) < ballLimitNotifier.value;

      // Check for boundary collisions
      if (ball.position.dx - ball.radius < 0 ||
          ball.position.dx + ball.radius > widgetSize.width) {
        ball.velocity = Offset(-ball.velocity.dx, ball.velocity.dy);
        ball.position = Offset(
            ball.radius +
                (ball.position.dx - ball.radius).abs() % widgetSize.width,
            ball.position.dy);
        if (canSpawn) newBalls.add(_createBall(widgetSize));
      }
      if (ball.position.dy - ball.radius < 0 ||
          ball.position.dy + ball.radius > widgetSize.height) {
        ball.velocity = Offset(ball.velocity.dx, -ball.velocity.dy);
        ball.position = Offset(
            ball.position.dx,
            ball.radius +
                (ball.position.dy - ball.radius).abs() % widgetSize.height);
        if (canSpawn) newBalls.add(_createBall(widgetSize));
      }
    }
    if (newBalls.isNotEmpty) {
      balls.addAll(newBalls);
      // Schedule the update to occur after the build phase
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          ballCountNotifier.value = balls.length;
        }
      });
    }
  }

  void updateFpsAverage(double newFps) {
    _fpsValues.add(newFps);
    if (_fpsValues.length > fpsAverageCount) {
      _fpsValues.removeAt(0);
    }
    double averageFps = _fpsValues.reduce((a, b) => a + b) / _fpsValues.length;
    fpsNotifier.value = averageFps;
  }
}
