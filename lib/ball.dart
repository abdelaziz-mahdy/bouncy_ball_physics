// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:bouncy_ball_physics/common_classes.dart';

class Ball {
  CustomOffset position;
  CustomOffset velocity;
  List<int> color;
  double radius;
  List<CustomOffset> trail = [];
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
