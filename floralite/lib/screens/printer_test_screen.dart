import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/printer_provider.dart';
import '../widgets/common_widgets.dart';

class PrinterTestScreen extends StatelessWidget {
  const PrinterTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PrinterProvider>();
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      appBar: AppBar(title: const Text('Printer Test')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomInset),
          children: [
            if (provider.error != null) ...[
              AppCard(
                backgroundColor: Theme.of(context).colorScheme.errorContainer,
                child: Text(provider.error!),
              ),
              const SizedBox(height: 12),
            ],
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FLORAPRISE',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Printer Test'),
                  const SizedBox(height: 12),
                  _Line('Printer',
                      provider.config?.printerName ?? 'POSIFLOW BT80'),
                  const _Line('Bluetooth', 'OK'),
                  _Line(
                    'Paper Width',
                    provider.config?.paperWidth.name == 'mm58'
                        ? '58 mm'
                        : '80 mm',
                  ),
                  const _Line('Barcode Test', '123456789012'),
                  const _Line('QR Code Test', 'FLORAPRISE PRINTER READY'),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed:
                        provider.isPrinting ? null : provider.printTestPage,
                    icon: provider.isPrinting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.print_rounded),
                    label: Text(provider.isPrinting
                        ? 'Printing...'
                        : 'Print Test Page'),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.tonalIcon(
                    onPressed: provider.isPrinting || !provider.hasLastReceipt
                        ? null
                        : () async {
                            await provider.reprintLastReceipt();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  provider.error ??
                                      'Last receipt queued for reprint.',
                                ),
                              ),
                            );
                          },
                    icon: const Icon(Icons.replay_rounded),
                    label: const Text('Reprint Last Receipt'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
