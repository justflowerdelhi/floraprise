import 'dart:io';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';

import '../data/repositories/occasion_repository.dart';

enum OccasionDuplicateHandlingOption {
  updateExisting,
  skipExisting,
}

class OccasionImportRow {
  final int sourceRowNumber;
  final String customer;
  final String mobile;
  final String recipient;
  final String relationship;
  final String occasion;
  final DateTime date;
  final String phone;
  final String company;
  final String notes;
  final int? customerId;
  final OccasionContactRecord? existing;

  const OccasionImportRow({
    required this.sourceRowNumber,
    required this.customer,
    required this.mobile,
    required this.recipient,
    required this.relationship,
    required this.occasion,
    required this.date,
    required this.phone,
    required this.company,
    required this.notes,
    required this.customerId,
    required this.existing,
  });
}

class OccasionImportPreview {
  final int totalRows;
  final int readyRows;
  final int skippedRows;
  final int duplicateRows;
  final List<OccasionImportRow> ready;
  final Map<String, int> errorCounts;

  const OccasionImportPreview({
    required this.totalRows,
    required this.readyRows,
    required this.skippedRows,
    required this.duplicateRows,
    required this.ready,
    required this.errorCounts,
  });
}

class OccasionImportResult {
  final int imported;
  final int updated;
  final int skipped;
  final Map<String, int> errorCounts;

  const OccasionImportResult({
    required this.imported,
    required this.updated,
    required this.skipped,
    required this.errorCounts,
  });
}

class OccasionImportManager {
  OccasionImportManager(this._occasionRepository);

  final OccasionRepository _occasionRepository;

  static const List<String> _requiredTemplateColumns = [
    'customer',
    'mobile',
    'recipient',
    'relationship',
    'occasion',
    'date',
    'phone',
    'company',
    'notes',
  ];

  Future<OccasionImportPreview> prepareImport(String filePath) async {
    final rows = await _readRows(filePath);
    if (rows.isEmpty) {
      return const OccasionImportPreview(
        totalRows: 0,
        readyRows: 0,
        skippedRows: 0,
        duplicateRows: 0,
        ready: <OccasionImportRow>[],
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
    final ready = <OccasionImportRow>[];
    final errorCounts = <String, int>{};
    var duplicateRows = 0;

    for (var i = 1; i < rows.length; i++) {
      final sourceRow = rows[i];
      if (_isRowEmpty(sourceRow)) {
        continue;
      }

      final customer = _readColumn(sourceRow, headerIndex, 'customer').trim();
      final mobile = _normalizeMobile(
        _readColumn(sourceRow, headerIndex, 'mobile').trim(),
      );
      final recipient = _readColumn(sourceRow, headerIndex, 'recipient').trim();
      final relationship =
          _readColumn(sourceRow, headerIndex, 'relationship').trim();
      final occasion = _readColumn(sourceRow, headerIndex, 'occasion').trim();
      final dateRaw = _readColumn(sourceRow, headerIndex, 'date').trim();
      final phone =
          _normalizeMobile(_readColumn(sourceRow, headerIndex, 'phone'));
      final company = _readColumn(sourceRow, headerIndex, 'company').trim();
      final notes = _readColumn(sourceRow, headerIndex, 'notes').trim();

      if (customer.isEmpty) {
        _inc(errorCounts, 'Missing Customer');
        continue;
      }
      if (recipient.isEmpty) {
        _inc(errorCounts, 'Missing Recipient');
        continue;
      }
      if (occasion.isEmpty) {
        _inc(errorCounts, 'Missing Occasion');
        continue;
      }
      final parsedDate = _parseDate(dateRaw);
      if (parsedDate == null) {
        _inc(errorCounts, 'Invalid Date');
        continue;
      }

      final customerId = await _occasionRepository.findCustomerIdByNameOrPhone(
        customerName: customer,
        mobile: mobile,
      );
      if (customerId == null) {
        _inc(errorCounts, 'Customer Not Found');
        continue;
      }

      final existing = await _occasionRepository.getDuplicateContact(
        customerId: customerId,
        recipientName: recipient,
        occasion: occasion,
      );
      if (existing != null) {
        duplicateRows++;
      }

      ready.add(
        OccasionImportRow(
          sourceRowNumber: i + 1,
          customer: customer,
          mobile: mobile,
          recipient: recipient,
          relationship: relationship.isEmpty ? 'Other' : relationship,
          occasion: occasion,
          date: parsedDate,
          phone: phone,
          company: company,
          notes: notes,
          customerId: customerId,
          existing: existing,
        ),
      );
    }

    final skipped = errorCounts.values.fold<int>(0, (a, b) => a + b);
    return OccasionImportPreview(
      totalRows: totalRows,
      readyRows: ready.length,
      skippedRows: skipped,
      duplicateRows: duplicateRows,
      ready: ready,
      errorCounts: errorCounts,
    );
  }

  Future<OccasionImportResult> runImport({
    required List<OccasionImportRow> rows,
    required OccasionDuplicateHandlingOption duplicateHandling,
  }) async {
    var imported = 0;
    var updated = 0;
    var skipped = 0;
    final errors = <String, int>{};

    for (final row in rows) {
      try {
        if (row.customerId == null) {
          skipped++;
          _inc(errors, 'Customer Not Found');
          continue;
        }

        if (row.existing != null) {
          if (duplicateHandling ==
              OccasionDuplicateHandlingOption.skipExisting) {
            skipped++;
            continue;
          }

          await _occasionRepository.updateContact(
            id: row.existing!.id,
            customerId: row.customerId!,
            recipientName: row.recipient,
            relationship: row.relationship,
            occasion: row.occasion,
            occasionDate: row.date,
            recipientPhone: row.phone,
            company: row.company,
            notes: row.notes,
            reminderEnabled: true,
            source: 'Excel Import',
          );
          updated++;
          continue;
        }

        await _occasionRepository.createContact(
          customerId: row.customerId!,
          recipientName: row.recipient,
          relationship: row.relationship,
          occasion: row.occasion,
          occasionDate: row.date,
          recipientPhone: row.phone,
          company: row.company,
          notes: row.notes,
          reminderEnabled: true,
          source: 'Excel Import',
        );
        imported++;
      } catch (_) {
        skipped++;
        _inc(errors, 'Duplicate Reminder');
      }
    }

    return OccasionImportResult(
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

  DateTime? _parseDate(String raw) {
    final input = raw.trim();
    if (input.isEmpty) {
      return null;
    }

    final direct = DateTime.tryParse(input);
    if (direct != null) {
      return DateTime(direct.year, direct.month, direct.day);
    }

    final normalized = input.replaceAll('/', '-').replaceAll('.', '-');
    final parts =
        normalized.split('-').where((p) => p.trim().isNotEmpty).toList();
    if (parts.length >= 3) {
      final first = int.tryParse(parts[0]);
      final second = int.tryParse(parts[1]);
      final third = int.tryParse(parts[2]);
      if (first != null && second != null && third != null) {
        final year = first > 31 ? first : third;
        final month = second;
        final day = first > 31 ? third : first;
        if (_isValidDate(year, month, day)) {
          return DateTime(year, month, day);
        }
      }
    }

    final alpha = _parseAlphaDate(input);
    if (alpha != null) {
      return alpha;
    }

    return null;
  }

  DateTime? _parseAlphaDate(String input) {
    final cleaned = input.toLowerCase().replaceAll(',', ' ').trim();
    final match =
        RegExp(r'^(\d{1,2})\s+([a-z]+)(\s+\d{2,4})?$').firstMatch(cleaned);
    if (match == null) {
      return null;
    }

    final day = int.tryParse(match.group(1) ?? '');
    final yearPart = (match.group(3) ?? '').trim();
    final year =
        yearPart.isEmpty ? DateTime.now().year : int.tryParse(yearPart);
    if (day == null || year == null) {
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
    if (month == null || !_isValidDate(year, month, day)) {
      return null;
    }

    return DateTime(year, month, day);
  }

  bool _isValidDate(int year, int month, int day) {
    if (month < 1 || month > 12) return false;
    if (day < 1 || day > 31) return false;
    final candidate = DateTime(year, month, day);
    return candidate.year == year &&
        candidate.month == month &&
        candidate.day == day;
  }

  void _inc(Map<String, int> map, String key) {
    map[key] = (map[key] ?? 0) + 1;
  }

  static String buildSampleTemplateCsv() {
    const rows = [
      [
        'Customer',
        'Mobile',
        'Recipient',
        'Relationship',
        'Occasion',
        'Date',
        'Phone',
        'Company',
        'Notes'
      ],
      [
        'Priya Sharma',
        '9876543210',
        'Aarav Sharma',
        'Son',
        'Birthday',
        '2015-08-15',
        '9876543210',
        'Bloom Events',
        'Prefers morning call'
      ],
      [
        'Rahul Singh',
        '9988776655',
        'Nisha Singh',
        'Wife',
        'Anniversary',
        '2024-12-02',
        '9988776655',
        '',
        'Send premium bouquet suggestion'
      ],
    ];

    return const ListToCsvConverter().convert(rows);
  }
}
