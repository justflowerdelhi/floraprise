import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/repositories/staff_repository.dart';
import '../models/attendance.dart';
import '../providers/attendance_provider.dart';
import '../providers/staff_provider.dart';

class AttendanceMonthlySummaryScreen extends StatefulWidget {
  const AttendanceMonthlySummaryScreen({super.key});

  @override
  State<AttendanceMonthlySummaryScreen> createState() => _AttendanceMonthlySummaryScreenState();
}

class _AttendanceMonthlySummaryScreenState extends State<AttendanceMonthlySummaryScreen> {
  DateTime _selectedMonth = DateTime.now();
  Staff? _selectedStaff;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StaffProvider>().loadStaff();
      _loadSummary();
    });
  }

  @override
  Widget build(BuildContext context) {
    final staffProvider = context.watch<StaffProvider>();
    final attendanceProvider = context.watch<AttendanceProvider>();
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Summary'),
        actions: [
          IconButton(
            onPressed: () => _selectMonth(),
            icon: const Icon(Icons.calendar_month),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildMonthHeader(),
            _buildStaffFilter(staffProvider),
            const SizedBox(height: 16),
            Expanded(
              child: _buildBody(attendanceProvider, staffProvider, bottomInset),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            Icons.calendar_month,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selected Month',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                '${_getMonthName(_selectedMonth.month)} ${_selectedMonth.year}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStaffFilter(StaffProvider staffProvider) {
    final activeStaff = staffProvider.staff.where((s) => s.active).toList();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonFormField<Staff?>(
        initialValue: _selectedStaff,
        decoration: const InputDecoration(
          labelText: 'Filter by Staff',
          prefixIcon: Icon(Icons.person),
          border: OutlineInputBorder(),
        ),
        items: [
          const DropdownMenuItem(
            value: null,
            child: Text('All Staff'),
          ),
          ...activeStaff.map((staff) {
            return DropdownMenuItem(
              value: staff,
              child: Text(staff.name),
            );
          }),
        ],
        onChanged: (value) {
          setState(() {
            _selectedStaff = value;
          });
          _loadSummary();
        },
      ),
    );
  }

  Widget _buildBody(
    AttendanceProvider attendanceProvider,
    StaffProvider staffProvider,
    double bottomInset,
  ) {
    if (attendanceProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (attendanceProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(attendanceProvider.error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSummary,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (attendanceProvider.summary == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final summary = attendanceProvider.summary!;

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 16),
      children: [
        _buildSummaryCard(summary),
        const SizedBox(height: 16),
        _buildDetailedSummary(summary),
      ],
    );
  }

  Widget _buildSummaryCard(AttendanceSummary summary) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Attendance Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Present',
                    summary.present,
                    AttendanceStatus.present.emoji,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Absent',
                    summary.absent,
                    AttendanceStatus.absent.emoji,
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Leave',
                    summary.leave,
                    AttendanceStatus.leave.emoji,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Half Day',
                    summary.halfDay,
                    AttendanceStatus.halfDay.emoji,
                    Colors.amber,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatItem(
              'Total Overtime',
              '${summary.totalOvertimeHours}h',
              '⏱️',
              Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, dynamic value, String emoji, Color color) {
    return Column(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedSummary(AttendanceSummary summary) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monthly Report',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildReportRow('Total Days', summary.total.toString()),
            _buildReportRow('Present Days', summary.present.toString()),
            _buildReportRow('Absent Days', summary.absent.toString()),
            _buildReportRow('Leave Days', summary.leave.toString()),
            _buildReportRow('Half Days', summary.halfDay.toString()),
            _buildReportRow('Not Marked', summary.notMarked.toString()),
            const Divider(height: 24),
            _buildReportRow('Total Overtime Hours', '${summary.totalOvertimeHours}h'),
          ],
        ),
      ),
    );
  }

  Widget _buildReportRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectMonth() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (selected != null) {
      setState(() {
        _selectedMonth = DateTime(selected.year, selected.month, 1);
      });
      _loadSummary();
    }
  }

  void _loadSummary() {
    final attendanceProvider = context.read<AttendanceProvider>();
    final startDate = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final endDate = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);

    if (_selectedStaff != null) {
      attendanceProvider.loadAttendanceForStaff(
        _selectedStaff!.id,
        startDate,
        endDate,
      );
    } else {
      attendanceProvider.loadAttendanceForDate(DateTime.now());
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }
}
