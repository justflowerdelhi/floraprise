import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class QuantityInputStepper extends StatefulWidget {
  const QuantityInputStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max,
    this.width = 64,
    this.height = 40,
    this.debounceDuration = const Duration(milliseconds: 250),
    this.enabled = true,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int? max;
  final double width;
  final double height;
  final Duration debounceDuration;
  final bool enabled;

  @override
  State<QuantityInputStepper> createState() => _QuantityInputStepperState();
}

class _QuantityInputStepperState extends State<QuantityInputStepper> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString());
    _focusNode = FocusNode()..addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(covariant QuantityInputStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && !_focusNode.hasFocus) {
      _controller.text = widget.value.toString();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.removeListener(_handleFocusChanged);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (_focusNode.hasFocus) {
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
      return;
    }
    _commitText();
  }

  void _changeBy(int delta) {
    _debounce?.cancel();
    final next = _clamp(widget.value + delta);
    _controller.text = next.toString();
    widget.onChanged(next);
  }

  void _handleTyped(String value) {
    _debounce?.cancel();
    if (value.isEmpty) return;
    _debounce = Timer(widget.debounceDuration, _commitText);
  }

  void _commitText() {
    _debounce?.cancel();
    final next = _clamp(int.tryParse(_controller.text) ?? widget.min);
    _controller.text = next.toString();
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
    if (next != widget.value) {
      widget.onChanged(next);
    }
  }

  int _clamp(int value) {
    final lowerBounded = value < widget.min ? widget.min : value;
    final max = widget.max;
    if (max != null && lowerBounded > max) return max;
    return lowerBounded;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove),
          onPressed: widget.enabled && widget.value > widget.min
              ? () => _changeBy(-1)
              : null,
          style: IconButton.styleFrom(
              minimumSize: Size(widget.height, widget.height)),
        ),
        SizedBox(
          width: widget.width,
          height: widget.height,
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            enabled: widget.enabled,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onTap: () {
              _controller.selection = TextSelection(
                baseOffset: 0,
                extentOffset: _controller.text.length,
              );
            },
            onChanged: _handleTyped,
            onEditingComplete: () {
              _commitText();
              _focusNode.unfocus();
            },
            onSubmitted: (_) => _commitText(),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: widget.enabled &&
                  (widget.max == null || widget.value < widget.max!)
              ? () => _changeBy(1)
              : null,
          style: IconButton.styleFrom(
              minimumSize: Size(widget.height, widget.height)),
        ),
      ],
    );
  }
}
