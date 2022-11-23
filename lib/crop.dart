/// Crop for Flutter. Crop any widget/image in Android, iOS, Web and Desktop with fancy and customizable UI, in 100% pure Dart code.
library crop;

import 'dart:ui' as ui;
import 'dart:math';

import 'package:collision/collision.dart';
import 'package:crop/src/matrix_decomposition.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

export 'src/matrix_decomposition.dart';

part 'src/crop.dart';
part 'src/crop_render.dart';
part 'src/crop_controller.dart';
part 'src/utils.dart';
part 'src/crop_render_object_widget.dart';
