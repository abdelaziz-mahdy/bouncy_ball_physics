import 'package:flutter/material.dart';

class Ball {
  Offset position;
  Offset velocity;
  Color color;
  double radius;
  List<Offset> trail = [];
  DateTime creationTime;

  Ball({required this.position, required this.velocity, required this.color, required this.radius})
      : creationTime = DateTime.now();
}
