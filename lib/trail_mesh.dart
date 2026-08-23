import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:bouncy_ball_physics/ball.dart';
import 'package:bouncy_ball_physics/trail_shape.dart';

/// Triangulates every ball's trail into `ui.Vertices` batches for
/// `Canvas.drawVertices`, so a frame's worth of trails costs a handful of
/// draw calls instead of one per segment.
///
/// Scratch arrays are grow-only and reused across frames. `ui.Vertices.raw`
/// indexes with 16-bit integers, so the batch is flushed whenever the next
/// ball would push past 65 535 vertices.
class TrailMeshBuilder {
  static const int _maxVertices = 0xFFFF;

  Float32List _positions = Float32List(0);
  Int32List _colors = Int32List(0);
  Uint16List _indices = Uint16List(0);

  static const int _circleSegments = 24;

  /// Draws every ball as a triangle-fan disc, batched like [draw].
  void drawBalls(ui.Canvas canvas, ui.Paint paint, List<Ball> balls) {
    var v = 0;
    var i = 0;
    void flush() {
      if (i == 0) return;
      _flush(canvas, paint, v, i);
      v = 0;
      i = 0;
    }

    const vCount = _circleSegments + 1;
    const iCount = _circleSegments * 3;
    for (final ball in balls) {
      if (v + vCount > _maxVertices) flush();
      _ensureCapacity(v + vCount, i + iCount);
      final color = ball.color.toARGB32();
      final c = ball.position;
      final r = ball.radius;
      final base = v;
      _put(v++, c.dx, c.dy, color);
      for (var k = 0; k < _circleSegments; k++) {
        final a = k * 2 * math.pi / _circleSegments;
        _put(v++, c.dx + r * math.cos(a), c.dy + r * math.sin(a), color);
      }
      for (var k = 0; k < _circleSegments; k++) {
        _indices[i++] = base;
        _indices[i++] = base + 1 + k;
        _indices[i++] = base + 1 + (k + 1) % _circleSegments;
      }
    }
    flush();
  }

  void _flush(ui.Canvas canvas, ui.Paint paint, int v, int i) {
    final vertices = ui.Vertices.raw(
      ui.VertexMode.triangles,
      Float32List.sublistView(_positions, 0, v * 2),
      colors: Int32List.sublistView(_colors, 0, v),
      indices: Uint16List.sublistView(_indices, 0, i),
    );
    canvas.drawVertices(vertices, ui.BlendMode.srcOver, paint);
    vertices.dispose();
  }

  /// Draws all trails in [balls] onto [canvas] with [paint].
  void draw(ui.Canvas canvas, ui.Paint paint, List<Ball> balls, TrailShape shape) {
    var v = 0;
    var i = 0;
    void flush() {
      if (i == 0) return;
      _flush(canvas, paint, v, i);
      v = 0;
      i = 0;
    }

    for (final ball in balls) {
      final n = ball.trail.length;
      if (n < 2) continue;
      final (vCount, iCount) = switch (shape) {
        TrailShape.line => (n * 2, (n - 1) * 6),
        TrailShape.singleTriangle ||
        TrailShape.multipleTriangles =>
          (n + 1, (n - 1) * 3),
      };
      if (v + vCount > _maxVertices) flush();
      _ensureCapacity(v + vCount, i + iCount);
      final color = ball.color.toARGB32();
      final base = v;
      switch (shape) {
        case TrailShape.line:
          final half = math.max(0.5, ball.radius / 20);
          for (var k = 0; k < n; k++) {
            final p = ball.trail[k];
            final from = k + 1 < n ? p : ball.trail[k - 1];
            final to = k + 1 < n ? ball.trail[k + 1] : p;
            var dx = to.dx - from.dx;
            var dy = to.dy - from.dy;
            final len = math.sqrt(dx * dx + dy * dy);
            if (len > 0) {
              dx /= len;
              dy /= len;
            }
            final nx = -dy * half;
            final ny = dx * half;
            _put(v++, p.dx + nx, p.dy + ny, color);
            _put(v++, p.dx - nx, p.dy - ny, color);
          }
          for (var k = 0; k < n - 1; k++) {
            final a = base + k * 2;
            _indices[i++] = a;
            _indices[i++] = a + 1;
            _indices[i++] = a + 2;
            _indices[i++] = a + 1;
            _indices[i++] = a + 3;
            _indices[i++] = a + 2;
          }
        case TrailShape.singleTriangle:
        case TrailShape.multipleTriangles:
          final apex = shape == TrailShape.singleTriangle
              ? ball.trail.first
              : ball.position;
          _put(v++, apex.dx, apex.dy, color);
          for (var k = 0; k < n; k++) {
            final p = ball.trail[k];
            _put(v++, p.dx, p.dy, color);
          }
          for (var k = 0; k < n - 1; k++) {
            _indices[i++] = base;
            _indices[i++] = base + 1 + k;
            _indices[i++] = base + 2 + k;
          }
      }
    }
    flush();
  }

  void _put(int idx, double x, double y, int color) {
    _positions[idx * 2] = x;
    _positions[idx * 2 + 1] = y;
    _colors[idx] = color;
  }

  void _ensureCapacity(int vertices, int indices) {
    if (_colors.length < vertices) {
      final cap = math.min(_maxVertices, math.max(vertices, _colors.length * 2));
      _positions = Float32List(cap * 2)..setAll(0, _positions);
      _colors = Int32List(cap)..setAll(0, _colors);
    }
    if (_indices.length < indices) {
      final cap = math.max(indices, _indices.length * 2);
      _indices = Uint16List(cap)..setAll(0, _indices);
    }
  }
}
