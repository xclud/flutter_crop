import 'dart:ui';

/// Decomposition of a matrix into [rotation], [scale], [translation].
class MatrixDecomposition {
  /// Rotation
  final double rotation;

  /// Scale
  final double scale;

  /// Translation
  final Offset translation;

  /// Construction
  MatrixDecomposition({
    required this.scale,
    required this.rotation,
    required this.translation,
  });
}
