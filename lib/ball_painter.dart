import 'dart:ui' as ui;

import 'package:bouncy_ball_physics/ball.dart';
import 'package:bouncy_ball_physics/trail_shape.dart';
import 'package:flutter/material.dart';

/// Draws balls and trails with plain `Canvas` calls.
///
/// Each ball's trail is one draw: a polyline via `drawPoints` for line
/// trails, or a single `Path` for the triangle shapes. Paints are cached per
/// colour.
class BallPainter extends CustomPainter {
  BallPainter({required this.balls, this.trailShape = TrailShape.line});

  final List<Ball> balls;
  final TrailShape trailShape;

  final Map<Color, Paint> _fillCache = {};
  final Map<Color, Paint> _strokeCache = {};

  Paint _fill(Ball ball) =>
      _fillCache.putIfAbsent(ball.color, () => Paint()..color = ball.color);

  Paint _stroke(Ball ball) => _strokeCache.putIfAbsent(
        ball.color,
        () => Paint()
          ..color = ball.color
          ..strokeWidth = ball.radius / 10
          ..style = PaintingStyle.stroke,
      );

  @override
  void paint(Canvas canvas, Size size) {
    for (final ball in balls) {
      if (ball.trail.length >= 2) {
        switch (trailShape) {
          case TrailShape.line:
            canvas.drawPoints(ui.PointMode.polygon, ball.trail, _stroke(ball));
          case TrailShape.singleTriangle:
            canvas.drawPath(_polygonPath(ball.trail), _fill(ball));
          case TrailShape.multipleTriangles:
            canvas.drawPath(_fanPath(ball), _fill(ball));
        }
      }
      canvas.drawCircle(ball.position, ball.radius, _fill(ball));
    }
  }

  Path _polygonPath(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    return path..close();
  }

  /// One path holding every `(trail[i], trail[i+1], position)` triangle.
  Path _fanPath(Ball ball) {
    final path = Path();
    final apex = ball.position;
    for (var i = 0; i < ball.trail.length - 1; i++) {
      path
        ..moveTo(ball.trail[i].dx, ball.trail[i].dy)
        ..lineTo(ball.trail[i + 1].dx, ball.trail[i + 1].dy)
        ..lineTo(apex.dx, apex.dy)
        ..close();
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
