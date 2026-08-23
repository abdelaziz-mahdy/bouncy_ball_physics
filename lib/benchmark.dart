import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:bouncy_ball_physics/ball_physics_manager.dart';
import 'package:bouncy_ball_physics/render_mode.dart';
import 'package:bouncy_ball_physics/trail_shape.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Size;

/// Enabled with `--dart-define=BENCH=true`. Cycles every renderer through a
/// fixed set of loads, prints one `BENCH` line per run, then exits.
///
///     flutter run --profile -d macos --dart-define=BENCH=true
const bool kBenchmark = bool.fromEnvironment('BENCH');

/// Optional filters: `--dart-define=BENCH_MODES=scene,vertices` and
/// `--dart-define=BENCH_LOADS=500x500,1000x100`.
const String _benchModes = String.fromEnvironment('BENCH_MODES');
const String _benchLoads = String.fromEnvironment('BENCH_LOADS');

/// Each cell is measured this many times and the best run is reported, which
/// filters out interference from other processes on the machine.
const int benchRepeat = int.fromEnvironment('BENCH_REPEAT', defaultValue: 1);

List<RenderMode> get benchModes => _benchModes.isEmpty
    ? _modeOrder
    : [
        for (final name in _benchModes.split(','))
          RenderMode.values.byName(name.trim()),
      ];

List<BenchConfig> get benchLoads => _benchLoads.isEmpty
    ? benchConfigs
    : [
        for (final load in _benchLoads.split(','))
          BenchConfig(
            int.parse(load.split('x')[0]),
            int.parse(load.split('x')[1]),
          ),
      ];

class BenchConfig {
  const BenchConfig(this.balls, this.tail);
  final int balls;
  final int tail;
}

const benchConfigs = [
  BenchConfig(10, 100),
  BenchConfig(100, 10),
  BenchConfig(100, 100),
  BenchConfig(300, 300),
  BenchConfig(500, 500),
  BenchConfig(1000, 100),
  BenchConfig(1000, 500),
  BenchConfig(2000, 100),
];

const _modeOrder = [RenderMode.canvas, RenderMode.scene, RenderMode.vertices];

/// Idle on a trivial canvas load between runs so a slow renderer's queued
/// raster frames drain before the next measurement starts.
const _drain = Duration(seconds: 3);

const _warmup = Duration(seconds: 8);
const _measure = Duration(seconds: 5);

/// One frame's worth of rendering is never shorter than this; used to give up
/// on a renderer that has fallen below 1 FPS rather than waiting forever.
const _giveUp = Duration(seconds: 20);

class BenchmarkRunner {
  BenchmarkRunner({
    required this.manager,
    required this.renderMode,
    required this.trailShape,
    required this.viewSize,
  });

  final BallPhysicsManager manager;
  final ValueNotifier<RenderMode> renderMode;
  final ValueNotifier<TrailShape> trailShape;
  final Size Function() viewSize;

  Future<void> run() async {
    trailShape.value = TrailShape.line;
    debugPrint('BENCH start  warmup=${_warmup.inSeconds}s '
        'measure=${_measure.inSeconds}s repeat=$benchRepeat');
    final results = <String>[];
    for (final config in benchLoads) {
      for (final mode in benchModes) {
        var fps = 0.0;
        final runs = <double>[];
        for (var r = 0; r < benchRepeat; r++) {
          final run = await _runOne(mode, config);
          runs.add(run);
          fps = math.max(fps, run);
        }
        final line = 'BENCH mode=${mode.name} balls=${config.balls} '
            'tail=${config.tail} fps=${fps.toStringAsFixed(1)}'
            '${benchRepeat > 1 ? ' runs=${runs.map((r) => r.toStringAsFixed(1)).join('/')}' : ''}';
        debugPrint(line);
        results.add(line);
      }
    }
    debugPrint('BENCH done');
    debugPrint(results.join('\n'));
    exit(0);
  }

  Future<double> _runOne(RenderMode mode, BenchConfig config) async {
    renderMode.value = RenderMode.canvas;
    manager.ballLimitNotifier.value = 1;
    manager.tailLengthNotifier.value = 1;
    manager.resetBalls(viewSize());
    await Future<void>.delayed(_drain);

    renderMode.value = mode;
    manager.ballLimitNotifier.value = config.balls;
    manager.tailLengthNotifier.value = config.tail;
    manager.resetBalls(viewSize());

    // Warm up until the ball count and trails have filled, or give up waiting
    // if the renderer is so slow it will never get there.
    final warmupStart = DateTime.now();
    while (DateTime.now().difference(warmupStart) < _warmup) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }

    final startFrames = manager.frameCount;
    final start = DateTime.now();
    while (true) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      final elapsed = DateTime.now().difference(start);
      final frames = manager.frameCount - startFrames;
      if (elapsed >= _measure && frames > 0) {
        return frames / (elapsed.inMilliseconds / 1000);
      }
      if (elapsed >= _giveUp) {
        return frames / (elapsed.inMilliseconds / 1000);
      }
    }
  }
}
