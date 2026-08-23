/// Which backend draws the balls.
enum RenderMode {
  /// `CustomPainter` using plain `Canvas` calls.
  canvas,

  /// `CustomPainter` batching all geometry through `Canvas.drawVertices`.
  vertices,

  /// `flutter_scene` 3D engine via Flutter GPU.
  scene,
}

extension RenderModeLabel on RenderMode {
  String get label => switch (this) {
        RenderMode.canvas => 'Canvas (CPU)',
        RenderMode.vertices => 'Vertices (batched)',
        RenderMode.scene => 'flutter_scene (3D)',
      };

  String get description => switch (this) {
        RenderMode.canvas => 'CustomPainter with canvas draw calls',
        RenderMode.vertices => 'CustomPainter with batched drawVertices',
        RenderMode.scene => 'flutter_scene engine on Flutter GPU',
      };
}
