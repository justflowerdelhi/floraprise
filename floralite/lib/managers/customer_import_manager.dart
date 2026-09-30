import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../data/repositories/customer_repository.dart';
import '../services/contact_picker_service.dart';

enum DuplicateHandlingOption {
  updateExisting,
  skipExisting,
}

enum CustomerImportRowStatus {
  ready,
  duplicateInStore,
  duplicateInBatch,
  invalidPhone,
  invalidName,
}

class CustomerImportRow {
  final int sourceRowNumber;
  final String name;
  final String mobile;
  final String rawMobile;
  final String birthdayMd;
  final String anniversaryMd;
  final String company;
  final String department;
  final String notes;
  final dynamic existing;
  final CustomerImportRowStatus status;
  final String? statusMessage;

  const CustomerImportRow({
    required this.sourceRowNumber,
    required this.name,
    required this.mobile,
    this.rawMobile = '',
    this.birthdayMd = '',
    this.anniversaryMd = '',
    this.company = '',
    this.department = '',
    this.notes = '',
    this.existing,
    this.status = CustomerImportRowStatus.ready,
    this.statusMessage,
  });

  bool get isReady => status == CustomerImportRowStatus.ready;
  bool get isDuplicateInStore => status == CustomerImportRowStatus.duplicateInStore;
  bool get isDuplicateInBatch => status == CustomerImportRowStatus.duplicateInBatch;
  bool get isInvalidPhone => status == CustomerImportRowStatus.invalidPhone;
  bool get isInvalidName => status == CustomerImportRowStatus.invalidName;
  bool get isEligible => isReady || isDuplicateInStore;
}

class CustomerImportPreview {
  final int totalRows;
  final int readyRows;
  final int skippedRows;
  final int duplicateRows;
  final int invalidRows;
  final List<CustomerImportRow> items;
  final List<CustomerImportRow> ready;
  final Map<String, int> errorCounts;

  const CustomerImportPreview({
    required this.totalRows,
    required this.readyRows,
    required this.skippedRows,
    required this.duplicateRows,
    this.invalidRows = 0,
    this.items = const <CustomerImportRow>[],
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

typedef CustomerLookupFunction = Future<dynamic> Function(String phone);

class CustomerImportManager {
  CustomerImportManager([this._repository]);

  final CustomerRepository? _repository;

  static const Map<String, List<String>> _columnAliases = {
    'name': [
      'name',
      'customername',
      'customer',
      'fullname',
      'clientname',
      'contactname',
      'partyname',
      'person',
      'client',
    ],
    'mobile': [
      'mobile',
      'mobilenumber',
      'phone',
      'phonenumber',
      'contact',
      'cell',
      'cellnumber',
      'whatsapp',
      'whatsappnumber',
      'phoneno',
      'mobileno',
      'contactno',
      'tel',
      'telephonenumber',
      'telephone',
    ],
    'birthday': [
      'birthday',
      'dob',
      'dateofbirth',
      'birthdate',
      'bday',
    ],
    'anniversary': [
      'anniversary',
      'anniversarydate',
      'marriageanniversary',
      'weddingdate',
    ],
    'company': [
      'company',
      'companyname',
      'organization',
      'org',
      'business',
      'firm',
    ],
    'department': [
      'department',
      'dept',
    ],
    'notes': [
      'notes',
      'note',
      'remarks',
      'remark',
      'comments',
      'comment',
      'address',
      'description',
    ],
  };

  /// Parses file bytes directly (works cross-platform including Web).
  Future<CustomerImportPreview> prepareImportBytes({
    required Uint8List bytes,
    required String fileName,
    CustomerLookupFunction? findExistingCustomer,
  }) async {
    final extension = fileName.toLowerCase().split('.').last;
    List<List<String>> rows = [];

    if (extension == 'csv') {
      final text = utf8.decode(bytes, allowMalformed: true);
      final normalized = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
      final parsed = const CsvToListConverter(eol: '\n').convert(normalized);
      rows = parsed
          .map((row) => row.map((cell) => cell?.toString() ?? '').toList())
          .toList();
    } else if (extension == 'xlsx') {
      final excel = Excel.decodeBytes(bytes);
      if (excel.tables.isNotEmpty) {
        final firstSheet = excel.tables.keys.first;
        final sheet = excel.tables[firstSheet];
        if (sheet != null && sheet.rows.isNotEmpty) {
          rows = sheet.rows
              .map((row) =>
                  row.map((cell) => cell?.value?.toString() ?? '').toList())
              .toList();
        }
      }
    } else {
      throw const FormatException('Unsupported file format. Please upload .xlsx or .csv.');
    }

    return prepareImportFromRows(
      rows: rows,
      findExistingCustomer: findExistingCustomer,
    );
  }

  /// Parses rows of text strings from CSV / Excel.
  Future<CustomerImportPreview> prepareImportFromRows({
    required List<List<String>> rows,
    CustomerLookupFunction? findExistingCustomer,
  }) async {
    if (rows.isEmpty) {
      return const CustomerImportPreview(
        totalRows: 0,
        readyRows: 0,
        skippedRows: 0,
        duplicateRows: 0,
        items: [],
        ready: [],
        errorCounts: {},
      );
    }

    // Skip any leading completely empty rows
    final nonEmptyRows = rows.where((r) => !_isRowEmpty(r)).toList();
    if (nonEmptyRows.isEmpty) {
      return const CustomerImportPreview(
        totalRows: 0,
        readyRows: 0,
        skippedRows: 0,
        duplicateRows: 0,
        items: [],
        ready: [],
        errorCounts: {},
      );
    }

    final headerRow = nonEmptyRows.first;
    final headerIndex = <String, int>{};

    for (var i = 0; i < headerRow.length; i++) {
      final normalized = _normalizeHeader(headerRow[i]);
      for (final entry in _columnAliases.entries) {
        if (entry.value.contains(normalized)) {
          headerIndex.putIfAbsent(entry.key, () => i);
          break;
        }
      }
    }

    var startRowIndex = 1;
    // Fallback: If header matching did not find Name and Mobile, check if row 0 was actually data without header
    if (!headerIndex.containsKey('name') || !headerIndex.containsKey('mobile')) {
      if (headerRow.length >= 2) {
        final col0Digits = _normalizeMobile(headerRow[0]);
        final col1Digits = _normalizeMobile(headerRow[1]);
        if (col1Digits.length == 10) {
          headerIndex['name'] = 0;
          headerIndex['mobile'] = 1;
          startRowIndex = 0;
        } else if (col0Digits.length == 10) {
          headerIndex['mobile'] = 0;
          headerIndex['name'] = 1;
          startRowIndex = 0;
        } else {
          throw const FormatException(
            'Missing required columns: File must have "Name" and "Phone/Mobile" columns.',
          );
        }
      } else {
        throw const FormatException(
          'Missing required columns: File must have "Name" and "Phone/Mobile" columns.',
        );
      }
    }

    final items = <CustomerImportRow>[];
    final ready = <CustomerImportRow>[];
    final errorCounts = <String, int>{};
    final seenMobiles = <String>{};
    var duplicateRows = 0;
    var invalidRows = 0;
    var readyRows = 0;

    for (var i = startRowIndex; i < nonEmptyRows.length; i++) {
      final sourceRow = nonEmptyRows[i];
      if (_isRowEmpty(sourceRow)) {
        continue;
      }

      final rowNum = i + 1;
      final name = _readColumn(sourceRow, headerIndex, 'name').trim();
      final rawMobile = _readColumn(sourceRow, headerIndex, 'mobile').trim();
      final company = _readColumn(sourceRow, headerIndex, 'company').trim();
      final department = _readColumn(sourceRow, headerIndex, 'department').trim();
      final notes = _readColumn(sourceRow, headerIndex, 'notes').trim();

      if (name.isEmpty) {
        _inc(errorCounts, 'Missing Name');
        invalidRows++;
        items.add(
          CustomerImportRow(
            sourceRowNumber: rowNum,
            name: '',
            mobile: '',
            rawMobile: rawMobile,
            status: CustomerImportRowStatus.invalidName,
            statusMessage: 'Missing Name',
          ),
        );
        continue;
      }

      final normalizedMobile = _normalizeMobile(rawMobile);
      if (normalizedMobile.length < 10) {
        _inc(errorCounts, 'Invalid Mobile');
        invalidRows++;
        items.add(
          CustomerImportRow(
            sourceRowNumber: rowNum,
            name: name,
            mobile: normalizedMobile,
            rawMobile: rawMobile,
            status: CustomerImportRowStatus.invalidPhone,
            statusMessage: 'Invalid phone number',
          ),
        );
        continue;
      }

      if (seenMobiles.contains(normalizedMobile)) {
        _inc(errorCounts, 'Duplicate Mobile in File');
        invalidRows++;
        items.add(
          CustomerImportRow(
            sourceRowNumber: rowNum,
            name: name,
            mobile: normalizedMobile,
            rawMobile: rawMobile,
            status: CustomerImportRowStatus.duplicateInBatch,
            statusMessage: 'Duplicate in file',
          ),
        );
        continue;
      }

      seenMobiles.add(normalizedMobile);

      final birthdayRaw = _readColumn(sourceRow, headerIndex, 'birthday').trim();
      final anniversaryRaw = _readColumn(sourceRow, headerIndex, 'anniversary').trim();
      final birthdayMd = _normalizeMonthDayOrEmpty(birthdayRaw) ?? '';
      final anniversaryMd = _normalizeMonthDayOrEmpty(anniversaryRaw) ?? '';

      dynamic existing;
      if (findExistingCustomer != null) {
        existing = await findExistingCustomer(normalizedMobile);
      } else if (_repository != null) {
        existing = await _repository!.findByPhone(normalizedMobile);
      }

      CustomerImportRowStatus status = CustomerImportRowStatus.ready;
      String? statusMessage;

      if (existing != null) {
        status = CustomerImportRowStatus.duplicateInStore;
        statusMessage = 'Existing customer';
        duplicateRows++;
      } else {
        readyRows++;
      }

      final rowItem = CustomerImportRow(
        sourceRowNumber: rowNum,
        name: name,
        mobile: normalizedMobile,
        rawMobile: rawMobile,
        birthdayMd: birthdayMd,
        anniversaryMd: anniversaryMd,
        company: company,
        department: department,
        notes: notes,
        existing: existing,
        status: status,
        statusMessage: statusMessage,
      );

      items.add(rowItem);
      ready.add(rowItem);
    }

    final totalDataRows = nonEmptyRows.length - startRowIndex;
    final skipped = invalidRows;

    return CustomerImportPreview(
      totalRows: totalDataRows,
      readyRows: readyRows,
      skippedRows: skipped,
      duplicateRows: duplicateRows,
      invalidRows: invalidRows,
      items: items,
      ready: ready,
      errorCounts: errorCounts,
    );
  }

  /// Parses contacts list (from device contacts).
  Future<CustomerImportPreview> prepareImportFromContacts({
    required List<dynamic> contacts,
    CustomerLookupFunction? findExistingCustomer,
  }) async {
    final items = <CustomerImportRow>[];
    final ready = <CustomerImportRow>[];
    final errorCounts = <String, int>{};
    final seenMobiles = <String>{};
    var duplicateRows = 0;
    var invalidRows = 0;
    var readyRows = 0;
    var rowNum = 0;

    for (final contact in contacts) {
      rowNum++;
      String name = '';
      List<String> rawPhones = [];

      if (contact is Contact) {
        name = contact.displayName?.trim() ?? '';
        if (name.isEmpty) {
          final first = contact.name?.first ?? '';
          final last = contact.name?.last ?? '';
          name = '$first $last'.trim();
        }
        rawPhones = contact.phones.map((p) => p.number).toList();
      } else if (contact is Map) {
        name = (contact['name'] ?? contact['displayName'] ?? '').toString().trim();
        final p = contact['phones'] ?? contact['phone'] ?? contact['mobile'];
        if (p is List) {
          rawPhones = p.map((e) => e.toString()).toList();
        } else if (p != null) {
          rawPhones = [p.toString()];
        }
      }

      if (name.isEmpty) {
        _inc(errorCounts, 'Missing Name');
        invalidRows++;
        items.add(
          CustomerImportRow(
            sourceRowNumber: rowNum,
            name: '',
            mobile: '',
            status: CustomerImportRowStatus.invalidName,
            statusMessage: 'Missing Name',
          ),
        );
        continue;
      }

      // Filter and normalize valid phone numbers from contact
      final validMobiles = <String>{};
      for (final raw in rawPhones) {
        final normalized = _normalizeMobile(raw);
        if (normalized.length == 10) {
          validMobiles.add(normalized);
        }
      }

      if (validMobiles.isEmpty) {
        _inc(errorCounts, 'No Valid Mobile');
        invalidRows++;
        items.add(
          CustomerImportRow(
            sourceRowNumber: rowNum,
            name: name,
            mobile: '',
            rawMobile: rawPhones.isNotEmpty ? rawPhones.first : '',
            status: CustomerImportRowStatus.invalidPhone,
            statusMessage: 'No valid 10-digit mobile',
          ),
        );
        continue;
      }

      // Create a row for each distinct valid number of this contact
      for (final mobile in validMobiles) {
        if (seenMobiles.contains(mobile)) {
          _inc(errorCounts, 'Duplicate Mobile in Batch');
          invalidRows++;
          items.add(
            CustomerImportRow(
              sourceRowNumber: rowNum,
              name: name,
              mobile: mobile,
              status: CustomerImportRowStatus.duplicateInBatch,
              statusMessage: 'Duplicate number in batch',
            ),
          );
          continue;
        }

        seenMobiles.add(mobile);

        dynamic existing;
        if (findExistingCustomer != null) {
          existing = await findExistingCustomer(mobile);
        } else if (_repository != null) {
          existing = await _repository!.findByPhone(mobile);
        }

        CustomerImportRowStatus status = CustomerImportRowStatus.ready;
        String? statusMessage;

        if (existing != null) {
          status = CustomerImportRowStatus.duplicateInStore;
          statusMessage = 'Existing customer';
          duplicateRows++;
        } else {
          readyRows++;
        }

        final rowItem = CustomerImportRow(
          sourceRowNumber: rowNum,
          name: name,
          mobile: mobile,
          existing: existing,
          status: status,
          statusMessage: statusMessage,
        );

        items.add(rowItem);
        ready.add(rowItem);
      }
    }

    return CustomerImportPreview(
      totalRows: items.length,
      readyRows: readyRows,
      skippedRows: invalidRows,
      duplicateRows: duplicateRows,
      invalidRows: invalidRows,
      items: items,
      ready: ready,
      errorCounts: errorCounts,
    );
  }

  /// Legacy file-path import preparation.
  Future<CustomerImportPreview> prepareImport(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    final fileName = filePath.split(Platform.pathSeparator).last;
    return prepareImportBytes(
      bytes: bytes,
      fileName: fileName,
      findExistingCustomer: _repository != null
          ? (phone) => _repository!.findByPhone(phone)
          : null,
    );
  }

  /// Executes the import with customizable create/update handlers.
  Future<CustomerImportResult> runImport({
    required List<CustomerImportRow> rows,
    required DuplicateHandlingOption duplicateHandling,
    Future<void> Function({
      required String phone,
      required String name,
      String birthdayMd,
      String anniversaryMd,
      String company,
      String department,
      String notes,
    })? createCustomer,
    Future<void> Function({
      required dynamic existing,
      required String phone,
      required String name,
      String birthdayMd,
      String anniversaryMd,
      String company,
      String department,
      String notes,
    })? updateCustomer,
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

          if (updateCustomer != null) {
            await updateCustomer(
              existing: row.existing,
              phone: row.mobile,
              name: row.name,
              birthdayMd: row.birthdayMd,
              anniversaryMd: row.anniversaryMd,
              company: row.company,
              department: row.department,
              notes: row.notes,
            );
          } else if (_repository != null && row.existing is CustomerRecord) {
            final current = row.existing as CustomerRecord;
            await _repository!.update(
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
          }
          updated++;
          continue;
        }

        if (createCustomer != null) {
          await createCustomer(
            phone: row.mobile,
            name: row.name,
            birthdayMd: row.birthdayMd,
            anniversaryMd: row.anniversaryMd,
            company: row.company,
            department: row.department,
            notes: row.notes,
          );
        } else if (_repository != null) {
          await _repository!.create(
            phone: row.mobile,
            name: row.name,
            birthdayMd: row.birthdayMd,
            anniversaryMd: row.anniversaryMd,
            company: row.company,
            department: row.department,
            notes: row.notes,
          );
        }
        imported++;
      } catch (e) {
        _inc(errors, 'Failed: $e');
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

  String _readColumn(List<String> row, Map<String, int> header, String key) {
    final index = header[key];
    if (index == null || index < 0 || index >= row.length) {
      return '';
    }
    return row[index];
  }

  static String _normalizeHeader(String input) {
    return input.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  static bool _isRowEmpty(List<String> row) {
    return row.every((cell) => cell.trim().isEmpty);
  }

  static String _normalizeMobile(String input) {
    return ContactPickerService.normalizeMobile(input);
  }

  static String? _normalizeMonthDayOrEmpty(String raw) {
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

  static String? _normalizeAlphaDate(String input) {
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

  static bool _isValidMonthDay(int month, int day) {
    if (month < 1 || month > 12) return false;
    if (day < 1) return false;

    const dayLimits = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    return day <= dayLimits[month - 1];
  }

  static void _inc(Map<String, int> map, String key) {
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
      ['Rahul Singh', '9812345678', '15 August', '12/02/2018', '', '', 'Call in morning'],
    ];

    return const ListToCsvConverter().convert(rows);
  }
}
