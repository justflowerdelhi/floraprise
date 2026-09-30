import 'package:shared_preferences/shared_preferences.dart';
import '../data/repositories/associate_repository.dart';

class AssociateTypeService {
  AssociateTypeService({SharedPreferences? preferences})
      : _preferences = preferences;

  SharedPreferences? _preferences;

  static const String _customTypesKey = 'custom_associate_types';

  static final List<String> defaultTypes = AssociateTypeExtension.allTypes
      .map((t) => t.displayName)
      .toList(growable: false);

  Future<SharedPreferences> get _prefs async =>
      _preferences ??= await SharedPreferences.getInstance();

  Future<List<String>> getTypes() async {
    final prefs = await _prefs;
    final stored = prefs.getStringList(_customTypesKey) ?? const <String>[];
    final result = <String>[...defaultTypes];
    for (final custom in stored) {
      final trimmed = custom.trim();
      if (trimmed.isEmpty) continue;
      if (!result.any((t) => t.toLowerCase() == trimmed.toLowerCase())) {
        result.add(trimmed);
      }
    }
    return result;
  }

  bool isDuplicate(String name, List<String> existingTypes) {
    final trimmed = name.trim().toLowerCase();
    if (trimmed.isEmpty) return false;
    return existingTypes.any((t) => t.trim().toLowerCase() == trimmed);
  }

  Future<bool> addCustomType(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;

    final currentTypes = await getTypes();
    if (isDuplicate(trimmed, currentTypes)) {
      return false;
    }

    final prefs = await _prefs;
    final stored =
        List<String>.from(prefs.getStringList(_customTypesKey) ?? <String>[]);
    stored.add(trimmed);
    return await prefs.setStringList(_customTypesKey, stored);
  }
}
