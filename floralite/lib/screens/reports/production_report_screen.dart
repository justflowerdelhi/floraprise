import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/repositories/production_repository.dart';
import '../production_detail_screen.dart';
import '../../widgets/common_widgets.dart';

class ProductionReportScreen extends StatefulWidget {
  const ProductionReportScreen({super.key});

  @override
  State<ProductionReportScreen> createState() => _ProductionReportScreenState();
}

class _ProductionReportScreenState extends State<ProductionReportScreen> {
  final ProductionRepository _repository = ProductionRepository();
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime.now();
  List<ProductionReportRecord> _records = const [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final records = await _repository.getProductionReport(startDate: _startDate, endDate: _endDate);
      if (!mounted) return;
      setState(() => _records = records);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (selected == null) return;
    setState(() {
      if (isStart) {
        _startDate = selected;
        if (_endDate.isBefore(selected)) _endDate = selected;
      } else {
        _endDate = selected;
      }
    });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final producedQuantity = _records.fold<int>(0, (total, record) => total + record.quantity);
    final producedCost = _records.fold<int>(0, (total, record) => total + record.productionCostPaise);
    return Scaffold(
      appBar: AppBar(title: const Text('Production Report')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => _pickDate(isStart: true), child: Text(DateFormat('dd MMM yyyy').format(_startDate)))),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('to')),
                  Expanded(child: OutlinedButton(onPressed: () => _pickDate(isStart: false), child: Text(DateFormat('dd MMM yyyy').format(_endDate)))),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _summaryCard('Produced', '$producedQuantity', Icons.local_florist_outlined)),
                  const SizedBox(width: 12),
                  Expanded(child: _summaryCard('Production Cost', '₹${(producedCost / 100).toStringAsFixed(0)}', Icons.payments_outlined)),
                ],
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                const Padding(padding: EdgeInsets.all(36), child: Center(child: CircularProgressIndicator()))
              else if (_records.isEmpty)
                const Padding(padding: EdgeInsets.all(36), child: Center(child: Text('No production recorded for this period.')))
              else
                ..._records.map((record) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(record.productName),
                      subtitle: Text('PROD-${record.id.toString().padLeft(6, '0')} • ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(record.producedAt))}\n${record.isReversed ? 'Reversed' : 'Current Stock: ${record.currentStock}'}'),
                      isThreeLine: true,
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(record.isReversed ? 'Reversed' : '+${record.quantity}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: record.isReversed ? Theme.of(context).colorScheme.error : null)),
                          Text('₹${(record.productionCostPaise / 100).toStringAsFixed(0)}'),
                        ],
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ProductionDetailScreen(productionId: record.id),
                        ),
                      ).then((_) => _load()),
                    ),
                  ),
                )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryCard(String label, String value, IconData icon) {
    return AppCard(
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 12)), Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17))])),
        ],
      ),
    );
  }
}
