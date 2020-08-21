import 'dart:ui' as ui;
import 'dart:math';

import 'package:crop/src/geometry_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

enum CropShape {
  box,
  oval,
}


class MatrixDecomposition {
  final double rotation;
  final double scale;
  final Offset translation;

  MatrixDecomposition({this.scale, this.rotation, this.translation});
}

class Crop extends StatefulWidget {
  final Widget child;
  final CropController controller;
  final Color backgroundColor;
  final Color dimColor;
  final EdgeInsetsGeometry padding;
  final Widget background;
  final Widget foreground;
  final Widget helper;
  final Widget overlay;
  final bool interactive;
  final CropShape shape;
  final double shapeScale;
  final ValueChanged<MatrixDecomposition> onChanged;

  Crop({
    Key key,
    @required this.child,
    @required this.controller,
    this.padding: const EdgeInsets.all(8),
    this.dimColor: const Color.fromRGBO(0, 0, 0, 0.8),
    this.backgroundColor: Colors.black,
    this.background,
    this.foreground,
    this.helper,
    this.overlay,
    this.interactive: true,
    this.shape: CropShape.box,
    this.onChanged,
    this.shapeScale,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _CropState();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<EdgeInsets>('padding', padding));
    properties.add(ColorProperty('dimColor', dimColor));
    properties.add(DiagnosticsProperty('child', child));
    properties.add(DiagnosticsProperty('controller', controller));
    properties.add(DiagnosticsProperty('background', background));
    properties.add(DiagnosticsProperty('foreground', foreground));
    properties.add(DiagnosticsProperty('helper', helper));
    properties.add(DiagnosticsProperty('overlay', overlay));
    properties.add(FlagProperty('interactive', value: interactive));
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
      if (_animation.isCompleted) {
        _reCenterImageNoAnimation();
      }
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

    widget.controller._offset = _endOffset;

    if (_controller.isCompleted || _controller.isAnimating) {
      _controller.reset();
    }
    _controller.forward();

    setState(() {});

    _handleOnChanged();
  }

  void _reCenterImageNoAnimation() {
    final sz = _key.currentContext.size;
    final s = widget.controller._scale * widget.controller._getMinScale();
    final w = sz.width;
    final h = sz.height;
    final canvas = Rect.fromLTWH(0, 0, w, h);
    final image = getRotated(
        canvas, widget.controller._rotation, s, widget.controller._offset);
    _startOffset = widget.controller._offset;
    _endOffset = widget.controller._offset;

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

    _startOffset = _endOffset;
    widget.controller._offset = _endOffset;

    setState(() {});

    _handleOnChanged();
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    widget.controller._offset += details.focalPoint - _previousOffset;
    _previousOffset = details.focalPoint;
    widget.controller._scale = _previousScale * details.scale;
    _startOffset = widget.controller._offset;
    _endOffset = widget.controller._offset;

    setState(() {});
    _handleOnChanged();
  }

  void _handleOnChanged() {
    widget?.onChanged?.call(MatrixDecomposition(
        scale: widget.controller.scale,
        rotation: widget.controller.rotation,
        translation: widget.controller.offset));
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.controller._rotation / 180.0 * pi;
    final s = widget.controller._scale * widget.controller._getMinScale();
    final o = Offset.lerp(_startOffset, _endOffset, _animation.value);

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

      List<Widget> widgets = [];

      if (widget.background != null) {
        widgets.add(widget.background);
      }

      widgets.add(ip);

      if (widget.foreground != null) {
        widgets.add(widget.foreground);
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

    Widget getRepaintBoundary() {
      final repaint = RepaintBoundary(
        key: widget.controller._previewKey,
        child: getInCanvas(),
      );

      if (widget.helper == null) {
        return repaint;
      }

      return Stack(
        fit: StackFit.expand,
        children: [repaint, widget.helper],
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
        _reCenterImage();
      },
    );

    List<Widget> over = [
      CropRenderObjectWidget(
        aspectRatio: widget.controller._aspectRatio,
        backgroundColor: widget.backgroundColor,
        shape: widget.shape,
        dimColor: widget.dimColor,
        shapeScale: widget.shapeScale,
        child: getRepaintBoundary(),
      ),
    ];

    if (widget.overlay != null) {
      over.add(widget.overlay);
    }

    if (widget.interactive) {
      over.add(gd);
    }

    return ClipRect(
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
    final r = (_rotation % 360) / 180.0 * pi;
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
    RenderRepaintBoundary rrb = _previewKey.currentContext.findRenderObject();
    return rrb.toImage(pixelRatio: pixelRatio);
  }
}

class CropRenderObjectWidget extends SingleChildRenderObjectWidget {
  final double aspectRatio;
  final Color dimColor;
  final Color backgroundColor;
  final CropShape shape;
  final double shapeScale;
  CropRenderObjectWidget({
    @required Widget child,
    @required this.aspectRatio,
    @required this.shape,
    this.shapeScale: 1,
    this.backgroundColor: Colors.black,
    this.dimColor: const Color.fromRGBO(0, 0, 0, 0.8),
  }) : super(child: child);
  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderCrop()
      ..aspectRatio = aspectRatio
      ..dimColor = dimColor
      ..backgroundColor = backgroundColor
      ..shape = shape
      ..shapeScale = shapeScale;
  }

  @override
  void updateRenderObject(BuildContext context, RenderCrop renderObject) {
    if (renderObject == null) return;

    bool needsPaint = false;
    bool needsLayout = false;

    if (renderObject.aspectRatio != aspectRatio) {
      renderObject.aspectRatio = aspectRatio;
      needsLayout = true;
    }

    if (renderObject.dimColor != dimColor) {
      renderObject.dimColor = dimColor;
      needsPaint = true;
    }

    if (renderObject.shape != shape) {
      renderObject.shape = shape;
      needsPaint = true;
    }

    if(renderObject.shapeScale != shapeScale) {
      renderObject.shapeScale = shapeScale;
      needsPaint = true;
    }

    if (renderObject.backgroundColor != backgroundColor) {
      renderObject.backgroundColor = backgroundColor;
      needsPaint = true;
    }

    if (needsLayout) {
      renderObject.markNeedsLayout();
    }
    if (needsPaint) {
      renderObject.markNeedsPaint();
    }

    super.updateRenderObject(context, renderObject);
  }
}

class RenderCrop extends RenderBox with RenderObjectWithChildMixin<RenderBox> {
  double aspectRatio;
  Color dimColor;
  Color backgroundColor;
  CropShape shape;
  double shapeScale;
  @override
  bool hitTestSelf(Offset position) => false;

  @override
  void performLayout() {
    final BoxConstraints constraints = this.constraints;
    size = constraints.biggest;

    if (child != null) {
      final scale = shapeScale ?? 1;
      final forcedSize =
          getSizeToFitByRatio(aspectRatio,
              size.width * scale, size.height * scale);
      child.layout(BoxConstraints.tight(forcedSize), parentUsesSize: true);
    }
  }

  Path _getDimClipPath() {
    final scale = shapeScale ?? 1;
    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final forcedSize =
        getSizeToFitByRatio(aspectRatio,
            size.width * scale, size.height * scale);
    Rect rect = Rect.fromCenter(
        center: center, width: forcedSize.width, height: forcedSize.height);

    final path = Path();
    if (shape == CropShape.oval) {
      path.addOval(rect);
    } else if (shape == CropShape.box) {
      path.addRect(rect);
    }

    path.addRect(Rect.fromLTWH(0.0, 0.0, size.width, size.height));
    path.fillType = PathFillType.evenOdd;
    return path;
  }

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {}

  void paint(PaintingContext context, Offset offset) {
    final scale = shapeScale ?? 1;
    final bounds = offset & size;

    if (backgroundColor != null) {
      context.canvas.drawRect(bounds, Paint()..color = backgroundColor);
    }

    final forcedSize =
        getSizeToFitByRatio(aspectRatio,
            size.width * scale, size.height * scale);

    if (child != null) {
      final Offset tmp = size - forcedSize;
      context.paintChild(child, offset + tmp / 2);

      final clipPath = _getDimClipPath();

      context.pushClipPath(
        needsCompositing,
        offset,
        bounds,
        clipPath,
        (context, offset) {
          context.canvas.drawRect(bounds, Paint()..color = dimColor);
        },
      );
    }
  }
}
