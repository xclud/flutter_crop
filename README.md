
# crop
[![pub package](https://img.shields.io/pub/v/crop.svg)](https://pub.dartlang.org/packages/crop)

A Flutter package for cropping any widget, not only images. This package is entirely written in Dart and supports Android, iOS, Web and Desktop. Also, because of being independent from native platform, it does not increase size of your apps output (e.g. apk).

## Supported platforms
* Flutter Android
* Flutter iOS
* Flutter Web (as of 2020 Nov 24)*
* Flutter Desktop

## Building For Web
In order to run Crop on web, flutter version`1.24.0` or above is needed. Also, you need to set CanvasKit as the renderer with the following command: 
```
flutter build web --web-renderer canvaskit
```

## Demo
[Web Demo](https://xclud.github.io/flutter_crop/) | [Install from Google Play](https://play.google.com/store/apps/details?id=dev.pub.crop.app)

![Screenshot](docs/screenshot01.png)

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
Now in build function, put a `Crop` widget in the widget tree and you are done. Please don't forget to check ```/example``` folder, there is much more.
