/// Which backend draws the balls.
enum RenderMode {
  /// `CustomPainter` using plain `Canvas` calls.
  canvas,

  /// `CustomPainter` using fragment shaders (`shaders/*.frag`).
  shader,

  /// `flutter_scene` 3D engine via Flutter GPU.
  scene,
}

extension RenderModeLabel on RenderMode {
  String get label => switch (this) {
        RenderMode.canvas => 'Canvas (CPU)',
        RenderMode.shader => 'Shader (GPU)',
        RenderMode.scene => 'flutter_scene (3D)',
      };

  String get description => switch (this) {
        RenderMode.canvas => 'CustomPainter with canvas draw calls',
        RenderMode.shader => 'CustomPainter with fragment shaders',
        RenderMode.scene => 'flutter_scene engine on Flutter GPU',
      };
}
