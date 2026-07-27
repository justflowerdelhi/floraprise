import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/printer_models.dart';
import '../providers/printer_provider.dart';
import '../widgets/common_widgets.dart';

class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PrinterProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PrinterProvider>();
    final config = provider.config;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      appBar: AppBar(title: const Text('Printer Settings')),
      body: SafeArea(
        top: false,
        child: provider.isLoading && config == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + bottomInset),
                children: [
                  if (provider.error != null) ...[
                    _ErrorCard(message: provider.error!),
                    const SizedBox(height: 12),
                  ],
                  _ConnectionCard(config: config, provider: provider),
                  const SizedBox(height: 12),
                  if (config != null) _PaperCard(config: config),
                  const SizedBox(height: 12),
                  if (config != null) _OptionsCard(config: config),
                  const SizedBox(height: 12),
                  _QueueCard(provider: provider),
                ],
              ),
      ),
    );
  }
}

class _ConnectionCard extends StatelessWidget {
  const _ConnectionCard({required this.config, required this.provider});

  final PrinterConfig? config;
  final PrinterProvider provider;

  @override
  Widget build(BuildContext context) {
    final printerName = config?.printerName?.trim();
    final printerAddress = config?.printerAddress?.trim();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            icon: Icons.bluetooth_rounded,
            title: 'Connection',
          ),
          const SizedBox(height: 8),
          const _InfoLine(label: 'Type', value: 'Bluetooth'),
          _InfoLine(
            label: 'Printer',
            value: printerName?.isNotEmpty == true
                ? printerName!
                : 'Not connected',
          ),
          if (printerAddress?.isNotEmpty == true)
            _InfoLine(label: 'Address', value: printerAddress!),
          _InfoLine(
            label: 'Status',
            value: provider.isConnected ? 'Connected' : 'Not Connected',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: provider.isScanning
                    ? null
                    : () => provider.scanBluetoothPrinters(),
                icon: provider.isScanning
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search_rounded),
                label: Text(
                    provider.isScanning ? 'Searching...' : 'Search Printers'),
              ),
              OutlinedButton.icon(
                onPressed: provider.isConnected ? provider.disconnect : null,
                icon: const Icon(Icons.link_off_rounded),
                label: const Text('Disconnect'),
              ),
              OutlinedButton.icon(
                onPressed:
                    config?.hasPrinter == true ? provider.clearPrinter : null,
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Forget'),
              ),
              FilledButton.tonalIcon(
                onPressed: provider.isPrinting ? null : provider.printTestPage,
                icon: const Icon(Icons.receipt_long_rounded),
                label: Text(
                    provider.isPrinting ? 'Printing...' : 'Print Test Page'),
              ),
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
              OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/printer-test'),
                icon: const Icon(Icons.fact_check_rounded),
                label: const Text('Open Test Page'),
              ),
            ],
          ),
          if (provider.discoveredPrinters.isNotEmpty) ...[
            const Divider(height: 24),
            ...provider.discoveredPrinters.map(
              (device) {
                final isConnecting =
                    provider.connectingAddress == device.address;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.print_rounded),
                  title: Text(device.name),
                  subtitle: Text(device.address),
                  trailing: FilledButton(
                    onPressed: provider.isLoading
                        ? null
                        : () async {
                            await provider.connect(device);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  provider.error ??
                                      '${device.name} connected and saved.',
                                ),
                              ),
                            );
                          },
                    child: isConnecting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Connect'),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _PaperCard extends StatelessWidget {
  const _PaperCard({required this.config});

  final PrinterConfig config;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            icon: Icons.straighten_rounded,
            title: 'Paper Width',
          ),
          const SizedBox(height: 8),
          SegmentedButton<PrinterPaperWidth>(
            segments: const [
              ButtonSegment(
                  value: PrinterPaperWidth.mm58, label: Text('58 mm')),
              ButtonSegment(
                  value: PrinterPaperWidth.mm80, label: Text('80 mm')),
            ],
            selected: {config.paperWidth},
            onSelectionChanged: (selected) {
              context.read<PrinterProvider>().saveConfig(
                    config.copyWith(paperWidth: selected.first),
                  );
            },
          ),
        ],
      ),
    );
  }
}

class _OptionsCard extends StatelessWidget {
  const _OptionsCard({required this.config});

  final PrinterConfig config;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<PrinterProvider>();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            icon: Icons.tune_rounded,
            title: 'Settings',
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: config.autoConnect,
            title: const Text('Auto Connect'),
            onChanged: (value) => provider.saveConfig(
              config.copyWith(autoConnect: value),
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: config.autoPrintAfterBilling,
            title: const Text('Auto Print after Billing'),
            onChanged: (value) => provider.saveConfig(
              config.copyWith(autoPrintAfterBilling: value),
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: config.cutPaper,
            title: const Text('Cut Paper'),
            onChanged: (value) => provider.saveConfig(
              config.copyWith(cutPaper: value),
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: config.printLogo,
            title: const Text('Print Logo'),
            onChanged: (value) => provider.saveConfig(
              config.copyWith(printLogo: value),
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: config.printQrCode,
            title: const Text('Print QR Code'),
            onChanged: (value) => provider.saveConfig(
              config.copyWith(printQrCode: value),
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: config.printBarcode,
            title: const Text('Print Barcode'),
            onChanged: (value) => provider.saveConfig(
              config.copyWith(printBarcode: value),
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: config.printDuplicateCopy,
            title: const Text('Print Duplicate Copy'),
            onChanged: (value) => provider.saveConfig(
              config.copyWith(printDuplicateCopy: value),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(child: Text('Number of Copies')),
              DropdownButton<int>(
                value: config.copies,
                items: [1, 2, 3, 4, 5]
                    .map((copy) => DropdownMenuItem(
                          value: copy,
                          child: Text('$copy'),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  provider.saveConfig(config.copyWith(copies: value));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QueueCard extends StatelessWidget {
  const _QueueCard({required this.provider});

  final PrinterProvider provider;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            icon: Icons.queue_rounded,
            title: 'Print Queue',
          ),
          const SizedBox(height: 8),
          if (provider.queue.isEmpty)
            Text(
              'No pending prints.',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            )
          else
            ...provider.queue.map(
              (job) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_jobLabel(job.type)),
                subtitle:
                    Text(job.lastError ?? 'Retry count: ${job.retryCount}'),
                trailing: Wrap(
                  spacing: 4,
                  children: [
                    IconButton(
                      tooltip: 'Retry',
                      onPressed: () => provider.retryJob(job.id),
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                    IconButton(
                      tooltip: 'Cancel',
                      onPressed: () => provider.cancelJob(job.id),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _jobLabel(PrintJobType type) {
    return switch (type) {
      PrintJobType.posBill => 'POS Bill',
      PrintJobType.deliverySlip => 'Delivery Slip',
      PrintJobType.messageCard => 'Message Card',
      PrintJobType.productionSlip => 'Production Slip',
      PrintJobType.bouquetBarcodeLabel => 'Barcode Label',
      PrintJobType.expenseReceipt => 'Expense Receipt',
      PrintJobType.dayCloseReport => 'Day Close Report',
      PrintJobType.testPage => 'Printer Test Page',
    };
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppCard(
      backgroundColor: colorScheme.errorContainer,
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: colorScheme.error),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
