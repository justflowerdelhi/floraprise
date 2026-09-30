import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/repositories/customer_repository.dart';
import '../providers/customer_provider.dart';

class CustomerNameAutocomplete extends StatefulWidget {
  const CustomerNameAutocomplete({
    super.key,
    required this.controller,
    this.focusNode,
    required this.labelText,
    this.hintText,
    this.prefixIcon = const Icon(Icons.person),
    this.onChanged,
    required this.onCustomerSelected,
    this.decoration,
    this.debounceDuration = const Duration(milliseconds: 250),
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String labelText;
  final String? hintText;
  final Widget? prefixIcon;
  final ValueChanged<String>? onChanged;
  final ValueChanged<CustomerRecord> onCustomerSelected;
  final InputDecoration? decoration;
  final Duration debounceDuration;

  @override
  State<CustomerNameAutocomplete> createState() =>
      _CustomerNameAutocompleteState();
}

class _CustomerNameAutocompleteState extends State<CustomerNameAutocomplete> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  FocusNode? _internalFocusNode;
  FocusNode get _effectiveFocusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  List<CustomerRecord> _suggestions = const [];
  int _querySequence = 0;
  final String _regionGroupId = 'CustomerNameAutocomplete_${UniqueKey()}';

  @override
  void initState() {
    super.initState();
    _effectiveFocusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _hideOverlay();
    _effectiveFocusNode.removeListener(_onFocusChanged);
    _internalFocusNode?.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_effectiveFocusNode.hasFocus && _suggestions.isNotEmpty) {
      _showOverlay();
    }
  }

  void _showOverlay() {
    _hideOverlay();
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 4),
          child: TapRegion(
            groupId: _regionGroupId,
            child: Material(
              elevation: 6.0,
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              shadowColor: Colors.black.withValues(alpha: 0.2),
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: _suggestions.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final customer = _suggestions[index];
                    return ListTile(
                      dense: true,
                      leading: const CircleAvatar(
                        radius: 14,
                        backgroundColor: Color(0xFFE8F5E9),
                        child: Icon(
                          Icons.person,
                          size: 16,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      title: Text(
                        customer.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Color(0xFF1E2922),
                        ),
                      ),
                      subtitle: Text(
                        customer.phone.isNotEmpty
                            ? customer.phone
                            : 'No phone',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      onTap: () {
                        _hideOverlay();
                        widget.controller.text = customer.name;
                        widget.onCustomerSelected(customer);
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Future<void> _onTextChanged(String value) async {
    widget.onChanged?.call(value);

    final query = value.trim();
    if (query.length < 2) {
      _suggestions = const [];
      _hideOverlay();
      return;
    }

    final currentSeq = ++_querySequence;
    if (widget.debounceDuration > Duration.zero) {
      await Future.delayed(widget.debounceDuration);
    }

    if (currentSeq != _querySequence || !mounted) {
      return;
    }

    try {
      final provider = context.read<CustomerProvider>();
      final results = await provider.searchCustomers(query);

      if (currentSeq != _querySequence || !mounted) {
        return;
      }

      setState(() {
        _suggestions = results;
      });

      if (_suggestions.isNotEmpty && _effectiveFocusNode.hasFocus) {
        _showOverlay();
      } else {
        _hideOverlay();
      }
    } catch (_) {
      _suggestions = const [];
      _hideOverlay();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TapRegion(
        groupId: _regionGroupId,
        onTapOutside: (_) => _hideOverlay(),
        child: TextField(
          controller: widget.controller,
          focusNode: _effectiveFocusNode,
          decoration: widget.decoration ??
              InputDecoration(
                labelText: widget.labelText,
                hintText: widget.hintText,
                prefixIcon: widget.prefixIcon,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 12,
                ),
              ),
          onChanged: _onTextChanged,
        ),
      ),
    );
  }
}
