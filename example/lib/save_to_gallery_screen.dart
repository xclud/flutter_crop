import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:ui' as ui;

class SaveToGalleryScreen extends StatelessWidget {
  final ui.Image cropped;
  const SaveToGalleryScreen(this.cropped, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crop Result'),
        centerTitle: true,
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.save),
              onPressed: () async {
                final status = await Permission.storage.request();
                if (status != PermissionStatus.granted) return;
                await _saveScreenShot(cropped);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Saved to gallery.'),
                  ),
                );
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
    );
  }
}

Future<dynamic> _saveScreenShot(ui.Image img) async {
  var byteData = await img.toByteData(format: ui.ImageByteFormat.png);
  var buffer = byteData!.buffer.asUint8List();
  final result = await ImageGallerySaver.saveImage(buffer);

  return result;
}
