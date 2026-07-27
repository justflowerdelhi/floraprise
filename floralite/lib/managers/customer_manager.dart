import '../data/repositories/customer_repository.dart';

class CustomerManager {
  CustomerManager(this._customerRepository);

  final CustomerRepository _customerRepository;

  String normalizePhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length >= 10) {
      return digits.substring(digits.length - 10);
    }
    return digits;
  }

  Future<CustomerRecord?> lookupByPhone(String phone) async {
    final normalized = normalizePhone(phone);
    if (normalized.length != 10) {
      return null;
    }
    return _customerRepository.findByPhone(normalized);
  }

  Future<CustomerRecord?> ensureCustomer({
    required String phone,
    required String name,
    String birthdayMd = '',
    String anniversaryMd = '',
    String company = '',
    String department = '',
    String notes = '',
  }) async {
    final normalized = normalizePhone(phone);
    if (normalized.length != 10 || name.trim().isEmpty) {
      return null;
    }

    final existing = await _customerRepository.findByPhone(normalized);
    if (existing != null) {
      return existing;
    }

    return _customerRepository.create(
      phone: normalized,
      name: name.trim(),
      birthdayMd: birthdayMd,
      anniversaryMd: anniversaryMd,
      company: company,
      department: department,
      notes: notes,
    );
  }

  Future<int> getTodayBirthdayCount() {
    return _customerRepository.getTodayBirthdayCount();
  }

  Future<List<CustomerRecord>> getAllCustomers() async {
    return _customerRepository.getAll();
  }

  Future<List<CustomerRecord>> searchCustomers(String query) async {
    return _customerRepository.search(query);
  }

  Future<CustomerRecord?> getCustomerById(int id) async {
    return _customerRepository.getById(id);
  }

  Future<CustomerRecord> updateCustomer({
    required int id,
    required String phone,
    required String name,
    String birthdayMd = '',
    String anniversaryMd = '',
    String company = '',
    String department = '',
    String notes = '',
  }) async {
    final normalized = normalizePhone(phone);
    if (normalized.length != 10 || name.trim().isEmpty) {
      throw ArgumentError('Invalid phone or name');
    }
    return _customerRepository.update(
      id: id,
      phone: normalized,
      name: name.trim(),
      birthdayMd: birthdayMd,
      anniversaryMd: anniversaryMd,
      company: company,
      department: department,
      notes: notes,
    );
  }

  Future<void> deleteCustomer(int id) async {
    await _customerRepository.softDelete(id);
  }
}
