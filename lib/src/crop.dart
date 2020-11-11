import 'dart:ui' as ui;
import 'dart:math';

import 'package:crop/src/crop_render.dart';
import 'package:crop/src/geometry_helper.dart';
import 'package:crop/src/matrix_decomposition.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

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

  late AnimationController _controller;
  late CurvedAnimation _animation;

  Future<ui.Image> _crop({
    double? targetWidth,
    double? targetHeight,
    required double pixelRatio,
  }) {
    final rrb = _repaintBoundaryKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    
    if (rrb == null || !rrb.hasSize) {
      return Future.value(null);
    }

    final effectivePixelRatio = (targetWidth != null) 
      ? targetWidth / rrb.size.width
      : (targetHeight != null)
      ? targetHeight / rrb.size.height
      : pixelRatio;

    return rrb.toImage(pixelRatio: effectivePixelRatio);
  }

  @override
  void initState() {
    widget.controller._cropCallback = _crop;
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
    //final totalSize = _parent.currentContext.size;

    final sz = _key.currentContext!.size!;
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
    final sz = _key.currentContext!.size!;
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
    widget.onChanged?.call(MatrixDecomposition(
        scale: widget.controller.scale,
        rotation: widget.controller.rotation,
        translation: widget.controller.offset));
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.controller._rotation / 180.0 * pi;
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

typedef _CropCallback = Future<ui.Image> Function({
  double? targetWidth,
  double? targetHeight,
  required double pixelRatio,
});

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
  /// The returned [ui.Image] has uncompressed raw RGBA bytes. When the widget
  /// has not been laid out, it maybe null.
  ///
  /// [targetWidth], [targetHeight], [pixelRatio] can be set only one.
  /// - if set [targetWidth], the width of the returned [ui.Image] will be [targetWidth] pixels.
  /// - if set [targetHeight], the height of the returned [ui.Image] will be [targetHeight] pixels.
  /// - if set [pixelRatio], the returned [ui.Image] will have dimensions equal
  /// to the size of the [child] widget multiplied by [pixelRatio].
  /// The [pixelRatio] describes the scale between the logical pixels and the
  /// size of the output image. It is independent of the
  /// [window.devicePixelRatio] for the device, so specifying 1.0 (the default)
  /// will give you a 1:1 mapping between logical pixels and the output pixels
  /// in the image.
  Future<ui.Image> crop({
    double? targetWidth,
    double? targetHeight,
    double? pixelRatio
  }) {
    if (_cropCallback == null) {
      return Future.value(null);  
    }

    // Note: to preserve backwards compatbility of `pixelRatio` default to 1.0, we allow 0 args to be passed
    assert(
      [targetWidth, targetHeight, pixelRatio]
            .where((it) => it != null)
            .length <= 1,
      "Only one arg is allowed: targetWidget($targetWidth), targetHeight($targetHeight), pixelRatio($pixelRatio).",
    );

    // if others are not set, set pixelRatio
    return _cropCallback!.call(targetWidth: targetWidth, targetHeight: targetHeight, pixelRatio: pixelRatio ?? 1.0);
  }
}
