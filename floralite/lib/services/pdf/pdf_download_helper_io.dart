import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// IO implementation for Android, iOS, Windows, macOS, Linux.
/// Saves to temporary directory and invokes system share_plus sheet.
Future<void> saveOrDownloadPdf({
  required Uint8List bytes,
  required String fileName,
  String? shareTitle,
}) async {
  final tempDir = await getTemporaryDirectory();
  final filePath = '${tempDir.path}/$fileName';
  final file = File(filePath);
  await file.writeAsBytes(bytes, flush: true);

  await Share.shareXFiles(
    [
      XFile(
        filePath,
        mimeType: 'application/pdf',
        name: fileName,
      ),
    ],
    text: shareTitle ?? fileName,
    subject: shareTitle,
  );
}
