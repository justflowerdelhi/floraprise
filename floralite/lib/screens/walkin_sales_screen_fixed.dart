import 'package:flutter/material.dart';
import '../data/repositories/order_repository.dart';
import '../l10n/app_localizations.dart';
import '../widgets/app_header.dart';
import '../widgets/common_widgets.dart';
import 'take_away_screen.dart';
import 'pickup_later_screen.dart';
import 'delivery_screen.dart';

class WalkinSalesScreen extends StatelessWidget {
  WalkinSalesScreen({
    super.key,
    this.prefillCustomerId,
    this.prefillCustomerName,
    this.prefillCustomerPhone,
    this.prefillRecipientName,
    this.prefillOccasion,
  });

  final int? prefillCustomerId;
  final String? prefillCustomerName;
  final String? prefillCustomerPhone;
  final String? prefillRecipientName;
  final String? prefillOccasion;
  final OrderRepository _orderRepository = OrderRepository();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final l10n = AppLocalizations.of(context)!;

    // Auto-navigate to Take Away if customer data is provided
    if (prefillCustomerId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TakeAwayScreen(
              prefillCustomerId: prefillCustomerId,
              prefillCustomerName: prefillCustomerName,
              prefillCustomerPhone: prefillCustomerPhone,
              prefillRecipientName: prefillRecipientName,
              prefillOccasion: prefillOccasion,
            ),
          ),
        );
      });
    }

    return Scaffold(
      appBar: AppHeader(title: l10n.walkinSales),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 24 + bottomInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.howCustomerReceiveOrder,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: GridView.extent(
                  maxCrossAxisExtent: 360,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  mainAxisExtent: 210,
                  children: [
                    FutureBuilder<int>(
                      future: _orderRepository.countDraftOrders(),
                      builder: (context, snapshot) {
                        final count = snapshot.data ?? 0;
                        return _buildDeliveryOptionCard(
                          context,
                          'Draft Orders ($count)',
                          'Continue or delete saved draft orders.',
                          Icons.note_alt_outlined,
                          colorScheme.primary,
                          () => Navigator.pushNamed(context, '/draft-orders'),
                        );
                      },
                    ),
                    _buildDeliveryOptionCard(
                      context,
                      '🛍 ${l10n.takeAway}',
                      l10n.takeAwayDesc,
                      Icons.shopping_bag,
                      colorScheme.primary,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TakeAwayScreen(
                              prefillCustomerId: prefillCustomerId,
                              prefillCustomerName: prefillCustomerName,
                              prefillCustomerPhone: prefillCustomerPhone,
                              prefillRecipientName: prefillRecipientName,
                              prefillOccasion: prefillOccasion,
                            ),
                          ),
                        );
                      },
                    ),
                    _buildDeliveryOptionCard(
                      context,
                      '📦 ${l10n.pickupLater}',
                      l10n.pickupLaterDesc,
                      Icons.inventory_2,
                      colorScheme.tertiary,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PickupLaterScreen(
                              prefillCustomerId: prefillCustomerId,
                              prefillCustomerName: prefillCustomerName,
                              prefillCustomerPhone: prefillCustomerPhone,
                              prefillRecipientName: prefillRecipientName,
                              prefillOccasion: prefillOccasion,
                            ),
                          ),
                        );
                      },
                    ),
                    _buildDeliveryOptionCard(
                      context,
                      '🚚 ${l10n.delivery}',
                      l10n.deliveryDesc,
                      Icons.local_shipping,
                      colorScheme.secondary,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DeliveryScreen(
                              prefillCustomerId: prefillCustomerId,
                              prefillCustomerName: prefillCustomerName,
                              prefillCustomerPhone: prefillCustomerPhone,
                              prefillRecipientName: prefillRecipientName,
                              prefillOccasion: prefillOccasion,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveryOptionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return AppCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 10),
            Flexible(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
