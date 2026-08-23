import 'dart:math' as math;
import 'dart:typed_data';

import 'package:bouncy_ball_physics/ball.dart';
import 'package:bouncy_ball_physics/trail_shape.dart';
import 'package:flutter/material.dart' hide Material;
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// Renders the balls with the `flutter_scene` engine.
///
/// Scene units equal widget pixels: a ball at `Offset(x, y)` becomes a sphere
/// at `(x, -y, 0)`, and the camera sits on the +Z axis at a distance where its
/// 45° vertical field of view spans exactly the widget height.
///
/// Each ball owns a sphere [Node]. All trails share one [Node] whose
/// [MeshGeometry] is updatable: every frame the trail vertices are written
/// into reused CPU arrays and uploaded in place, so steady-state frames
/// allocate no geometry and issue a single draw for every trail.
class BallSceneView extends StatefulWidget {
  const BallSceneView({
    super.key,
    required this.balls,
    required this.trailShape,
    required this.onTick,
  });

  final List<Ball> balls;
  final TrailShape trailShape;

  /// Advances physics. Called once per rendered frame, before the scene graph
  /// is synced to [balls].
  final VoidCallback onTick;

  @override
  State<BallSceneView> createState() => _BallSceneViewState();
}

class _BallSceneViewState extends State<BallSceneView> {
  final Scene _scene = Scene();
  // Ball overrides == / hashCode on mutable fields (position, trail), so key
  // by identity.
  final Map<Ball, Node> _spheres = Map.identity();
  final Map<double, SphereGeometry> _sphereCache = {};
  final Map<Color, UnlitMaterial> _materialCache = {};
  late final PerspectiveCamera _camera = PerspectiveCamera(
    fovRadiansY: _fovY,
    fovNear: 1,
    fovFar: 100000,
  );
  Size _size = Size.zero;

  final _TrailBatch _trails = _TrailBatch();
  final Node _trailNode = Node();

  static const double _fovY = 45 * vm.degrees2Radians;

  @override
  void initState() {
    super.initState();
    _scene.add(_trailNode);
  }

  @override
  void dispose() {
    for (final n in _spheres.values) {
      _scene.remove(n);
    }
    _spheres.clear();
    _scene.remove(_trailNode);
    super.dispose();
  }

  void _updateCamera(Size size) {
    _size = size;
    final distance = (size.height / 2) / math.tan(_fovY / 2);
    final center = vm.Vector3(size.width / 2, -size.height / 2, 0);
    _camera
      ..position = center + vm.Vector3(0, 0, distance)
      ..target = center
      ..up = vm.Vector3(0, 1, 0);
  }

  UnlitMaterial _materialFor(Color c) => _materialCache.putIfAbsent(
        c,
        () => UnlitMaterial()
          ..baseColorFactor = vm.Vector4(c.r, c.g, c.b, c.a)
          ..doubleSided = true,
      );

  Node _createSphere(Ball ball) {
    final geometry = _sphereCache.putIfAbsent(
      ball.radius,
      () => SphereGeometry(radius: ball.radius, segments: 24, rings: 12),
    );
    final node = Node(mesh: Mesh(geometry, _materialFor(ball.color)));
    _scene.add(node);
    return node;
  }

  void _sync() {
    widget.onTick();
    final live = Set<Ball>.identity()..addAll(widget.balls);

    // Drop nodes for balls that were removed by the ball limit or a reset.
    _spheres.removeWhere((ball, node) {
      if (live.contains(ball)) return false;
      _scene.remove(node);
      return true;
    });

    for (final ball in widget.balls) {
      final node = _spheres.putIfAbsent(ball, () => _createSphere(ball));
      final p = ball.position;
      node.position = vm.Vector3(p.dx, -p.dy, 0);
    }

    _trailNode.mesh = _trails.update(widget.balls, widget.trailShape);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        if (size != _size) _updateCamera(size);
        return SceneView(
          _scene,
          camera: _camera,
          onTick: (_, __) => _sync(),
          loadingBuilder: (context, progress) =>
              const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}

/// One mesh holding every ball's trail, rebuilt in place each frame.
///
/// Line trails become a flat quad strip in the z = 0 plane (the camera looks
/// straight down -Z, so no camera-facing expansion is needed). Triangle trails
/// become a fan, matching the canvas painter's filled paths.
class _TrailBatch {
  final UnlitMaterial _material = UnlitMaterial()
    ..baseColorFactor = vm.Vector4(1, 1, 1, 1)
    ..vertexColorWeight = 1
    ..doubleSided = true;

  MeshGeometry? _geometry;
  Mesh? _mesh;

  // Grow-only scratch arrays; only the first [_vertexCount] / [_indexCount]
  // entries are live.
  Float32List _positions = Float32List(0);
  Float32List _normals = Float32List(0);
  Float32List _colors = Float32List(0);
  Uint32List _indices = Uint32List(0);
  int _vertexCount = 0;
  int _indexCount = 0;
  int _uploadedVertexCount = -1;
  int _uploadedIndexCount = -1;
  int _uploadedColorSignature = 0;
  int _colorSignature = 0;

  Mesh? update(List<Ball> balls, TrailShape shape) {
    var vertices = 0;
    var indices = 0;
    var signature = 0;
    for (final ball in balls) {
      final n = ball.trail.length;
      if (n < 2) continue;
      signature = signature * 31 + ball.color.hashCode;
      switch (shape) {
        case TrailShape.line:
          vertices += n * 2;
          indices += (n - 1) * 6;
        case TrailShape.singleTriangle:
        case TrailShape.multipleTriangles:
          vertices += n + 1;
          indices += (n - 1) * 3;
      }
    }
    if (vertices == 0) return null;
    _ensureCapacity(vertices, indices);
    _vertexCount = vertices;
    _indexCount = indices;
    _colorSignature = signature;

    var v = 0;
    var i = 0;
    for (final ball in balls) {
      final n = ball.trail.length;
      if (n < 2) continue;
      final c = ball.color;
      final base = v;
      switch (shape) {
        case TrailShape.line:
          final half = math.max(0.5, ball.radius / 20);
          for (var k = 0; k < n; k++) {
            final p = ball.trail[k];
            // Direction along the trail; the last point reuses the
            // incoming segment so the strip does not twist at the end.
            final from = k + 1 < n ? p : ball.trail[k - 1];
            final to = k + 1 < n ? ball.trail[k + 1] : p;
            var dx = to.dx - from.dx;
            var dy = to.dy - from.dy;
            final len = math.sqrt(dx * dx + dy * dy);
            if (len > 0) {
              dx /= len;
              dy /= len;
            }
            // Perpendicular in pixel space; y is flipped into world space.
            final nx = -dy * half;
            final ny = dx * half;
            _putVertex(v++, p.dx + nx, -(p.dy + ny), c);
            _putVertex(v++, p.dx - nx, -(p.dy - ny), c);
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
          _putVertex(v++, apex.dx, -apex.dy, c);
          for (var k = 0; k < n; k++) {
            final p = ball.trail[k];
            _putVertex(v++, p.dx, -p.dy, c);
          }
          for (var k = 0; k < n - 1; k++) {
            _indices[i++] = base;
            _indices[i++] = base + 1 + k;
            _indices[i++] = base + 2 + k;
          }
      }
    }
    assert(v == vertices && i == indices);
    _upload();
    return _mesh;
  }

  void _putVertex(int idx, double x, double y, Color c) {
    final p = idx * 3;
    _positions[p] = x;
    _positions[p + 1] = y;
    _positions[p + 2] = 0;
    _normals[p] = 0;
    _normals[p + 1] = 0;
    _normals[p + 2] = 1;
    final k = idx * 4;
    _colors[k] = c.r;
    _colors[k + 1] = c.g;
    _colors[k + 2] = c.b;
    _colors[k + 3] = c.a;
  }

  void _ensureCapacity(int vertices, int indices) {
    if (_positions.length < vertices * 3) {
      final cap = math.max(vertices, _positions.length ~/ 3 * 2);
      _positions = _grow(_positions, cap * 3);
      _normals = _grow(_normals, cap * 3);
      _colors = _grow(_colors, cap * 4);
    }
    if (_indices.length < indices) {
      final cap = math.max(indices, _indices.length * 2);
      _indices = Uint32List(cap)..setAll(0, _indices);
    }
  }

  static Float32List _grow(Float32List old, int length) =>
      Float32List(length)..setAll(0, old);

  /// Uploads the live span. The engine copies attribute arrays, so they are
  /// handed over as views of exactly the live length.
  void _upload() {
    final positions = Float32List.sublistView(_positions, 0, _vertexCount * 3);
    final normals = Float32List.sublistView(_normals, 0, _vertexCount * 3);
    final colors = Float32List.sublistView(_colors, 0, _vertexCount * 4);
    final geometry = _geometry;
    if (geometry == null) {
      final g = MeshGeometry.fromArrays(
        positions: positions,
        normals: normals,
        colors: colors,
        indices: Uint32List.sublistView(_indices, 0, _indexCount),
        storage: GeometryStorage.updatable,
      );
      _geometry = g;
      _mesh = Mesh(g, _material);
    } else if (_vertexCount == _uploadedVertexCount &&
        _indexCount == _uploadedIndexCount) {
      // Same topology: only positions moved, unless the set of balls was
      // swapped for one with identical trail lengths.
      geometry.updatePositions(positions);
      if (_colorSignature != _uploadedColorSignature) {
        geometry.updateColors(colors);
      }
    } else {
      geometry.rebuild(
        positions: positions,
        normals: normals,
        colors: colors,
        indices: Uint32List.sublistView(_indices, 0, _indexCount),
      );
    }
    _uploadedVertexCount = _vertexCount;
    _uploadedIndexCount = _indexCount;
    _uploadedColorSignature = _colorSignature;
  }
}
