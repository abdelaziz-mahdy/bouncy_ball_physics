import 'package:bouncy_ball_physics/ball_physics_widget.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final GlobalKey<BallPhysicsWidgetState> ballPhysicsKey = GlobalKey();

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
      appBar: AppBar(title: const Text('Ball Physics')),
      body: BallPhysicsWidget(key: ballPhysicsKey), // Use the key here
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Call the reset method using the key
          ballPhysicsKey.currentState?.resetBalls();
        },
        child: const Icon(Icons.refresh),
      ),
    ));
  }
}
