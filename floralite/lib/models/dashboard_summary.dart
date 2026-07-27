class DashboardSummary {
  final int todaySalesAmount;
  final int todayOrderCount;
  final int pendingOrders;
  final int preparingOrders;
  final int readyOrders;
  final int outForDeliveryOrders;
  final int todayDeliveryCount;
  final int todayPickupCount;
  final int todayTaskCount;
  final int lowStockItems;
  final int outOfStockItems;
  final int todayBirthdays;
  final int todayFollowUps;
  final int todayFestivalCount;
  final int todayPendingPayments;
  final int todayPurchaseListCount;
  final int activeAssociates;
  final int activeStaff;
  final int unmarkedAttendanceCount;
  final int todayExpenses;
  final List<LowStockItem> lowStockList;
  final List<DashboardScheduleItem> todaySchedule;

  const DashboardSummary({
    required this.todaySalesAmount,
    required this.todayOrderCount,
    required this.pendingOrders,
    required this.preparingOrders,
    required this.readyOrders,
    required this.outForDeliveryOrders,
    required this.todayDeliveryCount,
    required this.todayPickupCount,
    required this.todayTaskCount,
    required this.lowStockItems,
    required this.outOfStockItems,
    required this.todayBirthdays,
    required this.todayFollowUps,
    required this.todayFestivalCount,
    required this.todayPendingPayments,
    required this.todayPurchaseListCount,
    required this.activeAssociates,
    required this.activeStaff,
    required this.unmarkedAttendanceCount,
    required this.todayExpenses,
    required this.lowStockList,
    required this.todaySchedule,
  });

  static DashboardSummary empty() {
    return const DashboardSummary(
      todaySalesAmount: 0,
      todayOrderCount: 0,
      pendingOrders: 0,
      preparingOrders: 0,
      readyOrders: 0,
      outForDeliveryOrders: 0,
      todayDeliveryCount: 0,
      todayPickupCount: 0,
      todayTaskCount: 0,
      lowStockItems: 0,
      outOfStockItems: 0,
      todayBirthdays: 0,
      todayFollowUps: 0,
      todayFestivalCount: 0,
      todayPendingPayments: 0,
      todayPurchaseListCount: 0,
      activeAssociates: 0,
      activeStaff: 0,
      unmarkedAttendanceCount: 0,
      todayExpenses: 0,
      lowStockList: [],
      todaySchedule: [],
    );
  }
}

class DashboardScheduleItem {
  final DateTime scheduledAt;
  final String icon;
  final String type;
  final String title;
  final String route;

  const DashboardScheduleItem({
    required this.scheduledAt,
    required this.icon,
    required this.type,
    required this.title,
    required this.route,
  });
}

class LowStockItem {
  final int id;
  final String name;
  final String? barcode;
  final int currentQty;
  final int minQty;

  LowStockItem({
    required this.id,
    required this.name,
    this.barcode,
    required this.currentQty,
    required this.minQty,
  });

  factory LowStockItem.fromMap(Map<String, dynamic> map) {
    return LowStockItem(
      id: map['id'] as int,
      name: map['name'] as String,
      barcode: map['barcode'] as String?,
      currentQty: map['current_qty'] as int,
      minQty: map['min_qty'] as int,
    );
  }
}
