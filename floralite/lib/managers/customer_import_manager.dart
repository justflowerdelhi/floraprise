import 'dart:io';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';

import '../data/repositories/customer_repository.dart';

enum DuplicateHandlingOption {
  updateExisting,
  skipExisting,
}

class CustomerImportRow {
  final int sourceRowNumber;
  final String name;
  final String mobile;
  final String birthdayMd;
  final String anniversaryMd;
  final String company;
  final String department;
  final String notes;
  final CustomerRecord? existing;

  const CustomerImportRow({
    required this.sourceRowNumber,
    required this.name,
    required this.mobile,
    required this.birthdayMd,
    required this.anniversaryMd,
    required this.company,
    required this.department,
    required this.notes,
    required this.existing,
  });
}

class CustomerImportPreview {
  final int totalRows;
  final int readyRows;
  final int skippedRows;
  final int duplicateRows;
  final List<CustomerImportRow> ready;
  final Map<String, int> errorCounts;

  const CustomerImportPreview({
    required this.totalRows,
    required this.readyRows,
    required this.skippedRows,
    required this.duplicateRows,
    required this.ready,
    required this.errorCounts,
  });
}

class CustomerImportResult {
  final int imported;
  final int updated;
  final int skipped;
  final Map<String, int> errorCounts;

  const CustomerImportResult({
    required this.imported,
    required this.updated,
    required this.skipped,
    required this.errorCounts,
  });
}

class CustomerImportManager {
  CustomerImportManager(this._repository);

  final CustomerRepository _repository;

  static const List<String> _requiredTemplateColumns = [
    'name',
    'mobile',
    'birthday',
    'anniversary',
    'company',
    'department',
    'notes',
  ];

  Future<CustomerImportPreview> prepareImport(String filePath) async {
    final rows = await _readRows(filePath);
    if (rows.isEmpty) {
      return const CustomerImportPreview(
        totalRows: 0,
        readyRows: 0,
        skippedRows: 0,
        duplicateRows: 0,
        ready: <CustomerImportRow>[],
        errorCounts: <String, int>{},
      );
    }

    final header = rows.first.map((c) => c.trim().toLowerCase()).toList();
    final headerIndex = <String, int>{};
    for (var i = 0; i < header.length; i++) {
      headerIndex[_normalizeHeader(header[i])] = i;
    }

    final hasMissingRequired = _requiredTemplateColumns
        .map(_normalizeHeader)
        .any((column) => !headerIndex.containsKey(column));
    if (hasMissingRequired) {
      throw const FormatException('Template columns are missing.');
    }

    final totalRows = rows.length - 1;
    final ready = <CustomerImportRow>[];
    final errorCounts = <String, int>{};
    final seenMobiles = <String>{};
    var duplicateRows = 0;

    for (var i = 1; i < rows.length; i++) {
      final sourceRow = rows[i];
      if (_isRowEmpty(sourceRow)) {
        continue;
      }

      final name = _readColumn(sourceRow, headerIndex, 'name').trim();
      final rawMobile = _readColumn(sourceRow, headerIndex, 'mobile').trim();
      final company = _readColumn(sourceRow, headerIndex, 'company').trim();
      final department =
          _readColumn(sourceRow, headerIndex, 'department').trim();
      final notes = _readColumn(sourceRow, headerIndex, 'notes').trim();

      if (name.isEmpty) {
        _inc(errorCounts, 'Missing Name');
        continue;
      }

      final normalizedMobile = _normalizeMobile(rawMobile);
      if (rawMobile.isNotEmpty && normalizedMobile.isEmpty) {
        _inc(errorCounts, 'Invalid Mobile');
        continue;
      }

      if (normalizedMobile.isNotEmpty &&
          seenMobiles.contains(normalizedMobile)) {
        _inc(errorCounts, 'Duplicate Mobile');
        duplicateRows++;
        continue;
      }

      if (normalizedMobile.isNotEmpty) {
        seenMobiles.add(normalizedMobile);
      }

      final birthdayRaw =
          _readColumn(sourceRow, headerIndex, 'birthday').trim();
      final anniversaryRaw =
          _readColumn(sourceRow, headerIndex, 'anniversary').trim();

      final birthdayMd = _normalizeMonthDayOrEmpty(birthdayRaw);
      if (birthdayRaw.isNotEmpty && birthdayMd == null) {
        _inc(errorCounts, 'Invalid Date');
        continue;
      }

      final anniversaryMd = _normalizeMonthDayOrEmpty(anniversaryRaw);
      if (anniversaryRaw.isNotEmpty && anniversaryMd == null) {
        _inc(errorCounts, 'Invalid Date');
        continue;
      }

      CustomerRecord? existing;
      if (normalizedMobile.isNotEmpty) {
        existing = await _repository.findByPhone(normalizedMobile);
        if (existing != null) {
          duplicateRows++;
        }
      }

      ready.add(
        CustomerImportRow(
          sourceRowNumber: i + 1,
          name: name,
          mobile: normalizedMobile,
          birthdayMd: birthdayMd ?? '',
          anniversaryMd: anniversaryMd ?? '',
          company: company,
          department: department,
          notes: notes,
          existing: existing,
        ),
      );
    }

    final skipped = errorCounts.values.fold<int>(0, (a, b) => a + b);
    return CustomerImportPreview(
      totalRows: totalRows,
      readyRows: ready.length,
      skippedRows: skipped,
      duplicateRows: duplicateRows,
      ready: ready,
      errorCounts: errorCounts,
    );
  }

  Future<CustomerImportResult> runImport({
    required List<CustomerImportRow> rows,
    required DuplicateHandlingOption duplicateHandling,
  }) async {
    var imported = 0;
    var updated = 0;
    var skipped = 0;
    final errors = <String, int>{};

    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      try {
        if (row.existing != null) {
          if (duplicateHandling == DuplicateHandlingOption.skipExisting) {
            skipped++;
            continue;
          }

          final current = row.existing!;
          await _repository.update(
            id: current.id,
            phone: current.phone,
            name: row.name,
            birthdayMd:
                row.birthdayMd.isEmpty ? current.birthdayMd : row.birthdayMd,
            anniversaryMd: row.anniversaryMd.isEmpty
                ? current.anniversaryMd
                : row.anniversaryMd,
            company: row.company.isEmpty ? current.company : row.company,
            department:
                row.department.isEmpty ? current.department : row.department,
            notes: row.notes.isEmpty ? current.notes : row.notes,
          );
          updated++;
          continue;
        }

        var phoneToStore = row.mobile;
        if (phoneToStore.isEmpty) {
          phoneToStore = _syntheticPhone(i);
        }

        await _repository.create(
          phone: phoneToStore,
          name: row.name,
          birthdayMd: row.birthdayMd,
          anniversaryMd: row.anniversaryMd,
          company: row.company,
          department: row.department,
          notes: row.notes,
        );
        imported++;
      } catch (_) {
        _inc(errors, 'Duplicate Mobile');
        skipped++;
      }
    }

    return CustomerImportResult(
      imported: imported,
      updated: updated,
      skipped: skipped,
      errorCounts: errors,
    );
  }

  Future<List<List<String>>> _readRows(String filePath) async {
    final extension = filePath.toLowerCase().split('.').last;
    if (extension == 'csv') {
      return _readCsvRows(filePath);
    }
    if (extension == 'xlsx') {
      return _readXlsxRows(filePath);
    }
    return const [];
  }

  Future<List<List<String>>> _readCsvRows(String filePath) async {
    final file = File(filePath);
    final content = await file.readAsString();
    final parsed = const CsvToListConverter(eol: '\n').convert(content);
    return parsed
        .map((row) => row.map((cell) => cell?.toString() ?? '').toList())
        .toList();
  }

  Future<List<List<String>>> _readXlsxRows(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) {
      return const [];
    }

    final firstSheet = excel.tables.keys.first;
    final sheet = excel.tables[firstSheet];
    if (sheet == null) {
      return const [];
    }

    return sheet.rows
        .map((row) => row.map((cell) => cell?.value?.toString() ?? '').toList())
        .toList();
  }

  String _readColumn(List<String> row, Map<String, int> header, String key) {
    final index = header[_normalizeHeader(key)];
    if (index == null || index < 0 || index >= row.length) {
      return '';
    }
    return row[index];
  }

  String _normalizeHeader(String input) {
    return input.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  bool _isRowEmpty(List<String> row) {
    return row.every((cell) => cell.trim().isEmpty);
  }

  String _normalizeMobile(String input) {
    final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return '';
    }
    if (digits.length < 10) {
      return '';
    }
    return digits.substring(digits.length - 10);
  }

  String? _normalizeMonthDayOrEmpty(String raw) {
    final input = raw.trim();
    if (input.isEmpty) {
      return '';
    }

    final alpha = _normalizeAlphaDate(input);
    if (alpha != null) {
      return alpha;
    }

    final numeric = input.replaceAll('/', '-').replaceAll('.', '-');
    final parts = numeric.split('-').where((p) => p.trim().isNotEmpty).toList();

    if (parts.length >= 2) {
      final first = int.tryParse(parts[0]);
      final second = int.tryParse(parts[1]);
      if (first != null && second != null) {
        final day = first;
        final month = second;
        if (_isValidMonthDay(month, day)) {
          return '${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
        }
      }
    }

    return null;
  }

  String? _normalizeAlphaDate(String input) {
    final cleaned = input.toLowerCase().replaceAll(',', ' ').trim();
    final match =
        RegExp(r'^(\d{1,2})\s+([a-z]+)(\s+\d{2,4})?$').firstMatch(cleaned);
    if (match == null) {
      return null;
    }

    final day = int.tryParse(match.group(1) ?? '');
    if (day == null) {
      return null;
    }

    const monthMap = {
      'jan': 1,
      'january': 1,
      'feb': 2,
      'february': 2,
      'mar': 3,
      'march': 3,
      'apr': 4,
      'april': 4,
      'may': 5,
      'jun': 6,
      'june': 6,
      'jul': 7,
      'july': 7,
      'aug': 8,
      'august': 8,
      'sep': 9,
      'sept': 9,
      'september': 9,
      'oct': 10,
      'october': 10,
      'nov': 11,
      'november': 11,
      'dec': 12,
      'december': 12,
    };

    final month = monthMap[match.group(2) ?? ''];
    if (month == null || !_isValidMonthDay(month, day)) {
      return null;
    }

    return '${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
  }

  bool _isValidMonthDay(int month, int day) {
    if (month < 1 || month > 12) return false;
    if (day < 1) return false;

    const dayLimits = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    return day <= dayLimits[month - 1];
  }

  String _syntheticPhone(int index) {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final suffix = index.toString().padLeft(3, '0');
    return 'IMP-$stamp-$suffix';
  }

  void _inc(Map<String, int> map, String key) {
    map[key] = (map[key] ?? 0) + 1;
  }

  static String buildSampleTemplateCsv() {
    const rows = [
      [
        'Name',
        'Mobile',
        'Birthday',
        'Anniversary',
        'Company',
        'Department',
        'Notes'
      ],
      [
        'Priya Sharma',
        '9876543210',
        '15-08',
        '',
        'Bloom Events',
        'Marketing',
        'Prefers pastel bouquets'
      ],
      ['Rahul Singh', '', '15 August', '12/02/2018', '', '', 'Call in morning'],
    ];

    return const ListToCsvConverter().convert(rows);
  }
}
