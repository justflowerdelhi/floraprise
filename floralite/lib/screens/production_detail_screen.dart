import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../controllers/voice_dictation_controller.dart';
import '../data/repositories/production_repository.dart';
import '../services/speech_recognition_service.dart';
import '../widgets/voice_dictation_field_header.dart';
import 'bouquet_builder_screen.dart';
import '../widgets/common_widgets.dart';

class ProductionDetailScreen extends StatefulWidget {
  const ProductionDetailScreen({super.key, required this.productionId});

  final int productionId;

  @override
  State<ProductionDetailScreen> createState() => _ProductionDetailScreenState();
}

class _ProductionDetailScreenState extends State<ProductionDetailScreen> {
  final ProductionRepository _repository = ProductionRepository();
  ProductionDetail? _detail;
  bool _isLoading = true;
  bool _isReversing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final detail = await _repository.getProductionDetail(widget.productionId);
    if (!mounted) return;
    setState(() {
      _detail = detail;
      _isLoading = false;
    });
  }

  Future<void> _reverse() async {
    final detail = _detail;
    if (detail == null || detail.isReversed) return;
    final noteController = TextEditingController();
    final notesDictationController = VoiceDictationController(
      speechRecognition: SpeechRecognitionService(),
    );
    notesDictationController.bindController(noteController);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reverse ${detail.productionNumber}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'This will return raw inventory and remove ${detail.quantity} finished goods from stock.'),
            const SizedBox(height: 12),
            VoiceDictationFieldHeader(
              label: 'Reason (Optional)',
              controller: notesDictationController,
              compact: true,
            ),
            TextField(
              controller: noteController,
              maxLines: 2,
              decoration: const InputDecoration(),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton.tonal(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Reverse Production')),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _isReversing = true);
    try {
      await _repository.reverseProduction(
          productionId: detail.id, note: noteController.text);
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Production reversed successfully')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error.toString().replaceFirst('Bad state: ', ''))));
    } finally {
      if (mounted) setState(() => _isReversing = false);
    }
    notesDictationController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;
    return Scaffold(
      appBar:
          AppBar(title: Text(detail?.productionNumber ?? 'Production Details')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : detail == null
              ? const Center(child: Text('Production record not found.'))
              : SafeArea(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (detail.isReversed)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: AppCard(
                            backgroundColor:
                                Theme.of(context).colorScheme.errorContainer,
                            child: Text(
                                'Reversed on ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(detail.reversedAt!))}${detail.reversalNote?.isNotEmpty == true ? '\n${detail.reversalNote}' : ''}'),
                          ),
                        ),
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(detail.productName,
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            _detailRow(
                                'Production Number', detail.productionNumber),
                            const Divider(),
                            _detailRow('Produced', '${detail.quantity}'),
                            const Divider(),
                            _detailRow('Cost',
                                '₹${(detail.productionCostPaise / 100).toStringAsFixed(0)}'),
                            const Divider(),
                            _detailRow(
                                'Created',
                                DateFormat('dd MMM yyyy, hh:mm a')
                                    .format(DateTime.parse(detail.producedAt))),
                            const Divider(),
                            _detailRow('Operator', detail.operatorName),
                            if (detail.deviceName?.isNotEmpty == true) ...[
                              const Divider(),
                              _detailRow('Device', detail.deviceName!),
                            ],
                            if (detail.note?.isNotEmpty == true) ...[
                              const Divider(),
                              _detailRow('Note', detail.note!),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Recipe Used',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            ...detail.consumptions.map((item) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(item.productName.isEmpty
                                      ? 'Product #${item.rawProductId}'
                                      : item.productName),
                                  subtitle: Text(
                                      '₹${(item.unitCostPaise / 100).toStringAsFixed(0)} each'),
                                  trailing: Text(
                                      '${item.quantity} ${item.unit}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                )),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => BouquetBuilderScreen(
                              existingProductId: detail.finishedProductId,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.replay_outlined),
                        label: const Text('Produce Again'),
                        style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16)),
                      ),
                      const SizedBox(height: 12),
                      if (!detail.isReversed)
                        OutlinedButton.icon(
                          onPressed: _isReversing ? null : _reverse,
                          icon: _isReversing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.undo),
                          label: const Text('Reverse Production'),
                          style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16)),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w500))),
        const SizedBox(width: 20),
        Expanded(child: Text(value, textAlign: TextAlign.end)),
      ],
    );
  }
}
