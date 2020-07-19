// Based on slider.dart
// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class TapeMeasureSlider extends StatefulWidget {
  final double value;
  final Color activeColor;
  final Color tickColor;
  final ValueChanged<double> onChanged;
  final int divisions;
  final double min;
  final double max;
  final int smallTickEvery;
  final int bigTickEvery;
  final int mainTickEvery;
  final int mainSnapDistance;

  const TapeMeasureSlider({Key key, @required this.value, this.activeColor, this.tickColor, this.onChanged, @required this.divisions, @required this.min, @required this.max, @required this.smallTickEvery, @required this.bigTickEvery, @required this.mainTickEvery, this.mainSnapDistance})
      : assert(value != null),
        assert(divisions > 0),
        assert(min != null),
        assert(max != null),
        assert(value >= min && value <= max),
        assert(smallTickEvery != null),
        assert(bigTickEvery != null),
        assert(mainTickEvery != null),
        assert(bigTickEvery > smallTickEvery && bigTickEvery % smallTickEvery == 0, 'bigTickEvery not divisible by smallTickEvery'),
        assert(mainTickEvery >= bigTickEvery && mainTickEvery % bigTickEvery == 0, 'mainTickEvery not divisible by bigTickEvery'),
        super(key: key);

  @override
  _TapeMeasureSliderState createState() => _TapeMeasureSliderState();
}

class _TapeMeasureSliderState extends State<TapeMeasureSlider> with TickerProviderStateMixin {
  final GlobalKey _renderObjectKey = GlobalKey();
  static const Duration enableAnimationDuration = Duration(milliseconds: 75);
  AnimationController overlayController;
  AnimationController enableController;
  AnimationController positionController;
  Timer interactionTimer;

  bool get _enabled => widget.onChanged != null;

  @override
  void initState() {
    super.initState();

    overlayController = AnimationController(duration: kRadialReactionDuration, vsync: this);
    enableController = AnimationController(duration: enableAnimationDuration, vsync: this);
    positionController = AnimationController(duration: Duration.zero, vsync: this);
    enableController.value = widget.onChanged != null ? 1.0 : 0.0;
    positionController.value = _unlerp(widget.value);
  }

  @override
  void dispose() {
    interactionTimer?.cancel();
    overlayController.dispose();
    enableController.dispose();
    positionController.dispose();
    if (overlayEntry != null) {
      overlayEntry.remove();
      overlayEntry = null;
    }
    super.dispose();
  }

  void _handleChanged(double value) {
    assert(widget.onChanged != null);
    final double lerpValue = _lerp(value);
    if (lerpValue != widget.value) {
      widget.onChanged(lerpValue);
    }
  }

  bool _focused = false;

  void _handleFocusHighlightChanged(bool focused) {
    if (focused != _focused) {
      setState(() => _focused = focused);
    }
  }

  bool _hovering = false;

  void _handleHoverChanged(bool hovering) {
    if (hovering != _hovering) {
      setState(() => _hovering = hovering);
    }
  }

  // Returns a number between min and max, proportional to value, which must
  // be between 0.0 and 1.0.
  double _lerp(double value) {
    assert(value >= 0.0);
    assert(value <= 1.0);
    return value * (widget.max - widget.min) + widget.min;
  }

  // Returns a number between 0.0 and 1.0, given a value between min and max.
  double _unlerp(double value) {
    assert(value <= widget.max);
    assert(value >= widget.min);
    return widget.max > widget.min ? (value - widget.min) / (widget.max - widget.min) : 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    SliderThemeData sliderTheme = SliderTheme.of(context);

    // If the widget has active or inactive colors specified, then we plug them
    // in to the slider theme as best we can. If the developer wants more
    // control than that, then they need to use a SliderTheme. The default
    // colors come from the ThemeData.colorScheme. These colors, along with
    // the default shapes and text styles are aligned to the Material
    // Guidelines.

    const double _defaultTrackHeight = 4;
    final SliderTrackShape _defaultTrackShape = RoundedRectSliderTrackShape();
    final SliderTickMarkShape _defaultTickMarkShape = _TapeMeasureTick(smallTickEvery: widget.smallTickEvery, bigTickEvery: widget.bigTickEvery, mainTickEvery: widget.mainTickEvery);
    final SliderComponentShape _defaultOverlayShape = _TapeMeasureOverlay();
    final _defaultThumbShape = _TapeMeasureThumb(min: widget.min.toInt(), max: widget.max.toInt());

    sliderTheme = sliderTheme.copyWith(
      trackHeight: sliderTheme.trackHeight ?? _defaultTrackHeight,
      activeTrackColor: widget.activeColor ?? sliderTheme.activeTrackColor ?? theme.colorScheme.primary,
      inactiveTrackColor: sliderTheme.inactiveTrackColor ?? theme.colorScheme.primary.withOpacity(0.24),
      disabledActiveTrackColor: sliderTheme.disabledActiveTrackColor ?? theme.colorScheme.onSurface.withOpacity(0.32),
      disabledInactiveTrackColor: sliderTheme.disabledInactiveTrackColor ?? theme.colorScheme.onSurface.withOpacity(0.12),
      activeTickMarkColor: widget.tickColor ?? sliderTheme.activeTickMarkColor ?? theme.colorScheme.onPrimary.withOpacity(0.54),
      inactiveTickMarkColor: widget.tickColor ?? sliderTheme.inactiveTickMarkColor ?? theme.colorScheme.primary.withOpacity(0.54),
      disabledActiveTickMarkColor: sliderTheme.disabledActiveTickMarkColor ?? theme.colorScheme.onPrimary.withOpacity(0.12),
      disabledInactiveTickMarkColor: sliderTheme.disabledInactiveTickMarkColor ?? theme.colorScheme.onSurface.withOpacity(0.12),
      thumbColor: widget.activeColor ?? sliderTheme.thumbColor ?? theme.colorScheme.primary,
      disabledThumbColor: sliderTheme.disabledThumbColor ?? Color.alphaBlend(theme.colorScheme.onSurface.withOpacity(.38), theme.colorScheme.surface),
      overlayColor: widget.activeColor?.withOpacity(0.12) ?? sliderTheme.overlayColor ?? theme.colorScheme.primary.withOpacity(0.12),
      trackShape: sliderTheme.trackShape ?? _defaultTrackShape,
      tickMarkShape: sliderTheme.tickMarkShape ?? _defaultTickMarkShape,
      thumbShape: sliderTheme.thumbShape ?? _defaultThumbShape,
      overlayShape: sliderTheme.overlayShape ?? _defaultOverlayShape,
    );
    final MouseCursor effectiveMouseCursor = MaterialStateProperty.resolveAs<MouseCursor>(
      MaterialStateMouseCursor.clickable,
      <MaterialState>{
        if (!_enabled) MaterialState.disabled,
        if (_hovering) MaterialState.hovered,
        if (_focused) MaterialState.focused,
      },
    );

    // This size is used as the max bounds for the painting of the value
    // indicators It must be kept in sync with the function with the same name
    // in range_slider.dart.
    Size _screenSize() => MediaQuery.of(context).size;

    return FocusableActionDetector(
      enabled: _enabled,
      onShowFocusHighlight: _handleFocusHighlightChanged,
      onShowHoverHighlight: _handleHoverChanged,
      mouseCursor: effectiveMouseCursor,
      child: CompositedTransformTarget(
        link: _layerLink,
        child: _SliderRenderObjectWidget(
          key: _renderObjectKey,
          value: _unlerp(widget.value),
          divisions: widget.divisions,
          mainTickEvery: widget.mainTickEvery,
          sliderTheme: sliderTheme,
          textScaleFactor: MediaQuery.of(context).textScaleFactor,
          screenSize: _screenSize(),
          onChanged: (widget.onChanged != null) && (widget.max > widget.min) ? _handleChanged : null,
          state: this,
          hasFocus: _focused,
          hovering: _hovering,
        ),
      ),
    );
  }

  final LayerLink _layerLink = LayerLink();
  OverlayEntry overlayEntry;
}

class _TapeMeasureThumb extends SliderComponentShape {
  final double thumbRadius;
  final double thumbHeight;
  final int min;
  final int max;

  const _TapeMeasureThumb({this.thumbRadius = 3, this.thumbHeight = 24, this.min = 0, this.max = 10});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => Size(thumbHeight * 1.2, thumbHeight);

  @override
  void paint(PaintingContext context, Offset center, {@required Animation<double> activationAnimation, @required Animation<double> enableAnimation, bool isDiscrete = false, @required TextPainter labelPainter, @required RenderBox parentBox, @required SliderThemeData sliderTheme, @required TextDirection textDirection, @required double value, double textScaleFactor, Size sizeWithOverflow}) {
    assert(context != null);
    assert(center != null);
    assert(activationAnimation != null);
    assert(enableAnimation != null);
    assert(labelPainter != null);
    assert(parentBox != null);
    assert(sliderTheme != null);
    assert(textDirection != null);
    assert(value != null);

    final rRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: thumbHeight * 1.2, height: thumbHeight),
      Radius.circular(thumbRadius),
    );
    final paint = Paint()
      ..color = sliderTheme.thumbColor
      ..style = PaintingStyle.fill;

    TextSpan span = TextSpan(style: TextStyle(fontSize: thumbHeight * 0.5, fontWeight: FontWeight.w700, color: Colors.white, height: 0.9), text: '${getValue(value)}');
    TextPainter tp = TextPainter(text: span, textAlign: TextAlign.left, textDirection: TextDirection.ltr);
    tp.layout();
    Offset textCenter = Offset(center.dx - (tp.width / 2), center.dy - (tp.height / 2));

    context.canvas.drawRRect(rRect, paint);
    tp.paint(context.canvas, textCenter);
  }

  String getValue(double value) {
    double lerp = value * (max - min) + min;
    return lerp.round().toString();
  }
}

class _TapeMeasureOverlay extends SliderComponentShape {
  final double thumbRadius;
  final double thumbHeight;

  const _TapeMeasureOverlay({this.thumbRadius = 3, this.thumbHeight = 36});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => Size(thumbHeight * 1.2, thumbHeight);

  @override
  void paint(PaintingContext context, Offset center, {@required Animation<double> activationAnimation, @required Animation<double> enableAnimation, bool isDiscrete = false, @required TextPainter labelPainter, @required RenderBox parentBox, @required SliderThemeData sliderTheme, @required TextDirection textDirection, @required double value, double textScaleFactor, Size sizeWithOverflow}) {
    assert(context != null);
    assert(center != null);
    assert(activationAnimation != null);
    assert(enableAnimation != null);
    assert(labelPainter != null);
    assert(parentBox != null);
    assert(sliderTheme != null);
    assert(textDirection != null);
    assert(value != null);

    final Tween<double> sizeTween = Tween<double>(
      begin: 0.0,
      end: thumbHeight,
    );

    double currentSize = sizeTween.evaluate(activationAnimation);
    final rRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: currentSize * 1.2, height: currentSize),
      Radius.circular(thumbRadius),
    );
    final paint = Paint()
      ..color = sliderTheme.overlayColor
      ..style = PaintingStyle.fill;

    context.canvas.drawRRect(rRect, paint);
  }
}

abstract class _TapeMeasureTickMarkShape extends SliderTickMarkShape {
  const _TapeMeasureTickMarkShape();

  @override
  Size getPreferredSize({SliderThemeData sliderTheme, bool isEnabled});

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    RenderBox parentBox,
    SliderThemeData sliderTheme,
    Animation<double> enableAnimation,
    Offset thumbCenter,
    bool isEnabled,
    TextDirection textDirection,
    int index,
  });
}

class _TapeMeasureTick extends _TapeMeasureTickMarkShape {
  final double tickWidth;
  final double tickHeight;
  final int smallTickEvery;
  final int bigTickEvery;
  final int mainTickEvery;

  const _TapeMeasureTick({this.tickWidth = 2, this.tickHeight = 10, this.smallTickEvery = 10, this.bigTickEvery = 50, this.mainTickEvery = 100});

  @override
  Size getPreferredSize({SliderThemeData sliderTheme, bool isEnabled = false}) => Size(tickWidth, tickHeight);

  @override
  void paint(PaintingContext context, Offset center, {@required RenderBox parentBox, @required SliderThemeData sliderTheme, @required Animation<double> enableAnimation, @required TextDirection textDirection, @required Offset thumbCenter, bool isEnabled = false, int index}) {
    assert(context != null);
    assert(center != null);
    assert(parentBox != null);
    assert(sliderTheme != null);
    assert(sliderTheme.disabledActiveTickMarkColor != null);
    assert(sliderTheme.disabledInactiveTickMarkColor != null);
    assert(sliderTheme.activeTickMarkColor != null);
    assert(sliderTheme.inactiveTickMarkColor != null);
    assert(enableAnimation != null);
    assert(textDirection != null);
    assert(thumbCenter != null);
    assert(isEnabled != null);

    if (index % smallTickEvery == 0) {
      final paint = Paint()
        ..color = sliderTheme.activeTickMarkColor
        ..style = PaintingStyle.fill;

      Rect rect;
      if (index % bigTickEvery == 0)
        rect = Rect.fromCenter(center: center, width: tickWidth, height: tickHeight);
      else
        rect = Rect.fromCenter(center: center, width: tickWidth / 2, height: tickHeight / 2);

      if (index % mainTickEvery == 0) paint.color = sliderTheme.activeTrackColor;
      context.canvas.drawRect(rect, paint);
    }
  }
}

class _SliderRenderObjectWidget extends LeafRenderObjectWidget {
  final double value;
  final int divisions;
  final int mainTickEvery;
  final int mainSnapDistance;
  final String label;
  final SliderThemeData sliderTheme;
  final double textScaleFactor;
  final Size screenSize;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeStart;
  final ValueChanged<double> onChangeEnd;
  final SemanticFormatterCallback semanticFormatterCallback;
  final _TapeMeasureSliderState state;
  final bool hasFocus;
  final bool hovering;

  const _SliderRenderObjectWidget({Key key, this.value, this.divisions, this.mainTickEvery, this.mainSnapDistance, this.label, this.sliderTheme, this.textScaleFactor, this.screenSize, this.onChanged, this.onChangeStart, this.onChangeEnd, this.state, this.semanticFormatterCallback, this.hasFocus, this.hovering}) : super(key: key);

  @override
  _RenderSlider createRenderObject(BuildContext context) => _RenderSlider(
        value: value,
        divisions: divisions,
        mainTickEvery: mainTickEvery,
        mainSnapDistance: mainSnapDistance,
        label: label,
        sliderTheme: sliderTheme,
        textScaleFactor: textScaleFactor,
        screenSize: screenSize,
        onChanged: onChanged,
        state: state,
        textDirection: Directionality.of(context),
        semanticFormatterCallback: semanticFormatterCallback,
        platform: Theme.of(context).platform,
        hasFocus: hasFocus,
        hovering: hovering,
      );

  @override
  void updateRenderObject(BuildContext context, _RenderSlider renderObject) {
    renderObject
      ..value = value
      ..divisions = divisions
      ..mainTickEvery = mainTickEvery
      ..mainSnapDistance = mainSnapDistance
      ..label = label
      ..sliderTheme = sliderTheme
      ..theme = Theme.of(context)
      ..textScaleFactor = textScaleFactor
      ..screenSize = screenSize
      ..onChanged = onChanged
      ..textDirection = Directionality.of(context)
      ..semanticFormatterCallback = semanticFormatterCallback
      ..platform = Theme.of(context).platform
      ..hasFocus = hasFocus
      ..hovering = hovering;
  }
}

class _RenderSlider extends RenderBox with RelayoutWhenSystemFontsChangeMixin {
  _RenderSlider({
    @required double value,
    int divisions,
    int mainTickEvery,
    int mainSnapDistance,
    String label,
    SliderThemeData sliderTheme,
    double textScaleFactor,
    Size screenSize,
    TargetPlatform platform,
    ValueChanged<double> onChanged,
    SemanticFormatterCallback semanticFormatterCallback,
    @required _TapeMeasureSliderState state,
    @required TextDirection textDirection,
    bool hasFocus,
    bool hovering,
  })  : assert(value != null && value >= 0.0 && value <= 1.0),
        assert(state != null),
        assert(textDirection != null),
        _platform = platform,
        _semanticFormatterCallback = semanticFormatterCallback,
        _label = label,
        _value = value,
        _divisions = divisions,
        _mainTickEvery = mainTickEvery,
        _mainSnapDistance = mainSnapDistance,
        _sliderTheme = sliderTheme,
        _textScaleFactor = textScaleFactor,
        _screenSize = screenSize,
        _onChanged = onChanged,
        _state = state,
        _textDirection = textDirection,
        _hasFocus = hasFocus,
        _hovering = hovering {
    final team = GestureArenaTeam();
    _drag = HorizontalDragGestureRecognizer()
      ..team = team
      ..onStart = _handleDragStart
      ..onUpdate = _handleDragUpdate
      ..onEnd = _handleDragEnd
      ..onCancel = _endInteraction;
    _tap = TapGestureRecognizer()
      ..team = team
      ..onTapDown = _handleTapDown
      ..onTapUp = _handleTapUp
      ..onTapCancel = _endInteraction;
    _overlayAnimation = CurvedAnimation(
      parent: _state.overlayController,
      curve: Curves.fastOutSlowIn,
    );
    _enableAnimation = CurvedAnimation(
      parent: _state.enableController,
      curve: Curves.easeInOut,
    );
  }

  static const Duration _positionAnimationDuration = Duration(milliseconds: 75);

  // This value is the touch target, 48, multiplied by 3.
  static const double _minPreferredTrackWidth = 144.0;

  // Compute the largest width and height needed to paint the slider shapes,
  // other than the track shape. It is assumed that these shapes are vertically
  // centered on the track.
  double get _maxSliderPartWidth => _sliderPartSizes.map((Size size) => size.width).reduce(math.max);

  double get _maxSliderPartHeight => _sliderPartSizes.map((Size size) => size.height).reduce(math.max);

  List<Size> get _sliderPartSizes => <Size>[
        _sliderTheme.overlayShape.getPreferredSize(isInteractive, true),
        _sliderTheme.thumbShape.getPreferredSize(isInteractive, true),
        _sliderTheme.tickMarkShape.getPreferredSize(isEnabled: isInteractive, sliderTheme: sliderTheme),
      ];

  double get _minPreferredTrackHeight => _sliderTheme.trackHeight;

  final _TapeMeasureSliderState _state;
  Animation<double> _overlayAnimation;
  Animation<double> _enableAnimation;
  final TextPainter _labelPainter = TextPainter();
  HorizontalDragGestureRecognizer _drag;
  TapGestureRecognizer _tap;
  bool _active = false;
  double _currentDragValue = 0.0;

  // This rect is used in gesture calculations, where the gesture coordinates
  // are relative to the sliders origin. Therefore, the offset is passed as
  // (0,0).
  Rect get _trackRect => _sliderTheme.trackShape.getPreferredRect(
        parentBox: this,
        offset: Offset.zero,
        sliderTheme: _sliderTheme,
        isDiscrete: false,
      );

  bool get isInteractive => onChanged != null;

  double get value => _value;
  double _value;

  set value(double newValue) {
    assert(newValue != null && newValue >= 0.0 && newValue <= 1.0);
    final double convertedValue = _discretize(newValue, mainTickEvery);
    if (convertedValue == _value) {
      return;
    }
    _value = convertedValue;
    // Reset the duration to match the distance that we're traveling, so that
    // whatever the distance, we still do it in _positionAnimationDuration,
    // and if we get re-targeted in the middle, it still takes that long to
    // get to the new location.
    final double distance = (_value - _state.positionController.value).abs();
    _state.positionController.duration = distance != 0.0 ? _positionAnimationDuration * (1.0 / distance) : Duration.zero;
    _state.positionController.animateTo(convertedValue, curve: Curves.easeInOut);
    markNeedsSemanticsUpdate();
  }

  TargetPlatform _platform;

  TargetPlatform get platform => _platform;

  set platform(TargetPlatform value) {
    if (_platform == value) return;
    _platform = value;
    markNeedsSemanticsUpdate();
  }

  SemanticFormatterCallback _semanticFormatterCallback;

  SemanticFormatterCallback get semanticFormatterCallback => _semanticFormatterCallback;

  set semanticFormatterCallback(SemanticFormatterCallback value) {
    if (_semanticFormatterCallback == value) return;
    _semanticFormatterCallback = value;
    markNeedsSemanticsUpdate();
  }

  int get divisions => _divisions;
  int _divisions;

  set divisions(int value) {
    if (value == _divisions) {
      return;
    }
    _divisions = value;
    markNeedsPaint();
  }

  int get mainTickEvery => _mainTickEvery;
  int _mainTickEvery;

  set mainTickEvery(int value) {
    if (value == _mainTickEvery) {
      return;
    }
    _mainTickEvery = value;
    markNeedsPaint();
  }

  int _mainSnapDistance;

  int get mainSnapDistance => _mainSnapDistance;

  set mainSnapDistance(int value) => _mainSnapDistance = value;

  String get label => _label;
  String _label;

  set label(String value) {
    if (value == _label) {
      return;
    }
    _label = value;
  }

  SliderThemeData get sliderTheme => _sliderTheme;
  SliderThemeData _sliderTheme;

  set sliderTheme(SliderThemeData value) {
    if (value == _sliderTheme) {
      return;
    }
    _sliderTheme = value;
    markNeedsPaint();
  }

  ThemeData get theme => _theme;
  ThemeData _theme;

  set theme(ThemeData value) {
    if (value == _theme) {
      return;
    }
    _theme = value;
    markNeedsPaint();
  }

  double get textScaleFactor => _textScaleFactor;
  double _textScaleFactor;

  set textScaleFactor(double value) {
    if (value == _textScaleFactor) {
      return;
    }
    _textScaleFactor = value;
  }

  Size get screenSize => _screenSize;
  Size _screenSize;

  set screenSize(Size value) {
    if (value == _screenSize) {
      return;
    }
    _screenSize = value;
    markNeedsPaint();
  }

  ValueChanged<double> get onChanged => _onChanged;
  ValueChanged<double> _onChanged;

  set onChanged(ValueChanged<double> value) {
    if (value == _onChanged) {
      return;
    }
    final bool wasInteractive = isInteractive;
    _onChanged = value;
    if (wasInteractive != isInteractive) {
      if (isInteractive) {
        _state.enableController.forward();
      } else {
        _state.enableController.reverse();
      }
      markNeedsPaint();
      markNeedsSemanticsUpdate();
    }
  }

  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;

  set textDirection(TextDirection value) {
    assert(value != null);
    if (value == _textDirection) {
      return;
    }
    _textDirection = value;
  }

  /// True if this slider has the input focus.
  bool get hasFocus => _hasFocus;
  bool _hasFocus;

  set hasFocus(bool value) {
    assert(value != null);
    if (value == _hasFocus) return;
    _hasFocus = value;
    _updateForFocusOrHover(_hasFocus);
  }

  /// True if this slider is being hovered over by a pointer.
  bool get hovering => _hovering;
  bool _hovering;

  set hovering(bool value) {
    assert(value != null);
    if (value == _hovering) return;
    _hovering = value;
    _updateForFocusOrHover(_hovering);
  }

  void _updateForFocusOrHover(bool hasFocusOrIsHovering) {
    if (hasFocusOrIsHovering)
      _state.overlayController.forward();
    else
      _state.overlayController.reverse();
  }

  @override
  void systemFontsDidChange() {
    super.systemFontsDidChange();
    _labelPainter.markNeedsLayout();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _overlayAnimation.addListener(markNeedsPaint);
    _enableAnimation.addListener(markNeedsPaint);
    _state.positionController.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _overlayAnimation.removeListener(markNeedsPaint);
    _enableAnimation.removeListener(markNeedsPaint);
    _state.positionController.removeListener(markNeedsPaint);
    super.detach();
  }

  double _getValueFromVisualPosition(double visualPosition) {
    switch (textDirection) {
      case TextDirection.rtl:
        return 1.0 - visualPosition;
      case TextDirection.ltr:
        return visualPosition;
    }
    return null;
  }

  double _getValueFromGlobalPosition(Offset globalPosition) {
    final double visualPosition = (globalToLocal(globalPosition).dx - _trackRect.left) / _trackRect.width;
    return _getValueFromVisualPosition(visualPosition);
  }

  double _discretize(double value, int mainTickEvery) {
    double result = value.clamp(0.0, 1.0) as double;

    // check if we're near a main tick
    if (mainSnapDistance != null) {
      int dist = (value * divisions).toInt() % mainTickEvery;
      if (dist < mainSnapDistance || dist > mainTickEvery - mainSnapDistance) {
        double mainDivisions = (divisions - 1) / mainTickEvery;
        return (result * mainDivisions).round() / mainDivisions;
      }
    }

    return (result * divisions).round() / divisions;
  }

  void _startInteraction(Offset globalPosition) {
    if (isInteractive) {
      _active = true;
      _currentDragValue = _getValueFromGlobalPosition(globalPosition);
      onChanged(_discretize(_currentDragValue, mainTickEvery));
      _state.overlayController.forward();
    }
  }

  void _endInteraction() {
    if (!_state.mounted) {
      return;
    }

    if (_active && _state.mounted) {
      _active = false;
      _currentDragValue = 0.0;
      _state.overlayController.reverse();
    }
  }

  void _handleDragStart(DragStartDetails details) => _startInteraction(details.globalPosition);

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_state.mounted) {
      return;
    }

    if (isInteractive) {
      final double valueDelta = details.primaryDelta / _trackRect.width;
      switch (textDirection) {
        case TextDirection.rtl:
          _currentDragValue -= valueDelta;
          break;
        case TextDirection.ltr:
          _currentDragValue += valueDelta;
          break;
      }
      onChanged(_discretize(_currentDragValue, mainTickEvery));
    }
  }

  void _handleDragEnd(DragEndDetails details) => _endInteraction();

  void _handleTapDown(TapDownDetails details) => _startInteraction(details.globalPosition);

  void _handleTapUp(TapUpDetails details) => _endInteraction();

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    assert(debugHandleEvent(event, entry));
    if (event is PointerDownEvent && isInteractive) {
      // We need to add the drag first so that it has priority.
      _drag.addPointer(event);
      _tap.addPointer(event);
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) => _minPreferredTrackWidth + _maxSliderPartWidth;

  @override
  double computeMaxIntrinsicWidth(double height) => _minPreferredTrackWidth + _maxSliderPartWidth;

  @override
  double computeMinIntrinsicHeight(double width) => math.max(_minPreferredTrackHeight, _maxSliderPartHeight);

  @override
  double computeMaxIntrinsicHeight(double width) => math.max(_minPreferredTrackHeight, _maxSliderPartHeight);

  @override
  bool get sizedByParent => true;

  @override
  void performResize() {
    size = Size(
      constraints.hasBoundedWidth ? constraints.maxWidth : _minPreferredTrackWidth + _maxSliderPartWidth,
      constraints.hasBoundedHeight ? constraints.maxHeight : math.max(_minPreferredTrackHeight, _maxSliderPartHeight),
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final double value = _state.positionController.value;

    // The visual position is the position of the thumb from 0 to 1 from left
    // to right. In left to right, this is the same as the value, but it is
    // reversed for right to left text.
    double visualPosition;
    switch (textDirection) {
      case TextDirection.rtl:
        visualPosition = 1.0 - value;
        break;
      case TextDirection.ltr:
        visualPosition = value;
        break;
    }

    final Rect trackRect = _sliderTheme.trackShape.getPreferredRect(
      parentBox: this,
      offset: offset,
      sliderTheme: _sliderTheme,
      isDiscrete: true,
    );
    final Offset thumbCenter = Offset(trackRect.left + visualPosition * trackRect.width, trackRect.center.dy);

    if (!_overlayAnimation.isDismissed) {
      _sliderTheme.overlayShape.paint(
        context,
        thumbCenter,
        activationAnimation: _overlayAnimation,
        enableAnimation: _enableAnimation,
        isDiscrete: true,
        labelPainter: _labelPainter,
        parentBox: this,
        sliderTheme: _sliderTheme,
        textDirection: _textDirection,
        value: _value,
      );
    }

    final double padding = trackRect.height;
    final double adjustedTrackWidth = trackRect.width - padding;
    final double dy = trackRect.center.dy;
    for (int i = 0; i <= divisions; i++) {
      final double value = i / divisions;
      // The ticks are mapped to be within the track, so the tick mark width
      // must be subtracted from the track width.
      final double dx = trackRect.left + value * adjustedTrackWidth + padding / 2;
      final Offset tickMarkOffset = Offset(dx, dy);
      _TapeMeasureTickMarkShape tickMarkShape = _sliderTheme.tickMarkShape;
      tickMarkShape.paint(
        context,
        tickMarkOffset,
        parentBox: this,
        sliderTheme: _sliderTheme,
        enableAnimation: _enableAnimation,
        textDirection: _textDirection,
        thumbCenter: thumbCenter,
        isEnabled: isInteractive,
        index: i,
      );
    }

    _sliderTheme.thumbShape.paint(
      context,
      thumbCenter,
      activationAnimation: _overlayAnimation,
      enableAnimation: _enableAnimation,
      isDiscrete: true,
      labelPainter: _labelPainter,
      parentBox: this,
      sliderTheme: _sliderTheme,
      textDirection: _textDirection,
      sizeWithOverflow: screenSize.isEmpty ? size : screenSize,
      value: _value,
    );
  }
}
