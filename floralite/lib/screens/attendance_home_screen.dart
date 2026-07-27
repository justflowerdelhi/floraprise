import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/voice_dictation_controller.dart';
import '../data/repositories/attendance_repository.dart';
import '../data/repositories/staff_repository.dart';
import '../models/attendance.dart';
import '../providers/attendance_provider.dart';
import '../providers/staff_provider.dart';
import '../services/speech_recognition_service.dart';
import '../widgets/voice_dictation_field_header.dart';

class AttendanceHomeScreen extends StatefulWidget {
  const AttendanceHomeScreen({super.key});

  @override
  State<AttendanceHomeScreen> createState() => _AttendanceHomeScreenState();
}

class _AttendanceHomeScreenState extends State<AttendanceHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StaffProvider>().loadStaff();
      context.read<AttendanceProvider>().loadAttendanceForDate(DateTime.now());
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AttendanceProvider>();
    final staffProvider = context.watch<StaffProvider>();
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        actions: [
          IconButton(
            onPressed: () => _selectDate(context, provider),
            icon: const Icon(Icons.calendar_today),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildDateHeader(provider),
            const SizedBox(height: 8),
            if (provider.summary != null)
              _buildSummaryChips(provider.summary!)
            else
              const SizedBox(),
            const SizedBox(height: 8),
            Expanded(
              child: _buildBody(provider, staffProvider, bottomInset),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateHeader(AttendanceProvider provider) {
    final date = provider.selectedDate;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            '📅 ${date.day} ${_getMonthName(date.month)} ${date.year}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChips(AttendanceSummary summary) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildChip('Present', summary.present.toString(), Colors.green),
          const SizedBox(width: 8),
          _buildChip('Absent', summary.absent.toString(), Colors.red),
          const SizedBox(width: 8),
          _buildChip('Not Marked', summary.notMarked.toString(), Colors.grey),
        ],
      ),
    );
  }

  Widget _buildChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$label $value',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Widget _buildBody(
    AttendanceProvider provider,
    StaffProvider staffProvider,
    double bottomInset,
  ) {
    if (provider.isLoading || staffProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(provider.error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.read<StaffProvider>().loadStaff();
                provider.loadAttendanceForDate(provider.selectedDate);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final activeStaff = staffProvider.staff.where((s) => s.active).toList();

    if (activeStaff.isEmpty) {
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
              'No active staff found',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 16),
      itemCount: activeStaff.length,
      itemBuilder: (context, index) {
        final staff = activeStaff[index];
        final attendance = provider.attendanceList.firstWhere(
          (a) => a.staffId == staff.id,
          orElse: () => Attendance(
            id: 0,
            staffId: staff.id,
            attendanceDate: provider.selectedDate,
            status: AttendanceStatus.notMarked,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        return _buildStaffCard(staff, attendance);
      },
    );
  }

  Widget _buildStaffCard(Staff staff, Attendance attendance) {
    final isMarked = attendance.status != AttendanceStatus.notMarked;

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                staff.name.isEmpty ? '?' : staff.name[0].toUpperCase(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    staff.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    staff.role.name,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isMarked) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        attendance.status.emoji,
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        attendance.status.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _getStatusColor(attendance.status),
                        ),
                      ),
                    ],
                  ),
                  if (attendance.status == AttendanceStatus.present &&
                      attendance.clockIn != null)
                    Text(
                      _formatTime(attendance.clockIn),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8),
            ],
            FilledButton.tonal(
              onPressed: () => _showAttendanceBottomSheet(staff, attendance),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: const Size(60, 32),
              ),
              child: Text(isMarked ? 'Edit' : 'Mark',
                  style: const TextStyle(fontSize: 13)),
            ),
          ],
        ),
      ),
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

  Future<void> _selectDate(
      BuildContext context, AttendanceProvider provider) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: provider.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (selected != null) {
      provider.setSelectedDate(selected);
      provider.loadAttendanceForDate(selected);
    }
  }

  Future<void> _showAttendanceBottomSheet(
      Staff staff, Attendance attendance) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AttendanceBottomSheet(
        staff: staff,
        attendance: attendance,
        onSave: () {
          context.read<AttendanceProvider>().loadAttendanceForDate(
                context.read<AttendanceProvider>().selectedDate,
              );
        },
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

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final hour = time.hour;
    final minute = time.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }
}

class AttendanceBottomSheet extends StatefulWidget {
  final Staff staff;
  final Attendance attendance;
  final VoidCallback onSave;

  const AttendanceBottomSheet({
    super.key,
    required this.staff,
    required this.attendance,
    required this.onSave,
  });

  @override
  State<AttendanceBottomSheet> createState() => _AttendanceBottomSheetState();
}

class _AttendanceBottomSheetState extends State<AttendanceBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _clockInController = TextEditingController();
  final _clockOutController = TextEditingController();
  final _notesDictationController = VoiceDictationController(
    speechRecognition: SpeechRecognitionService(),
  );

  late AttendanceStatus _status;
  late int _overtimeHours;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _notesDictationController.bindController(_notesController);
    _status = widget.attendance.status == AttendanceStatus.notMarked
        ? AttendanceStatus.present
        : widget.attendance.status;
    _overtimeHours = widget.attendance.overtimeHours;
    _selectedDate = widget.attendance.attendanceDate;
    _notesController.text = widget.attendance.notes ?? '';
    if (widget.attendance.clockIn != null) {
      _clockInController.text = _formatTime(widget.attendance.clockIn);
    }
    if (widget.attendance.clockOut != null) {
      _clockOutController.text = _formatTime(widget.attendance.clockOut);
    }
    if (_status == AttendanceStatus.present &&
        _clockInController.text.isEmpty) {
      _clockInController.text = _formatTime(DateTime.now());
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _clockInController.dispose();
    _clockOutController.dispose();
    _notesDictationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    widget.staff.name.isEmpty
                        ? '?'
                        : widget.staff.name[0].toUpperCase(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.staff.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.staff.role.name,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Status',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<AttendanceStatus>(
              initialValue: _status,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: AttendanceStatus.values
                  .where((s) => s != AttendanceStatus.notMarked)
                  .map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Row(
                    children: [
                      Text(status.emoji),
                      const SizedBox(width: 8),
                      Text(status.displayName),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _status = value!;
                  if (_status == AttendanceStatus.present &&
                      _clockInController.text.isEmpty) {
                    _clockInController.text = _formatTime(DateTime.now());
                  }
                });
              },
            ),
            const SizedBox(height: 16),
            if (_status == AttendanceStatus.present) ...[
              const Text(
                'Clock In',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _clockInController,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.access_time),
                    onPressed: () =>
                        _clockInController.text = _formatTime(DateTime.now()),
                  ),
                ),
                readOnly: true,
                onTap: () => _selectTime(_clockInController),
                validator: (value) {
                  if (_status == AttendanceStatus.present &&
                      (value == null || value.isEmpty)) {
                    return 'Clock In is required for Present status';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Clock Out',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _clockOutController,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.access_time),
                    onPressed: () =>
                        _clockOutController.text = _formatTime(DateTime.now()),
                  ),
                ),
                readOnly: true,
                onTap: () => _selectTime(_clockOutController),
              ),
              const SizedBox(height: 16),
            ],
            const Text(
              'Overtime',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              initialValue: _overtimeHours,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [0, 1, 2, 3, 4, 5].map((hours) {
                return DropdownMenuItem(
                  value: hours,
                  child: Text(hours == 0
                      ? 'None'
                      : '$hours Hour${hours > 1 ? "s" : ""}'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _overtimeHours = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            VoiceDictationFieldHeader(
              label: 'Notes',
              controller: _notesDictationController,
              compact: true,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saveAttendance,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectTime(TextEditingController controller) async {
    final now = DateTime.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: now.hour, minute: now.minute),
    );
    if (picked != null) {
      controller.text =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _saveAttendance() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final provider = context.read<AttendanceProvider>();

    try {
      final clockIn = _clockInController.text.isNotEmpty
          ? _parseTime(_clockInController.text, _selectedDate)
          : null;
      final clockOut = _clockOutController.text.isNotEmpty
          ? _parseTime(_clockOutController.text, _selectedDate)
          : null;

      final input = AttendanceUpsertInput(
        staffId: widget.staff.id,
        attendanceDate: _selectedDate,
        status: _status,
        clockIn: clockIn,
        clockOut: clockOut,
        overtimeHours: _overtimeHours,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (widget.attendance.id == 0) {
        await provider.createAttendance(input);
      } else {
        await provider.updateAttendance(widget.attendance.id, input);
      }

      if (!mounted) return;
      Navigator.pop(context);
      widget.onSave();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance saved successfully')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  DateTime? _parseTime(String timeStr, DateTime date) {
    final parts = timeStr.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }
}
