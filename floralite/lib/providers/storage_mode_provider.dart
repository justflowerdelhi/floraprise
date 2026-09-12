import 'package:flutter/foundation.dart';

import '../models/storage_mode.dart';
import '../services/storage_mode_service.dart';

class StorageModeProvider extends ChangeNotifier {
  StorageModeProvider(this._service);

  final StorageModeService _service;

  StorageMode? _mode;
  bool _loaded = false;

  StorageMode? get selectedMode => kIsWeb ? StorageMode.cloud : _mode;
  StorageMode get effectiveMode => kIsWeb ? StorageMode.cloud : (_mode ?? StorageMode.local);
  bool get isLoaded => _loaded;
  bool get hasSelectedMode => kIsWeb ? true : _mode != null;
  bool get isLocal => kIsWeb ? false : effectiveMode == StorageMode.local;
  bool get isCloud => kIsWeb ? true : effectiveMode == StorageMode.cloud;

  Future<void> load() async {
    _mode = await _service.getCurrentMode();
    _loaded = true;
    notifyListeners();
  }

  Future<void> setMode(StorageMode mode) async {
    await _service.setMode(mode);
    _mode = mode;
    _loaded = true;
    notifyListeners();
  }

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    await load();
  }
}