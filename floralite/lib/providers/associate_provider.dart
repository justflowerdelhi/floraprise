import 'package:flutter/foundation.dart';
import '../data/repositories/associate_repository.dart';
import '../managers/associate_manager.dart';
import '../services/business_data_event_bus.dart';

enum AssociateSort {
  businessNameAsc,
  cityAsc,
  recentlyAdded,
}

class AssociateProvider extends ChangeNotifier {
  AssociateProvider(this._associateManager, [this._businessDataEvents]);

  final AssociateManager _associateManager;
  final BusinessDataEventBus? _businessDataEvents;

  List<AssociateRecord> _associates = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  AssociateType? _typeFilter;
  bool _showActive = true;
  bool _showInactive = false;
  AssociateSort _sort = AssociateSort.businessNameAsc;

  List<AssociateRecord> get associates => _filteredAssociates;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  AssociateType? get typeFilter => _typeFilter;
  bool get showActive => _showActive;
  bool get showInactive => _showInactive;
  AssociateSort get sort => _sort;

  List<AssociateRecord> get _filteredAssociates {
    var filtered = _associates;

    // Apply search
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((associate) {
        final businessName = associate.businessName.toLowerCase();
        final contactPerson = associate.contactPerson?.toLowerCase() ?? '';
        final phone = associate.phone;
        final city = associate.city.toLowerCase();
        final query = _searchQuery.toLowerCase();
        return businessName.contains(query) ||
            contactPerson.contains(query) ||
            phone.contains(query) ||
            city.contains(query);
      }).toList();
    }

    // Apply type filter
    if (_typeFilter != null) {
      filtered = filtered.where((associate) {
        return associate.types.contains(_typeFilter);
      }).toList();
    }

    // Apply active/inactive filter
    if (_showActive && !_showInactive) {
      filtered = filtered.where((a) => a.isActive).toList();
    } else if (!_showActive && _showInactive) {
      filtered = filtered.where((a) => !a.isActive).toList();
    }

    // Apply sort
    switch (_sort) {
      case AssociateSort.businessNameAsc:
        filtered.sort((a, b) => a.businessName.compareTo(b.businessName));
        break;
      case AssociateSort.cityAsc:
        filtered.sort((a, b) => a.city.compareTo(b.city));
        break;
      case AssociateSort.recentlyAdded:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    return filtered;
  }

  Future<void> loadAssociates() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _associates = await _associateManager.getAllAssociates();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setSearchQuery(String query) async {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> setTypeFilter(AssociateType? type) async {
    _typeFilter = type;
    notifyListeners();
  }

  Future<void> setStatusFilters({
    required bool showActive,
    required bool showInactive,
  }) async {
    _showActive = showActive;
    _showInactive = showInactive;
    notifyListeners();
  }

  Future<void> setSort(AssociateSort sortOption) async {
    _sort = sortOption;
    notifyListeners();
  }

  Future<void> refresh() async {
    await loadAssociates();
  }

  Future<void> createAssociate(AssociateUpsertInput input) async {
    try {
      await _associateManager.createAssociate(input);
      await loadAssociates();
      _businessDataEvents?.publish(source: BusinessDataChangeSource.supplier);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateAssociate(int id, AssociateUpsertInput input) async {
    try {
      await _associateManager.updateAssociate(id, input);
      await loadAssociates();
      _businessDataEvents?.publish(source: BusinessDataChangeSource.supplier);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deactivateAssociate(int id) async {
    try {
      await _associateManager.deactivateAssociate(id);
      await loadAssociates();
      _businessDataEvents?.publish(source: BusinessDataChangeSource.supplier);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> reactivateAssociate(int id) async {
    try {
      await _associateManager.reactivateAssociate(id);
      await loadAssociates();
      _businessDataEvents?.publish(source: BusinessDataChangeSource.supplier);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteAssociate(int id) async {
    try {
      await _associateManager.deleteAssociate(id);
      await loadAssociates();
      _businessDataEvents?.publish(source: BusinessDataChangeSource.supplier);
    } catch (e) {
      rethrow;
    }
  }

  Future<int> getActiveCount() async {
    return _associateManager.getActiveAssociateCount();
  }
}
