import 'package:flutter/material.dart';

class Line {
  final Offset a;
  final Offset b;
  final double length;
  Line(this.a, this.b) : length = (a - b).distance;

  static double _side(Offset a, Offset b, Offset p) {
    return (b.dx - a.dx) * (a.dy - p.dy) - (a.dx - p.dx) * (b.dy - a.dy);
  }

  double distanceToPoint(Offset point) {
    final d = _side(a, b, point);
    return d / (b - a).distance;
  }

  /// Compute a line perpendicular to this line from the given point.
  Line lineTo(Offset point) {
    final lineDir = _normalize(b - a);
    var v = point - a;
    var d = _dot(v, lineDir);
    final aa = a + Offset(lineDir.dx * d, lineDir.dy * d);

    return Line(aa, point);
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
