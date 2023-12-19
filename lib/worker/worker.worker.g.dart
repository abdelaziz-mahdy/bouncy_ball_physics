// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'worker.dart';

// **************************************************************************
// Generator: WorkerGenerator 2.4.2
// **************************************************************************

/// WorkerService class for MyPhysicsWorker
class _$MyPhysicsWorkerWorkerService extends MyPhysicsWorker
    implements WorkerService {
  _$MyPhysicsWorkerWorkerService() : super();

  @override
  Map<int, CommandHandler> get operations => _operations;

  late final Map<int, CommandHandler> _operations =
      Map.unmodifiable(<int, CommandHandler>{
    _$updatePhysicsId: ($) async => (await updatePhysics($.args[0].cast<Ball>(),
            $.args[1], $.args[2], $.args[3], $.args[4], $.args[5]))
        .cast<Ball>(),
  });

  static const int _$updatePhysicsId = 1;
}

/// Service initializer for MyPhysicsWorker
WorkerService $MyPhysicsWorkerInitializer(WorkerRequest startRequest) =>
    _$MyPhysicsWorkerWorkerService();

/// Operations map for MyPhysicsWorker
@Deprecated(
    'squadron_builder now supports "plain old Dart objects" as services. '
    'Services do not need to derive from WorkerService nor do they need to mix in '
    'with \$MyPhysicsWorkerOperations anymore.')
mixin $MyPhysicsWorkerOperations on WorkerService {
  @override
  // not needed anymore, generated for compatibility with previous versions of squadron_builder
  Map<int, CommandHandler> get operations => WorkerService.noOperations;
}

/// Worker for MyPhysicsWorker
class MyPhysicsWorkerWorker extends Worker implements MyPhysicsWorker {
  MyPhysicsWorkerWorker({PlatformWorkerHook? platformWorkerHook})
      : super($MyPhysicsWorkerActivator,
            platformWorkerHook: platformWorkerHook);

  @override
  Future<List<Ball>> updatePhysics(List<Ball> balls, CustomSize size,
          int tailLength, int ballLimit, Duration noSpawnDuration, int speed) =>
      send(_$MyPhysicsWorkerWorkerService._$updatePhysicsId, args: [
        balls.cast<Ball>(),
        size,
        tailLength,
        ballLimit,
        noSpawnDuration,
        speed
      ]).then((_) => _.cast<Ball>());

  @override
  Ball _createBall(CustomSize size, int speed) => throw UnimplementedError();
}

/// Worker pool for MyPhysicsWorker
class MyPhysicsWorkerWorkerPool extends WorkerPool<MyPhysicsWorkerWorker>
    implements MyPhysicsWorker {
  MyPhysicsWorkerWorkerPool(
      {ConcurrencySettings? concurrencySettings,
      PlatformWorkerHook? platformWorkerHook})
      : super(
            () => MyPhysicsWorkerWorker(platformWorkerHook: platformWorkerHook),
            concurrencySettings: concurrencySettings);

  @override
  Future<List<Ball>> updatePhysics(List<Ball> balls, CustomSize size,
          int tailLength, int ballLimit, Duration noSpawnDuration, int speed) =>
      execute((w) => w.updatePhysics(
          balls, size, tailLength, ballLimit, noSpawnDuration, speed));

  @override
  Ball _createBall(CustomSize size, int speed) => throw UnimplementedError();
}
