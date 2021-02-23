import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

class Line {
  final Offset a;
  final Offset b;

  const Line(this.a, this.b);

  static double _side(vm.Vector2 a, vm.Vector2 b, vm.Vector2 p) {
    return (b.x - a.x) * (a.y - p.y) - (a.x - p.x) * (b.y - a.y);
  }

  double distanceToPoint(Offset point) {
    final aa = vm.Vector2(a.dx, a.dy);
    final bb = vm.Vector2(b.dx, b.dy);
    final cc = vm.Vector2(point.dx, point.dy);

    vm.Vector2(b.dx, b.dy);
    final d = _side(aa, bb, cc);

    return d / bb.distanceTo(aa);
  }

  /// Compute the distance from AB to C
  Offset lineTo(Offset point) {
    final lineDir = _normalize(b - a);
    var v = point - a;
    var d = _dot(v, lineDir);
    return a + Offset(lineDir.dx * d, lineDir.dy * d);
  }
}

/// Normalize
Offset _normalize(Offset o) {
  final double l = o.distance;
  if (l == 0.0) {
    return o;
  }
  final double d = 1.0 / l;
  return Offset(o.dx * d, o.dy * d);
}

/// Inner product.
double _dot(Offset a, Offset b) {
  return a.dx * b.dx + a.dy * b.dy;
}
