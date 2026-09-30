import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:floraprise/services/associate_type_service.dart';
import 'package:floraprise/data/repositories/associate_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AssociateTypeService Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('getTypes includes default types', () async {
      final service = AssociateTypeService();
      final types = await service.getTypes();
      expect(types, contains('Florist'));
      expect(types, contains('Supplier'));
      expect(types, contains('Wedding Planner'));
      expect(types, contains('Hotel'));
    });

    test('addCustomType adds and persists a new type', () async {
      final service = AssociateTypeService();
      final added = await service.addCustomType('Event Decorator');
      expect(added, isTrue);

      final types = await service.getTypes();
      expect(types, contains('Event Decorator'));

      // Case-insensitive duplicate check
      final isDup = service.isDuplicate('event decorator', types);
      expect(isDup, isTrue);

      final addedDuplicate = await service.addCustomType('event decorator');
      expect(addedDuplicate, isFalse);
    });

    test('isDuplicate detects default types case-insensitively', () async {
      final service = AssociateTypeService();
      final types = await service.getTypes();

      expect(service.isDuplicate('florist', types), isTrue);
      expect(service.isDuplicate('FLORIST', types), isTrue);
      expect(service.isDuplicate('Supplier', types), isTrue);
      expect(service.isDuplicate('Unique New Partner', types), isFalse);
    });

    test('AssociateRecord and AssociateUpsertInput support rawTypes', () {
      const input = AssociateUpsertInput(
        businessName: 'Grand Decor',
        phone: '9876543210',
        city: 'Delhi',
        pincode: '110001',
        rawTypes: ['Event Decorator', 'Wholesaler'],
      );

      expect(input.rawTypes, equals(['Event Decorator', 'Wholesaler']));

      final record = AssociateRecord(
        id: 1,
        associateCode: 'ASC000001',
        businessName: 'Grand Decor',
        phone: '9876543210',
        city: 'Delhi',
        pincode: '110001',
        rawTypes: ['Event Decorator', 'Wholesaler'],
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );

      expect(record.typesDisplay, equals('Event Decorator, Wholesaler'));
      expect(record.typesStorage, equals('Event Decorator,Wholesaler'));
    });
  });
}
