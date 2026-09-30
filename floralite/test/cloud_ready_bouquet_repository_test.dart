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

  test('CloudReadyBouquetRepository reads /api/production/finished-goods and maps FinishedGoodsBatchDto', () async {
    final repository = CloudReadyBouquetRepository(
      sender: (method, uri, {body}) async {
        if (uri.path == '/api/production/finished-goods') {
          return [
            {
              'id': 'fg-batch-001',
              'recipeId': 'recipe-001',
              'recipeName': 'Sunflower Bliss',
              'batchCode': 'FG-20260923-001',
              'barcode': '8901234560001',
              'quantityProduced': 5,
              'quantityAvailable': 4,
              'expectedExpiry': '2026-09-26T12:00:00Z',
              'locationName': 'Main Display',
              'status': 'Active',
              'producedAt': '2026-09-23T12:00:00Z',
              'totalCost': 600.0,
            }
          ];
        }
        if (uri.path == '/api/ready-bouquets') {
          return [];
        }
        return null;
      },
    );

    final batches = await repository.listAllBatches();
    expect(batches.length, 1);
    final batch = batches.first;
    expect(batch.cloudId, 'fg-batch-001');
    expect(batch.cloudRecipeId, 'recipe-001');
    expect(batch.productName, 'Sunflower Bliss');
    expect(batch.initialQuantity, 5);
    expect(batch.remainingQuantity, 4);
    expect(batch.status, ReadyBouquetStatus.fresh);
    expect(batch.note, 'FG-20260923-001');

    final summaries = await repository.listReadyBouquets();
    expect(summaries.length, 1);
    expect(summaries.first.productName, 'Sunflower Bliss');
    expect(summaries.first.currentStock, 4);
  });

  test('CloudReadyBouquetRepository.refreshBouquet sends production maintenance payload', () async {
    Map<String, dynamic>? capturedBody;
    Uri? capturedUri;

    final repository = CloudReadyBouquetRepository(
      sender: (method, uri, {body}) async {
        if (uri.path == '/api/production/maintenance') {
          capturedUri = uri;
          capturedBody = body as Map<String, dynamic>?;
          return {'id': 'm-log-1'};
        }
        return null;
      },
    );

    await repository.refreshBouquet(
      batchId: 'fg-batch-001',
      actionType: 'replace',
      productId: 'prod-rose-01',
      quantity: 2,
      reason: 'Wilted stem replacement',
      note: 'Routine morning refresh',
    );

    expect(capturedUri?.path, '/api/production/maintenance');
    expect(capturedBody, isNotNull);
    expect(capturedBody!['finishedBatchId'], 'fg-batch-001');
    expect(capturedBody!['notes'], 'Routine morning refresh');
    final replacements = capturedBody!['replacements'] as List;
    expect(replacements.length, 1);
    expect(replacements[0]['productId'], 'prod-rose-01');
    expect(replacements[0]['productName'], 'Component Replacement');
    expect(replacements[0]['quantityReplaced'], 2);
    expect(replacements[0]['reason'], 'Wilted stem replacement');
  });

  test('CloudReadyBouquetRepository.getBatchConsumptions fetches real RawProductIds from /api/production/finished-goods/{id}', () async {
    final repository = CloudReadyBouquetRepository(
      sender: (method, uri, {body}) async {
        if (uri.path == '/api/production/finished-goods/3fa85f64-5717-4562-b3fc-2c963f66afa6') {
          return {
            'id': '3fa85f64-5717-4562-b3fc-2c963f66afa6',
            'recipeName': 'Rose Bouquet',
            'consumptions': [
              {
                'rawProductId': '8bb1b82c-4999-4d89-a9a3-5ea451296720',
                'productName': 'Red Roses',
                'unit': 'Stems',
                'quantity': 10,
                'unitCost': 15.0,
              },
              {
                'rawProductId': '9cc2c93d-5000-4e90-b0b4-6fb562307831',
                'productName': 'Gypsophila',
                'unit': 'Stems',
                'quantity': 2,
                'unitCost': 20.0,
              },
            ],
          };
        }
        return null;
      },
    );

    final consumptions = await repository.getBatchConsumptions('3fa85f64-5717-4562-b3fc-2c963f66afa6');
    expect(consumptions.length, 2);
    expect(consumptions[0]['rawProductId'], '8bb1b82c-4999-4d89-a9a3-5ea451296720');
    expect(consumptions[0]['productName'], 'Red Roses');
    expect(consumptions[0]['unit'], 'Stems');
    expect(consumptions[0]['quantity'], 10);
  });

  test('ReadyBouquetRepository.getBatchConsumptions maps to ReadyBouquetConsumptionRecord', () async {
    final cloudRepo = CloudReadyBouquetRepository(
      sender: (method, uri, {body}) async {
        if (uri.path == '/api/production/finished-goods/3fa85f64-5717-4562-b3fc-2c963f66afa6') {
          return {
            'id': '3fa85f64-5717-4562-b3fc-2c963f66afa6',
            'recipeName': 'Rose Bouquet',
            'consumptions': [
              {
                'rawProductId': '8bb1b82c-4999-4d89-a9a3-5ea451296720',
                'productName': 'Red Roses',
                'unit': 'Stems',
                'quantity': 10,
              }
            ],
          };
        }
        return null;
      },
    );

    final repo = ReadyBouquetRepository(
      storageModeService: _MockStorageModeService(),
      cloudRepository: cloudRepo,
    );

    final consumptions = await repo.getBatchConsumptions(
      batchId: 1,
      cloudBatchId: '3fa85f64-5717-4562-b3fc-2c963f66afa6',
    );
    expect(consumptions.length, 1);
    expect(consumptions.first.rawProductId, '8bb1b82c-4999-4d89-a9a3-5ea451296720');
    expect(consumptions.first.productName, 'Red Roses');
    expect(consumptions.first.unit, 'Stems');
    expect(consumptions.first.quantity, 10);
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
