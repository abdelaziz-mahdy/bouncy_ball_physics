import 'package:bouncy_ball_physics/ball.dart';
import 'package:flutter/foundation.dart';
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
  @override
  void paint(Canvas canvas, Size size) {
    int ballCount = balls.length;
    int hiddenBalls = 0;
    double totalHiddenPercentage = 0.0;

    // 1. Sort balls by Y-position (descending)
    balls.sort((a, b) => b.position.dy.compareTo(a.position.dy));

    List<Rect> drawnBallsBounds = []; // Store bounding boxes of drawn balls

    for (var ball in balls) {
      final paint = _getPaintForBall(ball);
      paint.strokeWidth = ball.radius / 10;

      double hiddenPct = 0.0;
      for (var drawnBounds in drawnBallsBounds) {
        hiddenPct = ball.boundingBox.hiddenPercentage(drawnBounds);
        if (hiddenPct >= 0.6) break;
      }

      if (hiddenPct < 0.6) {
        // Draw the ball because its not fully hidden
        switch (trailShape) {
          case TrailShape.line:
            _drawLineTrail(canvas, ball, paint);
            break;
          case TrailShape.singleTriangle:
            _drawSingleTriangleTrail(canvas, ball, paint);
            break;
          case TrailShape.multipleTriangles:
            _drawMultipleTrianglesTrail(canvas, ball, paint);
            break;
        }

        canvas.drawCircle(ball.position, ball.radius, paint);

        if (hiddenPct == 0.0) {
          drawnBallsBounds.add(ball.boundingBox);
        }
      } else {
        hiddenBalls++;
      }
      totalHiddenPercentage += hiddenPct;
    }

    // Calculate and print the overall hidden percentage
    double overallHiddenPercentage =
        ballCount > 0 ? (totalHiddenPercentage / ballCount) * 100 : 0.0;

    if (kDebugMode) {
      print(
          "ballCount: $ballCount, hiddenBalls: $hiddenBalls, hiddenPercentage: ${overallHiddenPercentage.toStringAsFixed(2)}%} s");
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
    Canvas canvas,
    Offset point1,
    Offset point2,
    Offset point3,
    Paint paint,
  ) {
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

extension RectExtensions on Rect {
  /// Checks if this rectangle completely contains another rectangle.
  bool containsRect(Rect other) {
    return left <= other.left &&
        right >= other.right &&
        top <= other.top &&
        bottom >= other.bottom;
  }

  /// Calculates the percentage of this rectangle that is hidden by another rectangle.
  /// Returns 0.0 if there is no overlap, and 1.0 if this rect is fully contained.
  double hiddenPercentage(Rect other) {
    // If there is no overlap, return 0.0
    if (!overlaps(other)) {
      return 0.0;
    }

    // Calculate the intersection rectangle
    Rect intersection = intersect(other);

    // Calculate the area of this rectangle and the intersection rectangle
    double thisArea = width * height;
    double intersectionArea = intersection.width * intersection.height;

    // Calculate the hidden percentage (0 to 1 range)
    return (intersectionArea / thisArea).clamp(0.0, 1.0);
  }
}
