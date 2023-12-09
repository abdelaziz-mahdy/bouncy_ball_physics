// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class Ball {
  Offset position;
  Offset velocity;
  Color color;
  double radius;
  List<Offset> trail = [];
  DateTime creationTime;

  Ball(
      {required this.position,
      required this.velocity,
      required this.color,
      required this.radius})
      : creationTime = DateTime.now();

  @override
  bool operator ==(covariant Ball other) {
    if (identical(this, other)) return true;

    return other.position == position &&
        other.velocity == velocity &&
        other.color == color &&
        other.radius == radius &&
        listEquals(other.trail, trail) &&
        other.creationTime == creationTime;
  }

  @override
  int get hashCode {
    return position.hashCode ^
        velocity.hashCode ^
        color.hashCode ^
        radius.hashCode ^
        trail.hashCode ^
        creationTime.hashCode;
  }
}
