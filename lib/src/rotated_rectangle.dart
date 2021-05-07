import 'package:crop/src/rectangle.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

class RotatedRectangle {
  final vm.Vector2 topLeft;
  final vm.Vector2 topRight;
  final vm.Vector2 bottomLeft;
  final vm.Vector2 bottomRight;

  RotatedRectangle({
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
  });

  factory RotatedRectangle.fromRectRotationScaleOffset({
    required Rectangle rect,
    double rotation = 0,
    double scale = 1,
    vm.Vector2? offset,
  }) {
    final r = vm.radians(rotation);

    offset ??= vm.Vector2(0, 0);

    rotation %= 360;

    final c = rect.center;
    final tl = rect.topLeft;
    final tr = rect.topRight;
    final bl = rect.bottomLeft;
    final br = rect.bottomRight;

    final mat = vm.Matrix4.identity()
      ..translate(offset.x, offset.y, 0)
      ..rotateZ(r)
      ..scale(scale, scale, 1);

    vm.Vector2 _rot(vm.Vector2 p) {
      final t = mat.transform(vm.Vector4(p.x, p.y, 0, 1));

      return vm.Vector2(t.x, t.y);
    }

    final topLeft = _rot(tl - c) + c;
    final topRight = _rot(tr - c) + c;
    final bottomLeft = _rot(bl - c) + c;
    final bottomRight = _rot(br - c) + c;

    if (rotation <= 90) {
      return RotatedRectangle(
          topLeft: topLeft,
          topRight: topRight,
          bottomLeft: bottomLeft,
          bottomRight: bottomRight);
    }
    if (rotation <= 180) {
      return RotatedRectangle(
          bottomLeft: bottomRight,
          topLeft: bottomLeft,
          topRight: topLeft,
          bottomRight: topRight);
    }

    if (rotation <= 270) {
      return RotatedRectangle(
          bottomLeft: topRight,
          topLeft: bottomRight,
          topRight: bottomLeft,
          bottomRight: topLeft);
    }

    return RotatedRectangle(
        topLeft: topRight,
        topRight: bottomRight,
        bottomLeft: topLeft,
        bottomRight: bottomLeft);
  }
}
