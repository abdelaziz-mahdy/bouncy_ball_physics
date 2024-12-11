import 'package:bouncy_ball_physics/ball.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Enum representing the shape of the trail left by balls.
enum TrailShape {
  line,
  singleTriangle,
  multipleTriangles,
}

/// A custom painter for rendering bouncing balls with optional trails.
class BallPainter extends CustomPainter {
  /// The list of balls to be painted.
  List<Ball> balls;

  /// The shape of the trail for each ball.
  TrailShape trailShape;

  /// Cache for ball paints based on their colors.
  final Map<Color, Paint> _paintCache = {};

  /// Constructor to initialize the ball painter.
  /// [balls] is the list of balls to be painted.
  /// [trailShape] defines the trail style for the balls. Default is [TrailShape.line].
  BallPainter({required this.balls, this.trailShape = TrailShape.line});

  /// Retrieves or creates a [Paint] object for a given ball.
  Paint _getPaintForBall(Ball ball) {
    return _paintCache.putIfAbsent(
      ball.color,
      () => Paint()..color = ball.color,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    int ballCount = balls.length;
    int hiddenBalls = 0;
    double totalHiddenPercentage = 0.0;

    // Sort balls by Y-position (descending).
    balls.sort((a, b) => b.position.dy.compareTo(a.position.dy));

    // Store bounding boxes of drawn balls.
    List<Rect> drawnBallsBounds = [];

    for (var ball in balls) {
      final paint = _getPaintForBall(ball);
      paint.strokeWidth = ball.radius / 10;

      /// Calculate the hidden percentage of the current ball's bounding box relative to previously drawn balls.
      /// Iterates through the bounding boxes of previously drawn balls to determine how much of the current ball is hidden.
      /// Stops early if the hidden percentage reaches or exceeds 40% (0.4) to optimize performance.
      double hiddenPct = 0.0;
      for (var drawnBounds in drawnBallsBounds) {
        hiddenPct = ball.boundingBox.hiddenPercentage(drawnBounds);
        if (hiddenPct >= 0.4) {
          break; // Exit the loop early if the ball is sufficiently hidden.
        }
      }

      // If the ball is less than 40% hidden, draw it.
      if (hiddenPct < 0.4) {
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

        // If the ball is completely visible, add its bounds to the drawn list.
        if (hiddenPct == 0.0) {
          drawnBallsBounds.add(ball.boundingBox);
        }
      } else {
        hiddenBalls++;
      }
      totalHiddenPercentage += hiddenPct;
    }

    // Calculate and log the overall hidden percentage.
    double overallHiddenPercentage =
        ballCount > 0 ? (totalHiddenPercentage / ballCount) * 100 : 0.0;

    if (kDebugMode) {
      print(
          "ballCount: $ballCount, hiddenBalls: $hiddenBalls, hiddenPercentage: ${overallHiddenPercentage.toStringAsFixed(2)}%}");
    }
  }

  /// Draws a line trail for the ball.
  void _drawLineTrail(Canvas canvas, Ball ball, Paint paint) {
    for (var i = 0; i < ball.trail.length - 1; i++) {
      canvas.drawLine(ball.trail[i], ball.trail[i + 1],
          paint..strokeWidth = ball.radius / 10);
    }
  }

  /// Draws a single triangle trail for the ball.
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

  /// Draws multiple triangles as a trail for the ball.
  void _drawMultipleTrianglesTrail(Canvas canvas, Ball ball, Paint paint) {
    for (int i = 0; i < ball.trail.length - 1; i++) {
      _drawTriangle(
          canvas, ball.trail[i], ball.trail[i + 1], ball.position, paint);
    }
  }

  /// Draws a single triangle given three points.
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

/// Extension methods for the [Rect] class.
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
    // If there is no overlap, return 0.0.
    if (!overlaps(other)) {
      return 0.0;
    }

    // Calculate the intersection rectangle.
    Rect intersection = intersect(other);

    // Calculate the area of this rectangle and the intersection rectangle.
    double thisArea = width * height;
    double intersectionArea = intersection.width * intersection.height;

    // Calculate the hidden percentage (0 to 1 range).
    return (intersectionArea / thisArea).clamp(0.0, 1.0);
  }
}
