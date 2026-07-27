import '../data/repositories/scheduler_repository.dart';
import '../data/repositories/attendance_repository.dart';
import '../data/repositories/expense_repository.dart';
import '../managers/associate_manager.dart';
import '../managers/customer_manager.dart';
import '../managers/inventory_manager.dart';
import '../managers/occasion_manager.dart';
import '../managers/order_manager.dart';
import '../managers/staff_manager.dart';
import '../models/dashboard_summary.dart';
import '../models/expense.dart';
import '../models/scheduler_task.dart';

class DashboardManager {
  DashboardManager(
    this._orderManager,
    this._inventoryManager,
    this._customerManager,
    this._schedulerRepository,
    this._occasionManager,
    this._associateManager,
    this._staffManager,
  );

  final OrderManager _orderManager;
  final InventoryManager _inventoryManager;
  final CustomerManager _customerManager;
  final SchedulerRepository _schedulerRepository;
  final OccasionManager _occasionManager;
  final AssociateManager _associateManager;
  final StaffManager _staffManager;
  AttendanceRepository? _attendanceRepository;
  ExpenseRepository? _expenseRepository;

  Future<DashboardSummary> getTodaySummary() async {
    final orderSummary = await _orderManager.getTodaySummary();
    final lowStockCount = await _inventoryManager.getLowStockCount();
    final outOfStockCount = await _inventoryManager.getOutOfStockCount();
    final lowStockItems = await _inventoryManager.getLowStockItems(limit: 5);
    final todayBirthdays = await _customerManager.getTodayBirthdayCount();
    final todayScheduledTasks =
        await _schedulerRepository.getTodayScheduledTasks(
      DateTime.now(),
    );
    final occasionSummary =
        await _occasionManager.dashboardSummary(DateTime.now());
    final activeAssociates = await _associateManager.getActiveAssociateCount();
    final activeStaff = await _staffManager.getActiveStaffCount();
    int unmarkedAttendanceCount = 0;
    try {
      _attendanceRepository ??= AttendanceRepository();
      unmarkedAttendanceCount =
          await _attendanceRepository!.getUnmarkedCount(DateTime.now());
    } catch (e) {
      unmarkedAttendanceCount = 0;
    }
    int todayExpenses = 0;
    try {
      _expenseRepository ??= ExpenseRepository();
      final cashExpenses = await _expenseRepository!
          .getTotalByPaymentMode(PaymentMode.cash, DateTime.now());
      final upiExpenses = await _expenseRepository!
          .getTotalByPaymentMode(PaymentMode.upi, DateTime.now());
      final cardExpenses = await _expenseRepository!
          .getTotalByPaymentMode(PaymentMode.card, DateTime.now());
      todayExpenses = cashExpenses + upiExpenses + cardExpenses;
    } catch (e) {
      todayExpenses = 0;
    }
    final todaySchedule = await _getTodaySchedule(DateTime.now());

    final lowStockList =
        lowStockItems.map((item) => LowStockItem.fromMap(item)).toList();

    return DashboardSummary(
      todaySalesAmount: orderSummary['todaySalesAmount'] ?? 0,
      todayOrderCount: orderSummary['todayOrderCount'] ?? 0,
      pendingOrders: orderSummary['pendingOrders'] ?? 0,
      preparingOrders: orderSummary['preparingOrders'] ?? 0,
      readyOrders: orderSummary['readyOrders'] ?? 0,
      outForDeliveryOrders: orderSummary['outForDeliveryOrders'] ?? 0,
      todayDeliveryCount: orderSummary['todayDeliveryCount'] ?? 0,
      todayPickupCount: orderSummary['todayPickupCount'] ?? 0,
      todayTaskCount: todayScheduledTasks.length,
      lowStockItems: lowStockCount,
      outOfStockItems: outOfStockCount,
      todayBirthdays: occasionSummary.birthdayCount > 0
          ? occasionSummary.birthdayCount
          : todayBirthdays,
      todayFollowUps: occasionSummary.todayFollowUps,
      todayFestivalCount: occasionSummary.festivalCount,
      todayPendingPayments: occasionSummary.pendingPayments,
      todayPurchaseListCount: 0,
      activeAssociates: activeAssociates,
      activeStaff: activeStaff,
      unmarkedAttendanceCount: unmarkedAttendanceCount,
      todayExpenses: todayExpenses,
      lowStockList: lowStockList,
      todaySchedule: todaySchedule,
    );
  }

  Future<List<DashboardScheduleItem>> _getTodaySchedule(DateTime now) async {
    final today = DateTime(now.year, now.month, now.day);
    final schedulerTasks = await _schedulerRepository.getOperationalQueue(
      selectedDate: today,
    );
    final occasionData = await _occasionManager.screenData(today: today);

    final items = <DashboardScheduleItem>[];

    for (final task in schedulerTasks) {
      if (!_isSameDay(task.scheduledAt, today)) continue;
      final header = task.linkedOrderId == null
          ? null
          : await _orderManager.getOrderDetailHeader(task.linkedOrderId!);
      items.add(
        DashboardScheduleItem(
          scheduledAt: task.scheduledAt,
          icon: _taskIcon(task.type),
          type: _taskTypeLabel(task.type, task.title),
          title: _taskTitle(task, header?.recipientName),
          route: '/scheduler',
        ),
      );
    }

    for (final followUp in occasionData.today) {
      if (followUp.isCompleted || followUp.sourceType == 'delivery') continue;
      items.add(
        DashboardScheduleItem(
          scheduledAt: _defaultFollowUpTime(today, followUp.sourceType),
          icon: _followUpIcon(followUp.sourceType, followUp.category),
          type: _followUpType(followUp.sourceType, followUp.category),
          title: followUp.title.trim().isEmpty
              ? followUp.subtitle
              : followUp.title,
          route: '/reminders',
        ),
      );
    }

    items.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return items;
  }

  bool _isSameDay(DateTime value, DateTime day) {
    return value.year == day.year &&
        value.month == day.month &&
        value.day == day.day;
  }

  String _taskIcon(TaskType type) {
    switch (type) {
      case TaskType.delivery:
        return '🚚';
      case TaskType.pickup:
        return '🛍';
      case TaskType.purchase:
        return '🛒';
      case TaskType.appointment:
      case TaskType.meeting:
        return '📅';
      case TaskType.reminder:
        return '🔔';
      case TaskType.personalTask:
        return '🎨';
    }
  }

  String _taskTypeLabel(TaskType type, String title) {
    final lower = title.toLowerCase();
    if (lower.contains('designer') || lower.contains('production')) {
      return 'Prepare';
    }
    switch (type) {
      case TaskType.delivery:
        return 'Delivery';
      case TaskType.pickup:
        return 'Pickup';
      case TaskType.purchase:
        return 'Purchase';
      case TaskType.appointment:
        return 'Appointment';
      case TaskType.meeting:
        return 'Meeting';
      case TaskType.reminder:
        return 'Reminder';
      case TaskType.personalTask:
        return 'Prepare';
    }
  }

  String _taskTitle(SchedulerTask task, String? orderRecipient) {
    final recipient = orderRecipient?.trim();
    if (recipient != null && recipient.isNotEmpty) return recipient;
    return task.title.trim().isEmpty ? 'Scheduled Task' : task.title.trim();
  }

  DateTime _defaultFollowUpTime(DateTime today, String sourceType) {
    if (sourceType == 'payment') {
      return DateTime(today.year, today.month, today.day, 17);
    }
    return DateTime(today.year, today.month, today.day, 14);
  }

  String _followUpIcon(String sourceType, String category) {
    if (sourceType == 'payment') return '💰';
    if (category.toLowerCase() == 'birthday') return '🎂';
    if (sourceType == 'festival') return '🎉';
    return '🔔';
  }

  String _followUpType(String sourceType, String category) {
    if (sourceType == 'payment') return 'Payment Follow-up';
    if (category.trim().isEmpty) return 'Reminder';
    return '$category Reminder';
  }
}
