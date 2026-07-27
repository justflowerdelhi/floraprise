import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/repositories/opening_cash_repository.dart';
import '../models/opening_cash.dart';

class OpeningCashScreen extends StatefulWidget {
  const OpeningCashScreen({super.key});

  @override
  State<OpeningCashScreen> createState() => _OpeningCashScreenState();
}

class _OpeningCashScreenState extends State<OpeningCashScreen> {
  final _amountController = TextEditingController();
  final _repository = OpeningCashRepository();
  DateTime _selectedDate = DateTime.now();
  OpeningCash? _existingOpeningCash;
  bool _isLocked = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final openingCash = await _repository.getByDate(_selectedDate);
    final hasTransactions = await _repository.hasTransactionsForDate(_selectedDate);
    
    setState(() {
      _existingOpeningCash = openingCash;
      _isLocked = hasTransactions;
      if (openingCash != null) {
        _amountController.text = (openingCash.amount / 100).toStringAsFixed(2);
      }
      _isLoading = false;
    });
  }

  Future<void> _selectDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (selected != null) {
      setState(() {
        _selectedDate = selected;
        _amountController.clear();
        _existingOpeningCash = null;
        _isLocked = false;
      });
      await _loadData();
    }
  }

  Future<void> _saveOpeningCash() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter amount')),
      );
      return;
    }

    final amount = (double.parse(amountText) * 100).toInt();
    
    try {
      if (_existingOpeningCash != null) {
        await _repository.update(_existingOpeningCash!.copyWith(amount: amount));
      } else {
        await _repository.create(amount, _selectedDate);
      }
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Opening cash saved successfully')),
      );
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Opening Cash'),
        actions: [
          IconButton(
            onPressed: _selectDate,
            icon: const Icon(Icons.calendar_today),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDateHeader(),
                  const SizedBox(height: 24),
                  _buildAmountField(),
                  const SizedBox(height: 24),
                  if (_isLocked)
                    _buildLockedMessage()
                  else
                    _buildSaveButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildDateHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${_selectedDate.day} ${_getMonthName(_selectedDate.month)} ${_selectedDate.year}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cash in Hand',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _amountController,
          enabled: !_isLocked,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          decoration: InputDecoration(
            prefixText: '₹ ',
            border: const OutlineInputBorder(),
            filled: _isLocked,
            fillColor: Colors.grey.shade100,
          ),
        ),
      ],
    );
  }

  Widget _buildLockedMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Opening cash is locked after first transaction',
              style: TextStyle(color: Colors.orange.shade900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: _saveOpeningCash,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: const Text('Start Day'),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}
