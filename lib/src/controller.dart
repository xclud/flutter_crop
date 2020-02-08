import 'dart:async';
import 'dart:ui' as ui;
import 'dart:math';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class CropController {
  CropController({
    CropValue initialValue = const CropValue(),
  })  : _value = initialValue,
        _prevValue = initialValue,
        _valueStreamController = StreamController<CropValue>.broadcast()
          ..sink.add(initialValue);
  final previewKey = GlobalKey();

  CropValue _value, _prevValue;
  CropValue get value => _value;
  CropValue get prevValue => _prevValue;

  final StreamController<CropValue> _valueStreamController;
  Stream<CropValue> get valueStream => _valueStreamController.stream;

  void setValue(CropValue value, {bool ignoreNotify = false}) {
    _prevValue = _value;
    _value = value;
    if (!ignoreNotify) {
      _valueStreamController.sink.add(value);
    }
  }

  double get aspectRatio => value.aspectRatio;
  set aspectRatio(double aspectRatio) {
    setValue(value.copyWith(aspectRatio: aspectRatio));
  }

  Offset get offset => value.offset;
  set offset(Offset offset) {
    setValue(value.copyWith(offset: offset));
  }

  double get scale => max(value.scale, 1);
  set scale(double scale) {
    setValue(value.copyWith(scale: max(scale, 1)));
  }

  double get rotation => value.rotation;
  set rotation(double rotation) {
    setValue(value.copyWith(rotation: rotation));
  }

  void reset() {
    setValue(value.copyWith(
      rotation: 0,
      scale: 1,
      offset: Offset.zero,
    ));
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
    RenderRepaintBoundary rrb = previewKey.currentContext.findRenderObject();
    return rrb.toImage(pixelRatio: pixelRatio);
  }

  dispose() {
    _valueStreamController.close();
  }
}

class CropValue {
  const CropValue({
    this.aspectRatio = 1,
    this.offset = Offset.zero,
    this.rotation = 0,
    this.scale = 1,
  });

  final double aspectRatio;
  final Offset offset;
  final double rotation;
  final double scale;

  CropValue copyWith({
    double aspectRatio,
    Offset offset,
    double rotation,
    double scale,
  }) =>
      CropValue(
        aspectRatio: aspectRatio ?? this.aspectRatio,
        offset: offset ?? this.offset,
        rotation: rotation ?? this.rotation,
        scale: scale ?? this.scale,
      );
}
