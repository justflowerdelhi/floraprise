import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/voice_dictation_controller.dart';
import '../data/repositories/cash_book_repository.dart';
import '../data/repositories/day_closing_repository.dart';
import '../data/repositories/expense_repository.dart';
import '../data/repositories/opening_cash_repository.dart';
import '../models/cash_book.dart';
import '../models/day_closing.dart';
import '../models/expense.dart';
import '../models/opening_cash.dart';
import '../services/speech_recognition_service.dart';
import '../widgets/voice_dictation_field_header.dart';

class DayClosingScreen extends StatefulWidget {
  const DayClosingScreen({super.key});

  @override
  State<DayClosingScreen> createState() => _DayClosingScreenState();
}

class _DayClosingScreenState extends State<DayClosingScreen> {
  final _openingCashRepository = OpeningCashRepository();
  final _expenseRepository = ExpenseRepository();
  final _dayClosingRepository = DayClosingRepository();
  final _cashBookRepository = CashBookRepository();

  DateTime _selectedDate = DateTime.now();
  OpeningCash? _openingCash;

  int _cashSales = 0;
  int _upiSales = 0;
  int _cardSales = 0;
  int _creditSales = 0;
  int _cashExpenses = 0;
  int _upiExpenses = 0;
  int _cardExpenses = 0;
  int _cashReceived = 0;
  int _cashPaid = 0;

  final _countedCashController = TextEditingController();
  final _notesController = TextEditingController();
  final _notesDictationController = VoiceDictationController(
    speechRecognition: SpeechRecognitionService(),
  );

  bool _isLoading = true;
  bool _isClosed = false;

  @override
  void initState() {
    super.initState();
    _notesDictationController.bindController(_notesController);
    _loadData();
  }

  @override
  void dispose() {
    _countedCashController.dispose();
    _notesController.dispose();
    _notesDictationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final openingCash = await _openingCashRepository.getByDate(_selectedDate);
      final existingClosing =
          await _dayClosingRepository.getByDate(_selectedDate);

      final cashExpenses = await _expenseRepository.getTotalByPaymentMode(
          PaymentMode.cash, _selectedDate);
      final upiExpenses = await _expenseRepository.getTotalByPaymentMode(
          PaymentMode.upi, _selectedDate);
      final cardExpenses = await _expenseRepository.getTotalByPaymentMode(
          PaymentMode.card, _selectedDate);

      final cashBookTransactions =
          await _cashBookRepository.getByDate(_selectedDate);
      int cashReceived = 0;
      int cashPaid = 0;
      for (final tx in cashBookTransactions) {
        if (tx.transactionType == CashBookTransactionType.cashReceived) {
          cashReceived += tx.cashIn;
        } else if (tx.transactionType == CashBookTransactionType.cashPaid) {
          cashPaid += tx.cashOut;
        }
      }

      setState(() {
        _openingCash = openingCash;
        _isClosed = existingClosing != null;
        _cashExpenses = cashExpenses;
        _upiExpenses = upiExpenses;
        _cardExpenses = cardExpenses;
        _cashReceived = cashReceived;
        _cashPaid = cashPaid;

        if (existingClosing != null) {
          _cashSales = existingClosing.cashSales;
          _upiSales = existingClosing.upiSales;
          _cardSales = existingClosing.cardSales;
          _creditSales = existingClosing.creditSales;
          _countedCashController.text =
              (existingClosing.countedCash / 100).toStringAsFixed(2);
          _notesController.text = existingClosing.notes ?? '';
        }

        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
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
        _countedCashController.clear();
        _notesController.clear();
        _isClosed = false;
      });
      await _loadData();
    }
  }

  int get _expectedCash {
    final opening = _openingCash?.amount ?? 0;
    return opening + _cashSales + _cashReceived - _cashExpenses - _cashPaid;
  }

  int get _difference {
    final counted = _countedCashController.text.isEmpty
        ? 0
        : (double.parse(_countedCashController.text) * 100).toInt();
    return counted - _expectedCash;
  }

  Future<void> _closeDay() async {
    if (_openingCash == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set opening cash first')),
      );
      return;
    }

    final countedText = _countedCashController.text.trim();
    if (countedText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter counted cash')),
      );
      return;
    }

    final countedCash = (double.parse(countedText) * 100).toInt();
    final difference = countedCash - _expectedCash;

    try {
      final dayClosing = DayClosing(
        id: 0,
        date: _selectedDate,
        cashSales: _cashSales,
        upiSales: _upiSales,
        cardSales: _cardSales,
        creditSales: _creditSales,
        cashExpenses: _cashExpenses,
        upiExpenses: _upiExpenses,
        cardExpenses: _cardExpenses,
        openingCash: _openingCash!.amount,
        expectedCash: _expectedCash,
        countedCash: countedCash,
        difference: difference,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        closedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      await _dayClosingRepository.create(dayClosing);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Day closed successfully')),
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
        title: const Text('Day Closing'),
        actions: [
          IconButton(
            onPressed: _selectDate,
            icon: const Icon(Icons.calendar_today),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDateHeader(),
                  const SizedBox(height: 16),
                  _buildSalesSection(),
                  const SizedBox(height: 16),
                  _buildExpensesSection(),
                  const SizedBox(height: 16),
                  _buildOpeningCashSection(),
                  const SizedBox(height: 16),
                  _buildExpectedCashSection(),
                  const SizedBox(height: 16),
                  _buildCountedCashSection(),
                  const SizedBox(height: 16),
                  _buildDifferenceSection(),
                  const SizedBox(height: 16),
                  _buildNotesSection(),
                  const SizedBox(height: 24),
                  if (!_isClosed)
                    _buildCloseButton()
                  else
                    _buildClosedMessage(),
                ],
              ),
            ),
    );
  }

  Widget _buildDateHeader() {
    return Text(
      '📅 ${_selectedDate.day} ${_getMonthName(_selectedDate.month)} ${_selectedDate.year}',
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildSalesSection() {
    return _buildSection(
      'Sales',
      [
        _buildRow('Cash Sales', _cashSales),
        _buildRow('UPI Sales', _upiSales),
        _buildRow('Card Sales', _cardSales),
        _buildRow('Credit Sales', _creditSales),
      ],
    );
  }

  Widget _buildExpensesSection() {
    return _buildSection(
      'Expenses',
      [
        _buildRow('Cash Expenses', _cashExpenses),
        _buildRow('UPI Expenses', _upiExpenses),
        _buildRow('Card Expenses', _cardExpenses),
      ],
    );
  }

  Widget _buildOpeningCashSection() {
    return _buildSection(
      'Opening Cash',
      [
        _buildRow('Opening Cash', _openingCash?.amount ?? 0),
      ],
    );
  }

  Widget _buildExpectedCashSection() {
    return _buildSection(
      'Expected Cash',
      [
        _buildRow('Expected Cash', _expectedCash, isBold: true),
      ],
    );
  }

  Widget _buildCountedCashSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cash Counted',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _countedCashController,
          enabled: !_isClosed,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          decoration: InputDecoration(
            prefixText: '₹ ',
            border: const OutlineInputBorder(),
            filled: _isClosed,
            fillColor: Colors.grey.shade100,
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildDifferenceSection() {
    final diff = _difference;
    final isPositive = diff >= 0;

    return _buildSection(
      'Difference',
      [
        _buildRow(
          'Difference',
          diff.abs(),
          isBold: true,
          color: isPositive ? Colors.green : Colors.red,
          prefix: isPositive ? '+' : '-',
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notes',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        VoiceDictationFieldHeader(
          label: 'Notes',
          controller: _notesDictationController,
          compact: true,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _notesController,
          enabled: !_isClosed,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            filled: _isClosed,
            fillColor: Colors.grey.shade100,
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildRow(String label, int amount,
      {bool isBold = false, Color? color, String? prefix}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            '${prefix ?? ''}${_formatCurrency(amount)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCloseButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: _closeDay,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: const Text('Close Day'),
      ),
    );
  }

  Widget _buildClosedMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Day closed successfully',
              style: TextStyle(color: Colors.green.shade900),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(int amount) {
    return '₹${(amount / 100).toStringAsFixed(2)}';
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
