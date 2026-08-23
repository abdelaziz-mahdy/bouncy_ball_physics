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
/// 45° vertical field of view spans exactly the widget height. Each ball owns a
/// sphere [Node] plus a trail [Node] whose geometry is rebuilt every frame,
/// since the trail points change every frame.
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

class _BallNodes {
  _BallNodes(this.sphere, this.trail, this.material);
  final Node sphere;
  final Node trail;
  final UnlitMaterial material;
}

class _BallSceneViewState extends State<BallSceneView> {
  final Scene _scene = Scene();
  // Ball overrides == / hashCode on mutable fields (position, trail), so key
  // by identity.
  final Map<Ball, _BallNodes> _nodes = Map.identity();
  final Map<double, SphereGeometry> _sphereCache = {};
  late final PerspectiveCamera _camera = PerspectiveCamera(
    fovRadiansY: _fovY,
    fovNear: 1,
    fovFar: 100000,
  );
  Size _size = Size.zero;

  static const double _fovY = 45 * vm.degrees2Radians;

  @override
  void dispose() {
    for (final n in _nodes.values) {
      _scene.remove(n.sphere);
      _scene.remove(n.trail);
    }
    _nodes.clear();
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

  vm.Vector3 _toWorld(Offset o) => vm.Vector3(o.dx, -o.dy, 0);

  vm.Vector4 _toColor(Color c) =>
      vm.Vector4(c.r, c.g, c.b, c.a);

  _BallNodes _createNodes(Ball ball) {
    final material = UnlitMaterial()
      ..baseColorFactor = _toColor(ball.color)
      ..doubleSided = true;
    final geometry = _sphereCache.putIfAbsent(
      ball.radius,
      () => SphereGeometry(radius: ball.radius, segments: 24, rings: 12),
    );
    final sphere = Node(mesh: Mesh(geometry, material));
    final trail = Node();
    _scene.add(sphere);
    _scene.add(trail);
    return _BallNodes(sphere, trail, material);
  }

  void _sync() {
    widget.onTick();
    final live = Set<Ball>.identity()..addAll(widget.balls);

    // Drop nodes for balls that were removed by the ball limit or a reset.
    _nodes.removeWhere((ball, n) {
      if (live.contains(ball)) return false;
      _scene.remove(n.sphere);
      _scene.remove(n.trail);
      return true;
    });

    for (final ball in widget.balls) {
      final n = _nodes.putIfAbsent(ball, () => _createNodes(ball));
      n.sphere.position = _toWorld(ball.position);
      n.trail.mesh = _buildTrail(ball, n.material);
    }
  }

  Mesh? _buildTrail(Ball ball, Material material) {
    if (ball.trail.length < 2) return null;
    final geometry = switch (widget.trailShape) {
      TrailShape.line => _lineTrail(ball),
      TrailShape.singleTriangle => _fanTrail(
          ball.trail.map(_toWorld).toList(),
          apex: _toWorld(ball.trail.first),
        ),
      TrailShape.multipleTriangles => _fanTrail(
          ball.trail.map(_toWorld).toList(),
          apex: _toWorld(ball.position),
        ),
    };
    return geometry == null ? null : Mesh(geometry, material);
  }

  Geometry _lineTrail(Ball ball) {
    final geometry = PolylineGeometry(
      ball.trail.map(_toWorld).toList(),
      width: math.max(1, ball.radius / 10),
      widthMode: PolylineWidthMode.worldUnits,
    );
    // PolylineGeometry expands its strip toward the camera on demand; the
    // engine does not do this for us.
    geometry.updateForCamera(_camera, _size);
    return geometry;
  }

  /// Filled fan of triangles `(apex, p[i], p[i+1])`, matching the canvas
  /// painter's filled-path trails. Both windings are emitted so the result
  /// does not depend on the trail's turn direction.
  Geometry? _fanTrail(List<vm.Vector3> points, {required vm.Vector3 apex}) {
    final triCount = points.length - 1;
    if (triCount < 1) return null;
    final vertexCount = points.length + 1;
    final positions = Float32List(vertexCount * 3);
    final normals = Float32List(vertexCount * 3);
    void put(int i, vm.Vector3 p) {
      positions[i * 3] = p.x;
      positions[i * 3 + 1] = p.y;
      positions[i * 3 + 2] = p.z;
      normals[i * 3 + 2] = 1;
    }

    put(0, apex);
    for (var i = 0; i < points.length; i++) {
      put(i + 1, points[i]);
    }
    final indices = <int>[];
    for (var i = 0; i < triCount; i++) {
      indices
        ..addAll([0, i + 1, i + 2])
        ..addAll([0, i + 2, i + 1]);
    }
    return MeshGeometry.fromArrays(
      positions: positions,
      normals: normals,
      indices: indices,
    );
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
