import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:floraprise/data/database/app_database.dart';
import 'package:floraprise/data/repositories/customer_repository.dart';
import 'package:floraprise/managers/customer_import_manager.dart';
import 'package:floraprise/managers/customer_manager.dart';
import 'package:floraprise/providers/customer_provider.dart';
import 'package:floraprise/providers/storage_mode_provider.dart';
import 'package:floraprise/services/storage_mode_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await AppDatabase.instance.close();
    AppDatabase.useInMemoryForTests = true;
  });

  tearDown(() async {
    await AppDatabase.instance.close();
    AppDatabase.testDatabaseName = null;
    AppDatabase.useInMemoryForTests = false;
  });

  group('CustomerBulkImport - Normalization & Column Aliases', () {
    test('sample template CSV is generated with correct headers and rows', () {
      final csv = CustomerImportManager.buildSampleTemplateCsv();
      expect(csv, contains('Name'));
      expect(csv, contains('Mobile'));
      expect(csv, contains('Priya Sharma'));
      expect(csv, contains('9876543210'));
    });

    test('parses CSV bytes with standard column names', () async {
      const csvData = '''Name,Mobile,Birthday,Anniversary,Company,Department,Notes
Aarav Patel,9876543210,15-08,,Bloom Flowers,Sales,Prefers roses
Neha Gupta,09876543211,10/05,12/12/2020,Floral World,Design,VIP customer
''';
      final bytes = Uint8List.fromList(utf8.encode(csvData));
      final manager = CustomerImportManager();

      final preview = await manager.prepareImportBytes(
        bytes: bytes,
        fileName: 'customers.csv',
      );

      expect(preview.totalRows, 2);
      expect(preview.readyRows, 2);
      expect(preview.duplicateRows, 0);
      expect(preview.invalidRows, 0);
      expect(preview.items.length, 2);
      expect(preview.items[0].name, 'Aarav Patel');
      expect(preview.items[0].mobile, '9876543210');
      expect(preview.items[0].company, 'Bloom Flowers');
      expect(preview.items[0].department, 'Sales');
      expect(preview.items[0].notes, 'Prefers roses');
      expect(preview.items[0].birthdayMd, '08-15');
      expect(preview.items[1].name, 'Neha Gupta');
      expect(preview.items[1].mobile, '9876543211');
      expect(preview.items[1].status, CustomerImportRowStatus.ready);
    });

    test('parses CSV bytes with varied column alias headers (case-insensitive, spaced, alternate names)', () async {
      const csvData = '''Customer Name, Phone Number ,DOB, Wedding Date , Organization , Dept , Remarks
Vikram Malhotra,+91 91234 56789,20 March,05-11-2015,Malhotra Corp,Operations,Cash on delivery
Ananya Roy,+91-98765-43210,01/01,,Roy Studios,,Weekly order
''';
      final bytes = Uint8List.fromList(utf8.encode(csvData));
      final manager = CustomerImportManager();

      final preview = await manager.prepareImportBytes(
        bytes: bytes,
        fileName: 'clients.csv',
      );

      expect(preview.totalRows, 2);
      expect(preview.readyRows, 2);
      expect(preview.items[0].name, 'Vikram Malhotra');
      expect(preview.items[0].mobile, '9123456789');
      expect(preview.items[0].birthdayMd, '03-20');
      expect(preview.items[0].company, 'Malhotra Corp');
      expect(preview.items[0].notes, 'Cash on delivery');
      expect(preview.items[1].name, 'Ananya Roy');
      expect(preview.items[1].mobile, '9876543210');
    });

    test('parses XLSX bytes correctly', () async {
      final excel = Excel.createExcel();
      final sheetName = excel.tables.keys.first;
      final sheet = excel.tables[sheetName]!;

      sheet.appendRow([
        'Full Name',
        'WhatsApp Number',
        'Company',
        'Notes',
      ]);
      sheet.appendRow([
        'Sunil Kumar',
        '+91 9988776655',
        'SK Enterprises',
        'Large orders',
      ]);
      sheet.appendRow([
        'Kavita Mehta',
        '9876543212',
        'Mehta & Co',
        'Regular buyer',
      ]);

      final bytes = Uint8List.fromList(excel.encode()!);
      final manager = CustomerImportManager();

      final preview = await manager.prepareImportBytes(
        bytes: bytes,
        fileName: 'customers.xlsx',
      );

      expect(preview.totalRows, 2);
      expect(preview.readyRows, 2);
      expect(preview.items[0].name, 'Sunil Kumar');
      expect(preview.items[0].mobile, '9988776655');
      expect(preview.items[0].company, 'SK Enterprises');
      expect(preview.items[1].name, 'Kavita Mehta');
      expect(preview.items[1].mobile, '9876543212');
    });
  });

  group('CustomerBulkImport - Validation & Duplicate Detection', () {
    test('identifies missing names, invalid numbers, duplicate numbers in file, and store duplicates', () async {
      const csvData = '''Name,Phone
Valid User 1,9876543210
,9876543211
Invalid Phone User,12345
Valid User 2,9876543212
Duplicate In File User,9876543210
Existing Store User,9999999999
''';
      final bytes = Uint8List.fromList(utf8.encode(csvData));
      final manager = CustomerImportManager();

      final preview = await manager.prepareImportBytes(
        bytes: bytes,
        fileName: 'data.csv',
        findExistingCustomer: (phone) async {
          if (phone == '9999999999') {
            return {'id': 'cust-123', 'name': 'Old Name', 'phone': '9999999999'};
          }
          return null;
        },
      );

      expect(preview.totalRows, 6);
      expect(preview.readyRows, 2); // Valid User 1, Valid User 2
      expect(preview.duplicateRows, 1); // Existing Store User
      expect(preview.invalidRows, 3); // missing name, invalid phone, duplicate in file
      expect(preview.ready.length, 3); // 2 ready + 1 duplicate eligible for import/update

      expect(preview.items[0].status, CustomerImportRowStatus.ready);
      expect(preview.items[1].status, CustomerImportRowStatus.invalidName);
      expect(preview.items[2].status, CustomerImportRowStatus.invalidPhone);
      expect(preview.items[3].status, CustomerImportRowStatus.ready);
      expect(preview.items[4].status, CustomerImportRowStatus.duplicateInBatch);
      expect(preview.items[5].status, CustomerImportRowStatus.duplicateInStore);
    });

    test('executes runImport with skipExisting option', () async {
      final manager = CustomerImportManager();
      final rows = [
        const CustomerImportRow(
          sourceRowNumber: 1,
          name: 'New Customer 1',
          mobile: '9876543210',
          status: CustomerImportRowStatus.ready,
        ),
        const CustomerImportRow(
          sourceRowNumber: 2,
          name: 'Existing Customer',
          mobile: '9999999999',
          existing: {'id': '101', 'name': 'Old Name'},
          status: CustomerImportRowStatus.duplicateInStore,
        ),
        const CustomerImportRow(
          sourceRowNumber: 3,
          name: 'New Customer 2',
          mobile: '9876543211',
          status: CustomerImportRowStatus.ready,
        ),
      ];

      final created = <Map<String, String>>[];
      final updated = <Map<String, String>>[];

      final result = await manager.runImport(
        rows: rows,
        duplicateHandling: DuplicateHandlingOption.skipExisting,
        createCustomer: ({
          required String phone,
          required String name,
          String birthdayMd = '',
          String anniversaryMd = '',
          String company = '',
          String department = '',
          String notes = '',
        }) async {
          created.add({'phone': phone, 'name': name});
        },
        updateCustomer: ({
          required dynamic existing,
          required String phone,
          required String name,
          String birthdayMd = '',
          String anniversaryMd = '',
          String company = '',
          String department = '',
          String notes = '',
        }) async {
          updated.add({'phone': phone, 'name': name});
        },
      );

      expect(result.imported, 2);
      expect(result.updated, 0);
      expect(result.skipped, 1);
      expect(created.length, 2);
      expect(created[0]['name'], 'New Customer 1');
      expect(created[1]['name'], 'New Customer 2');
      expect(updated.isEmpty, true);
    });

    test('executes runImport with updateExisting option', () async {
      final manager = CustomerImportManager();
      final rows = [
        const CustomerImportRow(
          sourceRowNumber: 1,
          name: 'New Customer 1',
          mobile: '9876543210',
          status: CustomerImportRowStatus.ready,
        ),
        const CustomerImportRow(
          sourceRowNumber: 2,
          name: 'Updated Name',
          mobile: '9999999999',
          existing: {'id': '101', 'name': 'Old Name'},
          status: CustomerImportRowStatus.duplicateInStore,
        ),
      ];

      final created = <Map<String, String>>[];
      final updated = <Map<String, String>>[];

      final result = await manager.runImport(
        rows: rows,
        duplicateHandling: DuplicateHandlingOption.updateExisting,
        createCustomer: ({
          required String phone,
          required String name,
          String birthdayMd = '',
          String anniversaryMd = '',
          String company = '',
          String department = '',
          String notes = '',
        }) async {
          created.add({'phone': phone, 'name': name});
        },
        updateCustomer: ({
          required dynamic existing,
          required String phone,
          required String name,
          String birthdayMd = '',
          String anniversaryMd = '',
          String company = '',
          String department = '',
          String notes = '',
        }) async {
          updated.add({'phone': phone, 'name': name});
        },
      );

      expect(result.imported, 1);
      expect(result.updated, 1);
      expect(result.skipped, 0);
      expect(created.length, 1);
      expect(created[0]['name'], 'New Customer 1');
      expect(updated.length, 1);
      expect(updated[0]['name'], 'Updated Name');
      expect(updated[0]['phone'], '9999999999');
    });
  });

  group('CustomerBulkImport - Device Contacts Parsing', () {
    test('parses device contact list with single and multiple numbers', () async {
      final contacts = [
        const Contact(
          displayName: 'Pooja Verma',
          phones: [
            Phone(number: '+91 98765 43210'),
          ],
        ),
        const Contact(
          displayName: 'Rajesh Khanna',
          phones: [
            Phone(number: '9811122233'),
            Phone(number: '09811122244'),
          ],
        ),
        const Contact(
          displayName: 'No Phone Contact',
          phones: [],
        ),
      ];

      final manager = CustomerImportManager();
      final preview = await manager.prepareImportFromContacts(contacts: contacts);

      expect(preview.readyRows, 3); // Pooja + 2 Rajesh numbers
      expect(preview.invalidRows, 1); // No Phone Contact
      expect(preview.totalRows, 4);
      expect(preview.ready[0].name, 'Pooja Verma');
      expect(preview.ready[0].mobile, '9876543210');
      expect(preview.ready[1].name, 'Rajesh Khanna');
      expect(preview.ready[1].mobile, '9811122233');
      expect(preview.ready[2].name, 'Rajesh Khanna');
      expect(preview.ready[2].mobile, '9811122244');
    });

    test('extracts structured name when displayName is empty', () async {
      final contacts = [
        const Contact(
          displayName: '',
          name: Name(first: 'Rohan', last: 'Sharma'),
          phones: [
            Phone(number: '9876500000'),
          ],
        ),
      ];

      final manager = CustomerImportManager();
      final preview = await manager.prepareImportFromContacts(contacts: contacts);

      expect(preview.readyRows, 1);
      expect(preview.ready[0].name, 'Rohan Sharma');
      expect(preview.ready[0].mobile, '9876500000');
    });
  });

  group('CustomerProvider - Bulk Import Integration', () {
    test('Solo / SQLite mode: imports new customers and updates existing in SQLite', () async {
      final repo = CustomerRepository();
      // Pre-populate one customer in database
      await repo.create(phone: '9876543210', name: 'Original Name');

      final manager = CustomerManager(repo);
      final storageModeProvider = StorageModeProvider(StorageModeService());

      final provider = CustomerProvider(manager, storageModeProvider);
      await provider.loadCustomers();
      expect(provider.customers.length, 1);

      const csvData = '''Name,Mobile,Company,Notes
Original Name Updated,9876543210,Bloom Inc,Updated notes
New Customer 2,9876543211,Flower Shop,New notes
''';
      final bytes = Uint8List.fromList(utf8.encode(csvData));
      final preview = await provider.prepareImportBytes(bytes, 'import.csv');

      expect(preview.totalRows, 2);
      expect(preview.readyRows, 1);
      expect(preview.duplicateRows, 1);

      // Import with updateExisting
      final result = await provider.importCustomers(
        rows: preview.ready,
        duplicateHandling: DuplicateHandlingOption.updateExisting,
      );

      expect(result.imported, 1);
      expect(result.updated, 1);
      expect(result.skipped, 0);

      // Verify records in database
      await provider.loadCustomers();
      expect(provider.customers.length, 2);

      final updatedCust = await repo.findByPhone('9876543210');
      expect(updatedCust?.name, 'Original Name Updated');
      expect(updatedCust?.company, 'Bloom Inc');

      final newCust = await repo.findByPhone('9876543211');
      expect(newCust?.name, 'New Customer 2');
    });
  });
}
