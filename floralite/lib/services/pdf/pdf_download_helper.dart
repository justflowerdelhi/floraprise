import 'dart:typed_data';

import 'pdf_download_helper_stub.dart'
    if (dart.library.html) 'pdf_download_helper_web.dart'
    if (dart.library.io) 'pdf_download_helper_io.dart' as impl;

/// Cross-platform PDF download and sharing helper.
///
/// On Web: Triggers browser blob download.
/// On Mobile / Desktop: Writes to temporary storage and invokes system sharing.
Future<void> saveOrDownloadPdf({
  required Uint8List bytes,
  required String fileName,
  String? shareTitle,
}) =>
    impl.saveOrDownloadPdf(
      bytes: bytes,
      fileName: fileName,
      shareTitle: shareTitle,
    );
