import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../controllers/voice_dictation_controller.dart';
import '../data/repositories/cash_book_repository.dart';
import '../data/repositories/expense_category_repository.dart';
import '../data/repositories/expense_repository.dart';
import '../models/cash_book.dart';
import '../models/expense.dart';
import '../models/expense_category.dart';
import '../services/business_data_event_bus.dart';
import '../services/speech_recognition_service.dart';
import '../widgets/voice_dictation_field_header.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final _expenseRepository = ExpenseRepository();
  final _categoryRepository = ExpenseCategoryRepository();
  DateTime _selectedDate = DateTime.now();
  List<Expense> _expenses = [];
  List<ExpenseCategory> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final expenses = await _expenseRepository.getByDate(_selectedDate);
      final categories = await _categoryRepository.getAll();
      setState(() {
        _expenses = expenses;
        _categories = categories;
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
      });
      await _loadData();
    }
  }

  Future<void> _showAddExpenseBottomSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddExpenseBottomSheet(
        categories: _categories,
        selectedDate: _selectedDate,
        onSave: () => _loadData(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          IconButton(
            onPressed: _selectDate,
            icon: const Icon(Icons.calendar_today),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDateHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _expenses.isEmpty
                    ? _buildEmptyState()
                    : _buildExpenseList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddExpenseBottomSheet,
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
    );
  }

  Widget _buildDateHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Text(
            '📅 ${_selectedDate.day} ${_getMonthName(_selectedDate.month)} ${_selectedDate.year}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No expenses for this date',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _expenses.length,
      itemBuilder: (context, index) {
        final expense = _expenses[index];
        final category = _categories.firstWhere(
          (c) => c.id == expense.categoryId,
          orElse: () => ExpenseCategory(
            id: 0,
            name: 'Unknown',
            emoji: '❓',
            groupName: 'Others',
            active: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        return _buildExpenseCard(expense, category);
      },
    );
  }

  Widget _buildExpenseCard(Expense expense, ExpenseCategory category) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                category.emoji,
                style: const TextStyle(fontSize: 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    expense.paymentMode.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (expense.notes != null && expense.notes!.isNotEmpty)
                    Text(
                      expense.notes!,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _formatCurrency(expense.amount),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
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

class AddExpenseBottomSheet extends StatefulWidget {
  final List<ExpenseCategory> categories;
  final DateTime selectedDate;
  final VoidCallback onSave;

  const AddExpenseBottomSheet({
    super.key,
    required this.categories,
    required this.selectedDate,
    required this.onSave,
  });

  @override
  State<AddExpenseBottomSheet> createState() => _AddExpenseBottomSheetState();
}

class _AddExpenseBottomSheetState extends State<AddExpenseBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _notesDictationController = VoiceDictationController(
    speechRecognition: SpeechRecognitionService(),
  );
  final _expenseRepository = ExpenseRepository();
  final _cashBookRepository = CashBookRepository();

  ExpenseCategory? _selectedCategory;
  PaymentMode _paymentMode = PaymentMode.cash;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _notesDictationController.bindController(_notesController);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    _notesDictationController.dispose();
    super.dispose();
  }

  Future<void> _saveExpense() async {
    if (_isSaving) {
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    final amount = (double.parse(_amountController.text) * 100).toInt();
    final now = DateTime.now();

    setState(() => _isSaving = true);
    try {
      final expense = Expense(
        id: 0,
        amount: amount,
        categoryId: _selectedCategory!.id,
        paymentMode: _paymentMode,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        expenseDate: widget.selectedDate,
        createdAt: now,
        updatedAt: now,
      );

      await _expenseRepository.create(expense);

      if (_paymentMode == PaymentMode.cash) {
        await _cashBookRepository.create(
          date: widget.selectedDate,
          transactionType: CashBookTransactionType.cashExpense,
          description: '${_selectedCategory!.emoji} ${_selectedCategory!.name}',
          amount: amount,
          cashIn: 0,
          cashOut: amount,
        );
      }

      if (!mounted) return;
      context.read<BusinessDataEventBus>().publish(
            source: BusinessDataChangeSource.expense,
            message: '${_selectedCategory!.name} expense added',
          );
      Navigator.pop(context);
      widget.onSave();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Expense added: ₹${(amount / 100).toStringAsFixed(2)} for ${_selectedCategory!.name}',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final colorScheme = Theme.of(context).colorScheme;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final topPadding = MediaQuery.paddingOf(context).top;
    final availableHeight = screenHeight - topPadding - bottomInset;
    final maxSheetHeight = availableHeight.clamp(320.0, screenHeight);
    final sheetHeight = maxSheetHeight < 620.0 ? maxSheetHeight : 620.0;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            width: double.infinity,
            height: sheetHeight,
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: DecoratedBox(
                decoration: BoxDecoration(color: colorScheme.surface),
                child: Material(
                  type: MaterialType.transparency,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildHeader(context),
                        const Divider(height: 1),
                        Expanded(
                          child: SingleChildScrollView(
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildAmountField(),
                                const SizedBox(height: 20),
                                _buildCategoryField(),
                                const SizedBox(height: 16),
                                _buildPaymentModeField(),
                                const SizedBox(height: 16),
                                _buildNotesField(),
                              ],
                            ),
                          ),
                        ),
                        const Divider(height: 1),
                        _buildActions(context),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Add Expense',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      autofocus: true,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      decoration: InputDecoration(
        labelText: 'Amount *',
        prefixText: '₹ ',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter amount';
        }
        final amount = double.tryParse(value);
        if (amount == null || amount <= 0) {
          return 'Enter a valid amount';
        }
        return null;
      },
    );
  }

  Widget _buildCategoryField() {
    return DropdownButtonFormField<ExpenseCategory>(
      initialValue: _selectedCategory,
      decoration: InputDecoration(
        labelText: 'Category *',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      hint: const Text('Select category'),
      items: widget.categories.map((category) {
        return DropdownMenuItem(
          value: category,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(category.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Text(category.name),
            ],
          ),
        );
      }).toList(),
      validator: (value) => value == null ? 'Please select a category' : null,
      onChanged: (value) {
        setState(() {
          _selectedCategory = value;
        });
      },
    );
  }

  Widget _buildPaymentModeField() {
    return DropdownButtonFormField<PaymentMode>(
      initialValue: _paymentMode,
      decoration: InputDecoration(
        labelText: 'Payment Mode *',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      items: PaymentMode.values.map((mode) {
        return DropdownMenuItem(
          value: mode,
          child: Text(mode.displayName),
        );
      }).toList(),
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          _paymentMode = value;
        });
      },
    );
  }

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VoiceDictationFieldHeader(
          label: 'Notes',
          controller: _notesDictationController,
          compact: true,
        ),
        TextFormField(
          controller: _notesController,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          keyboardType: TextInputType.multiline,
          minLines: 3,
          maxLines: 4,
          maxLength: 200,
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPadding),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: _isSaving ? null : _saveExpense,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSaving
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 10),
                        Text('Saving...'),
                      ],
                    )
                  : const Text('Save Expense'),
            ),
          ),
        ],
      ),
    );
  }
}
