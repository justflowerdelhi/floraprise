import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/voice_dictation_controller.dart';
import '../data/repositories/attendance_repository.dart';
import '../data/repositories/staff_repository.dart';
import '../models/attendance.dart';
import '../providers/attendance_provider.dart';
import '../services/speech_recognition_service.dart';
import '../widgets/voice_dictation_field_header.dart';

class AttendanceMarkScreen extends StatefulWidget {
  const AttendanceMarkScreen({super.key});

  @override
  State<AttendanceMarkScreen> createState() => _AttendanceMarkScreenState();
}

class _AttendanceMarkScreenState extends State<AttendanceMarkScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _clockInController = TextEditingController();
  final _clockOutController = TextEditingController();
  final _notesDictationController = VoiceDictationController(
    speechRecognition: SpeechRecognitionService(),
  );

  Staff? _staff;
  Attendance? _attendance;
  AttendanceStatus _status = AttendanceStatus.present;
  int _overtimeHours = 0;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _notesDictationController.bindController(_notesController);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    _clockInController.dispose();
    _clockOutController.dispose();
    _notesDictationController.dispose();
    super.dispose();
  }

  void _loadData() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Attendance) {
      _attendance = args;
      _status = _attendance!.status;
      _overtimeHours = _attendance!.overtimeHours;
      _selectedDate = _attendance!.attendanceDate;
      _notesController.text = _attendance!.notes ?? '';
      if (_attendance!.clockIn != null) {
        _clockInController.text = _formatTime(_attendance!.clockIn);
      }
      if (_attendance!.clockOut != null) {
        _clockOutController.text = _formatTime(_attendance!.clockOut);
      }
    } else if (args is Map<String, dynamic>) {
      _staff = args['staff'] as Staff;
      _attendance = args['attendance'] as Attendance?;
      if (_attendance != null) {
        _status = _attendance!.status;
        _overtimeHours = _attendance!.overtimeHours;
        _selectedDate = _attendance!.attendanceDate;
        _notesController.text = _attendance!.notes ?? '';
        if (_attendance!.clockIn != null) {
          _clockInController.text = _formatTime(_attendance!.clockIn);
        }
        if (_attendance!.clockOut != null) {
          _clockOutController.text = _formatTime(_attendance!.clockOut);
        }
      } else {
        _clockInController.text = _formatTime(DateTime.now());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(_attendance == null ? 'Mark Attendance' : 'Edit Attendance'),
        actions: [
          if (_attendance != null)
            IconButton(
              onPressed: () => _deleteAttendance(),
              icon: const Icon(Icons.delete),
              color: Colors.red,
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildDateField(),
              const SizedBox(height: 16),
              _buildStaffNameField(),
              const SizedBox(height: 16),
              _buildStatusDropdown(),
              const SizedBox(height: 16),
              if (_status == AttendanceStatus.present) ...[
                _buildClockInField(),
                const SizedBox(height: 16),
                _buildClockOutField(),
                const SizedBox(height: 16),
              ],
              _buildOvertimeDropdown(),
              const SizedBox(height: 16),
              _buildNotesField(),
              const SizedBox(height: 24),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: () => _selectDate(),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Date',
          prefixIcon: Icon(Icons.calendar_today),
          border: OutlineInputBorder(),
        ),
        child: Text(
          '${_selectedDate.day} ${_getMonthName(_selectedDate.month)} ${_selectedDate.year}',
        ),
      ),
    );
  }

  Widget _buildStaffNameField() {
    final staffName = _staff?.name ?? _attendance?.staffId.toString() ?? '';
    return TextFormField(
      initialValue: staffName,
      decoration: const InputDecoration(
        labelText: 'Staff Name',
        prefixIcon: Icon(Icons.person),
        border: OutlineInputBorder(),
      ),
      enabled: false,
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<AttendanceStatus>(
      initialValue: _status,
      decoration: const InputDecoration(
        labelText: 'Status',
        prefixIcon: Icon(Icons.check_circle),
        border: OutlineInputBorder(),
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
    );
  }

  Widget _buildClockInField() {
    return TextFormField(
      controller: _clockInController,
      decoration: InputDecoration(
        labelText: 'Clock In *',
        prefixIcon: const Icon(Icons.login),
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
    );
  }

  Widget _buildClockOutField() {
    return TextFormField(
      controller: _clockOutController,
      decoration: InputDecoration(
        labelText: 'Clock Out',
        prefixIcon: const Icon(Icons.logout),
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: const Icon(Icons.access_time),
          onPressed: () =>
              _clockOutController.text = _formatTime(DateTime.now()),
        ),
      ),
      readOnly: true,
      onTap: () => _selectTime(_clockOutController),
    );
  }

  Widget _buildOvertimeDropdown() {
    return DropdownButtonFormField<int>(
      initialValue: _overtimeHours,
      decoration: const InputDecoration(
        labelText: 'Overtime',
        prefixIcon: Icon(Icons.schedule),
        border: OutlineInputBorder(),
      ),
      items: [0, 1, 2, 3, 4, 5].map((hours) {
        return DropdownMenuItem(
          value: hours,
          child:
              Text(hours == 0 ? 'None' : '$hours Hour${hours > 1 ? "s" : ""}'),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _overtimeHours = value!;
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
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.note),
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return FilledButton(
      onPressed: _saveAttendance,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
      ),
      child: const Text('Save Attendance'),
    );
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
    }
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
    final staffId = _staff?.id ?? _attendance?.staffId ?? 0;

    if (staffId == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Staff not found')),
        );
      }
      return;
    }

    try {
      final clockIn = _clockInController.text.isNotEmpty
          ? _parseTime(_clockInController.text, _selectedDate)
          : null;
      final clockOut = _clockOutController.text.isNotEmpty
          ? _parseTime(_clockOutController.text, _selectedDate)
          : null;

      final input = AttendanceUpsertInput(
        staffId: staffId,
        attendanceDate: _selectedDate,
        status: _status,
        clockIn: clockIn,
        clockOut: clockOut,
        overtimeHours: _overtimeHours,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (_attendance == null || _attendance!.id == 0) {
        await provider.createAttendance(input);
      } else {
        await provider.updateAttendance(_attendance!.id, input);
      }

      if (!mounted) return;
      Navigator.pop(context);
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

  Future<void> _deleteAttendance() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Attendance'),
        content: const Text(
            'Are you sure you want to delete this attendance record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (confirmed == true && _attendance != null) {
      final provider = context.read<AttendanceProvider>();
      await provider.deleteAttendance(_attendance!.id);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attendance deleted')),
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
