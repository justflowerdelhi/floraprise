import 'package:floraprise/services/product_matcher.dart';
import 'package:floraprise/services/voice_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VoiceParser', () {
    final parser = VoiceParser();

    test('parses quantity, multi-word product, and decimal price', () {
      final result = parser.parse('100 white oriental lilies 65.50');

      expect(result, isNotNull);
      expect(result!.quantity, 100);
      expect(result.productName, 'white oriental lilies');
      expect(result.purchasePrice, 65.5);
    });

    test('converts simple spoken number words', () {
      final result = parser.parse('fifty red roses twelve');

      expect(result, isNotNull);
      expect(result!.quantity, 50);
      expect(result.productName, 'red roses');
      expect(result.purchasePrice, 12);
    });

    test('converts compound number words at both boundaries', () {
      final result = parser.parse(
        'one hundred white lilies one hundred twenty',
      );

      expect(result, isNotNull);
      expect(result!.quantity, 100);
      expect(result.productName, 'white lilies');
      expect(result.purchasePrice, 120);
    });

    test('parses connector phrase with at and currency suffix', () {
      final result = parser.parse('50 red roses at 12 rupees');

      expect(result, isNotNull);
      expect(result!.quantity, 50);
      expect(result.productName, 'red roses');
      expect(result.purchasePrice, 12);
    });

    test('parses mixed phrase with price keyword', () {
      final result = parser.parse('75 white lily price 18.5');

      expect(result, isNotNull);
      expect(result!.quantity, 75);
      expect(result.productName, 'white lily');
      expect(result.purchasePrice, 18.5);
    });

    test('rejects missing, zero, and malformed values', () {
      expect(parser.parse('red roses 12'), isNull);
      expect(parser.parse('0 red roses 12'), isNull);
      expect(parser.parse('50 red roses 0'), isNull);
      expect(parser.parse('hello flowers'), isNull);
    });
  });

  group('ProductMatcher', () {
    final matcher = ProductMatcher(const [
      ProductMatchCandidate(id: 1, name: 'Red Rose'),
      ProductMatchCandidate(id: 2, name: 'Dutch Rose'),
      ProductMatchCandidate(id: 3, name: 'Spray Rose'),
      ProductMatchCandidate(id: 4, name: 'White Lily'),
      ProductMatchCandidate(id: 5, name: 'Carnation'),
    ]);

    test('ignores case, plural, and extra spaces for exact matches', () {
      final result = matcher.match('  RED   ROSES ');

      expect(result.type, ProductMatchType.found);
      expect(result.product!.id, 1);
    });

    test('normalizes lilies to lily', () {
      final result = matcher.match('white lilies');

      expect(result.type, ProductMatchType.found);
      expect(result.product!.id, 4);
    });

    test('normalizes common speech drift wide to white', () {
      final result = matcher.match('wide lilies');

      expect(result.type, ProductMatchType.found);
      expect(result.product!.id, 4);
    });

    test('normalizes wait to white', () {
      final result = matcher.match('wait lilies');

      expect(result.type, ProductMatchType.found);
      expect(result.product!.id, 4);
    });

    test('normalizes lilly and lili to lily', () {
      final lillyResult = matcher.match('white lilly');
      final liliResult = matcher.match('white lili');

      expect(lillyResult.type, ProductMatchType.found);
      expect(lillyResult.product!.id, 4);
      expect(liliResult.type, ProductMatchType.found);
      expect(liliResult.product!.id, 4);
    });

    test('returns choices when multiple products contain spoken name', () {
      final result = matcher.match('rose');

      expect(result.type, ProductMatchType.ambiguous);
      expect(result.matches.map((item) => item.id), [1, 2, 3]);
    });

    test('returns not found for an unknown product', () {
      expect(matcher.match('orchid').type, ProductMatchType.notFound);
    });
  });
}
