# crop

A Flutter package for cropping any widget, not only images. This package is entirely written in Dart and supports Android, iOS, Web and Desktop. Also, because of being independent from native platform, it does not increase size of your apps output (e.g. apk).

[![Crop Demo on Google Play](https://play.google.com/intl/en_us/badges/images/badge_new.png)](https://play.google.com/store/apps/details?id=dev.pub.crop.app)

<img alt="Demo of Crop" src="doc/demo1.gif" width="35%" />

## Getting Started

In your flutter project add the dependency:

[![pub package](https://img.shields.io/pub/v/crop.svg)](https://pub.dartlang.org/packages/crop)

```yaml
dependencies:
  crop: any
```

For help getting started with Flutter, view the online [documentation](https://flutter.io/).

## Usage example

Now in build function, put a Crop widget in the widget tree:

```dart
import 'package:app/centered_slider_track_shape.dart';
import 'package:flutter/material.dart';
import 'package:crop/crop.dart';

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
  CropController _cropController;

  @override
  void initState() {
    // Initialize controller
    _cropController = CropController(
      initialValue: CropValue(aspectRatio: 16 / 9),
    );
    super.initState();
  }

  @override
  void dispose() {
    _cropController.dispose();
    super.dispose();
  }

  void _cropImage() async {
    final cropped = await _cropController.crop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('Crop Result'),
            centerTitle: true,
          ),
          body: Center(
            child: RawImage(image: cropped),
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
            // Show image preview
            child: Crop(
              controller: _cropController,
              child: Image.asset('images/sample.jpg'),
            ),
          ),
          Row(
            children: <Widget>[
              IconButton(
                icon: Icon(Icons.undo),
                tooltip: 'Undo',
                // Reset all changes
                onPressed: _cropController.reset,
              ),
              Expanded(
                child: SliderTheme(
                  data: theme.sliderTheme.copyWith(
                    trackShape: CenteredRectangularSliderTrackShape(),
                  ),
                  // Show slider for rotate image
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
            ],
          ),
        ],
      ),
    );
  }
}
```

Please don't forget to check ```/example``` folder, there is much more.
