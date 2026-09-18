import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:floraprise/data/database/app_database.dart';
import 'package:floraprise/models/subscription.dart';
import 'package:floraprise/providers/subscription_provider.dart';
import 'package:floraprise/services/mobile_auth_service.dart';
import 'package:floraprise/services/subscription_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:url_launcher/url_launcher.dart';

class FakeMobileAuthService extends MobileAuthService {
  FakeMobileAuthService({
    this.createOrderResponse,
    this.verifyPaymentResponse,
    this.currentSubscriptionResponse,
  });

  Map<String, dynamic>? createOrderResponse;
  Map<String, dynamic>? verifyPaymentResponse;
  Map<String, dynamic>? currentSubscriptionResponse;

  int createOrderCalls = 0;
  int verifyPaymentCalls = 0;
  int getCurrentSubscriptionCalls = 0;

  Map<String, dynamic>? lastVerifyArgs;

  @override
  Future<Map<String, dynamic>> createSubscriptionOrder(
    dynamic plan, {
    String billingCycle = 'annual',
    int? gateway,
    String? returnUrl,
  }) async {
    createOrderCalls++;
    if (createOrderResponse != null) {
      return createOrderResponse!;
    }
    return {
      'transactionRef': 'tx_ref_paypal_123',
      'gatewayOrderId': 'PAYPAL-ORDER-999',
      'orderId': 'PAYPAL-ORDER-999',
      'amount': 599.0,
      'currency': 'USD',
      'gateway': 3,
      'clientPayload': {
        'gateway': 'paypal',
        'approvalUrl': 'https://www.sandbox.paypal.com/checkoutnow?token=PAYPAL-ORDER-999',
        'amount': 599.0,
        'currency': 'USD',
      },
    };
  }

  @override
  Future<Map<String, dynamic>> verifySubscriptionPayment({
    required String transactionRef,
    required String gatewayOrderId,
    required String paymentId,
    String? signature,
    required String planCode,
    required String billingCycle,
    int? gateway,
  }) async {
    verifyPaymentCalls++;
    lastVerifyArgs = {
      'transactionRef': transactionRef,
      'gatewayOrderId': gatewayOrderId,
      'paymentId': paymentId,
      'signature': signature,
      'planCode': planCode,
      'billingCycle': billingCycle,
      'gateway': gateway,
    };
    if (verifyPaymentResponse != null) {
      return verifyPaymentResponse!;
    }
    return {
      'verified': true,
      'status': 'paid',
      'transactionRef': transactionRef,
      'gatewayOrderId': gatewayOrderId,
    };
  }

  @override
  Future<Map<String, dynamic>> getCurrentSubscription() async {
    getCurrentSubscriptionCalls++;
    if (currentSubscriptionResponse != null) {
      return currentSubscriptionResponse!;
    }
    return {
      'status': 'active',
      'planCode': 'annual',
      'endUtc': DateTime(2027, 7, 1).toIso8601String(),
      'lastPaymentId': 'PAYPAL-ORDER-999',
    };
  }

  @override
  Future<Map<String, dynamic>> getLicenseStatus() async {
    return {
      'allowsAccess': true,
      'licenseStatus': 'active',
      'subscriptionStatus': 'active',
    };
  }

  @override
  Future<Map<String, dynamic>?> readBootstrap() async {
    return {
      'subscription': {
        'status': 'active',
        'planCode': 'annual',
      },
    };
  }

  @override
  Future<List<Map<String, dynamic>>> getSubscriptionPlans() async {
    return [
      {
        'id': 'plan_annual_1',
        'code': 'annual',
        'name': 'Annual Plan',
        'billingCycles': ['annual'],
      },
      {
        'id': 'plan_quarterly_1',
        'code': 'quarterly',
        'name': 'Quarterly Plan',
        'billingCycles': ['quarterly'],
      },
      {
        'id': 'plan_half_yearly_1',
        'code': 'half_yearly',
        'name': 'Half-Yearly Plan',
        'billingCycles': ['half_yearly'],
      },
    ];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  var databaseCounter = 0;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({'mobile_auth_access_token': 'test_token'});
    await AppDatabase.instance.close();
    AppDatabase.testDatabaseName = 'paypal_approval_test_${databaseCounter++}.db';
  });

  tearDown(() async {
    await AppDatabase.instance.close();
    AppDatabase.testDatabaseName = null;
  });

  group('PayPal Checkout Approval Flow', () {
    test('1. PayPal order returns approvalUrl -> URL is launched via urlLauncher', () async {
      Uri? launchedUri;
      LaunchMode? launchedMode;
      final fakeAuth = FakeMobileAuthService();
      final secureStore = MemorySubscriptionSecureStore();

      final client = RazorpaySubscriptionClient(
        mobileAuthService: fakeAuth,
        secureStore: secureStore,
        urlLauncher: (uri, {mode = LaunchMode.platformDefault, webOnlyWindowName}) async {
          launchedUri = uri;
          launchedMode = mode;
          return true;
        },
      );

      final result = await client.startPurchase(SubscriptionPlan.annual);

      expect(result.verified, isFalse);
      expect(launchedUri, isNotNull);
      expect(
        launchedUri.toString(),
        'https://www.sandbox.paypal.com/checkoutnow?token=PAYPAL-ORDER-999',
      );
      expect(launchedMode, LaunchMode.externalApplication);
    });

    test('2. verifySubscriptionPayment is NOT called before approval/return', () async {
      final fakeAuth = FakeMobileAuthService();
      final secureStore = MemorySubscriptionSecureStore();

      final client = RazorpaySubscriptionClient(
        mobileAuthService: fakeAuth,
        secureStore: secureStore,
        urlLauncher: (uri, {mode = LaunchMode.platformDefault, webOnlyWindowName}) async {
          return true;
        },
      );

      await client.startPurchase(SubscriptionPlan.annual);

      // Verify that createOrder was called, but verifySubscriptionPayment was NOT called
      expect(fakeAuth.createOrderCalls, 1);
      expect(fakeAuth.verifyPaymentCalls, 0);
    });

    test('3. successful return/resume -> retryPendingVerification calls verifySubscriptionPayment', () async {
      final fakeAuth = FakeMobileAuthService();
      final secureStore = MemorySubscriptionSecureStore();

      final client = RazorpaySubscriptionClient(
        mobileAuthService: fakeAuth,
        secureStore: secureStore,
        urlLauncher: (uri, {mode = LaunchMode.platformDefault, webOnlyWindowName}) async {
          return true;
        },
      );

      await client.startPurchase(SubscriptionPlan.annual);
      expect(fakeAuth.verifyPaymentCalls, 0);

      // Simulate app return / retry
      final retryResult = await client.retryPendingVerification();

      expect(retryResult.verified, isTrue);
      expect(fakeAuth.verifyPaymentCalls, 1);
      expect(fakeAuth.lastVerifyArgs?['gateway'], 3);
      expect(fakeAuth.lastVerifyArgs?['gatewayOrderId'], 'PAYPAL-ORDER-999');
      expect(fakeAuth.lastVerifyArgs?['transactionRef'], 'tx_ref_paypal_123');
    });

    test('4. user cancels -> no subscription activation', () async {
      final fakeAuth = FakeMobileAuthService(
        verifyPaymentResponse: {
          'verified': false,
          'status': 'unverified',
        },
      );
      final secureStore = MemorySubscriptionSecureStore();

      final client = RazorpaySubscriptionClient(
        mobileAuthService: fakeAuth,
        secureStore: secureStore,
        urlLauncher: (uri, {mode = LaunchMode.platformDefault, webOnlyWindowName}) async {
          return true;
        },
      );

      await client.startPurchase(SubscriptionPlan.annual);
      final retryResult = await client.retryPendingVerification();

      expect(retryResult.verified, isFalse);
    });

    test('5. approval URL missing -> graceful error without crash', () async {
      final fakeAuth = FakeMobileAuthService(
        createOrderResponse: {
          'transactionRef': 'tx_ref_missing_url',
          'gatewayOrderId': 'PAYPAL-ORDER-123',
          'amount': 599.0,
          'currency': 'USD',
          'gateway': 3,
          'clientPayload': {
            'gateway': 'paypal',
            'amount': 599.0,
            'currency': 'USD',
            // approvalUrl is deliberately missing
          },
        },
      );
      final secureStore = MemorySubscriptionSecureStore();
      var launcherCalled = false;

      final client = RazorpaySubscriptionClient(
        mobileAuthService: fakeAuth,
        secureStore: secureStore,
        urlLauncher: (uri, {mode = LaunchMode.platformDefault, webOnlyWindowName}) async {
          launcherCalled = true;
          return true;
        },
      );

      final result = await client.startPurchase(SubscriptionPlan.annual);

      expect(result.verified, isFalse);
      expect(launcherCalled, isFalse);
    });

    test('6. launch failure -> graceful error without crash', () async {
      final fakeAuth = FakeMobileAuthService();
      final secureStore = MemorySubscriptionSecureStore();

      final client = RazorpaySubscriptionClient(
        mobileAuthService: fakeAuth,
        secureStore: secureStore,
        urlLauncher: (uri, {mode = LaunchMode.platformDefault, webOnlyWindowName}) async {
          throw Exception('Unable to open browser');
        },
      );

      final result = await client.startPurchase(SubscriptionPlan.annual);

      expect(result.verified, isFalse);
      expect(fakeAuth.verifyPaymentCalls, 0);
    });

    test('7. app resumes after PayPal -> SubscriptionProvider refreshes state', () async {
      final fakeAuth = FakeMobileAuthService();
      final secureStore = MemorySubscriptionSecureStore();

      final service = SubscriptionService(
        mobileAuthService: fakeAuth,
        secureStore: secureStore,
        urlLauncher: (uri, {mode = LaunchMode.platformDefault, webOnlyWindowName}) async => true,
      );

      final provider = SubscriptionProvider(
        service,
        mobileAuthService: fakeAuth,
      );
      await provider.initialize();

      await provider.startPurchase(SubscriptionPlan.annual);
      expect(fakeAuth.verifyPaymentCalls, 0);

      // Trigger resume / retry
      await provider.retryPendingVerification();

      expect(fakeAuth.verifyPaymentCalls, 1);
      expect(provider.state, SubscriptionState.active);
    });

    test('8. webhook-activated subscription -> Flutter reflects active subscription', () async {
      final fakeAuth = FakeMobileAuthService(
        currentSubscriptionResponse: {
          'status': 'active',
          'planCode': 'annual',
          'endUtc': DateTime(2027, 7, 1).toIso8601String(),
          'lastPaymentId': 'PAYPAL-ORDER-WEBHOOK-999',
        },
      );
      final secureStore = MemorySubscriptionSecureStore();

      final service = SubscriptionService(
        mobileAuthService: fakeAuth,
        secureStore: secureStore,
      );

      final provider = SubscriptionProvider(
        service,
        mobileAuthService: fakeAuth,
      );
      await provider.initialize();

      expect(provider.state, SubscriptionState.active);
    });

    test('9. existing PayU India flow remains unchanged', () async {
      final fakeAuth = FakeMobileAuthService(
        createOrderResponse: {
          'transactionRef': 'tx_ref_payu_123',
          'gatewayOrderId': 'PAYU-ORDER-777',
          'amount': 14999.0,
          'currency': 'INR',
          'gateway': 4,
          'clientPayload': {
            'gateway': 'payu',
            'amount': 14999.0,
            'currency': 'INR',
          },
        },
      );
      final secureStore = MemorySubscriptionSecureStore();

      final client = RazorpaySubscriptionClient(
        mobileAuthService: fakeAuth,
        secureStore: secureStore,
      );

      final result = await client.startPurchase(SubscriptionPlan.annual);

      expect(result.verified, isTrue);
      expect(fakeAuth.verifyPaymentCalls, 1);
      expect(fakeAuth.lastVerifyArgs?['gateway'], 4);
      expect(fakeAuth.lastVerifyArgs?['gatewayOrderId'], 'PAYU-ORDER-777');
    });
  });
}
