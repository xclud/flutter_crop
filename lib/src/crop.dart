import 'dart:ui' as ui;
import 'dart:math';

import 'package:crop/src/crop_render.dart';
import 'package:collision/collision.dart';
import 'package:crop/src/matrix_decomposition.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

class Crop extends StatefulWidget {
  final Widget child;
  final CropController controller;
  final Color backgroundColor;
  final Color dimColor;
  final EdgeInsetsGeometry padding;
  final Widget? background;
  final Widget? foreground;
  final Widget? helper;
  final Widget? overlay;
  final bool interactive;
  final BoxShape shape;
  final ValueChanged<MatrixDecomposition>? onChanged;
  final Duration animationDuration;

  Crop({
    Key? key,
    required this.child,
    required this.controller,
    this.padding: const EdgeInsets.all(8),
    this.dimColor: const Color.fromRGBO(0, 0, 0, 0.8),
    this.backgroundColor: Colors.black,
    this.background,
    this.foreground,
    this.helper,
    this.overlay,
    this.interactive: true,
    this.shape: BoxShape.rectangle,
    this.onChanged,
    this.animationDuration = const Duration(milliseconds: 200),
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _CropState();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('padding', padding));
    properties.add(ColorProperty('dimColor', dimColor));
    properties.add(DiagnosticsProperty('child', child));
    properties.add(DiagnosticsProperty('controller', controller));
    properties.add(DiagnosticsProperty('background', background));
    properties.add(DiagnosticsProperty('foreground', foreground));
    properties.add(DiagnosticsProperty('helper', helper));
    properties.add(DiagnosticsProperty('overlay', overlay));
    properties.add(FlagProperty('interactive',
        value: interactive,
        ifTrue: 'enabled',
        ifFalse: 'disabled',
        showName: true));
  }
}

class _CropState extends State<Crop> with TickerProviderStateMixin {
  final _key = GlobalKey();
  final _parent = GlobalKey();
  final _repaintBoundaryKey = GlobalKey();

  double _previousScale = 1;
  Offset _previousOffset = Offset.zero;
  Offset _startOffset = Offset.zero;
  Offset _endOffset = Offset.zero;
  double _previousGestureRotation = 0.0;

  /// Store the pointer count (finger involved to perform scaling).
  ///
  /// This is used to compare with the value in
  /// [ScaleUpdateDetails.pointerCount]. Check [_onScaleUpdate] for detail.
  int _previousPointerCount = 0;

  late AnimationController _controller;
  late CurvedAnimation _animation;

  Future<ui.Image> _crop(double pixelRatio) {
    final rrb = _repaintBoundaryKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary;

    return rrb.toImage(pixelRatio: pixelRatio);
  }

  @override
  void initState() {
    widget.controller._cropCallback = _crop;
    widget.controller.addListener(_reCenterImage);

    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) async {
      await Future.delayed(Duration(seconds: 1));
      while (mounted) {
        //_recenter();
        await Future.delayed(Duration(milliseconds: 1000));
      }
    });

    //Setup animation.
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _animation = CurvedAnimation(curve: Curves.easeInOut, parent: _controller);
    _animation.addListener(() {
      if (_animation.isCompleted) {
        _reCenterImage(false);
      }
      setState(() {});
    });
    super.initState();
  }

  void _recenter([bool animate = true]) {
    final sz = _key.currentContext!.size!;
    final s = widget.controller._scale * widget.controller._getMinScale();
    final w = sz.width;
    final h = sz.height;
    final canvas = Rectangle.fromLTWH(0, 0, w, h);
    var offset = _toVector2(widget.controller._offset);

    _startOffset = widget.controller._offset;
    _endOffset = widget.controller._offset;

    vm.Vector2 _integrate() {
      final obb = Obb2(
        center: offset + canvas.center,
        width: w * s,
        height: h * s,
        rotation: widget.controller._rotation,
      );

      final bakedObb = obb.bake();

      final ab0 = canvas.topEdge;
      final bc0 = canvas.rightEdge;
      final cd0 = canvas.bottomEdge;
      final da0 = canvas.leftEdge;

      final ab1 = bakedObb.topEdge;
      final bc1 = bakedObb.rightEdge;
      final cd1 = bakedObb.bottomEdge;
      final da1 = bakedObb.leftEdge;

      final ab0ab1 = ab0.intersect(ab1);
      final bc0ab1 = bc0.intersect(ab1);
      final cd0ab1 = cd0.intersect(ab1);
      final da0ab1 = da0.intersect(ab1);

      final ab0bc1 = ab0.intersect(bc1);
      final bc0bc1 = bc0.intersect(bc1);
      final cd0bc1 = cd0.intersect(bc1);
      final da0bc1 = da0.intersect(bc1);

      final ab0cd1 = ab0.intersect(cd1);
      final bc0cd1 = bc0.intersect(cd1);
      final cd0cd1 = cd0.intersect(cd1);
      final da0cd1 = da0.intersect(cd1);

      final ab0da1 = ab0.intersect(da1);
      final bc0da1 = bc0.intersect(da1);
      final cd0da1 = cd0.intersect(da1);
      final da0da1 = da0.intersect(da1);

      final top = max4(da0da1?.y, da0ab1?.y, bc0da1?.y, bc0ab1?.y);
      var bottom = min4(da0cd1?.y, da0bc1?.y, bc0bc1?.y, bc0cd1?.y);

      final left = max4(ab0da1?.x, ab0cd1?.x, cd0da1?.x, cd0cd1?.x);
      var right = min4(cd0bc1?.x, cd0ab1?.x, ab0bc1?.x, ab0ab1?.x);

      if (right != null) {
        right.value -= canvas.width;
      }

      if (bottom != null) {
        bottom.value -= canvas.height;
      }

      final msg = <String>[];

      if (top != null && top.value > 0) {
        msg.add('Top: ${top.value}');
      }

      if (bottom != null && bottom.value < 0) {
        msg.add('Bottom: ${-bottom.value}');
      }

      if (left != null && left.value > 0) {
        msg.add('Left: ${left.value}');
      }

      if (right != null && right.value < 0) {
        msg.add('Right: ${-right.value}');
      }

      var x = 0.0;
      var y = 0.0;

      if (top != null && top.value > 0) {
        y += top.value;
      }

      if (bottom != null && bottom.value < 0) {
        y += bottom.value;
      }

      if (left != null && left.value > 0) {
        x += left.value;
      }

      if (right != null && right.value < 0) {
        x += right.value;
      }

      print(msg.join(', '));

      return vm.Vector2(x, y);
    }

    const int integration_steps = 10;

    for (int i = 0; i < integration_steps; i++) {
      var dir = _integrate();

      if (dir.length <= 0.00000001) continue;

      offset.x -= dir.x;
      offset.y -= dir.y;

      print('MoveTo: $dir');
    }

    widget.controller._offset = _toOffset(offset);

    if (animate) {
      if (_controller.isCompleted || _controller.isAnimating) {
        _controller.reset();
      }
      _controller.forward();
    } else {
      _startOffset = _endOffset;
    }

    setState(() {});
    _handleOnChanged();
  }

  void _reCenterImage([bool animate = true]) {
    _recenter(animate);
    return;
    //final totalSize = _parent.currentContext.size;

    final sz = _key.currentContext!.size!;
    final s = widget.controller._scale * widget.controller._getMinScale();
    final w = sz.width;
    final h = sz.height;
    final offset = _toVector2(widget.controller._offset);
    final canvas = Rectangle.fromLTWH(0, 0, w, h);
    final obb = Obb2(
      center: offset + canvas.center,
      width: w * s,
      height: h * s,
      rotation: widget.controller._rotation,
    );

    final bakedObb = obb.bake();

    _startOffset = widget.controller._offset;
    _endOffset = widget.controller._offset;

    final ctl = canvas.topLeft;
    final ctr = canvas.topRight;
    final cbr = canvas.bottomRight;
    final cbl = canvas.bottomLeft;

    final ll = Line(bakedObb.topLeft, bakedObb.bottomLeft);
    final tt = Line(bakedObb.topRight, bakedObb.topLeft);
    final rr = Line(bakedObb.bottomRight, bakedObb.topRight);
    final bb = Line(bakedObb.bottomLeft, bakedObb.bottomRight);

    final tl = ll.project(ctl);
    final tr = tt.project(ctr);
    final br = rr.project(cbr);
    final bl = bb.project(cbl);

    final dtl = ll.distanceToPoint(ctl);
    final dtr = tt.distanceToPoint(ctr);
    final dbr = rr.distanceToPoint(cbr);
    final dbl = bb.distanceToPoint(cbl);

    if (dtl > 0) {
      final d = _toOffset(ctl - tl);
      _endOffset += d;
    }

    if (dtr > 0) {
      final d = _toOffset(ctr - tr);
      _endOffset += d;
    }

    if (dbr > 0) {
      final d = _toOffset(cbr - br);
      _endOffset += d;
    }
    if (dbl > 0) {
      final d = _toOffset(cbl - bl);
      _endOffset += d;
    }

    widget.controller._offset = _endOffset;

    if (animate) {
      if (_controller.isCompleted || _controller.isAnimating) {
        _controller.reset();
      }
      _controller.forward();
    } else {
      _startOffset = _endOffset;
    }

    setState(() {});
    _handleOnChanged();
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    widget.controller._offset += details.focalPoint - _previousOffset;
    _previousOffset = details.focalPoint;
    widget.controller._scale = _previousScale * details.scale;
    _startOffset = widget.controller._offset;
    _endOffset = widget.controller._offset;

    // In the case where lesser than 2 fingers involved in scaling, we ignore
    // the rotation handling.
    if (details.pointerCount > 1) {
      // In the first touch, we reset all the values.
      if (_previousPointerCount != details.pointerCount) {
        _previousPointerCount = details.pointerCount;
        _previousGestureRotation = 0.0;
      }

      // Instead of directly embracing the details.rotation, we need to
      // perform calculation to ensure that each round of rotation is smooth.
      // A user rotate the image using finger and release is considered as a
      // round. Without this calculation, the rotation degree of the image will
      // be reset.
      final gestureRotation = vm.degrees(details.rotation);

      // Within a round of rotation, the details.rotation is provided with
      // incremented value when user rotates. We don't need this, all we
      // want is the offset.
      final gestureRotationOffset = _previousGestureRotation - gestureRotation;

      // Remove the offset and constraint the degree scope to 0° <= degree <=
      // 360°. Constraint the scope is unnecessary, however, by doing this,
      // it would make our life easier when debugging.
      final rotationAfterCalculation =
          (widget.controller.rotation - gestureRotationOffset) % 360;

      /* details.rotation is in radians, convert this to degrees and set
        our rotation */
      widget.controller._rotation = rotationAfterCalculation;
      _previousGestureRotation = gestureRotation;
    }

    setState(() {});
    _handleOnChanged();
  }

  void _handleOnChanged() {
    widget.onChanged?.call(MatrixDecomposition(
        scale: widget.controller.scale,
        rotation: widget.controller.rotation,
        translation: widget.controller.offset));
  }

  @override
  Widget build(BuildContext context) {
    final r = vm.radians(widget.controller._rotation);
    final s = widget.controller._scale * widget.controller._getMinScale();
    final o = Offset.lerp(_startOffset, _endOffset, _animation.value)!;

    Widget _buildInnerCanvas() {
      final ip = IgnorePointer(
        key: _key,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..translate(o.dx, o.dy, 0)
            ..rotateZ(r)
            ..scale(s, s, 1),
          child: FittedBox(
            child: widget.child,
            fit: BoxFit.cover,
          ),
        ),
      );

      List<Widget> widgets = [];

      if (widget.background != null) {
        widgets.add(widget.background!);
      }

      widgets.add(ip);

      if (widget.foreground != null) {
        widgets.add(widget.foreground!);
      }

      if (widgets.length == 1) {
        return ip;
      } else {
        return Stack(
          fit: StackFit.expand,
          children: widgets,
        );
      }
    }

    Widget _buildRepaintBoundary() {
      final repaint = RepaintBoundary(
        key: _repaintBoundaryKey,
        child: _buildInnerCanvas(),
      );

      if (widget.helper == null) {
        return repaint;
      }

      return Stack(
        fit: StackFit.expand,
        children: [repaint, widget.helper!],
      );
    }

    final gd = GestureDetector(
      onScaleStart: (details) {
        _previousOffset = details.focalPoint;
        _previousScale = max(widget.controller._scale, 1);
      },
      onScaleUpdate: _onScaleUpdate,
      onScaleEnd: (details) {
        widget.controller._scale = max(widget.controller._scale, 1);
        _previousPointerCount = 0;
        _reCenterImage();
      },
    );

    List<Widget> over = [
      CropRenderObjectWidget(
        aspectRatio: widget.controller._aspectRatio,
        backgroundColor: widget.backgroundColor,
        shape: widget.shape,
        dimColor: widget.dimColor,
        child: _buildRepaintBoundary(),
      ),
    ];

    if (widget.overlay != null) {
      over.add(widget.overlay!);
    }

    if (widget.interactive) {
      over.add(gd);
    }

    return ClipRect(
      key: _parent,
      child: Stack(
        fit: StackFit.expand,
        children: over,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    widget.controller.removeListener(_reCenterImage);
    super.dispose();
  }
}

typedef _CropCallback = Future<ui.Image> Function(double pixelRatio);

class CropController extends ChangeNotifier {
  double _aspectRatio = 1;
  double _rotation = 0;
  double _scale = 1;
  Offset _offset = Offset.zero;
  _CropCallback? _cropCallback;

  double get aspectRatio => _aspectRatio;
  set aspectRatio(double value) {
    _aspectRatio = value;
    notifyListeners();
  }

  double get scale => max(_scale, 1);
  set scale(double value) {
    _scale = max(value, 1);
    notifyListeners();
  }

  double get rotation => _rotation;
  set rotation(double value) {
    _rotation = value;
    notifyListeners();
  }

  Offset get offset => _offset;
  set offset(Offset value) {
    _offset = value;
    notifyListeners();
  }

  Matrix4 get transform => Matrix4.identity()
    ..translate(_offset.dx, _offset.dy, 0)
    ..rotateZ(_rotation)
    ..scale(_scale, _scale, 1);

  CropController({
    double aspectRatio: 1.0,
    double scale: 1.0,
    double rotation: 0,
  }) {
    _aspectRatio = aspectRatio;
    _scale = scale;
    _rotation = rotation;
  }

  double _getMinScale() {
    final r = vm.radians(_rotation % 360);
    final rabs = r.abs();

    final sinr = sin(rabs).abs();
    final cosr = cos(rabs).abs();

    final x = cosr * _aspectRatio + sinr;
    final y = sinr * _aspectRatio + cosr;

    final m = max(x / _aspectRatio, y);

    return m;
  }

  /// Capture an image of the current state of this widget and its children.
  ///
  /// The returned [ui.Image] has uncompressed raw RGBA bytes, will have
  /// dimensions equal to the size of the [child] widget multiplied by [pixelRatio].
  ///
  /// The [pixelRatio] describes the scale between the logical pixels and the
  /// size of the output image. It is independent of the
  /// [window.devicePixelRatio] for the device, so specifying 1.0 (the default)
  /// will give you a 1:1 mapping between logical pixels and the output pixels
  /// in the image.
  Future<ui.Image> crop({double pixelRatio: 1}) {
    if (_cropCallback == null) {
      return Future.value(null);
    }

    return _cropCallback!.call(pixelRatio);
  }
}

vm.Vector2 _toVector2(Offset offset) => vm.Vector2(offset.dx, offset.dy);
Offset _toOffset(vm.Vector2 v) => Offset(v.x, v.y);

_IndexValue<double>? min4(double? a, double? b, double? c, double? d) {
  int? index;

  final all = [a, b, c, d];

  for (var i = 0; i < all.length; i++) {
    final num = all[i];

    if (num == null) continue;

    if (index == null || num < index) {
      index = i;
    }
  }

  if (index == null) {
    return null;
  }

  return _IndexValue(index, all[index]!);
}

_IndexValue<double>? max4(double? a, double? b, double? c, double? d) {
  int? index;

  final all = [a, b, c, d];

  for (var i = 0; i < all.length; i++) {
    final num = all[i];

    if (num == null) continue;

    if (index == null || num > index) {
      index = i;
    }
  }

  if (index == null) {
    return null;
  }

  return _IndexValue(index, all[index]!);
}

double? min2(double? a, double? b) {
  double? m;

  final all = [a, b];

  for (final num in all) {
    if (num == null) continue;

    if (m == null || num < m) {
      m = num;
    }
  }

  return m;
}

double? max2(double? a, double? b) {
  double? m;

  final all = [a, b];

  for (final num in all) {
    if (num == null) continue;

    if (m == null || num > m) {
      m = num;
    }
  }

  return m;
}

class _IndexValue<T> {
  int index;
  T value;

  _IndexValue(this.index, this.value);
}

vm.Vector2? _calculateDirection(
    double? top, double? left, double? bottom, double? right) {
  var dir = min4(top, left, bottom, right);

  if (dir == null) {
    return null;
  }

  return null;
}
