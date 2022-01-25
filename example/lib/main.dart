import 'dart:ui' as ui;
import 'package:app/centered_slider_track_shape.dart';
import 'package:app/save_to_gallery_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:crop/crop.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crop Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

final controllerN =
    ValueNotifier<CropController>(CropController(aspectRatio: 1000 / 667.0));

final rotationN = ValueNotifier<double>(0.0);

final shapeN = ValueNotifier<BoxShape>(BoxShape.rectangle);

class MyHomePage extends StatelessWidget {
  void _cropImage(BuildContext context) async {
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final cropped = await controllerN.value.crop(pixelRatio: pixelRatio);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SaveToGalleryScreen(cropped),
        fullscreenDialog: true,
      ),
    );
  }

  const MyHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crop Demo'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.link),
          onPressed: () {
            launch('https://github.com/xclud/flutter_crop');
          },
        ),
        actions: <Widget>[
          IconButton(
            onPressed: () => _cropImage(context),
            tooltip: 'Crop',
            icon: const Icon(Icons.crop),
          )
        ],
      ),
      body: Column(
        children: <Widget>[
          const Expanded(child: CropperWidget()),
          Column(
            children: [
              Row(
                children: const [
                  UndoButton(),
                  BoxShapeButton(),
                  RatioButton(),
                ],
              ),
              const RotationSlider()
            ],
          ),
        ],
      ),
    );
  }
}

class MultiValueListenable<A, B, C> extends StatelessWidget {
  const MultiValueListenable(
    this.a,
    this.b,
    this.c, {
    Key? key,
    required this.builder,
    this.child,
  }) : super(key: key);

  final ValueListenable<A> a;
  final ValueListenable<B> b;
  final ValueListenable<C> c;
  final Widget? child;
  final Widget Function(BuildContext context, A a, B b, C c, Widget? child)
      builder;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<A>(
      valueListenable: a,
      builder: (context, a, _) => ValueListenableBuilder<B>(
        valueListenable: b,
        builder: (context, b, _) => ValueListenableBuilder<C>(
          valueListenable: c,
          builder: (context, c, _) => builder(context, a, b, c, child),
        ),
      ),
    );
  }
}

class CropperWidget extends StatelessWidget {
  const CropperWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(8),
      child: MultiValueListenable<CropController, double, BoxShape>(
        controllerN,
        rotationN,
        shapeN,
        builder: (context, controller, rotation, shape, child) {
          return Crop(
            onChanged: (decomposition) {
              if (rotation != decomposition.rotation) {
                rotationN.value = ((decomposition.rotation + 180) % 360) - 180;
              }

              // print(
              //     "Scale : ${decomposition.scale}, Rotation: ${decomposition.rotation}, translation: ${decomposition.translation}");
            },
            controller: controller,
            shape: shape,
            child: Image.asset(
              'images/sample.jpg',
              fit: BoxFit.cover,
            ),
            /* It's very important to set `fit: BoxFit.cover`.
                       Do NOT remove this line.
                       There are a lot of issues on github repo by people who remove this line and their image is not shown correctly.
                    */
            foreground: IgnorePointer(
              child: Container(
                alignment: Alignment.bottomRight,
                child: const Text(
                  'Foreground Object',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ),
            helper: shape == BoxShape.rectangle
                ? Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  )
                : null,
          );
        },
      ),
    );
  }
}

class UndoButton extends StatelessWidget {
  const UndoButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.undo),
      tooltip: 'Undo',
      onPressed: () {
        controllerN.value.rotation = 0;
        controllerN.value.scale = 1;
        controllerN.value.offset = Offset.zero;
        rotationN.value = 0;
      },
    );
  }
}

class RotationSlider extends StatelessWidget {
  const RotationSlider({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ValueListenableBuilder<double>(
      valueListenable: rotationN,
      builder: (context, val, child) {
        return SliderTheme(
          data: theme.sliderTheme.copyWith(
            trackShape: CenteredRectangularSliderTrackShape(),
          ),
          child: Slider(
            divisions: 360,
            value: val,
            min: -180,
            max: 180,
            label: '$val°',
            onChanged: (n) {
              rotationN.value = n.roundToDouble();

              controllerN.value.rotation = rotationN.value;
            },
          ),
        );
      },
    );
  }
}

class BoxShapeButton extends StatelessWidget {
  const BoxShapeButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<BoxShape>(
      icon: const Icon(Icons.crop_free),
      itemBuilder: (context) => [
        const PopupMenuItem(
          child: Text("Box"),
          value: BoxShape.rectangle,
        ),
        const PopupMenuItem(
          child: Text("Oval"),
          value: BoxShape.circle,
        ),
      ],
      tooltip: 'Crop Shape',
      onSelected: (x) => shapeN.value = x,
    );
  }
}

class RatioButton extends StatelessWidget {
  const RatioButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<double>(
      icon: const Icon(Icons.aspect_ratio),
      itemBuilder: (context) => [
        const PopupMenuItem(
          child: Text("Original"),
          value: 1000 / 667.0,
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          child: Text("16:9"),
          value: 16.0 / 9.0,
        ),
        const PopupMenuItem(
          child: Text("4:3"),
          value: 4.0 / 3.0,
        ),
        const PopupMenuItem(
          child: Text("1:1"),
          value: 1,
        ),
        const PopupMenuItem(
          child: Text("3:4"),
          value: 3.0 / 4.0,
        ),
        const PopupMenuItem(
          child: Text("9:16"),
          value: 9.0 / 16.0,
        ),
      ],
      tooltip: 'Aspect Ratio',
      onSelected: (x) => controllerN.value.aspectRatio = x,
    );
  }
}
