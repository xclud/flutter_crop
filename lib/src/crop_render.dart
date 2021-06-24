import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Render object widget with a [RenderCrop] inside.
class CropRenderObjectWidget extends SingleChildRenderObjectWidget {

  const CropRenderObjectWidget({
    required Widget child,
    required this.aspectRatio,
    required this.shape,
    Key? key,
    this.backgroundColor = Colors.black,
    this.dimColor = const Color.fromRGBO(0, 0, 0, 0.8),
  }) : super(key: key, child: child);
  
  /// Aspect ratio.
  final double aspectRatio;
  
  /// Dim Color.
  final Color dimColor;
  
  /// Background color.
  final Color backgroundColor;
  
  /// Shape of crop area.
  final BoxShape shape;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderCrop()
      ..aspectRatio = aspectRatio
      ..dimColor = dimColor
      ..backgroundColor = backgroundColor
      ..shape = shape;
  }

  @override
  void updateRenderObject(BuildContext context, RenderCrop renderObject) {
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

/// RenderBox for [Crop].
class RenderCrop extends RenderBox with RenderObjectWithChildMixin<RenderBox> {
  double? aspectRatio;
  Color? dimColor;
  Color? backgroundColor;
  BoxShape? shape;

  @override
  bool hitTestSelf(Offset position) => false;

  @override
  void performLayout() {
    final BoxConstraints constraints = this.constraints;
    size = constraints.biggest;

    if (child != null) {
      final forcedSize =
          _getSizeToFitByRatio(aspectRatio!, size.width, size.height);
      child!.layout(BoxConstraints.tight(forcedSize), parentUsesSize: true);
    }
  }

  Path _getDimClipPath() {
    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final forcedSize =
        _getSizeToFitByRatio(aspectRatio!, size.width, size.height);
    Rect rect = Rect.fromCenter(
        center: center, width: forcedSize.width, height: forcedSize.height);

    final path = Path();
    if (shape == BoxShape.circle) {
      path.addOval(rect);
    } else if (shape == BoxShape.rectangle) {
      path.addRect(rect);
    }

    path.addRect(Rect.fromLTWH(0.0, 0.0, size.width, size.height));
    path.fillType = PathFillType.evenOdd;
    return path;
  }

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {}

  @override
  void paint(PaintingContext context, Offset offset) {
    final bounds = offset & size;

    if (backgroundColor != null) {
      context.canvas.drawRect(bounds, Paint()..color = backgroundColor!);
    }

    final forcedSize =
        _getSizeToFitByRatio(aspectRatio!, size.width, size.height);

    if (child != null) {
      final Offset tmp = (size - forcedSize) as Offset;
      context.paintChild(child!, offset + tmp / 2);

      final clipPath = _getDimClipPath();

      context.pushClipPath(
        needsCompositing,
        offset,
        bounds,
        clipPath,
        (context, offset) {
          context.canvas.drawRect(bounds, Paint()..color = dimColor!);
        },
      );
    }
  }
}

Size _getSizeToFitByRatio(
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
