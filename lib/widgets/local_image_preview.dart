import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Renders a locally-picked [XFile] as an image.
///
/// `Image.file` (backed by `dart:io.File`) asserts and crashes on
/// Flutter Web — `dart:io` file I/O simply isn't implemented there
/// ("Image.file is not supported on Flutter Web"). `XFile.readAsBytes()`
/// works identically on every platform, web included, so this widget
/// reads the picked file's bytes and renders them with `Image.memory`
/// instead, giving the same visual result everywhere.
class LocalImagePreview extends StatelessWidget {
  const LocalImagePreview({
    super.key,
    required this.file,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  final XFile file;
  final BoxFit fit;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: file.readAsBytes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return SizedBox(
            width: width,
            height: height,
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return SizedBox(
            width: width,
            height: height,
            child: const Center(child: Icon(Icons.broken_image_outlined)),
          );
        }
        return Image.memory(
          snapshot.data!,
          fit: fit,
          width: width,
          height: height,
        );
      },
    );
  }
}
