import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../controllers/voice_entry_controller.dart';
import '../data/repositories/product_repository.dart';
import '../providers/inventory_provider.dart';
import '../services/product_matcher.dart';
import '../services/speech_recognition_service.dart';
import '../services/voice_parser.dart';
import '../services/voice_stock_entry_service.dart';
import '../utils/locale_formatter.dart';
import '../widgets/common_widgets.dart';

class VoiceStockEntryScreen extends StatefulWidget {
  const VoiceStockEntryScreen({super.key});

  @override
  State<VoiceStockEntryScreen> createState() => _VoiceStockEntryScreenState();
}

class _VoiceStockEntryScreenState extends State<VoiceStockEntryScreen>
    with SingleTickerProviderStateMixin {
  final ProductRepository _productRepository = ProductRepository();
  late final AnimationController _pulseController;
  VoiceEntryController? _voiceController;
  List<String> _suppliers = const [];
  String _supplier = '';
  bool _loading = true;
  bool _saving = false;
  int _shownMessageVersion = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      final products = await _productRepository.listProducts(
        trackInventory: true,
        showActive: true,
        showInactive: false,
      );
      final controller = VoiceEntryController(
        speechRecognition: SpeechRecognitionService(),
        voiceEntry: VoiceStockEntryService(
          parser: VoiceParser(),
          matcher: ProductMatcher(
            products.map(
              (product) => ProductMatchCandidate(
                id: product.id,
                name: product.name,
              ),
            ),
          ),
        ),
      );
      controller.addListener(_handleControllerChange);
      final suppliers = products
          .map((product) => product.supplier.trim())
          .where((supplier) => supplier.isNotEmpty)
          .toSet()
          .toList()
        ..sort(
            (left, right) => left.toLowerCase().compareTo(right.toLowerCase()));
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() {
        _voiceController = controller;
        _suppliers = suppliers;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load the product master.')),
      );
    }
  }

  void _handleControllerChange() {
    if (!mounted) return;
    final controller = _voiceController;
    if (controller == null) return;
    if (controller.isListening && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!controller.isListening && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.value = 0;
    }
    setState(() {});
    if (controller.messageVersion != _shownMessageVersion) {
      _shownMessageVersion = controller.messageVersion;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || controller.message == null) return;
        final message = controller.message!;
        final isPermissionBlocked =
            message.toLowerCase().contains('permission is blocked') ||
                message.toLowerCase().contains('app settings');
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(message),
              action: isPermissionBlocked
                  ? const SnackBarAction(
                      label: 'Open Settings',
                      onPressed: openAppSettings,
                    )
                  : null,
            ),
          );
      });
    }
  }

  Future<void> _save() async {
    final controller = _voiceController;
    if (controller == null || controller.rows.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      final inventory = context.read<InventoryProvider>();
      while (controller.rows.isNotEmpty) {
        final row = controller.rows.first;
        await inventory.purchase(
          productId: row.productId,
          quantity: row.quantity,
          purchasePricePaise: row.purchasePricePaise,
          supplier: _supplier.isEmpty ? null : _supplier,
          note: 'Voice stock entry',
        );
        controller.removeFirst();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stock saved successfully.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save stock: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _voiceController?.removeListener(_handleControllerChange);
    _voiceController?.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _voiceController;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Scaffold(
      appBar: AppBar(title: const Text('Stock Update')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : controller == null
              ? const Center(child: Text('Product master is unavailable.'))
              : SafeArea(
                  top: false,
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomInset),
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _supplier,
                        decoration: const InputDecoration(
                          labelText: 'Supplier (Optional)',
                          prefixIcon: Icon(Icons.local_shipping_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: '',
                            child: Text('Select Supplier'),
                          ),
                          ..._suppliers.map(
                            (supplier) => DropdownMenuItem(
                              value: supplier,
                              child: Text(supplier),
                            ),
                          ),
                        ],
                        onChanged: controller.isListening || _saving
                            ? null
                            : (value) =>
                                setState(() => _supplier = value ?? ''),
                      ),
                      const SizedBox(height: 24),
                      _buildVoiceControl(controller),
                      const SizedBox(height: 16),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: controller.recentlyAdded == null
                            ? const SizedBox.shrink()
                            : _AddedBanner(
                                key: ValueKey(controller.recentlyAdded),
                                row: controller.recentlyAdded!,
                              ),
                      ),
                      if (controller.pendingMatches.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildProductChoices(controller),
                      ],
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Received Items',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text('${controller.rows.length} items'),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (controller.rows.isEmpty)
                        const AppCard(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: Text('Voice entries will appear here.'),
                            ),
                          ),
                        )
                      else
                        ...List.generate(
                          controller.rows.length,
                          (index) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _StockRowTile(
                              row: controller.rows[index],
                              onRemove: _saving
                                  ? null
                                  : () => controller.removeAt(index),
                            ),
                          ),
                        ),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 54,
                        child: FilledButton.icon(
                          onPressed: controller.rows.isEmpty ||
                                  controller.isListening ||
                                  _saving
                              ? null
                              : _save,
                          icon: const Icon(Icons.save_outlined),
                          label: Text(_saving ? 'Saving...' : 'Save Stock'),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildVoiceControl(VoiceEntryController controller) {
    final listening = controller.isListening;
    return AppCard(
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) => Transform.scale(
              scale: listening ? 1 + (_pulseController.value * 0.06) : 1,
              child: child,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 72,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: listening
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.primary,
                ),
                onPressed: _saving
                    ? null
                    : listening
                        ? controller.stop
                        : controller.start,
                icon: Icon(listening ? Icons.stop : Icons.mic, size: 32),
                label: Text(
                  listening ? 'Stop Voice Entry' : 'Start Voice Entry',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            listening ? 'Listening...' : 'Tap once and add multiple items',
            style: TextStyle(
              color: listening
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text('Speak like “50 red roses 12”'),
          if (listening || controller.liveTranscript.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                controller.liveTranscript.isEmpty
                    ? 'Listening for speech...'
                    : 'Heard: ${controller.liveTranscript}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductChoices(VoiceEntryController controller) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Did you mean?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          RadioGroup<int>(
            groupValue: null,
            onChanged: (productId) {
              if (productId == null) return;
              final product = controller.pendingMatches.firstWhere(
                (candidate) => candidate.id == productId,
              );
              controller.chooseProduct(product);
            },
            child: Column(
              children: controller.pendingMatches
                  .map(
                    (product) => RadioListTile<int>(
                      value: product.id,
                      title: Text(product.name),
                      contentPadding: EdgeInsets.zero,
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddedBanner extends StatelessWidget {
  const _AddedBanner({super.key, required this.row});

  final VoiceStockRow row;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Added\n${row.quantity} ${row.productName} ${LocaleFormatter.formatCurrency(context, row.purchasePricePaise)}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _StockRowTile extends StatelessWidget {
  const _StockRowTile({required this.row, required this.onRemove});

  final VoiceStockRow row;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Text(
              row.productName,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          SizedBox(
            width: 56,
            child: Text('${row.quantity}', textAlign: TextAlign.center),
          ),
          SizedBox(
            width: 82,
            child: Text(
              LocaleFormatter.formatCurrency(
                context,
                row.purchasePricePaise,
              ),
              textAlign: TextAlign.end,
            ),
          ),
          IconButton(
            tooltip: 'Remove item',
            onPressed: onRemove,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}
