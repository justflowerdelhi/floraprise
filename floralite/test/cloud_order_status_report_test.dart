import 'dart:io';

import 'package:floraprise/data/repositories/cloud_order_status_repository.dart';
import 'package:floraprise/models/cloud_order_status_report.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  group('CloudOrderStatusReport Model', () {
    test('fromJson and toJson deserialize and serialize accurately', () {
      final json = {
        'pending': 3,
        'inProgress': 5,
        'ready': 2,
        'completed': 12,
        'cancelled': 1,
        'total': 23,
        'fulfillment': {
          'delivery': 10,
          'pickup': 8,
          'takeAway': 5,
        },
        'fromDate': '2026-09-01T00:00:00.000Z',
        'toDate': '2026-09-08T23:59:59.000Z',
      };

      final report = CloudOrderStatusReport.fromJson(json);

      expect(report.pending, 3);
      expect(report.inProgress, 5);
      expect(report.ready, 2);
      expect(report.completed, 12);
      expect(report.cancelled, 1);
      expect(report.total, 23);
      expect(report.fulfillment.delivery, 10);
      expect(report.fulfillment.pickup, 8);
      expect(report.fulfillment.takeAway, 5);
      expect(report.fromDate, isNotNull);
      expect(report.toDate, isNotNull);

      final encoded = report.toJson();
      expect(encoded['pending'], 3);
      expect(encoded['inProgress'], 5);
      expect(encoded['ready'], 2);
      expect(encoded['completed'], 12);
      expect(encoded['cancelled'], 1);
      expect(encoded['total'], 23);
      expect(encoded['fulfillment']['delivery'], 10);
      expect(encoded['fulfillment']['pickup'], 8);
      expect(encoded['fulfillment']['takeAway'], 5);
    });

    test('handles alternate casing and snake_case keys in fulfillment and status', () {
      final json = {
        'Pending': 2,
        'in_progress': 4,
        'Ready': 1,
        'Completed': 7,
        'Cancelled': 0,
        'totalCount': 14,
        'fulfillment': {
          'delivery': 6,
          'pickup_later': 5,
          'take_away': 3,
        },
      };

      final report = CloudOrderStatusReport.fromJson(json);

      expect(report.pending, 2);
      expect(report.inProgress, 4);
      expect(report.ready, 1);
      expect(report.completed, 7);
      expect(report.cancelled, 0);
      expect(report.total, 14);
      expect(report.fulfillment.delivery, 6);
      expect(report.fulfillment.pickup, 5);
      expect(report.fulfillment.takeAway, 3);
    });

    test('empty report has all zero counts', () {
      const report = CloudOrderStatusReport.empty;
      expect(report.pending, 0);
      expect(report.inProgress, 0);
      expect(report.ready, 0);
      expect(report.completed, 0);
      expect(report.cancelled, 0);
      expect(report.total, 0);
      expect(report.fulfillment.delivery, 0);
      expect(report.fulfillment.pickup, 0);
      expect(report.fulfillment.takeAway, 0);
    });
  });

  group('CloudOrderStatusRepository', () {
    test('returns status and fulfillment counts from endpoint', () async {
      Uri? capturedUri;
      Future<dynamic> fakeSender(Uri uri) async {
        capturedUri = uri;
        return {
          'pending': 4,
          'inProgress': 6,
          'ready': 3,
          'completed': 15,
          'cancelled': 2,
          'total': 30,
          'fulfillment': {
            'delivery': 14,
            'pickup': 10,
            'takeAway': 6,
          },
        };
      }

      final repo = CloudOrderStatusRepository(
        sender: fakeSender,
      );

      final fromDate = DateTime.utc(2026, 9, 1);
      final toDate = DateTime.utc(2026, 9, 8);

      final report = await repo.getOrderStatusReport(
        fromDate: fromDate,
        toDate: toDate,
      );

      expect(capturedUri, isNotNull);
      expect(capturedUri!.path, contains('status-report'));
      expect(capturedUri!.queryParameters['fromDate'], contains('2026-09-01'));
      expect(capturedUri!.queryParameters['toDate'], contains('2026-09-08'));

      expect(report.pending, 4);
      expect(report.inProgress, 6);
      expect(report.ready, 3);
      expect(report.completed, 15);
      expect(report.cancelled, 2);
      expect(report.total, 30);
      expect(report.fulfillment.delivery, 14);
      expect(report.fulfillment.pickup, 10);
      expect(report.fulfillment.takeAway, 6);
    });

    test('handles zero-result case gracefully', () async {
      Future<dynamic> fakeSender(Uri uri) async {
        return {
          'pending': 0,
          'inProgress': 0,
          'ready': 0,
          'completed': 0,
          'cancelled': 0,
          'total': 0,
          'fulfillment': {
            'delivery': 0,
            'pickup': 0,
            'takeAway': 0,
          },
        };
      }

      final repo = CloudOrderStatusRepository(
        sender: fakeSender,
      );

      final report = await repo.getOrderStatusReport();

      expect(report.total, 0);
      expect(report.pending, 0);
      expect(report.inProgress, 0);
      expect(report.ready, 0);
      expect(report.completed, 0);
      expect(report.cancelled, 0);
      expect(report.fulfillment.delivery, 0);
      expect(report.fulfillment.pickup, 0);
      expect(report.fulfillment.takeAway, 0);
    });

    test('offline fallback: returns cached report when network fails', () async {
      var shouldFail = false;

      Future<dynamic> fakeSender(Uri uri) async {
        if (shouldFail) {
          throw const SocketException('No Internet Connection');
        }
        return {
          'pending': 5,
          'inProgress': 2,
          'ready': 1,
          'completed': 8,
          'cancelled': 0,
          'total': 16,
          'fulfillment': {
            'delivery': 7,
            'pickup': 6,
            'takeAway': 3,
          },
        };
      }

      final repo = CloudOrderStatusRepository(
        sender: fakeSender,
      );

      // 1. First call: online success
      final firstReport = await repo.getOrderStatusReport();
      expect(firstReport.total, 16);
      expect(firstReport.pending, 5);
      expect(firstReport.fulfillment.delivery, 7);

      // 2. Second call: network offline -> fallback to cache
      shouldFail = true;
      final fallbackReport = await repo.getOrderStatusReport();
      expect(fallbackReport.total, 16);
      expect(fallbackReport.pending, 5);
      expect(fallbackReport.fulfillment.delivery, 7);
      expect(fallbackReport.fulfillment.pickup, 6);
      expect(fallbackReport.fulfillment.takeAway, 3);
    });
  });
}
