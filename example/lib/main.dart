import 'dart:ui' as ui;
import 'package:app/centered_slider_track_shape.dart';
import 'package:app/save_to_gallery_screen.dart';
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

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final controller = CropController(aspectRatio: 1000 / 667.0);
  double _rotation = 0;
  BoxShape shape = BoxShape.rectangle;

  void _cropImage() async {
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final cropped = await controller.crop(pixelRatio: pixelRatio);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SaveToGalleryScreen(cropped),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
            onPressed: _cropImage,
            tooltip: 'Crop',
            icon: const Icon(Icons.crop),
          )
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Container(
              color: Colors.black,
              padding: const EdgeInsets.all(8),
              child: Crop(
                onChanged: (decomposition) {
                  if (_rotation != decomposition.rotation) {
                    setState(() {
                      _rotation = ((decomposition.rotation + 180) % 360) - 180;
                    });
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
              ),
            ),
          ),
          Row(
            children: <Widget>[
              IconButton(
                icon: const Icon(Icons.undo),
                tooltip: 'Undo',
                onPressed: () {
                  controller.rotation = 0;
                  controller.scale = 1;
                  controller.offset = Offset.zero;
                  setState(() {
                    _rotation = 0;
                  });
                },
              ),
              Expanded(
                child: SliderTheme(
                  data: theme.sliderTheme.copyWith(
                    trackShape: CenteredRectangularSliderTrackShape(),
                  ),
                  child: Slider(
                    divisions: 360,
                    value: _rotation,
                    min: -180,
                    max: 180,
                    label: '$_rotation°',
                    onChanged: (n) {
                      setState(() {
                        _rotation = n.roundToDouble();
                        controller.rotation = _rotation;
                      });
                    },
                  ),
                ),
              ),
              PopupMenuButton<BoxShape>(
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
                onSelected: (x) {
                  setState(() {
                    shape = x;
                  });
                },
              ),
              PopupMenuButton<double>(
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
                onSelected: (x) {
                  controller.aspectRatio = x;
                  setState(() {});
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
