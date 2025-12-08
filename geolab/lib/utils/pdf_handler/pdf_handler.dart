import 'dart:typed_data';

import 'pdf_handler_mobile.dart' if (dart.library.html) 'pdf_handler_web.dart';

class PdfHandler {
  /// Handles the generated PDF bytes.
  /// On Mobile: Saves to temp dir and opens Share sheet.
  /// On Web: Triggers a browser download.
  static Future<void> handlePdf(Uint8List bytes, String fileName) async {
    await handlePdfImpl(bytes, fileName);
  }
}
