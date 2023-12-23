import 'package:bouncy_ball_physics/ball_physics_manager.dart';
import 'package:bouncy_ball_physics/ball_physics_widget.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          appBar: AppBar(title: const Text('Ball Physics')),
          body: const BallPhysicsWidget(), // Use the key here
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              // Call the reset method using the key
              BallPhysicsManager().resetBalls(MediaQuery.of(context).size);
            },
            child: const Icon(Icons.refresh),
          ),
        ));
  }
}
