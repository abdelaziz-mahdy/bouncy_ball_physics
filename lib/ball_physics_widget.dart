import 'dart:ui' as ui;
import 'package:bouncy_ball_physics/trail_shape_selector.dart';
import 'package:bouncy_ball_physics/trail_shape.dart';
import 'package:flutter/material.dart';

import 'ball_painter.dart';
import 'ball_scene_view.dart';
import 'benchmark.dart';
import 'ball_shader_painter.dart';
import 'render_mode.dart';

import 'package:bouncy_ball_physics/ball_physics_manager.dart';

class BallPhysicsWidget extends StatefulWidget {
  const BallPhysicsWidget({super.key});

  @override
  BallPhysicsWidgetState createState() => BallPhysicsWidgetState();
}

class BallPhysicsWidgetState extends State<BallPhysicsWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final BallPhysicsManager manager = BallPhysicsManager();
  final ValueNotifier<TrailShape> trailShapeNotifier =
      ValueNotifier(TrailShape.line);
  final ValueNotifier<RenderMode> renderModeNotifier =
      ValueNotifier(RenderMode.canvas);

  // Shader programs
  ui.FragmentProgram? ballShaderProgram;
  ui.FragmentProgram? trailShaderProgram;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 16))
      ..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      manager.resetBalls(MediaQuery.of(context).size);
      if (kBenchmark) {
        BenchmarkRunner(
          manager: manager,
          renderMode: renderModeNotifier,
          trailShape: trailShapeNotifier,
          viewSize: () => MediaQuery.of(context).size,
        ).run();
      }
    });
    _loadShaders();
  }

  Future<void> _loadShaders() async {
    try {
      ballShaderProgram = await ui.FragmentProgram.fromAsset('shaders/ball.frag');
      trailShaderProgram = await ui.FragmentProgram.fromAsset('shaders/trail.frag');
      setState(() {}); // Trigger rebuild once shaders are loaded
    } catch (e) {
      debugPrint('Error loading shaders: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: TrailShapeSelector(trailShapeNotifier: trailShapeNotifier),
            ),
            Expanded(
              child: ValueListenableBuilder<int>(
                valueListenable: manager.ballCountNotifier,
                builder: (context, count, child) {
                  return Text(
                    'Balls: $count',
                    style: Theme.of(context).textTheme.titleLarge,
                  );
                },
              ),
            ),
            Expanded(
              child: ValueListenableBuilder<double>(
                valueListenable: manager.fpsNotifier,
                builder: (context, fps, child) {
                  return Text(
                    'FPS: ${fps.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleLarge,
                  );
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => _showSettingsPanel(context),
            ),
          ],
        ),
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(border: Border.all()),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return ValueListenableBuilder<RenderMode>(
                  valueListenable: renderModeNotifier,
                  builder: (context, mode, child) {
                    return ValueListenableBuilder<TrailShape>(
                      valueListenable: trailShapeNotifier,
                      builder: (context, trailShape, child) {
                        if (mode == RenderMode.scene) {
                          // SceneView drives its own frame loop; physics
                          // advances from its per-frame tick instead of the
                          // AnimationController.
                          return BallSceneView(
                            balls: manager.balls,
                            trailShape: trailShape,
                            onTick: () => manager.updatePhysics(
                                context, constraints.biggest),
                          );
                        }
                        return AnimatedBuilder(
                          animation: _controller,
                          builder: (context, child) {
                            manager.updatePhysics(context, constraints.biggest);
                            return CustomPaint(
                              painter: mode == RenderMode.shader
                                  ? BallShaderPainter(
                                      balls: manager.balls,
                                      trailShape: trailShape,
                                      ballProgram: ballShaderProgram,
                                      trailProgram: trailShaderProgram,
                                    )
                                  : BallPainter(
                                      balls: manager.balls,
                                      trailShape: trailShape,
                                    ),
                              child: Container(),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              }
            ),
          ),
        ),
      ],
    );
  }

  void _showSettingsPanel(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Settings"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Balls Limit"),
              ValueListenableBuilder(
                  valueListenable: manager.ballLimitNotifier,
                  builder: (BuildContext context, int value, Widget? child) {
                    return Slider(
                      value: manager.ballLimitNotifier.value.toDouble(),
                      min: manager.slidersMinValue,
                      max: manager.slidersMaxValue,
                      divisions:
                          (manager.slidersMaxValue - manager.slidersMinValue)
                              .toInt(),
                      label: manager.ballLimitNotifier.value.toString(),
                      onChanged: (double value) {
                        manager.ballLimitNotifier.value = value.toInt();
                      },
                    );
                  }),
              const Text("Tail Length"),
              ValueListenableBuilder(
                  valueListenable: manager.tailLengthNotifier,
                  builder: (BuildContext context, int value, Widget? child) {
                    return Slider(
                        value: manager.tailLengthNotifier.value.toDouble(),
                        min: manager.slidersMinValue,
                        max: manager.slidersMaxValue,
                        divisions:
                            (manager.slidersMaxValue - manager.slidersMinValue)
                                .toInt(),
                        label: manager.tailLengthNotifier.value.toString(),
                        onChanged: (double value) {
                          manager.tailLengthNotifier.value = value.toInt();
                        });
                  }),
              const SizedBox(height: 16),
              const Text("Renderer"),
              ValueListenableBuilder<RenderMode>(
                  valueListenable: renderModeNotifier,
                  builder: (BuildContext context, RenderMode value, Widget? child) {
                    return RadioGroup<RenderMode>(
                      groupValue: value,
                      onChanged: (m) {
                        if (m != null) renderModeNotifier.value = m;
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final mode in RenderMode.values)
                            RadioListTile<RenderMode>(
                              title: Text(mode.label),
                              subtitle: Text(mode.description),
                              value: mode,
                            ),
                        ],
                      ),
                    );
                  }),
            ],
          ),
          actions: [
            TextButton(
              child: const Text("Close"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
