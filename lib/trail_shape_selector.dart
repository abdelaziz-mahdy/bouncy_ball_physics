import 'package:bouncy_ball_physics/ball_painter.dart';
import 'package:flutter/material.dart';

class TrailShapeSelector extends StatelessWidget {
  final ValueNotifier<TrailShape> trailShapeNotifier;

  const TrailShapeSelector({Key? key, required this.trailShapeNotifier})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TrailShape>(
        valueListenable: trailShapeNotifier,
        builder: (context, count, child) {
          return Wrap(
            spacing: 8.0,
            children: TrailShape.values.map((shape) {
              return ChoiceChip(
                label: Text(_getLabelForTrailShape(shape)),
                selected: trailShapeNotifier.value == shape,
                onSelected: (bool selected) {
                  if (selected) {
                    trailShapeNotifier.value = shape;
                  }
                },
              );
            }).toList(),
          );
        });
  }

  String _getLabelForTrailShape(TrailShape shape) {
    switch (shape) {
      case TrailShape.line:
        return 'Line';
      case TrailShape.singleTriangle:
        return 'Single Triangle';
      case TrailShape.multipleTriangles:
        return 'Multiple Triangles';
      default:
        return '';
    }
  }
}
