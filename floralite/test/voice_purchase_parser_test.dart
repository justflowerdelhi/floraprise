import 'package:floraprise/services/product_matcher.dart';
import 'package:floraprise/services/voice_purchase_entry_service.dart';
import 'package:floraprise/services/voice_purchase_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VoicePurchaseParser', () {
    final parser = VoicePurchaseParser();

    test('parses product then quantity', () {
      final result = parser.parse('Red Roses 200');

      expect(result, isNotNull);
      expect(result!.productName, 'red roses');
      expect(result.quantity, 200);
    });

    test('parses quantity then product', () {
      final result = parser.parse('20 White Carnation');

      expect(result, isNotNull);
      expect(result!.productName, 'white carnation');
      expect(result.quantity, 20);
    });

    test('rejects missing quantity or product', () {
      expect(parser.parse('Gypsophila'), isNull);
      expect(parser.parse('0 Gypsophila'), isNull);
      expect(parser.parse('200'), isNull);
    });

    test('extracts quantity from quantity-only phrases', () {
      expect(parser.parseQuantityOnly('200'), 200);
      expect(parser.parseQuantityOnly('quantity 150 please'), 150);
      expect(parser.parseQuantityOnly('0'), isNull);
      expect(parser.parseQuantityOnly('one hundred'), isNull);
    });
  });

  group('VoicePurchaseEntryService', () {
    final service = VoicePurchaseEntryService(
      parser: VoicePurchaseParser(),
      matcher: ProductMatcher(const [
        ProductMatchCandidate(id: 1, name: 'Red Rose'),
        ProductMatchCandidate(id: 2, name: 'Dutch Rose'),
        ProductMatchCandidate(id: 3, name: 'Spray Rose'),
        ProductMatchCandidate(id: 4, name: 'White Carnation'),
      ]),
    );

    test('returns found item for singular/plural/case-insensitive product', () {
      final result = service.process('RED ROSES 200');

      expect(result.parsed, isNotNull);
      expect(result.parsed!.quantity, 200);
      expect(result.match.type, ProductMatchType.found);
      expect(result.match.product!.id, 1);
    });

    test('returns ambiguous for generic product name', () {
      final result = service.process('rose 10');

      expect(result.parsed, isNotNull);
      expect(result.match.type, ProductMatchType.ambiguous);
      expect(result.match.matches.length, 3);
    });

    test('returns not found when parser cannot read quantity', () {
      final result = service.process('white carnation');

      expect(result.parsed, isNull);
      expect(result.match.type, ProductMatchType.notFound);
    });
  });
}
