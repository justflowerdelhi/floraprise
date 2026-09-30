import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/voice_dictation_controller.dart';
import '../l10n/app_localizations.dart';
import '../models/scheduler_task.dart';
import '../providers/scheduler_provider.dart';
import '../services/speech_recognition_service.dart';
import '../services/web_notification/web_notification_service.dart';
import '../services/web_notification/web_scheduler_reminder_service.dart';
import '../widgets/common_widgets.dart';
import '../widgets/voice_dictation_field_header.dart';

class SchedulerScreen extends StatefulWidget {
  const SchedulerScreen({super.key});

  @override
  State<SchedulerScreen> createState() => _SchedulerScreenState();
}

class _SchedulerScreenState extends State<SchedulerScreen> {
  final TextEditingController _searchController = TextEditingController();
  WebNotificationPermission _webNotificationPermission =
      WebNotificationPermission.unsupported;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _webNotificationPermission = WebNotificationService.instance.permission;
      // Start or refresh Web Scheduler Reminder Service
      WebSchedulerReminderService.instance.start();
    }
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

  Future<void> _requestWebNotificationPermission() async {
    final granted = await WebNotificationService.instance.requestPermission();
    if (!mounted) return;
    setState(() {
      _webNotificationPermission = WebNotificationService.instance.permission;
    });
    if (granted) {
      WebSchedulerReminderService.instance.checkDueTasks();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Browser notifications enabled for scheduled tasks.')),
      );
    }
  }

  Widget _buildWebNotificationBanner(ColorScheme colorScheme) {
    if (!kIsWeb) return const SizedBox.shrink();

    if (_webNotificationPermission == WebNotificationPermission.defaultPermission) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.notifications_active_outlined, color: colorScheme.primary, size: 20),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Enable browser notifications to receive audible alerts for due tasks.',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonal(
              onPressed: _requestWebNotificationPermission,
              child: const Text('Enable'),
            ),
          ],
        ),
      );
    }

    if (_webNotificationPermission == WebNotificationPermission.denied) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFCD34D)),
        ),
        child: const Row(
          children: [
            Icon(Icons.notifications_off_outlined, color: Color(0xFFB45309), size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Browser notifications are blocked. Please allow notifications for Floraprise in Chrome site settings.',
                style: TextStyle(fontSize: 13, color: Color(0xFF92400E)),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
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
        actions: [
          if (kIsWeb && _webNotificationPermission == WebNotificationPermission.granted)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Tooltip(
                message: 'Browser notifications active',
                child: Icon(Icons.notifications_active, color: Color(0xFF15803D), size: 20),
              ),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildDateHeader(context, colorScheme),
            _buildWebNotificationBanner(colorScheme),
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
    DateTime selectedDate =
        (existing?.scheduledAt ?? provider.selectedDate).toLocal();
    bool useTime = existing != null;
    TimeOfDay selectedTime = existing == null
        ? const TimeOfDay(hour: 9, minute: 0)
        : TimeOfDay.fromDateTime(existing.scheduledAt.toLocal());
    TaskPriority priority =
        existing?.priority.normalized ?? TaskPriority.normal;
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
                      initialValue: priority.normalized,
                      decoration: const InputDecoration(labelText: 'Priority'),
                      items: TaskPriorityX.userFacingValues
                          .map(
                            (p) => DropdownMenuItem(
                              value: p,
                              child: Text(p.displayLabel),
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

                    final messenger = ScaffoldMessenger.of(this.context);
                    final nav = Navigator.of(dialogContext);

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

                    if (ok) {
                      nav.pop(true);
                      return;
                    }

                    if (mounted) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            provider.error ?? 'Could not save task.',
                          ),
                        ),
                      );
                    }
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
    final provider = context.read<SchedulerProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final currentNavigator = Navigator.of(context);

    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.85,
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
                if (task.linkedOrderId != null ||
                    (task.cloudLinkedOrderId != null &&
                        task.cloudLinkedOrderId!.trim().isNotEmpty))
                  ListTile(
                    leading:
                        const Icon(Icons.receipt_long_rounded, color: Colors.teal),
                    title: const Text('View Order Details'),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      currentNavigator.pushNamed(
                        '/order-detail',
                        arguments: {
                          'orderId': task.linkedOrderId ?? -1,
                          'cloudOrderId': task.cloudLinkedOrderId,
                        },
                      );
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Edit Task'),
                  onTap: taskId == null
                      ? null
                      : () async {
                          Navigator.pop(sheetContext);
                          await _showEditTaskDialog(task);
                        },
                ),
                ListTile(
                  leading: const Icon(Icons.check_circle),
                  title: const Text('Mark Complete'),
                  onTap: taskId == null
                      ? null
                      : () async {
                          Navigator.pop(sheetContext);
                          final ok = await provider.markTaskCompleted(taskId);
                          if (!mounted) return;
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(ok
                                  ? 'Task marked as completed.'
                                  : 'Could not complete task.'),
                            ),
                          );
                        },
                ),
                if (task.status == TaskStatus.pending)
                  ListTile(
                    leading: const Icon(Icons.play_arrow),
                    title: const Text('Mark In Progress'),
                    onTap: taskId == null
                        ? null
                        : () async {
                            Navigator.pop(sheetContext);
                            final ok = await provider.markTaskInProgress(taskId);
                            if (!mounted) return;
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(ok
                                    ? 'Task marked in progress.'
                                    : 'Could not update task.'),
                              ),
                            );
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
                            Navigator.pop(sheetContext);
                            final ok = await provider.snoozeTask(taskId, const Duration(minutes: 5));
                            if (!mounted) return;
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(ok
                                    ? 'Task snoozed for 5 minutes.'
                                    : 'Could not snooze task.'),
                              ),
                            );
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
                            Navigator.pop(sheetContext);
                            final ok = await provider.snoozeTask(taskId, const Duration(minutes: 10));
                            if (!mounted) return;
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(ok
                                    ? 'Task snoozed for 10 minutes.'
                                    : 'Could not snooze task.'),
                              ),
                            );
                          },
                  ),
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Delete Task'),
                  onTap: taskId == null
                      ? null
                      : () async {
                          Navigator.pop(sheetContext);
                          final ok = await provider.deleteTask(taskId);
                          if (!mounted) return;
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                  ok ? 'Task deleted.' : 'Could not delete task.'),
                            ),
                          );
                        },
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
    final la = a.toLocal();
    final lb = b.toLocal();
    return la.year == lb.year && la.month == lb.month && la.day == lb.day;
  }

  String _formatTime(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour == 0
        ? 12
        : (local.hour > 12 ? local.hour - 12 : local.hour);
    final minute = local.minute.toString().padLeft(2, '0');
    final meridiem = local.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $meridiem';
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    return '${local.day}/${local.month}/${local.year} ${_formatTime(local)}';
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
    switch (priority.normalized) {
      case TaskPriority.urgent:
        return Colors.red;
      case TaskPriority.normal:
        return Colors.blue;
      default:
        return Colors.blue;
    }
  }

  String _buildSubtitle(SchedulerTask task) {
    final pieces = <String>[];
    if (task.priority.normalized == TaskPriority.urgent) {
      pieces.add('🔥 URGENT');
    }
    pieces.add(task.type.name);
    pieces.add(task.status.name);
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
