import 'package:flutter_test/flutter_test.dart';
import 'package:floraprise/data/repositories/associate_repository.dart';
import 'package:floraprise/data/repositories/cloud_associate_repository.dart';
import 'package:floraprise/data/repositories/order_workflow_repository.dart';
import 'package:floraprise/managers/order_manager.dart';
import 'package:floraprise/managers/order_workflow_manager.dart';
import 'package:floraprise/managers/scheduler_manager.dart';
import 'package:floraprise/providers/order_workflow_provider.dart';

class _FakeOrderManager extends Fake implements OrderManager {}
class _FakeSchedulerManager extends Fake implements SchedulerManager {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Forward to Associate Cloud/Web Tests', () {
    test('OrderWorkflowManager fetches associates from CloudAssociateRepository in cloud mode', () async {
      final cloudRepo = CloudAssociateRepository(
        sender: (method, uri, {body}) async {
          return [
            {
              'id': 'asc-1',
              'associateCode': 'ASC000001',
              'businessName': 'Cloud Florist Partner',
              'phone': '9876543210',
              'city': 'Mumbai',
              'pincode': '400001',
              'types': ['Florist'],
              'isActive': true,
            },
            {
              'id': 'asc-2',
              'associateCode': 'ASC000002',
              'businessName': 'Cloud Decorator Partner',
              'phone': '9876543211',
              'city': 'Delhi',
              'pincode': '110001',
              'types': ['Decorator'],
              'isActive': false,
            }
          ];
        },
      );

      final manager = OrderWorkflowManager(
        orderManager: _FakeOrderManager(),
        workflowRepository: const OrderWorkflowRepository(),
        associateRepository: AssociateRepository(),
        schedulerManager: _FakeSchedulerManager(),
        cloudAssociateRepository: cloudRepo,
      );

      final associates = await manager.getAssignableAssociates(isCloud: true);
      expect(associates.length, equals(1));
      expect(associates.first.businessName, equals('Cloud Florist Partner'));
      expect(associates.first.cloudId, equals('asc-1'));
    });

    test('OrderWorkflowProvider loads cloud associates when cloud mode is active', () async {
      final cloudRepo = CloudAssociateRepository(
        sender: (method, uri, {body}) async {
          return [
            {
              'id': 'asc-10',
              'associateCode': 'ASC000010',
              'businessName': 'Royal Events',
              'phone': '9876543299',
              'city': 'Bangalore',
              'pincode': '560001',
              'types': ['Wedding Planner'],
              'isActive': true,
            }
          ];
        },
      );

      final manager = OrderWorkflowManager(
        orderManager: _FakeOrderManager(),
        workflowRepository: const OrderWorkflowRepository(),
        associateRepository: AssociateRepository(),
        schedulerManager: _FakeSchedulerManager(),
        cloudAssociateRepository: cloudRepo,
      );

      final provider = OrderWorkflowProvider(
        manager,
        cloudAssociateRepository: cloudRepo,
      );

      await provider.loadAssignableAssociates(isCloud: true);
      expect(provider.associates.length, equals(1));
      expect(provider.associates.first.businessName, equals('Royal Events'));
    });
  });
}
