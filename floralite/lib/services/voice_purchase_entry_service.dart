import 'product_matcher.dart';
import 'voice_purchase_parser.dart';

class VoicePurchaseEntryResult {
  const VoicePurchaseEntryResult({required this.parsed, required this.match});

  final VoicePurchaseParsedItem? parsed;
  final ProductMatchResult match;

  bool get isValid => parsed != null && match.type == ProductMatchType.found;
}

class VoicePurchaseEntryService {
  VoicePurchaseEntryService({
    required VoicePurchaseParser parser,
    required ProductMatcher matcher,
  })  : _parser = parser,
        _matcher = matcher;

  final VoicePurchaseParser _parser;
  final ProductMatcher _matcher;

  VoicePurchaseParser get parser => _parser;
  ProductMatcher get matcher => _matcher;

  VoicePurchaseEntryResult process(String words) {
    final parsed = _parser.parse(words);
    if (parsed == null) {
      return const VoicePurchaseEntryResult(
        parsed: null,
        match: ProductMatchResult.notFound(),
      );
    }

    return VoicePurchaseEntryResult(
      parsed: parsed,
      match: _matcher.match(parsed.productName),
    );
  }
}
