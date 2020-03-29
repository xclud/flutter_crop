import 'dart:ui' as ui;
import 'dart:math';

import 'package:crop/src/geometry_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class Crop extends StatefulWidget {
  final Widget child;
  final Color backgroundColor;
  final Color dimColor;
  final EdgeInsetsGeometry padding;
  final Color borderColor;
  final double borderWidth;
  final CropController controller;
  final Widget foreground;

  Crop({
    Key key,
    @required this.child,
    @required this.controller,
    this.padding: const EdgeInsets.all(8),
    this.dimColor: const Color.fromRGBO(0, 0, 0, 0.8),
    this.backgroundColor: Colors.black,
    this.borderColor: Colors.white,
    this.borderWidth: 2,
    this.foreground,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _CropState();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<EdgeInsets>('padding', padding));
    properties.add(DoubleProperty('borderWidth', borderWidth));
    properties.add(ColorProperty('borderColor', borderColor));
    properties.add(ColorProperty('dimColor', dimColor));
    properties.add(DiagnosticsProperty('child', child));
    properties.add(DiagnosticsProperty('foreground', foreground));
  }
}

class _CropState extends State<Crop> with TickerProviderStateMixin {
  final _key = GlobalKey();

  double _previousScale = 1;
  Offset _previousOffset = Offset.zero;
  Offset _startOffset = Offset.zero;
  Offset _endOffset = Offset.zero;

  AnimationController _controller;
  CurvedAnimation _animation;

  @override
  void initState() {
    widget.controller.addListener(_reCenterImage);

    //Setup animation.
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );

    _animation = CurvedAnimation(curve: Curves.easeInOut, parent: _controller);
    _animation.addListener(() {
      setState(() {});
    });
    super.initState();
  }

  void _reCenterImage() {
    final sz = _key.currentContext.size;
    final s = widget.controller._scale * widget.controller._getMinScale();
    final w = sz.width;
    final h = sz.height;
    final canvas = Rect.fromLTWH(0, 0, w, h);
    final image = getRotated(
        canvas, widget.controller._rotation, s, widget.controller._offset);
    _startOffset = widget.controller._offset;
    _endOffset = widget.controller._offset;

    if (widget.controller._rotation < 0) {
      final tl = line(image.topRight, image.topLeft, canvas.topLeft);
      final tr = line(image.bottomRight, image.topRight, canvas.topRight);
      final br = line(image.bottomLeft, image.bottomRight, canvas.bottomRight);
      final bl = line(image.topLeft, image.bottomLeft, canvas.bottomLeft);

      final dtl = side(image.topRight, image.topLeft, canvas.topLeft);
      final dtr = side(image.bottomRight, image.topRight, canvas.topRight);
      final dbr = side(image.bottomLeft, image.bottomRight, canvas.bottomRight);
      final dbl = side(image.topLeft, image.bottomLeft, canvas.bottomLeft);

      if (dtl > 0) {
        final d = canvas.topLeft - tl;
        _endOffset += d;
      }

      if (dtr > 0) {
        final d = canvas.topRight - tr;
        _endOffset += d;
      }

      if (dbr > 0) {
        final d = canvas.bottomRight - br;
        _endOffset += d;
      }
      if (dbl > 0) {
        final d = canvas.bottomLeft - bl;
        _endOffset += d;
      }
    } else {
      final tl = line(image.topLeft, image.bottomLeft, canvas.topLeft);
      final tr = line(image.topLeft, image.topRight, canvas.topRight);
      final br = line(image.bottomRight, image.topRight, canvas.bottomRight);
      final bl = line(image.bottomLeft, image.bottomRight, canvas.bottomLeft);

      final dtl = side(image.topLeft, image.bottomLeft, canvas.topLeft);
      final dtr = side(image.topRight, image.topLeft, canvas.topRight);
      final dbr = side(image.bottomRight, image.topRight, canvas.bottomRight);
      final dbl = side(image.bottomLeft, image.bottomRight, canvas.bottomLeft);

      if (dtl > 0) {
        final d = canvas.topLeft - tl;
        _endOffset += d;
      }

      if (dtr > 0) {
        final d = canvas.topRight - tr;
        _endOffset += d;
      }

      if (dbr > 0) {
        final d = canvas.bottomRight - br;
        _endOffset += d;
      }
      if (dbl > 0) {
        final d = canvas.bottomLeft - bl;
        _endOffset += d;
      }
    }

    widget.controller._offset = _endOffset;

    if (_controller.isCompleted || _controller.isAnimating) {
      _controller.reset();
    }
    _controller.forward();

    setState(() {});
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    widget.controller._offset += details.focalPoint - _previousOffset;
    _previousOffset = details.focalPoint;
    widget.controller._scale = _previousScale * details.scale;
    _startOffset = widget.controller._offset;
    _endOffset = widget.controller._offset;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.controller._rotation / 180.0 * pi;
    final s = widget.controller._scale * widget.controller._getMinScale();
    final o = Offset.lerp(_startOffset, _endOffset, _animation.value);

    return LayoutBuilder(
      builder: (context, constraints) {
        final sz = Size(constraints.maxWidth, constraints.maxHeight);

        final insets = widget.padding.resolve(Directionality.of(context));
        final v = insets.left + insets.right;
        final h = insets.top + insets.bottom;
        final size = getSizeToFitByRatio(
          widget.controller._aspectRatio,
          sz.width - v,
          sz.height - h,
        );

        Widget getInCanvas() {
          final ip = IgnorePointer(
            key: _key,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..translate(o.dx, o.dy, 0)
                ..rotateZ(r)
                ..scale(s, s, 1),
              child: widget.child,
            ),
          );
          if (widget.foreground == null) {
            return ip;
          } else {
            return Stack(
              fit: StackFit.expand,
              children: <Widget>[
                ip,
                widget.foreground,
              ],
            );
          }
        }

        return ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Container(color: widget.backgroundColor),
              CropRenderObjectWidget(
                child: FittedBox(
                  child: SizedBox.fromSize(
                    size: size,
                    child: RepaintBoundary(
                      key: widget.controller._previewKey,
                      child: getInCanvas(),
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onScaleStart: (details) {
                  _previousOffset = details.focalPoint;
                  _previousScale = max(widget.controller._scale, 1);
                },
                onScaleUpdate: _onScaleUpdate,
                onScaleEnd: (details) {
                  widget.controller._scale = max(widget.controller._scale, 1);
                  _reCenterImage();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    widget.controller.removeListener(_reCenterImage);
    super.dispose();
  }
}

class CropController extends ChangeNotifier {
  final _previewKey = GlobalKey();
  double _aspectRatio = 1;
  double _rotation = 0;
  double _scale = 1;
  Offset _offset = Offset.zero;

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
    final r = _rotation / 180.0 * pi;
    final rabs = r.abs();

    final sinr = sin(rabs);
    final cosr = cos(rabs);

    final x = cosr * _aspectRatio + sinr;
    final y = sinr * _aspectRatio + cosr;

    return max(x / _aspectRatio, y);
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
    RenderRepaintBoundary rrb = _previewKey.currentContext.findRenderObject();
    return rrb.toImage(pixelRatio: pixelRatio);
  }
}

class CropRenderObjectWidget extends SingleChildRenderObjectWidget {
  final Color dimColor;
  final double borderWidth;
  final Color borderColor;
  CropRenderObjectWidget({
    @required Widget child,
    this.borderWidth: 2,
    this.borderColor: Colors.white,
    this.dimColor: const Color.fromRGBO(0, 0, 0, 0.8),
  }) : super(child: child);
  @override
  RenderObject createRenderObject(BuildContext context) {
    return CropRenderObject()
      ..dimColor = dimColor
      ..borderColor = borderColor
      ..borderWidth = borderWidth;
  }

  @override
  void updateRenderObject(BuildContext context, CropRenderObject renderObject) {
    renderObject?.dimColor = dimColor;
    renderObject?.borderWidth = borderWidth;
    renderObject?.borderColor = borderColor;
    super.updateRenderObject(context, renderObject);
  }
}

class CropRenderObject extends RenderBox
    with RenderObjectWithChildMixin<RenderBox> {
  Color dimColor;
  double borderWidth;
  Color borderColor;
  @override
  bool hitTestSelf(Offset position) => false;

  @override
  void performLayout() {
    final BoxConstraints constraints = this.constraints;

    if (child != null) {
      child.layout(constraints.loosen(), parentUsesSize: true);
    }
    size = constraints.biggest;
  }

  Path _getDimClipPath() {
    final center = Offset(
      size.width / 2,
      size.height / 2,
    );
    Rect rect = Rect.fromCenter(
        center: center, width: child.size.width, height: child.size.height);

    return Path()
      ..addRect(rect)
      ..addRect(Rect.fromLTWH(0.0, 0.0, size.width, size.height))
      ..fillType = PathFillType.evenOdd;
  }

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {}

  void paint(PaintingContext context, Offset offset) {
    final bounds = offset & size;

    if (child != null) {
      final Offset tmp = size - child.size;

      final area = offset + tmp / 2 & child.size;
      context.paintChild(child, offset + tmp / 2);

      final clipPath = _getDimClipPath();

      context.pushClipPath(needsCompositing, offset, bounds, clipPath,
          (context, offset) {
        context.canvas.drawRect(bounds, Paint()..color = dimColor);
      });
      if (borderWidth != null && borderWidth > 0 && borderColor != null) {
        context.canvas.drawRect(
          area,
          Paint()
            ..color = borderColor
            ..strokeWidth = borderWidth
            ..style = PaintingStyle.stroke,
        );
      }
    }
  }
}
