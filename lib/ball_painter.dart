import 'package:bouncy_ball_physics/ball.dart';
import 'package:flutter/material.dart';

class BallPainter extends CustomPainter {
  List<Ball> balls;

  BallPainter({required this.balls});

  @override
  void paint(Canvas canvas, Size size) {
    for (var ball in balls) {
      final paint = Paint()..color = ball.color;
      for (var i = 0; i < ball.trail.length - 1; i++) {
        canvas.drawLine(ball.trail[i], ball.trail[i + 1], paint..strokeWidth = ball.radius / 10);
      }
      canvas.drawCircle(ball.position, ball.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
