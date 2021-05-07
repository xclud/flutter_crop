import 'dart:math';

import 'package:vector_math/vector_math_64.dart' as vm;

class Line {
  final vm.Vector2 a;
  final vm.Vector2 b;

  const Line(this.a, this.b);

  vm.Vector2 project(vm.Vector2 p) {
    final lineDir = (b - a).normalized();
    var v = p - a;
    var d = v.dot(lineDir);
    return a + (lineDir * d);
  }

  double calculateSide(vm.Vector2 p) {
    final d = (b.x - a.x) * (p.y - a.y) - (b.y - a.y) * (p.x - a.x);

    return d.sign * sqrt(d.abs());
  }
}
