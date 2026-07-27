import 'product_matcher.dart';
import 'voice_parser.dart';

class VoiceStockEntryResult {
  const VoiceStockEntryResult({required this.parsed, required this.match});

  final VoiceParsedItem? parsed;
  final ProductMatchResult match;

  bool get isValid => parsed != null && match.type == ProductMatchType.found;
}

class VoiceStockEntryService {
  VoiceStockEntryService({
    required VoiceParser parser,
    required ProductMatcher matcher,
  })  : _parser = parser,
        _matcher = matcher;

  final VoiceParser _parser;
  final ProductMatcher _matcher;

  VoiceStockEntryResult process(String words) {
    final parsed = _parser.parse(words);
    if (parsed == null) {
      return const VoiceStockEntryResult(
        parsed: null,
        match: ProductMatchResult.notFound(),
      );
    }
    return VoiceStockEntryResult(
      parsed: parsed,
      match: _matcher.match(parsed.productName),
    );
  }
}
