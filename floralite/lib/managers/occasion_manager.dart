import '../data/repositories/occasion_repository.dart';

class OccasionManager {
  OccasionManager(this._repository);

  final OccasionRepository _repository;

  Future<List<String>> relationshipMaster() =>
      _repository.listRelationshipMaster();

  Future<List<String>> occasionMaster() => _repository.listOccasionMaster();

  Future<OccasionContactRecord?> addOccasionContact({
    required int customerId,
    required String recipientName,
    required String relationship,
    required String occasion,
    required DateTime occasionDate,
    String recipientPhone = '',
    String company = '',
    String notes = '',
    bool reminderEnabled = true,
    String source = 'Manual',
  }) {
    if (recipientName.trim().isEmpty) {
      throw ArgumentError('Recipient name is required');
    }
    return _repository.createContact(
      customerId: customerId,
      recipientName: recipientName,
      relationship: relationship,
      occasion: occasion,
      occasionDate: occasionDate,
      recipientPhone: recipientPhone,
      company: company,
      notes: notes,
      reminderEnabled: reminderEnabled,
      source: source,
    );
  }

  Future<OccasionContactRecord?> editOccasionContact({
    required int id,
    required int customerId,
    required String recipientName,
    required String relationship,
    required String occasion,
    required DateTime occasionDate,
    String recipientPhone = '',
    String company = '',
    String notes = '',
    bool reminderEnabled = true,
    String source = 'Manual',
  }) {
    if (recipientName.trim().isEmpty) {
      throw ArgumentError('Recipient name is required');
    }
    return _repository.updateContact(
      id: id,
      customerId: customerId,
      recipientName: recipientName,
      relationship: relationship,
      occasion: occasion,
      occasionDate: occasionDate,
      recipientPhone: recipientPhone,
      company: company,
      notes: notes,
      reminderEnabled: reminderEnabled,
      source: source,
    );
  }

  Future<void> removeOccasionContact(int id) =>
      _repository.softDeleteContact(id);

  Future<List<OccasionContactRecord>> listContacts({
    String search = '',
    String filter = 'All',
    DateTime? specificDate,
  }) {
    return _repository.listContacts(search: search, filter: filter, specificDate: specificDate);
  }

  Future<OccasionScreenData> screenData({
    required DateTime today,
    String search = '',
    String filter = 'All',
    DateTime? specificDate,
  }) {
    return _repository.buildScreenData(
        today: today, search: search, filter: filter, specificDate: specificDate);
  }

  Future<OccasionDashboardSummary> dashboardSummary(DateTime today) {
    return _repository.getDashboardSummary(today);
  }

  Future<List<DateTime>> getReminderDatesInMonth(DateTime month) {
    return _repository.getReminderDatesInMonth(month);
  }

  Future<void> markDone({
    required String sourceType,
    required int sourceId,
    required DateTime occurrenceDate,
  }) {
    return _repository.markDone(
      sourceType: sourceType,
      sourceId: sourceId,
      occurrenceDate: occurrenceDate,
    );
  }

  Future<void> snoozeTomorrow({
    required String sourceType,
    required int sourceId,
    required DateTime occurrenceDate,
  }) {
    return _repository.snoozeTomorrow(
      sourceType: sourceType,
      sourceId: sourceId,
      occurrenceDate: occurrenceDate,
    );
  }

  Future<void> deleteManualReminder({
    required int contactId,
    required DateTime occurrenceDate,
  }) {
    return _repository.deleteManualReminder(
      contactId: contactId,
      occurrenceDate: occurrenceDate,
    );
  }

  Future<int?> findCustomerIdByNameOrPhone({
    required String customerName,
    required String mobile,
  }) {
    return _repository.findCustomerIdByNameOrPhone(
      customerName: customerName,
      mobile: mobile,
    );
  }

  Future<OccasionContactRecord?> findDuplicate({
    required int customerId,
    required String recipientName,
    required String occasion,
  }) {
    return _repository.getDuplicateContact(
      customerId: customerId,
      recipientName: recipientName,
      occasion: occasion,
    );
  }
}
