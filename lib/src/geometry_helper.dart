import 'dart:math';

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

class RotatedRect {
  final Offset topLeft;
  final Offset topRight;
  final Offset bottomLeft;
  final Offset bottomRight;

  RotatedRect({
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
  });

  RotatedRect rotate(double r) {
    final c = (this.topLeft + this.bottomRight) / 2;
    final mat = Matrix4.rotationZ(r);

    Offset _rot(Offset p) {
      final t = mat.transform(vm.Vector4(p.dx, p.dy, 0, 1));

      return Offset(t.x, t.y);
    }

    final topLeft = _rot(this.topLeft - c) + c;
    final topRight = _rot(this.topRight - c) + c;
    final bottomLeft = _rot(this.bottomLeft - c) + c;
    final bottomRight = _rot(this.bottomRight - c) + c;

    return RotatedRect(
        topLeft: topLeft,
        topRight: topRight,
        bottomLeft: bottomLeft,
        bottomRight: bottomRight);
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

// //Compute the distance from AB to C
// //if isSegment is true, AB is a segment, not a line.
// vm.Vector2 _line(vm.Vector2 pointA, vm.Vector2 pointB, vm.Vector2 pointC) {
//   final lineDir = (pointB - pointA).normalized();
//   var v = pointC - pointA;
//   var d = v.dot(lineDir);
//   return pointA + lineDir * d;
// }

// Offset line(Offset a, Offset b, Offset p) {
//   final d = _line(
//     vm.Vector2(a.dx, a.dy),
//     vm.Vector2(b.dx, b.dy),
//     vm.Vector2(p.dx, p.dy),
//   );

//   return Offset(d.x, d.y);
// }

/// Compute the distance from AB to C
/// if isSegment is true, AB is a segment, not a line.
Offset line(Offset pointA, Offset pointB, Offset pointC) {
  final lineDir = _normalize(pointB - pointA);
  var v = pointC - pointA;
  var d = _dot(v, lineDir);
  return pointA + Offset(lineDir.dx * d, lineDir.dy * d);
}

double _side(vm.Vector2 a, vm.Vector2 b, vm.Vector2 p) {
  return (b.x - a.x) * (p.y - a.y) - (b.y - a.y) * (p.x - a.x);
}

double side(Offset a, Offset b, Offset p) {
  final d = _side(
    vm.Vector2(a.dx, a.dy),
    vm.Vector2(b.dx, b.dy),
    vm.Vector2(p.dx, p.dy),
  );
  return d.sign * sqrt(d.abs());
}

Size getSizeToFit(double imageWidth, double imageHeight, double containerWidth,
    double containerHeight) {
  // get the aspect ratios in case we need to expand or shrink to fit
  var imageAspectRatio = imageWidth / imageHeight;
  var targetAspectRatio = containerWidth / containerHeight;

  // no need to adjust the size if current size is square
  var adjustedWidth = containerWidth;
  var adjustedHeight = containerHeight;

  // get the larger aspect ratio of the two
  // if aspect ratio is 1 then no adjustment needed
  if (imageAspectRatio > targetAspectRatio) {
    adjustedHeight = containerWidth / imageAspectRatio;
  } else if (imageAspectRatio < targetAspectRatio) {
    adjustedWidth = containerHeight * imageAspectRatio;
  }

  // set the adjusted size (same if square)
  return Size(adjustedWidth, adjustedHeight);
}

Size getSizeToFitByRatio(
    double imageAspectRatio, double containerWidth, double containerHeight) {
  var targetAspectRatio = containerWidth / containerHeight;

  // no need to adjust the size if current size is square
  var adjustedWidth = containerWidth;
  var adjustedHeight = containerHeight;

  // get the larger aspect ratio of the two
  // if aspect ratio is 1 then no adjustment needed
  if (imageAspectRatio > targetAspectRatio) {
    adjustedHeight = containerWidth / imageAspectRatio;
  } else if (imageAspectRatio < targetAspectRatio) {
    adjustedWidth = containerHeight * imageAspectRatio;
  }

  // set the adjusted size (same if square)
  return Size(adjustedWidth, adjustedHeight);
}

RotatedRect getRotated(
    Rect rect, double rotation, double scale, Offset offset) {
  final r = rotation / 180.0 * pi;

  rotation %= 360;

  final c = rect.center;
  final mat = Matrix4.identity()
    ..translate(offset.dx, offset.dy, 0)
    ..rotateZ(r)
    ..scale(scale, scale, 1);

  Offset _rot(Offset p) {
    final t = mat.transform(vm.Vector4(p.dx, p.dy, 0, 1));

    return Offset(t.x, t.y);
  }

  final topLeft = _rot(rect.topLeft - c) + c;
  final topRight = _rot(rect.topRight - c) + c;
  final bottomLeft = _rot(rect.bottomLeft - c) + c;
  final bottomRight = _rot(rect.bottomRight - c) + c;

  if (rotation <= 90) {
    return RotatedRect(
        topLeft: topLeft,
        topRight: topRight,
        bottomLeft: bottomLeft,
        bottomRight: bottomRight);
  }
  if (rotation <= 180) {
    return RotatedRect(
        bottomLeft: bottomRight,
        topLeft: bottomLeft,
        topRight: topLeft,
        bottomRight: topRight);
  }

  if (rotation <= 270) {
    return RotatedRect(
        bottomLeft: topRight,
        topLeft: bottomRight,
        topRight: bottomLeft,
        bottomRight: topLeft);
  }

  return RotatedRect(
      topLeft: topRight,
      topRight: bottomRight,
      bottomLeft: topLeft,
      bottomRight: bottomLeft);
}
