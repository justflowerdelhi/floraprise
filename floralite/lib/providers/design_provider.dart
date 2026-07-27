import 'package:flutter/foundation.dart';

import '../data/repositories/design_repository.dart';
import '../models/design.dart';

class DesignProvider extends ChangeNotifier {
  DesignProvider(this._designRepository);

  final DesignRepository _designRepository;

  List<DesignRecord> _designs = const [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String? _flowerFilter;
  String? _occasionFilter;
  String? _colorFilter;
  String? _statusFilter;
  bool? _favouriteFilter;
  int? _minPricePaise;
  int? _maxPricePaise;

  List<DesignRecord> get designs => _designs;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String? get flowerFilter => _flowerFilter;
  String? get occasionFilter => _occasionFilter;
  String? get colorFilter => _colorFilter;
  String? get statusFilter => _statusFilter;
  bool? get favouriteFilter => _favouriteFilter;
  int? get minPricePaise => _minPricePaise;
  int? get maxPricePaise => _maxPricePaise;

  Future<void> loadDesigns() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _designs = await _designRepository.listDesigns(
        query: _searchQuery,
        flower: _flowerFilter,
        occasion: _occasionFilter,
        color: _colorFilter,
        status: _statusFilter,
        favourite: _favouriteFilter,
        minPricePaise: _minPricePaise,
        maxPricePaise: _maxPricePaise,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await loadDesigns();
  }

  Future<void> setSearchQuery(String query) async {
    _searchQuery = query.trim();
    await loadDesigns();
  }

  Future<void> setFilters({
    String? flower,
    String? occasion,
    String? color,
    String? status,
    bool? favourite,
    int? minPricePaise,
    int? maxPricePaise,
  }) async {
    _flowerFilter = _normalizeFilter(flower);
    _occasionFilter = _normalizeFilter(occasion);
    _colorFilter = _normalizeFilter(color);
    _statusFilter = _normalizeStatusFilter(status);
    _favouriteFilter = favourite;
    _minPricePaise = minPricePaise;
    _maxPricePaise = maxPricePaise;
    await loadDesigns();
  }

  Future<void> clearFilters() async {
    _flowerFilter = null;
    _occasionFilter = null;
    _colorFilter = null;
    _statusFilter = null;
    _favouriteFilter = null;
    _minPricePaise = null;
    _maxPricePaise = null;
    await loadDesigns();
  }

  Future<bool> createDesign({
    required String? imagePath,
    required String description,
    required int? sellingPricePaise,
    String? flowers,
    String? occasion,
    String? color,
    String? collection,
    String? notes,
  }) async {
    _error = null;
    notifyListeners();

    try {
      await _designRepository.create(
        imagePath: imagePath,
        description: description,
        sellingPricePaise: sellingPricePaise,
        flowers: flowers,
        occasion: occasion,
        color: color,
        collection: collection,
        notes: notes,
      );
      await loadDesigns();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateDesign({
    required int id,
    required String description,
    required int? sellingPricePaise,
    String? flowers,
    String? occasion,
    String? color,
    String? collection,
    String? notes,
    String? replaceImagePath,
    bool removeImage = false,
  }) async {
    _error = null;
    notifyListeners();

    try {
      await _designRepository.update(
        id: id,
        description: description,
        sellingPricePaise: sellingPricePaise,
        flowers: flowers,
        occasion: occasion,
        color: color,
        collection: collection,
        notes: notes,
        replaceImagePath: replaceImagePath,
        removeImage: removeImage,
      );
      await loadDesigns();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteDesign(int id) async {
    _error = null;
    notifyListeners();

    try {
      await _designRepository.softDelete(id);
      await loadDesigns();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> toggleFavourite(DesignRecord design) async {
    _error = null;
    notifyListeners();

    try {
      await _designRepository.setFavourite(design.id, !design.isFavorite);
      await loadDesigns();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> bulkImportDesigns({
    required List<String> imagePaths,
    int? sellingPricePaise,
    String? flowers,
    String? occasion,
    String? color,
    String? collection,
    String? notes,
  }) async {
    _error = null;
    notifyListeners();

    try {
      await _designRepository.bulkCreate(
        imagePaths: imagePaths,
        sellingPricePaise: sellingPricePaise,
        flowers: flowers,
        occasion: occasion,
        color: color,
        collection: collection,
        notes: notes,
      );
      await loadDesigns();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  String? _normalizeFilter(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String? _normalizeStatusFilter(String? value) {
    if (value == null) return null;
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty || normalized == 'all') return null;
    if (normalized == 'draft') return 'needs_review';
    if (normalized == 'needs review') return 'needs_review';
    if (normalized == 'needs_review') return 'needs_review';
    if (normalized == 'ready') return 'ready';
    return null;
  }
}
