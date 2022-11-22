import 'dart:ui' as ui;
import 'package:app/centered_slider_track_shape.dart';
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
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final controller = CropController(aspectRatio: 1000 / 667.0);
  double _rotation = 0;
  BoxShape shape = BoxShape.rectangle;

  void _cropImage() async {
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final cropped = await controller.crop(pixelRatio: pixelRatio);

    if (cropped == null) {
      return;
    }

    if (!mounted) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Crop Result'),
            centerTitle: true,
            actions: [
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: () async {
                    final status = await Permission.storage.request();
                    if (status == PermissionStatus.granted) {
                      await _saveScreenShot(cropped);
                      if (!mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Saved to gallery.'),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
          body: Center(
            child: RawImage(
              image: cropped,
            ),
          ),
        ),
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
            launchUrl(Uri.parse('https://github.com/xclud/flutter_crop'),
                mode: LaunchMode.externalApplication);
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
              padding: const EdgeInsets.all(20),
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
                child: Image.asset(
                  'images/sample.jpg',
                  fit: BoxFit.cover,
                ),
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
                    value: BoxShape.rectangle,
                    child: Text("Box"),
                  ),
                  const PopupMenuItem(
                    value: BoxShape.circle,
                    child: Text("Oval"),
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
                    value: 1000 / 667.0,
                    child: Text("Original"),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 16.0 / 9.0,
                    child: Text("16:9"),
                  ),
                  const PopupMenuItem(
                    value: 4.0 / 3.0,
                    child: Text("4:3"),
                  ),
                  const PopupMenuItem(
                    value: 1,
                    child: Text("1:1"),
                  ),
                  const PopupMenuItem(
                    value: 3.0 / 4.0,
                    child: Text("3:4"),
                  ),
                  const PopupMenuItem(
                    value: 9.0 / 16.0,
                    child: Text("9:16"),
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

Future<dynamic> _saveScreenShot(ui.Image img) async {
  var byteData = await img.toByteData(format: ui.ImageByteFormat.png);
  var buffer = byteData!.buffer.asUint8List();
  final result = await ImageGallerySaver.saveImage(buffer);

  return result;
}
