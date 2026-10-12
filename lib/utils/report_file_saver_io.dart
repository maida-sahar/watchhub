// Mobile/desktop implementation: writes the report to a temporary file,
// then hands it to the OS share sheet so the admin can save/send it
// wherever they like (Files app, email, Drive, etc.) — this is the
// standard "download" pattern on platforms with no browser download bar.
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> saveAndShareReportFile({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
}) async {
  final directory = await getTemporaryDirectory();
  final file = File('${directory.path}/$fileName');
  await file.writeAsBytes(bytes);

  await Share.shareXFiles(
    [XFile(file.path, mimeType: mimeType, name: fileName)],
    subject: fileName,
  );
}