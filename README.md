# crop
[![pub package](https://img.shields.io/pub/v/crop.svg)](https://pub.dartlang.org/packages/crop)

A Flutter package for cropping any widget, not only images. This package is entirely written in Dart and supports Android, iOS, Web and Desktop. Also, because of being independent from native platform, it does not increase size of your apps output (e.g. apk).

[![Crop Demo on Google Play](doc/google-play-badge.png)](https://play.google.com/store/apps/details?id=dev.pub.crop.app)

![Demo of Crop](doc/demo1.gif)

## Getting Started

In your `pubspec.yaml` file add:

```dart
dependencies:
  crop: any
```
Then, in your code import:
```dart
import 'package:crop/crop.dart';
```
Now in build function, put a Crop widget in the widget tree:

```dart
import 'package:app/centered_slider_track_shape.dart';
import 'package:flutter/material.dart';
import 'package:crop/crop.dart';

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
  final _cropKey = GlobalKey<CropState>();
  double _rotation = 0;

  void _cropImage() async {
    final cropped = await _cropKey.currentState.crop();
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
      appBar: AppBar(
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
              key: _cropKey,
              child: Image.asset('images/sample.jpg'),
              aspectRatio: 1000 / 667.0,
            ),
          ),
          Row(
            children: <Widget>[
              IconButton(
                icon: Icon(Icons.undo),
                tooltip: 'Undo',
                onPressed: () {
                  _cropKey.currentState.rotation = 0;
                  _cropKey.currentState.scale = 1;
                  _cropKey.currentState.offset = Offset.zero;
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
                    divisions: 91,
                    value: _rotation,
                    min: -45,
                    max: 45,
                    label: '$_rotation°',
                    onChanged: (n) {
                      setState(() {
                        _rotation = n.roundToDouble();
                        _cropKey.currentState.rotation = _rotation;
                      });
                    },
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.aspect_ratio),
                tooltip: 'Aspect Ratio',
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

Please don't forget to check ```/example``` folder, there is much more.
