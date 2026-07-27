import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/voice_dictation_controller.dart';
import '../l10n/app_localizations.dart';
import '../models/scheduler_task.dart';
import '../providers/scheduler_provider.dart';
import '../services/speech_recognition_service.dart';
import '../widgets/common_widgets.dart';
import '../widgets/voice_dictation_field_header.dart';

class SchedulerScreen extends StatefulWidget {
  const SchedulerScreen({super.key});

  @override
  State<SchedulerScreen> createState() => _SchedulerScreenState();
}

class _SchedulerScreenState extends State<SchedulerScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      final focusTodayScheduledTasks = args is Map<String, dynamic> &&
          args['focus'] == 'todayScheduledTasks';
      if (focusTodayScheduledTasks) {
        context.read<SchedulerProvider>().loadTodayScheduledTasks();
        return;
      }
      context.read<SchedulerProvider>().loadOperationalQueue();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.scheduler),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildDateHeader(context, colorScheme),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  context.read<SchedulerProvider>().setSearchQuery(value);
                },
                decoration: InputDecoration(
                  hintText: 'Search task, order, customer',
                  prefixIcon: const Icon(Icons.search_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  isDense: true,
                ),
              ),
            ),
            Expanded(
              child: Consumer<SchedulerProvider>(
                builder: (context, provider, _) {
                  final tasks = provider.queueTasks;

                  if (provider.isLoading && tasks.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (provider.error != null && tasks.isEmpty) {
                    return ListView(
                      padding:
                          EdgeInsets.fromLTRB(16, 16, 16, 96 + bottomInset),
                      children: [
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Could not load tasks',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 8),
                              Text(provider.error!),
                              const SizedBox(height: 12),
                              FilledButton(
                                onPressed: () {
                                  provider.loadOperationalQueue();
                                },
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  if (tasks.isEmpty) {
                    return ListView(
                      padding:
                          EdgeInsets.fromLTRB(16, 16, 16, 96 + bottomInset),
                      children: [
                        AppCard(
                          child: Text(l10n.noTasksForToday),
                        ),
                      ],
                    );
                  }

                  return ListView.separated(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 96 + bottomInset),
                    itemCount: tasks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return TimelineCard(
                        time: _formatTime(task.scheduledAt),
                        title: task.title,
                        subtitle: _buildSubtitle(task),
                        icon: _iconForType(task.type),
                        color: _colorForPriority(task.priority),
                        onTap: () => _showTaskActions(task),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTaskDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
    );
  }

  Future<void> _showAddTaskDialog() async {
    final saved = await _showTaskDialog();
    if (!mounted || saved != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Task saved.')),
    );
  }

  Future<void> _showEditTaskDialog(SchedulerTask task) async {
    final saved = await _showTaskDialog(existing: task);
    if (!mounted || saved != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Task updated.')),
    );
  }

  Future<bool?> _showTaskDialog({SchedulerTask? existing}) async {
    final provider = context.read<SchedulerProvider>();
    final titleController = TextEditingController(text: existing?.title ?? '');
    final notesController = TextEditingController(text: existing?.notes ?? '');
    final notesDictationController = VoiceDictationController(
      speechRecognition: SpeechRecognitionService(),
    );
    notesDictationController.bindController(notesController);
    DateTime selectedDate = existing?.scheduledAt ?? provider.selectedDate;
    bool useTime = existing != null;
    TimeOfDay selectedTime = existing == null
        ? const TimeOfDay(hour: 9, minute: 0)
        : TimeOfDay.fromDateTime(existing.scheduledAt);
    TaskPriority priority = existing?.priority ?? TaskPriority.normal;
    bool requiresAlarm = existing?.requiresAlarm ?? false;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(existing == null ? 'Add Task' : 'Edit Task'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today),
                      title: Text(
                        '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 365),
                          ),
                          lastDate: DateTime.now().add(
                            const Duration(days: 3650),
                          ),
                        );
                        if (picked == null) return;
                        setDialogState(() => selectedDate = picked);
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: useTime,
                      onChanged: (value) {
                        setDialogState(() => useTime = value);
                      },
                      title: const Text('Add Time (optional)'),
                    ),
                    if (useTime)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.access_time),
                        title: Text(
                          '${selectedTime.hour}:${selectedTime.minute.toString().padLeft(2, '0')}',
                        ),
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: selectedTime,
                          );
                          if (picked == null) return;
                          setDialogState(() => selectedTime = picked);
                        },
                      ),
                    DropdownButtonFormField<TaskPriority>(
                      initialValue: priority,
                      decoration: const InputDecoration(labelText: 'Priority'),
                      items: TaskPriority.values
                          .map(
                            (p) => DropdownMenuItem(
                              value: p,
                              child: Text(_priorityLabel(p)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() {
                          priority = value;
                          if (priority != TaskPriority.urgent) {
                            requiresAlarm = false;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: requiresAlarm,
                      onChanged: priority == TaskPriority.urgent
                          ? (value) {
                              setDialogState(() => requiresAlarm = value);
                            }
                          : null,
                      title: const Text('Critical Alarm Repeat'),
                      subtitle: Text(
                        priority == TaskPriority.urgent
                            ? 'Repeat reminder every 5 minutes until completed or snoozed.'
                            : 'Set priority to Urgent to enable critical repeating alarm.',
                      ),
                    ),
                    const SizedBox(height: 12),
                    VoiceDictationFieldHeader(
                      label: 'Notes',
                      controller: notesDictationController,
                      compact: true,
                    ),
                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final title = titleController.text.trim();
                    if (title.isEmpty) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(content: Text('Please enter title.')),
                      );
                      return;
                    }

                    final scheduledAt = DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                      useTime ? selectedTime.hour : 9,
                      useTime ? selectedTime.minute : 0,
                    );

                    final ok = existing == null
                        ? await provider.createTask(
                            title: title,
                            scheduledAt: scheduledAt,
                            priority: priority,
                            requiresAlarm: requiresAlarm,
                            notes: notesController.text.trim(),
                          )
                        : await provider.editTask(
                            taskId: existing.id!,
                            title: title,
                            scheduledAt: scheduledAt,
                            priority: priority,
                            requiresAlarm: requiresAlarm,
                            notes: notesController.text.trim(),
                          );

                    if (!mounted) return;
                    if (ok) {
                      titleController.clear();
                      notesController.clear();
                      if (!dialogContext.mounted) return;
                      Navigator.of(dialogContext, rootNavigator: true)
                          .pop(true);
                      return;
                    }

                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(
                        content: Text(
                          provider.error ?? 'Could not save task.',
                        ),
                      ),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
    notesDictationController.dispose();
    return result;
  }

  Future<void> _showTaskActions(SchedulerTask task) async {
    final taskId = task.id;
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    task.title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    [
                      'Scheduled ${_formatDateTime(task.scheduledAt)}',
                      if (task.nextReminderAt != null)
                        'Next reminder ${_formatDateTime(task.nextReminderAt!)}',
                      'Alarm ${task.requiresAlarm ? 'On' : 'Off'}',
                    ].join(' • '),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (task.isOverdue)
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading:
                        Icon(Icons.warning_amber_rounded, color: Colors.red),
                    title: Text('Overdue'),
                  ),
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Edit Task'),
                  onTap: taskId == null
                      ? null
                      : () async {
                          Navigator.pop(context);
                          await _showEditTaskDialog(task);
                        },
                ),
                ListTile(
                  leading: const Icon(Icons.check_circle),
                  title: const Text('Mark Complete'),
                  onTap: taskId == null
                      ? null
                      : () async {
                          Navigator.pop(context);
                          await context
                              .read<SchedulerProvider>()
                              .markTaskCompleted(taskId);
                        },
                ),
                if (task.status == TaskStatus.pending)
                  ListTile(
                    leading: const Icon(Icons.play_arrow),
                    title: const Text('Mark In Progress'),
                    onTap: taskId == null
                        ? null
                        : () async {
                            Navigator.pop(context);
                            await context
                                .read<SchedulerProvider>()
                                .markTaskInProgress(taskId);
                          },
                  ),
                if (task.status != TaskStatus.completed &&
                    task.status != TaskStatus.cancelled)
                  ListTile(
                    leading: const Icon(Icons.snooze),
                    title: const Text('Snooze 5 min'),
                    onTap: taskId == null
                        ? null
                        : () async {
                            Navigator.pop(context);
                            await context
                                .read<SchedulerProvider>()
                                .snoozeTask(taskId, const Duration(minutes: 5));
                          },
                  ),
                if (task.status != TaskStatus.completed &&
                    task.status != TaskStatus.cancelled)
                  ListTile(
                    leading: const Icon(Icons.snooze_outlined),
                    title: const Text('Snooze 10 min'),
                    onTap: taskId == null
                        ? null
                        : () async {
                            Navigator.pop(context);
                            await context.read<SchedulerProvider>().snoozeTask(
                                taskId, const Duration(minutes: 10));
                          },
                  ),
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Delete Task'),
                  onTap: taskId == null
                      ? null
                      : () async {
                          Navigator.pop(context);
                          await context
                              .read<SchedulerProvider>()
                              .deleteTask(taskId);
                        },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _priorityLabel(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.normal:
        return 'Normal';
      case TaskPriority.high:
        return 'High';
      case TaskPriority.urgent:
        return 'Urgent';
    }
  }

  Widget _buildDateHeader(BuildContext context, ColorScheme colorScheme) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final l10n = AppLocalizations.of(context)!;
    final selectedDate = context.watch<SchedulerProvider>().selectedDate;
    final chipDates = List<DateTime>.generate(
      7,
      (index) => selectedDate.add(Duration(days: index - 2)),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () =>
                    context.read<SchedulerProvider>().previousDay(),
              ),
              Expanded(
                child: Text(
                  _formatHeaderDate(selectedDate, l10n),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => context.read<SchedulerProvider>().nextDay(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: textScale > 1.1 ? 4 : 8,
            runSpacing: 8,
            children: chipDates.map((date) {
              final isSelected = _isSameDay(selectedDate, date);
              return GestureDetector(
                onTap: () => context
                    .read<SchedulerProvider>()
                    .loadOperationalQueue(date: date),
                child: _buildDayChip(
                  _weekdayShort(date.weekday, l10n),
                  '${date.day}',
                  isSelected,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _formatHeaderDate(DateTime date, AppLocalizations l10n) {
    final monthNames = [
      l10n.january,
      l10n.february,
      l10n.march,
      l10n.april,
      l10n.may,
      l10n.june,
      l10n.july,
      l10n.august,
      l10n.september,
      l10n.october,
      l10n.november,
      l10n.december,
    ];
    return '${monthNames[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _weekdayShort(int weekday, AppLocalizations l10n) {
    final names = [
      l10n.mon,
      l10n.tue,
      l10n.wed,
      l10n.thu,
      l10n.fri,
      l10n.sat,
      l10n.sun,
    ];
    return names[weekday - 1];
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatTime(DateTime value) {
    final hour =
        value.hour == 0 ? 12 : (value.hour > 12 ? value.hour - 12 : value.hour);
    final minute = value.minute.toString().padLeft(2, '0');
    final meridiem = value.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $meridiem';
  }

  String _formatDateTime(DateTime value) {
    return '${value.day}/${value.month}/${value.year} ${_formatTime(value)}';
  }

  IconData _iconForType(TaskType type) {
    switch (type) {
      case TaskType.delivery:
        return Icons.delivery_dining;
      case TaskType.pickup:
        return Icons.shopping_bag;
      case TaskType.appointment:
        return Icons.person;
      case TaskType.meeting:
        return Icons.groups;
      case TaskType.purchase:
        return Icons.shopping_cart;
      case TaskType.reminder:
        return Icons.alarm;
      case TaskType.personalTask:
        return Icons.task_alt;
    }
  }

  Color _colorForPriority(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.urgent:
        return Colors.red;
      case TaskPriority.high:
        return Colors.orange;
      case TaskPriority.normal:
        return Colors.blue;
      case TaskPriority.low:
        return Colors.green;
    }
  }

  String _buildSubtitle(SchedulerTask task) {
    final pieces = <String>[
      task.type.name,
      task.status.name,
    ];
    if (task.linkedOrderId != null) {
      pieces.add('Order #${task.linkedOrderId}');
    }
    if (task.notes != null && task.notes!.trim().isNotEmpty) {
      pieces.add(task.notes!.trim());
    }
    return pieces.join(' • ');
  }

  Widget _buildDayChip(String day, String date, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            day,
            style: TextStyle(
              fontSize: 11,
              color: isSelected ? Colors.grey.shade700 : Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            date,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.black : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
