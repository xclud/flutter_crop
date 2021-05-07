import 'dart:math' as math;
import 'package:crop/src/line.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

/// An immutable, 2D, axis-aligned, floating-point rectangle whose coordinates
/// are relative to a given origin.
///
/// A Rect can be created with one its constructors or from an [vm.Vector2] and a
/// [Size] using the `&` operator:
///
/// ```dart
/// Rect myRect = const vm.Vector2(1.0, 2.0) & const Size(3.0, 4.0);
/// ```
class Rectangle {
  /// Construct a rectangle from its left, top, right, and bottom edges.
  const Rectangle.fromLTRB(this.left, this.top, this.right, this.bottom);

  /// Construct a rectangle from its left and top edges, its width, and its
  /// height.
  ///
  /// To construct a [Rectangle] from an [vm.Vector2] and a [Size], you can use the
  /// rectangle constructor operator `&`. See [vm.Vector2.&].
  const Rectangle.fromLTWH(double left, double top, double width, double height)
      : this.fromLTRB(left, top, left + width, top + height);

  /// Construct a rectangle that bounds the given circle.
  ///
  /// The `center` argument is assumed to be an offset from the origin.
  Rectangle.fromCircle({required vm.Vector2 center, required double radius})
      : this.fromCenter(
          center: center,
          width: radius * 2,
          height: radius * 2,
        );

  /// Constructs a rectangle from its center point, width, and height.
  ///
  /// The `center` argument is assumed to be an offset from the origin.
  Rectangle.fromCenter(
      {required vm.Vector2 center,
      required double width,
      required double height})
      : this.fromLTRB(
          center.x - width / 2,
          center.y - height / 2,
          center.x + width / 2,
          center.y + height / 2,
        );

  /// Construct the smallest rectangle that encloses the given offsets, treating
  /// them as vectors from the origin.
  Rectangle.fromPoints(vm.Vector2 a, vm.Vector2 b)
      : this.fromLTRB(
          math.min(a.x, b.x),
          math.min(a.y, b.y),
          math.max(a.x, b.x),
          math.max(a.y, b.y),
        );

  /// The offset of the left edge of this rectangle from the x axis.
  final double left;

  /// The offset of the top edge of this rectangle from the y axis.
  final double top;

  /// The offset of the right edge of this rectangle from the x axis.
  final double right;

  /// The offset of the bottom edge of this rectangle from the y axis.
  final double bottom;

  /// The distance between the left and right edges of this rectangle.
  double get width => right - left;

  /// The distance between the top and bottom edges of this rectangle.
  double get height => bottom - top;

  /// Whether any of the dimensions are `NaN`.
  bool get hasNaN => left.isNaN || top.isNaN || right.isNaN || bottom.isNaN;

  /// A rectangle with left, top, right, and bottom edges all at zero.
  static const Rectangle zero = Rectangle.fromLTRB(0.0, 0.0, 0.0, 0.0);

  static const double _giantScalar = 1.0E+9; // matches kGiantRect from layer.h

  /// A rectangle that covers the entire coordinate space.
  ///
  /// This covers the space from -1e9,-1e9 to 1e9,1e9.
  /// This is the space over which graphics operations are valid.
  static const Rectangle largest = Rectangle.fromLTRB(
      -_giantScalar, -_giantScalar, _giantScalar, _giantScalar);

  /// Whether any of the coordinates of this rectangle are equal to positive infinity.
  // included for consistency with vm.Vector2 and Size
  bool get isInfinite {
    return left >= double.infinity ||
        top >= double.infinity ||
        right >= double.infinity ||
        bottom >= double.infinity;
  }

  /// Whether all coordinates of this rectangle are finite.
  bool get isFinite =>
      left.isFinite && top.isFinite && right.isFinite && bottom.isFinite;

  /// Whether this rectangle encloses a non-zero area. Negative areas are
  /// considered empty.
  bool get isEmpty => left >= right || top >= bottom;

  /// Returns a new rectangle translated by the given offset.
  ///
  /// To translate a rectangle by separate x and y components rather than by an
  /// [vm.Vector2], consider [translate].
  Rectangle shift(vm.Vector2 offset) {
    return Rectangle.fromLTRB(
        left + offset.x, top + offset.y, right + offset.x, bottom + offset.y);
  }

  /// Returns a new rectangle with translateX added to the x components and
  /// translateY added to the y components.
  ///
  /// To translate a rectangle by an [vm.Vector2] rather than by separate x and y
  /// components, consider [shift].
  Rectangle translate(double translateX, double translateY) {
    return Rectangle.fromLTRB(left + translateX, top + translateY,
        right + translateX, bottom + translateY);
  }

  /// Returns a new rectangle with edges moved outwards by the given delta.
  Rectangle inflate(double delta) {
    return Rectangle.fromLTRB(
        left - delta, top - delta, right + delta, bottom + delta);
  }

  /// Returns a new rectangle with edges moved inwards by the given delta.
  Rectangle deflate(double delta) => inflate(-delta);

  /// Returns a new rectangle that is the intersection of the given
  /// rectangle and this rectangle. The two rectangles must overlap
  /// for this to be meaningful. If the two rectangles do not overlap,
  /// then the resulting Rect will have a negative width or height.
  Rectangle intersect(Rectangle other) {
    return Rectangle.fromLTRB(
        math.max(left, other.left),
        math.max(top, other.top),
        math.min(right, other.right),
        math.min(bottom, other.bottom));
  }

  /// Returns a new rectangle which is the bounding box containing this
  /// rectangle and the given rectangle.
  Rectangle expandToInclude(Rectangle other) {
    return Rectangle.fromLTRB(
      math.min(left, other.left),
      math.min(top, other.top),
      math.max(right, other.right),
      math.max(bottom, other.bottom),
    );
  }

  /// Whether `other` has a nonzero area of overlap with this rectangle.
  bool overlaps(Rectangle other) {
    if (right <= other.left || other.right <= left) return false;
    if (bottom <= other.top || other.bottom <= top) return false;
    return true;
  }

  /// The lesser of the magnitudes of the [width] and the [height] of this
  /// rectangle.
  double get shortestSide => math.min(width.abs(), height.abs());

  /// The greater of the magnitudes of the [width] and the [height] of this
  /// rectangle.
  double get longestSide => math.max(width.abs(), height.abs());

  /// The offset to the intersection of the top and left edges of this rectangle.
  ///
  /// See also [Size.topLeft].
  vm.Vector2 get topLeft => vm.Vector2(left, top);

  /// The offset to the center of the top edge of this rectangle.
  ///
  /// See also [Size.topCenter].
  vm.Vector2 get topCenter => vm.Vector2(left + width / 2.0, top);

  /// The offset to the intersection of the top and right edges of this rectangle.
  ///
  /// See also [Size.topRight].
  vm.Vector2 get topRight => vm.Vector2(right, top);

  /// The offset to the center of the left edge of this rectangle.
  ///
  /// See also [Size.centerLeft].
  vm.Vector2 get centerLeft => vm.Vector2(left, top + height / 2.0);

  /// The offset to the point halfway between the left and right and the top and
  /// bottom edges of this rectangle.
  ///
  /// See also [Size.center].
  vm.Vector2 get center => vm.Vector2(left + width / 2.0, top + height / 2.0);

  /// The offset to the center of the right edge of this rectangle.
  ///
  /// See also [Size.centerLeft].
  vm.Vector2 get centerRight => vm.Vector2(right, top + height / 2.0);

  /// The offset to the intersection of the bottom and left edges of this rectangle.
  ///
  /// See also [Size.bottomLeft].
  vm.Vector2 get bottomLeft => vm.Vector2(left, bottom);

  /// The offset to the center of the bottom edge of this rectangle.
  ///
  /// See also [Size.bottomLeft].
  vm.Vector2 get bottomCenter => vm.Vector2(left + width / 2.0, bottom);

  /// The offset to the intersection of the bottom and right edges of this rectangle.
  ///
  /// See also [Size.bottomRight].
  vm.Vector2 get bottomRight => vm.Vector2(right, bottom);

  Line get leftEdge => Line(topLeft, bottomLeft);
  Line get topEdge => Line(topRight, topLeft);

  Line get rightEdge => Line(bottomRight, topRight);
  Line get bottomEdge => Line(bottomLeft, bottomRight);

  /// Whether the point specified by the given offset (which is assumed to be
  /// relative to the origin) lies between the left and right and the top and
  /// bottom edges of this rectangle.
  ///
  /// Rectangles include their top and left edges but exclude their bottom and
  /// right edges.
  bool contains(vm.Vector2 offset) {
    return offset.x >= left &&
        offset.x < right &&
        offset.y >= top &&
        offset.y < bottom;
  }

  /// Linearly interpolate between two rectangles.
  ///
  /// If either rect is null, [Rectangle.zero] is used as a substitute.
  ///
  /// The `t` argument represents position on the timeline, with 0.0 meaning
  /// that the interpolation has not started, returning `a` (or something
  /// equivalent to `a`), 1.0 meaning that the interpolation has finished,
  /// returning `b` (or something equivalent to `b`), and values in between
  /// meaning that the interpolation is at the relevant point on the timeline
  /// between `a` and `b`. The interpolation can be extrapolated beyond 0.0 and
  /// 1.0, so negative values and values greater than 1.0 are valid (and can
  /// easily be generated by curves such as [Curves.elasticInOut]).
  ///
  /// Values for `t` are usually obtained from an [Animation<double>], such as
  /// an [AnimationController].
  static Rectangle? lerp(Rectangle? a, Rectangle? b, double t) {
    if (b == null) {
      if (a == null) {
        return null;
      } else {
        final double k = 1.0 - t;
        return Rectangle.fromLTRB(
            a.left * k, a.top * k, a.right * k, a.bottom * k);
      }
    } else {
      if (a == null) {
        return Rectangle.fromLTRB(
            b.left * t, b.top * t, b.right * t, b.bottom * t);
      } else {
        return Rectangle.fromLTRB(
          _lerpDouble(a.left, b.left, t),
          _lerpDouble(a.top, b.top, t),
          _lerpDouble(a.right, b.right, t),
          _lerpDouble(a.bottom, b.bottom, t),
        );
      }
    }
  }
}

double _lerpDouble(double a, double b, double t) {
  return a * (1.0 - t) + b * t;
}
