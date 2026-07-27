import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/repositories/staff_repository.dart';
import '../models/attendance.dart';
import '../providers/attendance_provider.dart';
import '../providers/staff_provider.dart';

class AttendanceTodayScreen extends StatefulWidget {
  const AttendanceTodayScreen({super.key});

  @override
  State<AttendanceTodayScreen> createState() => _AttendanceTodayScreenState();
}

class _AttendanceTodayScreenState extends State<AttendanceTodayScreen> {
  AttendanceStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['filterStatus'] != null) {
        setState(() {
          _filterStatus = args['filterStatus'] as AttendanceStatus;
        });
      }
      context.read<StaffProvider>().loadStaff();
      context.read<AttendanceProvider>().loadAttendanceForDate(DateTime.now());
    });
  }

  @override
  Widget build(BuildContext context) {
    final attendanceProvider = context.watch<AttendanceProvider>();
    final staffProvider = context.watch<StaffProvider>();
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Today's Attendance"),
        actions: [
          PopupMenuButton<AttendanceStatus?>(
            icon: const Icon(Icons.filter_list),
            initialValue: _filterStatus,
            onSelected: (value) {
              setState(() {
                _filterStatus = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('All'),
              ),
              const PopupMenuItem(
                value: AttendanceStatus.present,
                child: Text('Present'),
              ),
              const PopupMenuItem(
                value: AttendanceStatus.absent,
                child: Text('Absent'),
              ),
              const PopupMenuItem(
                value: AttendanceStatus.leave,
                child: Text('Leave'),
              ),
              const PopupMenuItem(
                value: AttendanceStatus.halfDay,
                child: Text('Half Day'),
              ),
              const PopupMenuItem(
                value: AttendanceStatus.notMarked,
                child: Text('Not Marked'),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _buildBody(attendanceProvider, staffProvider, bottomInset),
      ),
    );
  }

  Widget _buildBody(
    AttendanceProvider attendanceProvider,
    StaffProvider staffProvider,
    double bottomInset,
  ) {
    if (staffProvider.isLoading || attendanceProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final activeStaff = staffProvider.staff.where((s) => s.active).toList();
    final filteredStaff = _filterStaff(activeStaff, attendanceProvider);

    if (filteredStaff.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _filterStatus == null
                  ? 'No active staff found'
                  : 'No staff with ${_filterStatus!.displayName} status',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 16),
      itemCount: filteredStaff.length,
      itemBuilder: (context, index) {
        final staff = filteredStaff[index];
        final attendance = attendanceProvider.attendanceList.firstWhere(
          (a) => a.staffId == staff.id,
          orElse: () => Attendance(
            id: 0,
            staffId: staff.id,
            attendanceDate: attendanceProvider.selectedDate,
            status: AttendanceStatus.notMarked,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        return _buildStaffCard(staff, attendance);
      },
    );
  }

  List<Staff> _filterStaff(List<Staff> staff, AttendanceProvider provider) {
    if (_filterStatus == null) return staff;

    return staff.where((s) {
      final attendance = provider.attendanceList.firstWhere(
        (a) => a.staffId == s.id,
        orElse: () => Attendance(
          id: 0,
          staffId: s.id,
          attendanceDate: provider.selectedDate,
          status: AttendanceStatus.notMarked,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      return attendance.status == _filterStatus;
    }).toList();
  }

  Widget _buildStaffCard(Staff staff, Attendance attendance) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(attendance.status).withValues(alpha: 0.2),
          child: Text(
            attendance.status.emoji,
            style: const TextStyle(fontSize: 20),
          ),
        ),
        title: Text(staff.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(staff.role.name),
            if (attendance.clockIn != null)
              Text(
                'In: ${_formatTime(attendance.clockIn)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            if (attendance.clockOut != null)
              Text(
                'Out: ${_formatTime(attendance.clockOut)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            if (attendance.overtimeHours > 0)
              Text(
                'Overtime: ${attendance.overtimeHours}h',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.blue,
                ),
              ),
          ],
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.grey.shade400,
        ),
        onTap: () => _navigateToMarkAttendance(staff, attendance),
      ),
    );
  }

  void _navigateToMarkAttendance(Staff staff, Attendance attendance) {
    Navigator.pushNamed(
      context,
      '/attendance/mark',
      arguments: {'staff': staff, 'attendance': attendance},
    );
  }

  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Colors.green;
      case AttendanceStatus.absent:
        return Colors.red;
      case AttendanceStatus.leave:
        return Colors.orange;
      case AttendanceStatus.halfDay:
        return Colors.amber;
      case AttendanceStatus.notMarked:
        return Colors.grey;
    }
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '--:--';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
