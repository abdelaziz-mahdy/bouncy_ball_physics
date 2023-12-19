import 'dart:math';

import 'package:bouncy_ball_physics/ball.dart';
import 'package:flutter/material.dart';
import 'package:squadron/squadron.dart';
import 'package:squadron/squadron.dart';
import 'package:squadron/squadron_annotations.dart';

import 'worker.activator.g.dart';

part 'worker.worker.g.dart';

@UseLogger(ConsoleSquadronLogger)
@SquadronService()
class MyPhysicsWorker {
  Ball _createBall(Size size, int speed) {
    Random random = Random();
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

  @SquadronMethod()
  Future<List<Ball>> updatePhysics(List<Ball> balls, Size size, int tailLength,
      int ballLimit, Duration noSpawnDuration, int speed) async {
    List<Ball> newBalls = [];
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
              (balls.length + newBalls.length) < ballLimit;

      // Check for boundary collisions
      if (ball.position.dx - ball.radius < 0 ||
          ball.position.dx + ball.radius > size.width) {
        ball.velocity = Offset(-ball.velocity.dx, ball.velocity.dy);
        ball.position = Offset(
            ball.radius + (ball.position.dx - ball.radius).abs() % size.width,
            ball.position.dy);
        if (canSpawn) newBalls.add(_createBall(size, speed));
      }
      if (ball.position.dy - ball.radius < 0 ||
          ball.position.dy + ball.radius > size.height) {
        ball.velocity = Offset(ball.velocity.dx, -ball.velocity.dy);
        ball.position = Offset(ball.position.dx,
            ball.radius + (ball.position.dy - ball.radius).abs() % size.height);
        if (canSpawn) newBalls.add(_createBall(size, speed));
      }
    }

    if (newBalls.isNotEmpty) {
      balls.addAll(newBalls);
    }

    return balls;
  }
}
