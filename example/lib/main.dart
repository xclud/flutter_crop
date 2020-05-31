import 'dart:ui' as ui;
import 'package:app/centered_slider_track_shape.dart';
import 'package:flutter/material.dart';
import 'package:crop/crop.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crop Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var controller;
  double _rotation = 0;

  @override
  void initState() {
    super.initState();

    controller = CropController(
        aspectRatio: 1000 / 667.0,
        updatedCallback: () {
          setState(() {
            _rotation = controller.rotation;
          });
        });
  }

  void _cropImage() async {
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final cropped = await controller.crop(pixelRatio: pixelRatio);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('Crop Result'),
            centerTitle: true,
            actions: [
              Builder(
                builder: (context) => IconButton(
                  icon: Icon(Icons.save),
                  onPressed: () async {
                    final status = await Permission.storage.request();
                    if (status == PermissionStatus.granted) {
                      await _saveScreenShot(cropped);
                      Scaffold.of(context).showSnackBar(
                        SnackBar(
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
        title: Text('Crop Demo'),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(FontAwesome.github),
          onPressed: () {
            launch('https://github.com/xclud/flutter_crop');
          },
        ),
        actions: <Widget>[
          IconButton(
            onPressed: _cropImage,
            tooltip: 'Crop',
            icon: Icon(Icons.crop),
          )
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Container(
              color: Colors.black,
              padding: EdgeInsets.all(8),
              child: Crop(
                controller: controller,
                child: Image.asset(
                  'images/sample.jpg',
                  fit: BoxFit.cover,
                ), //It's very important to set fit: BoxFit.cover.
                foreground: IgnorePointer(
                  child: Container(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      'Foreground Object',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
                helper: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: <Widget>[
              IconButton(
                icon: Icon(Icons.undo),
                tooltip: 'Undo',
                onPressed: () {
                  setState(() {
                    controller.rotation = 0.0;
                    controller.scale = 1;
                    controller.offset = Offset.zero;
                  });
                },
              ),
              Expanded(
                child: SliderTheme(
                  data: theme.sliderTheme.copyWith(
                    trackShape: CenteredRectangularSliderTrackShape(),
                  ),
                  child: Slider(
                    divisions: 361,
                    value: _rotation,
                    min: -360,
                    max: 360,
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
              PopupMenuButton<double>(
                icon: Icon(Icons.aspect_ratio),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: Text("Original"),
                    value: 1000 / 667.0,
                  ),
                  PopupMenuDivider(),
                  PopupMenuItem(
                    child: Text("16:9"),
                    value: 16.0 / 9.0,
                  ),
                  PopupMenuItem(
                    child: Text("4:3"),
                    value: 4.0 / 3.0,
                  ),
                  PopupMenuItem(
                    child: Text("1:1"),
                    value: 1,
                  ),
                  PopupMenuItem(
                    child: Text("3:4"),
                    value: 3.0 / 4.0,
                  ),
                  PopupMenuItem(
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

Future<dynamic> _saveScreenShot(ui.Image img) async {
  var byteData = await img.toByteData(format: ui.ImageByteFormat.png);
  var buffer = byteData.buffer.asUint8List();
  final result = await ImageGallerySaver.saveImage(buffer);
  print(result);

  return result;
}
