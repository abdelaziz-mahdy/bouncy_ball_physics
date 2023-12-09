import 'package:bouncy_ball_physics/ball.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:bouncy_ball_physics/ball.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class BallPainter extends CustomPainter {
  List<Ball> balls;

  BallPainter({required this.balls});

  final Map<Color, Paint> _paintCache = {};

  Paint _getPaintForBall(Ball ball) {
    return _paintCache.putIfAbsent(
      ball.color,
      () => Paint()..color = ball.color,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (var ball in balls) {
      final paint = _getPaintForBall(ball);

      var path = Path();
      if (ball.trail.isNotEmpty) {
        path.moveTo(ball.trail.first.dx, ball.trail.first.dy);
        for (var point in ball.trail.skip(1)) {
          path.lineTo(point.dx, point.dy);
        }
      }
      canvas.drawPath(path, paint..strokeWidth = ball.radius / 10);
      canvas.drawCircle(ball.position, ball.radius, paint);
    }
  }

  @override
  bool shouldRepaint(BallPainter oldDelegate) {
    return !listEquals(balls, oldDelegate.balls);
  }
}
