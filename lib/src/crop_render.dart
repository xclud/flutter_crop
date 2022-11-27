part of crop;

/// RenderBox for [Crop].
class RenderCrop extends RenderBox with RenderObjectWithChildMixin<RenderBox> {
  double? aspectRatio;
  Color? dimColor;
  Color? backgroundColor;
  BoxShape? shape;
  EdgeInsets? padding;
  Radius? radius;

  @override
  bool hitTestSelf(Offset position) => false;

  @override
  void performLayout() {
    final BoxConstraints constraints = this.constraints;
    size = constraints.biggest;

    if (child != null) {
      final forcedSize =
          _getSizeToFitByRatio(aspectRatio!, size.width, size.height, padding!);
      child!.layout(BoxConstraints.tight(forcedSize), parentUsesSize: true);
    }
  }

  Path _getDimClipPath() {
    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final forcedSize =
        _getSizeToFitByRatio(aspectRatio!, size.width, size.height, padding!);

    final path = Path();
    final baseRect = Rect.fromCenter(
      center: center,
      width: forcedSize.width,
      height: forcedSize.height,
    );

    if (radius != null) {
      final rect = RRect.fromRectAndRadius(baseRect, radius!);
      path.addRRect(rect);
    } else {
      final rect = baseRect;
      if (shape == BoxShape.circle) {
        path.addOval(rect);
      } else if (shape == BoxShape.rectangle) {
        path.addRect(rect);
      }
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
        _getSizeToFitByRatio(aspectRatio!, size.width, size.height, padding!);

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
