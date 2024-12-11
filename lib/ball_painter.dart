import 'package:bouncy_ball_physics/ball.dart';
import 'package:flutter/material.dart';

enum TrailShape {
  line,
  singleTriangle,
  multipleTriangles,
}

class BallPainter extends CustomPainter {
  List<Ball> balls;
  TrailShape trailShape;

  BallPainter({required this.balls, this.trailShape = TrailShape.line});

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
      paint.strokeWidth = ball.radius / 10;

      switch (trailShape) {
        case TrailShape.line:
          // Draw the trail as a line
          _drawLineTrail(canvas, ball, paint);
          break;
        case TrailShape.singleTriangle:
          // Draw the trail as a single triangle
          _drawSingleTriangleTrail(canvas, ball, paint);
          break;
        case TrailShape.multipleTriangles:
          // Draw the trail as multiple triangles
          _drawMultipleTrianglesTrail(canvas, ball, paint);
          break;
      }

      canvas.drawCircle(ball.position, ball.radius, paint);
    }
  }

  void _drawLineTrail(Canvas canvas, Ball ball, Paint paint) {
    for (var i = 0; i < ball.trail.length - 1; i++) {
      canvas.drawLine(ball.trail[i], ball.trail[i + 1],
          paint..strokeWidth = ball.radius / 10);
    }
  }

  void _drawSingleTriangleTrail(Canvas canvas, Ball ball, Paint paint) {
    var path = Path();
    if (ball.trail.isNotEmpty) {
      path.moveTo(ball.trail.first.dx, ball.trail.first.dy);
      for (var point in ball.trail.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(path, paint);
  }

  void _drawMultipleTrianglesTrail(Canvas canvas, Ball ball, Paint paint) {
    for (int i = 0; i < ball.trail.length - 1; i++) {
      _drawTriangle(
          canvas, ball.trail[i], ball.trail[i + 1], ball.position, paint);
    }
  }

  void _drawTriangle(
      Canvas canvas, Offset point1, Offset point2, Offset point3, Paint paint) {
    var path = Path();
    path.moveTo(point1.dx, point1.dy);
    path.lineTo(point2.dx, point2.dy);
    path.lineTo(point3.dx, point3.dy);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
