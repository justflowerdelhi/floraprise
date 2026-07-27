import 'dart:convert';

export 'printer_device.dart';
export 'printer_settings.dart';

enum PrintJobType {
  posBill,
  deliverySlip,
  messageCard,
  productionSlip,
  bouquetBarcodeLabel,
  expenseReceipt,
  dayCloseReport,
  testPage,
}

enum PrintJobStatus { pending, printing, printed, failed, cancelled }

class PrintQueueJob {
  const PrintQueueJob({
    required this.id,
    required this.type,
    required this.payload,
    required this.status,
    required this.copies,
    required this.retryCount,
    required this.createdAt,
    required this.updatedAt,
    this.lastError,
    this.printedAt,
  });

  final int id;
  final PrintJobType type;
  final Map<String, dynamic> payload;
  final PrintJobStatus status;
  final int copies;
  final int retryCount;
  final String? lastError;
  final String createdAt;
  final String updatedAt;
  final String? printedAt;

  factory PrintQueueJob.fromMap(Map<String, dynamic> map) {
    return PrintQueueJob(
      id: map['id'] as int,
      type: PrintJobType.values.firstWhere(
        (type) => type.name == map['job_type'],
        orElse: () => PrintJobType.testPage,
      ),
      payload:
          jsonDecode(map['payload_json'] as String) as Map<String, dynamic>,
      status: PrintJobStatus.values.firstWhere(
        (status) => status.name == map['status'],
        orElse: () => PrintJobStatus.pending,
      ),
      copies: map['copies'] as int? ?? 1,
      retryCount: map['retry_count'] as int? ?? 0,
      lastError: map['last_error'] as String?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
      printedAt: map['printed_at'] as String?,
    );
  }
}
