import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/mobile_auth_service.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final MobileAuthService _mobileAuthService = MobileAuthService();
  List<Map<String, dynamic>> _payments = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPaymentHistory();
  }

  Future<void> _loadPaymentHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final payments = await _mobileAuthService.getPaymentHistory();
      setState(() {
        _payments = payments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPaymentHistory,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error loading payment history',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPaymentHistory,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_payments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No payment history',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your subscription payments will appear here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade500,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _payments.length,
      itemBuilder: (context, index) {
        final payment = _payments[index];
        return _PaymentCard(payment: payment);
      },
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.payment});

  final Map<String, dynamic> payment;

  @override
  Widget build(BuildContext context) {
    final createdAt = payment['createdAtUtc'] as String?;
    final planName = payment['planName'] as String? ?? 'Unknown Plan';
    final amount = payment['amount'] as num? ?? 0;
    final status = payment['status'] as String? ?? 'Unknown';
    final transactionId = payment['transactionId'] as String?;
    final paidAt = payment['paidAtUtc'] as String?;

    final createdAtDate =
        createdAt != null ? DateTime.tryParse(createdAt) : null;
    final paidAtDate = paidAt != null ? DateTime.tryParse(paidAt) : null;

    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    planName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        statusIcon,
                        size: 16,
                        color: statusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₹${amount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                ),
                if (createdAtDate != null)
                  Text(
                    DateFormat('dd MMM yyyy').format(createdAtDate),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
              ],
            ),
            if (transactionId != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.receipt,
                    size: 16,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Transaction ID: $transactionId',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                  ),
                ],
              ),
            ],
            if (paidAtDate != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: Colors.green.shade500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Paid on ${DateFormat('dd MMM yyyy, HH:mm').format(paidAtDate)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.green.shade700,
                        ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      case 'refunded':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'pending':
        return Icons.pending;
      case 'failed':
        return Icons.cancel;
      case 'refunded':
        return Icons.assignment_return;
      default:
        return Icons.help_outline;
    }
  }
}
