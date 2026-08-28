import '../models/storage_mode.dart';

enum MigrationStatus {
  notStarted,
  unavailable,
  inProgress,
  completed,
  failed,
}

class MigrationResult {
  const MigrationResult({
    required this.status,
    required this.message,
  });

  final MigrationStatus status;
  final String message;
}

class StorageMigrationService {
  const StorageMigrationService();

  Future<MigrationResult> previewModeChange({
    required StorageMode from,
    required StorageMode to,
  }) async {
    return const MigrationResult(
      status: MigrationStatus.unavailable,
      message: 'Migration will be available after your data migration is prepared.',
    );
  }
}