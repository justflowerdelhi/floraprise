import 'package:flutter/material.dart';

import '../data/repositories/cash_book_repository.dart';
import '../models/cash_book.dart';

class CashBookScreen extends StatefulWidget {
  const CashBookScreen({super.key});

  @override
  State<CashBookScreen> createState() => _CashBookScreenState();
}

class _CashBookScreenState extends State<CashBookScreen> {
  final _repository = CashBookRepository();
  DateTime _selectedDate = DateTime.now();
  List<CashBook> _transactions = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    
    try {
      final transactions = await _repository.getByDate(_selectedDate);
      setState(() {
        _transactions = transactions;
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
      await _loadTransactions();
    }
  }

  Future<void> _search() async {
    if (_searchQuery.isEmpty) {
      await _loadTransactions();
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      final results = await _repository.search(_searchQuery, _selectedDate, _selectedDate);
      setState(() {
        _transactions = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cash Book'),
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
          _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _transactions.isEmpty
                    ? _buildEmptyState()
                    : _buildTransactionList(),
          ),
        ],
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by description',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                    _loadTransactions();
                  },
                )
              : null,
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value);
        },
        onSubmitted: (_) => _search(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions for this date',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final transaction = _transactions[index];
        return _buildTransactionCard(transaction);
      },
    );
  }

  Widget _buildTransactionCard(CashBook transaction) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    transaction.transactionType.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatCurrency(transaction.amount),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: transaction.cashIn > 0 ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  transaction.cashIn > 0
                      ? '+${_formatCurrency(transaction.cashIn)}'
                      : '-${_formatCurrency(transaction.cashOut)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
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
