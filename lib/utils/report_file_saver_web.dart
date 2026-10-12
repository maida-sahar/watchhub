// Web implementation: triggers a browser download using an in-memory Blob.
// This file is only compiled when dart:html is available (Flutter Web).
import 'dart:html' as html;
import 'dart:typed_data';

Future<void> saveAndShareReportFile({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
}) async {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}