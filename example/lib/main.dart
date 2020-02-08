import 'dart:io';

import 'package:flutter/material.dart';
import 'package:crop/crop.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'centered_slider_track_shape.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Crop Demo',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: MyHomePage(),
      );
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  ImageProvider _imageProvider;
  CropController _cropController;

  @override
  void initState() {
    _cropController = CropController(
      initialValue: CropValue(aspectRatio: _1000x667Ratio),
    );
    _imageProvider = AssetImage('images/sample.jpg');
    super.initState();
  }

  @override
  void dispose() {
    _cropController.dispose();
    super.dispose();
  }

  void _undoPressed() {
    _cropController.reset();
  }

  void _cropImage() async {
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final cropped = await _cropController.crop(pixelRatio: pixelRatio);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('Crop Result'),
            centerTitle: true,
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
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.photo),
          onPressed: _getImage,
        ),
        title: Text('Crop Demo'),
        centerTitle: true,
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
            child: Crop(
              controller: _cropController,
              child: Image(image: _imageProvider),
            ),
          ),
          Row(
            children: <Widget>[
              IconButton(
                icon: Icon(Icons.undo),
                tooltip: 'Undo',
                onPressed: _undoPressed,
              ),
              Expanded(
                child: SliderTheme(
                  data: theme.sliderTheme.copyWith(
                    trackShape: CenteredRectangularSliderTrackShape(),
                  ),
                  child: StreamBuilder<CropValue>(
                    initialData: _cropController.value,
                    stream: _cropController.valueStream,
                    builder: (_, snapshot) => Slider(
                      divisions: 91,
                      value: snapshot.data.rotation,
                      min: -45,
                      max: 45,
                      label: snapshot.data.rotation.toString(),
                      onChanged: (value) {
                        _cropController.rotation = value.roundToDouble();
                      },
                    ),
                  ),
                ),
              ),
              StreamBuilder<CropValue>(
                initialData: _cropController.value,
                stream: _cropController.valueStream,
                builder: (_, snapshot) => PopupMenuButton<double>(
                  initialValue: snapshot.data.aspectRatio,
                  icon: Icon(Icons.aspect_ratio),
                  tooltip: 'Aspect Ratio',
                  itemBuilder: (_) => _aspectRations(snapshot.data.aspectRatio),
                  onSelected: (value) {
                    _cropController.aspectRatio = value;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<PopupMenuItem<double>> _aspectRations(double aspectRatio) => [
        PopupMenuItem(
          enabled: aspectRatio != _1000x667Ratio,
          value: _1000x667Ratio,
          child: Text('1000 / 667.0'),
        ),
        PopupMenuItem(
          enabled: aspectRatio != _18x9Ratio,
          value: _18x9Ratio,
          child: Text('18 / 9'),
        ),
        PopupMenuItem(
          enabled: aspectRatio != _4x3Ratio,
          value: _4x3Ratio,
          child: Text('4 / 3'),
        ),
      ];

  Future<void> _getImage() async {
    File image;

    try {
      image = await ImagePicker.pickImage(source: ImageSource.gallery);
    } on PlatformException {
      _scaffoldKey.currentState?.showSnackBar(SnackBar(
        content: Text('Not enough rights'),
      ));
      return;
    }

    if (image == null) {
      return;
    }

    setState(() {
      _imageProvider = FileImage(image);
    });
  }
}

const _1000x667Ratio = 1000 / 667.0;
const _18x9Ratio = 18 / 9;
const _4x3Ratio = 4 / 3;
