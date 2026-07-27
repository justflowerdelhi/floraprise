import 'dart:typed_data';

import '../../models/printer_settings.dart';

enum EscPosAlign { left, center, right }

class EscPosBuilder {
  EscPosBuilder({required this.paperWidth});

  final PrinterPaperWidth paperWidth;
  final List<int> _bytes = <int>[];

  int get charsPerLine => paperWidth == PrinterPaperWidth.mm58 ? 32 : 48;

  void reset() {
    _bytes.addAll(const [0x1B, 0x40]);
  }

  void text(
    String value, {
    EscPosAlign align = EscPosAlign.left,
    bool bold = false,
    bool doubleWidth = false,
    bool doubleHeight = false,
    int? maxChars,
    bool preserveWhitespace = false,
  }) {
    _align(align);
    _bold(bold);
    _size(doubleWidth: doubleWidth, doubleHeight: doubleHeight);
    final lineWidth = maxChars ?? charsPerLine;
    final clean = _clean(value, preserveWhitespace: preserveWhitespace);
    final lines = preserveWhitespace
        ? _wrapPreserved(clean, lineWidth)
        : _wrap(clean, lineWidth);
    for (final line in lines) {
      _write(line);
      newLine();
    }
    _size();
    _bold(false);
    _align(EscPosAlign.left);
  }

  void row(String left, String right, {bool bold = false}) {
    final width = charsPerLine;
    final cleanLeft = _clean(left);
    final cleanRight = _clean(right);
    final rightWidth = cleanRight.length.clamp(0, width ~/ 2);
    final leftWidth = width - rightWidth;
    final leftText = cleanLeft.length > leftWidth
        ? cleanLeft.substring(0, leftWidth)
        : cleanLeft.padRight(leftWidth);
    final rightText = cleanRight.length > rightWidth
        ? cleanRight.substring(0, rightWidth)
        : cleanRight.padLeft(rightWidth);
    text('$leftText$rightText', bold: bold, maxChars: width);
  }

  void columns(List<String> values, List<int> widths, {bool bold = false}) {
    final buffer = StringBuffer();
    for (var i = 0; i < values.length; i++) {
      final width = widths[i];
      final value = _clean(values[i]);
      buffer.write(
        value.length > width
            ? value.substring(0, width)
            : i == 0
                ? value.padRight(width)
                : value.padLeft(width),
      );
    }
    text(buffer.toString(), bold: bold, maxChars: charsPerLine);
  }

  void separator([String char = '-']) {
    text(char * charsPerLine, maxChars: charsPerLine);
  }

  void feed([int lines = 1]) {
    _bytes.addAll([0x1B, 0x64, lines.clamp(0, 8)]);
  }

  void cut() {
    _bytes.addAll(const [0x1D, 0x56, 0x00]);
  }

  void barcode(String value) {
    final clean = _clean(value).replaceAll(RegExp(r'[^A-Za-z0-9 \-.$/+%]'), '');
    if (clean.isEmpty) return;
    _align(EscPosAlign.center);
    _bytes.addAll(const [0x1D, 0x48, 0x02]);
    _bytes.addAll(const [0x1D, 0x68, 0x60]);
    _bytes.addAll(const [0x1D, 0x77, 0x02]);
    final data = _encode('{B$clean');
    _bytes.addAll([0x1D, 0x6B, 0x49, data.length]);
    _bytes.addAll(data);
    newLine();
    _align(EscPosAlign.left);
  }

  void qrCode(String value) {
    final data = _encode(_clean(value));
    if (data.isEmpty) return;
    _align(EscPosAlign.center);
    _bytes.addAll(const [0x1D, 0x28, 0x6B, 0x04, 0x00, 0x31, 0x41, 0x32, 0x00]);
    _bytes.addAll(const [0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x43, 0x06]);
    _bytes.addAll(const [0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x45, 0x31]);
    final storeLength = data.length + 3;
    _bytes.addAll([
      0x1D,
      0x28,
      0x6B,
      storeLength % 256,
      storeLength ~/ 256,
      0x31,
      0x50,
      0x30,
    ]);
    _bytes.addAll(data);
    _bytes.addAll(const [0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x51, 0x30]);
    newLine();
    _align(EscPosAlign.left);
  }

  Uint8List bytes() => Uint8List.fromList(_bytes);

  void newLine() => _bytes.add(0x0A);

  void _align(EscPosAlign align) {
    final value = switch (align) {
      EscPosAlign.left => 0,
      EscPosAlign.center => 1,
      EscPosAlign.right => 2,
    };
    _bytes.addAll([0x1B, 0x61, value]);
  }

  void _bold(bool enabled) {
    _bytes.addAll([0x1B, 0x45, enabled ? 1 : 0]);
  }

  void _size({bool doubleWidth = false, bool doubleHeight = false}) {
    var value = 0;
    if (doubleHeight) value |= 0x10;
    if (doubleWidth) value |= 0x20;
    _bytes.addAll([0x1D, 0x21, value]);
  }

  void _write(String value) {
    _bytes.addAll(_encode(value));
  }

  List<int> _encode(String value) {
    return value.codeUnits
        .map((codeUnit) => codeUnit <= 255 ? codeUnit : 63)
        .toList();
  }

  String _clean(String value, {bool preserveWhitespace = false}) {
    final cleaned = value.replaceAll('₹', 'Rs').replaceAll('\u20b9', 'Rs');
    if (preserveWhitespace) {
      return cleaned.replaceAll(RegExp(r'[\r\n]+'), ' ').trimRight();
    }
    return cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  List<String> _wrapPreserved(String value, int width) {
    if (value.isEmpty) return [''];
    if (value.length <= width) return [value];
    final lines = <String>[];
    for (var index = 0; index < value.length; index += width) {
      lines.add(value.substring(index, (index + width).clamp(0, value.length)));
    }
    return lines;
  }

  List<String> _wrap(String value, int width) {
    if (value.isEmpty) return [''];
    final words = value.split(' ');
    final lines = <String>[];
    var current = '';
    for (final word in words) {
      if (word.length > width) {
        if (current.isNotEmpty) {
          lines.add(current);
          current = '';
        }
        for (var index = 0; index < word.length; index += width) {
          lines.add(
              word.substring(index, (index + width).clamp(0, word.length)));
        }
        continue;
      }
      final candidate = current.isEmpty ? word : '$current $word';
      if (candidate.length > width) {
        lines.add(current);
        current = word;
      } else {
        current = candidate;
      }
    }
    if (current.isNotEmpty) lines.add(current);
    return lines;
  }
}
