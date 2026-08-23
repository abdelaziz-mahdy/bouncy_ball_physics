import 'dart:ui' as ui;
import 'package:bouncy_ball_physics/ball.dart';
import 'package:bouncy_ball_physics/trail_shape.dart';
import 'package:flutter/material.dart';

class BallShaderPainter extends CustomPainter {
  List<Ball> balls;
  TrailShape trailShape;
  ui.FragmentProgram? ballProgram;
  ui.FragmentProgram? trailProgram;

  // Cached shader instances - reuse instead of creating new ones
  ui.FragmentShader? _cachedBallShader;
  ui.FragmentShader? _cachedTrailShader;

  // Cached paint objects to reduce allocations
  final Paint _shaderPaint = Paint();

  BallShaderPainter({
    required this.balls,
    this.trailShape = TrailShape.line,
    this.ballProgram,
    this.trailProgram,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (ballProgram == null || trailProgram == null) {
      // Fallback to canvas rendering if shaders aren't loaded
      _paintWithCanvas(canvas, size);
      return;
    }

    // Initialize cached shaders once
    _cachedBallShader ??= ballProgram!.fragmentShader();
    _cachedTrailShader ??= trailProgram!.fragmentShader();

    // Use shader-based rendering
    for (var ball in balls) {
      // Draw trail using shader
      switch (trailShape) {
        case TrailShape.line:
          _drawLineTrailShader(canvas, ball, size);
          break;
        case TrailShape.singleTriangle:
          // For triangles, fall back to canvas
          _drawSingleTriangleTrailCanvas(canvas, ball);
          break;
        case TrailShape.multipleTriangles:
          // For triangles, fall back to canvas
          _drawMultipleTrianglesTrailCanvas(canvas, ball);
          break;
      }

      // Draw ball using shader
      _drawBallShader(canvas, ball, size);
    }
  }

  void _drawBallShader(Canvas canvas, Ball ball, Size size) {
    if (_cachedBallShader == null) return;

    // Reuse cached shader - just update uniforms
    final shader = _cachedBallShader!;

    // Set uniforms
    shader.setFloat(0, size.width);   // uResolution.x
    shader.setFloat(1, size.height);  // uResolution.y
    shader.setFloat(2, ball.position.dx);  // uPosition.x
    shader.setFloat(3, ball.position.dy);  // uPosition.y
    shader.setFloat(4, ball.radius);       // uRadius

    // Convert color to premultiplied alpha
    shader.setFloat(5, ball.color.r * ball.color.a);
    shader.setFloat(6, ball.color.g * ball.color.a);
    shader.setFloat(7, ball.color.b * ball.color.a);
    shader.setFloat(8, ball.color.a);

    // Draw a rectangle covering the ball area
    final rect = Rect.fromCircle(
      center: ball.position,
      radius: ball.radius + 2.0, // Add some padding for anti-aliasing
    );

    _shaderPaint.shader = shader;
    canvas.drawRect(rect, _shaderPaint);
  }

  void _drawLineTrailShader(Canvas canvas, Ball ball, Size size) {
    if (_cachedTrailShader == null) return;

    // Reuse cached shader - just update uniforms for each trail segment
    final shader = _cachedTrailShader!;

    for (var i = 0; i < ball.trail.length - 1; i++) {
      // Set uniforms
      shader.setFloat(0, size.width);   // uResolution.x
      shader.setFloat(1, size.height);  // uResolution.y
      shader.setFloat(2, ball.trail[i].dx);      // uPoint1.x
      shader.setFloat(3, ball.trail[i].dy);      // uPoint1.y
      shader.setFloat(4, ball.trail[i + 1].dx);  // uPoint2.x
      shader.setFloat(5, ball.trail[i + 1].dy);  // uPoint2.y
      shader.setFloat(6, ball.radius / 10);      // uThickness

      // Convert color to premultiplied alpha
      shader.setFloat(7, ball.color.r * ball.color.a);
      shader.setFloat(8, ball.color.g * ball.color.a);
      shader.setFloat(9, ball.color.b * ball.color.a);
      shader.setFloat(10, ball.color.a);

      // Draw a rectangle covering the line segment
      final p1 = ball.trail[i];
      final p2 = ball.trail[i + 1];
      final thickness = ball.radius / 10;

      final rect = Rect.fromLTRB(
        (p1.dx < p2.dx ? p1.dx : p2.dx) - thickness - 2,
        (p1.dy < p2.dy ? p1.dy : p2.dy) - thickness - 2,
        (p1.dx > p2.dx ? p1.dx : p2.dx) + thickness + 2,
        (p1.dy > p2.dy ? p1.dy : p2.dy) + thickness + 2,
      );

      _shaderPaint.shader = shader;
      canvas.drawRect(rect, _shaderPaint);
    }
  }

  // Fallback canvas implementations
  void _paintWithCanvas(Canvas canvas, Size size) {
    for (var ball in balls) {
      final paint = Paint()..color = ball.color;
      paint.strokeWidth = ball.radius / 10;

      switch (trailShape) {
        case TrailShape.line:
          _drawLineTrailCanvas(canvas, ball, paint);
          break;
        case TrailShape.singleTriangle:
          _drawSingleTriangleTrailCanvas(canvas, ball);
          break;
        case TrailShape.multipleTriangles:
          _drawMultipleTrianglesTrailCanvas(canvas, ball);
          break;
      }

      canvas.drawCircle(ball.position, ball.radius, paint);
    }
  }

  void _drawLineTrailCanvas(Canvas canvas, Ball ball, Paint paint) {
    for (var i = 0; i < ball.trail.length - 1; i++) {
      canvas.drawLine(ball.trail[i], ball.trail[i + 1],
          paint..strokeWidth = ball.radius / 10);
    }
  }

  void _drawSingleTriangleTrailCanvas(Canvas canvas, Ball ball) {
    var path = Path();
    if (ball.trail.isNotEmpty) {
      path.moveTo(ball.trail.first.dx, ball.trail.first.dy);
      for (var point in ball.trail.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
    }
    final paint = Paint()..color = ball.color;
    canvas.drawPath(path, paint);
  }

  void _drawMultipleTrianglesTrailCanvas(Canvas canvas, Ball ball) {
    final paint = Paint()..color = ball.color;
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
