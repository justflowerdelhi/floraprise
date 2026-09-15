import 'package:flutter_test/flutter_test.dart';
import 'package:floraprise/data/repositories/cloud_ready_bouquet_repository.dart';
import 'package:floraprise/data/repositories/ready_bouquet_repository.dart';
import 'package:floraprise/services/storage_mode_service.dart';

class _MockStorageModeService extends StorageModeService {
  @override
  Future<bool> isCloud() async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('CloudReadyBouquetRepository parses batches, summaries, and history', () async {
    final repository = CloudReadyBouquetRepository(
      sender: (method, uri, {body}) async {
        if (uri.path == '/api/ready-bouquets') {
          if (method == 'GET') {
            return [
              {
                'batch': {
                  'id': 'b101',
                  'finishedProductId': 'p101',
                  'productName': 'Red Rose Bouquet',
                  'unit': 'Piece',
                  'initialQuantity': 10,
                  'remainingQuantity': 8,
                  'shelfLifeDays': 5,
                  'refreshAfterDays': 2,
                  'producedAt': '2026-09-10T10:00:00Z',
                  'lastRefreshAt': '2026-09-12T10:00:00Z',
                  'expiryAt': '2026-09-15T10:00:00Z',
                  'location': 'Store Front',
                  'status': 'fresh',
                },
                'computedStatus': 'fresh',
              },
            ];
          }
          if (method == 'POST') {
            return {
              'id': 'b102',
              'finishedProductId': body['finishedProductId'],
              'initialQuantity': body['initialQuantity'],
              'remainingQuantity': body['initialQuantity'],
              'shelfLifeDays': body['shelfLifeDays'],
              'refreshAfterDays': body['refreshAfterDays'],
              'producedAt': body['producedAt'],
              'expiryAt': body['expiryAt'],
              'location': body['location'],
              'status': 'fresh',
            };
          }
        }
        if (uri.path == '/api/ready-bouquets/b101/history') {
          return [
            {
              'refresh': {
                'id': 'r1',
                'batchId': 'b101',
                'actionType': 'replace',
                'productId': 'c1',
                'quantity': 2,
                'wastageQuantity': 2,
                'createdAtUtc': '2026-09-12T10:00:00Z',
              },
              'productName': 'Baby Breath',
            },
          ];
        }
        if (uri.path == '/api/products') {
          return [
            {'id': 'p101', 'name': 'Red Rose Bouquet'},
          ];
        }
        return null;
      },
    );

    final summaries = await repository.listReadyBouquets();
    expect(summaries.length, 1);
    expect(summaries.first.productName, 'Red Rose Bouquet');
    expect(summaries.first.currentStock, 8);
    expect(summaries.first.status, ReadyBouquetStatus.fresh);

    final history = await repository.listRefreshEvents('b101');
    expect(history.length, 1);
    expect(history.first.productName, 'Baby Breath');
    expect(history.first.actionType, 'replace');
  });

  test('ReadyBouquetRepository delegates to CloudReadyBouquetRepository in cloud mode', () async {
    final cloudRepo = CloudReadyBouquetRepository(
      sender: (method, uri, {body}) async {
        if (uri.path == '/api/ready-bouquets') {
          return [
            {
              'batch': {
                'id': 'b201',
                'finishedProductId': 'p201',
                'productName': 'Lily Delight',
                'unit': 'Piece',
                'initialQuantity': 5,
                'remainingQuantity': 3,
                'shelfLifeDays': 4,
                'refreshAfterDays': 2,
                'producedAt': '2026-09-10T10:00:00Z',
                'expiryAt': '2026-09-14T10:00:00Z',
                'location': 'Front Display',
                'status': 'needs_refresh',
              },
              'computedStatus': 'needs_refresh',
            },
          ];
        }
        return null;
      },
    );

    final repo = ReadyBouquetRepository(
      storageModeService: _MockStorageModeService(),
      cloudRepository: cloudRepo,
    );

    // In web or cloud, it should return from cloud repo without opening SQLite
    final items = await repo.listReadyBouquets();
    expect(items.length, 1);
    expect(items.first.productName, 'Lily Delight');
    expect(items.first.currentStock, 3);
  });
}
