enum StorageMode {
  local,
  cloud;

  String get storageValue {
    switch (this) {
      case StorageMode.local:
        return 'local';
      case StorageMode.cloud:
        return 'cloud';
    }
  }

  String get label {
    switch (this) {
      case StorageMode.local:
        return 'Local Store';
      case StorageMode.cloud:
        return 'Cloud Store';
    }
  }

  static StorageMode? tryParse(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'local':
        return StorageMode.local;
      case 'cloud':
        return StorageMode.cloud;
      default:
        return null;
    }
  }
}