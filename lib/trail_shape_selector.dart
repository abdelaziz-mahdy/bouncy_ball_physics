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
      builder: (context, currentShape, child) {
        return DropdownButton<TrailShape>(
          value: currentShape,
          isExpanded: true,
          onChanged: (TrailShape? newValue) {
            if (newValue != null) {
              trailShapeNotifier.value = newValue;
            }
          },
          items: TrailShape.values
              .map<DropdownMenuItem<TrailShape>>((TrailShape shape) {
            return DropdownMenuItem<TrailShape>(
              value: shape,
              child: Text(
                _getLabelForTrailShape(shape),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            );
          }).toList(),
        );
      },
    );
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
