part of crop;

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

vm.Vector2 _toVector2(Offset offset) => vm.Vector2(offset.dx, offset.dy);
Offset _toOffset(vm.Vector2 v) => Offset(v.x, v.y);
