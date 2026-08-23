import 'package:bouncy_ball_physics/ball.dart';
import 'package:bouncy_ball_physics/trail_mesh.dart';
import 'package:bouncy_ball_physics/trail_shape.dart';
import 'package:flutter/material.dart';

/// Draws every trail and every ball through `Canvas.drawVertices`.
///
/// All geometry for a frame is triangulated on the CPU into a few
/// `ui.Vertices` batches with per-vertex colour, so the number of draw calls
/// is independent of ball and trail counts.
class BallVerticesPainter extends CustomPainter {
  BallVerticesPainter({required this.balls, this.trailShape = TrailShape.line});

  final List<Ball> balls;
  final TrailShape trailShape;

  final Paint _paint = Paint();
  final TrailMeshBuilder _mesh = TrailMeshBuilder();

  @override
  void paint(Canvas canvas, Size size) {
    _mesh.draw(canvas, _paint, balls, trailShape);
    _mesh.drawBalls(canvas, _paint, balls);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
