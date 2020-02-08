import 'dart:math';

import 'package:crop/src/geometry_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'controller.dart';

class Crop extends StatefulWidget {
  const Crop({
    Key key,
    @required this.child,
    this.padding: const EdgeInsets.all(8),
    this.dimColor: const Color.fromRGBO(0, 0, 0, 0.8),
    this.backgroundColor: Colors.black,
    this.controller,
  }) : super(key: key);

  final Widget child;

  final Color backgroundColor;
  final Color dimColor;
  final EdgeInsetsGeometry padding;
  final CropController controller;

  @override
  State<StatefulWidget> createState() => CropState();
}

class CropState extends State<Crop> with TickerProviderStateMixin {
  final _key = GlobalKey();
  CropController _controller;

  double _previousScale = 1;
  Offset _previousOffset = Offset.zero,
      _startOffset = Offset.zero,
      _endOffset = Offset.zero;

  AnimationController _animation;

  @override
  void initState() {
    _controller = widget.controller ?? CropController()
      ..valueStream.listen((value) {
        if (_controller.prevValue.offset != value.offset) {
          _startOffset = _endOffset = value.offset;
        }
        _reCenterImage();
      });

    // Setup animation.
    _animation = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );

    super.initState();
  }

  double _getMinScale() {
    final r = _controller.rotation / 180.0 * pi;
    final rabs = r.abs();

    final sinr = sin(rabs);
    final cosr = cos(rabs);

    final x = cosr * _controller.aspectRatio + sinr;
    final y = sinr * _controller.aspectRatio + cosr;

    return max(x / _controller.aspectRatio, y);
  }

  void _reCenterImage() {
    if (_key.currentContext?.owner?.debugBuilding ?? true) {
      return;
    }
    final sz = _key.currentContext.size;
    final s = _controller.scale * _getMinScale();
    final w = sz.width;
    final h = sz.height;
    final canvas = Rect.fromLTWH(0, 0, w, h);
    final image =
        getRotated(canvas, _controller.rotation, s, _controller.offset);
    _startOffset = _controller.offset;
    _endOffset = _controller.offset;

    if (_controller.rotation < 0) {
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

    _controller.setValue(
      _controller.value.copyWith(offset: _endOffset),
      ignoreNotify: true,
    );

    if (_animation.isCompleted || _animation.isAnimating) {
      _animation.reset();
    }
    _animation.forward();

    setState(() {});
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    final offset =
        _controller.value.offset + details.focalPoint - _previousOffset;
    _previousOffset = details.focalPoint;
    final scale = _previousScale * details.scale;
    _startOffset = _controller.offset;
    _endOffset = _controller.offset;

    _controller.setValue(
      _controller.value.copyWith(
        offset: offset,
        scale: scale,
      ),
      ignoreNotify: true,
    );

    setState(() {});
  }

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final r = _controller.rotation / 180.0 * pi;
        final s = _controller.scale * _getMinScale();

        final sz = Size(constraints.maxWidth, constraints.maxHeight);
        final insets = widget.padding.resolve(Directionality.of(context));
        final v = insets.left + insets.right;
        final h = insets.top + insets.bottom;
        final size = getSizeToFitByRatio(
          _controller.aspectRatio,
          sz.width - v,
          sz.height - h,
        );

        final offset = Offset(
          sz.width - size.width,
          sz.height - size.height,
        ).scale(0.5, 0.5);

        return ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Container(color: widget.backgroundColor),
              Padding(
                padding: widget.padding,
                child: FittedBox(
                  child: SizedBox.fromSize(
                    size: size,
                    child: RepaintBoundary(
                      key: _controller.previewKey,
                      child: IgnorePointer(
                        key: _key,
                        child: AnimatedBuilder(
                          animation: _animation,
                          builder: (_, widget) {
                            final o = Offset.lerp(
                              _startOffset,
                              _endOffset,
                              _animation.value,
                            );
                            return Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()
                                ..translate(o.dx, o.dy, 0)
                                ..rotateZ(r)
                                ..scale(s, s, 1),
                              child: widget,
                            );
                          },
                          child: widget.child,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              ClipPath(
                clipper: _InvertedRectangleClipper(offset & size),
                child: IgnorePointer(
                  child: Container(color: widget.dimColor),
                ),
              ),
              Padding(
                padding: widget.padding,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox.fromSize(
                    size: size,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onScaleStart: (details) {
                  _previousOffset = details.focalPoint;
                  _previousScale = max(_controller.scale, 1);
                },
                onScaleUpdate: _onScaleUpdate,
                onScaleEnd: (details) {
                  _controller.scale = max(_controller.scale, 1);
                },
              ),
            ],
          ),
        );
      });

  @override
  void dispose() {
    _controller.dispose();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }
}

class _InvertedRectangleClipper extends CustomClipper<Path> {
  final Rect rect;
  _InvertedRectangleClipper(this.rect);

  @override
  Path getClip(Size size) {
    return Path()
      ..addRect(rect)
      ..addRect(Rect.fromLTWH(0.0, 0.0, size.width, size.height))
      ..fillType = PathFillType.evenOdd;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
