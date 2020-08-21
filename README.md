# crop
[![pub package](https://img.shields.io/pub/v/crop.svg)](https://pub.dartlang.org/packages/crop)

A Flutter package for cropping any widget, not only images. This package is entirely written in Dart and supports Android, iOS, Web and Desktop. Also, because of being independent from native platform, it does not increase size of your apps output (e.g. apk).

## Supported platforms

* Flutter Android
* Flutter iOS
* Flutter Web (currently there is a blocking bug in flutter itself)
* Flutter Desktop

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
Now in build function, put a `Crop` widget in the widget tree and you are done. Please don't forget to check ```/example``` folder, there is much more.
