part of crop;

/// Render object widget with a [RenderCrop] inside.
class CropRenderObjectWidget extends SingleChildRenderObjectWidget {
  const CropRenderObjectWidget({
    required Widget child,
    required this.aspectRatio,
    required this.shape,
    Key? key,
    this.backgroundColor = Colors.black,
    this.dimColor = const Color.fromRGBO(0, 0, 0, 0.8),
    this.padding = EdgeInsets.zero,
    this.radius,
  }) : super(key: key, child: child);

  /// Aspect ratio.
  final double aspectRatio;

  /// Dim Color.
  final Color dimColor;

  /// Background color.
  final Color backgroundColor;

  /// Shape of crop area.
  final BoxShape shape;

  /// Padding of crop area.
  final EdgeInsets padding;

  /// Radius of crop area.
  final Radius? radius;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderCrop()
      ..aspectRatio = aspectRatio
      ..dimColor = dimColor
      ..backgroundColor = backgroundColor
      ..shape = shape
      ..padding = padding
      ..radius = radius;
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
