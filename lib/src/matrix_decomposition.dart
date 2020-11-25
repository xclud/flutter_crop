import 'dart:ui';

class MatrixDecomposition {
  final double rotation;
  final double scale;
  final Offset translation;

  MatrixDecomposition({
    required this.scale,
    required this.rotation,
    required this.translation,
  });
}
