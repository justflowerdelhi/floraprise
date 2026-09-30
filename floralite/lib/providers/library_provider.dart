import 'package:flutter/foundation.dart';

import '../data/repositories/library_repository.dart';
import '../models/library_models.dart';

enum LibraryTab { products, recipes, designs, cards, tutorials, festivals, weddingDates }

class LibraryProvider extends ChangeNotifier {
  LibraryProvider({LibraryRepository? repository})
      : _repo = repository ?? LibraryRepository();

  final LibraryRepository _repo;

  LibraryTab _activeTab = LibraryTab.products;
  LibraryTab get activeTab => _activeTab;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isImporting = false;
  bool get isImporting => _isImporting;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  LibraryManifest? _manifest;
  LibraryManifest? get manifest => _manifest;

  // Categories
  List<LibraryCategoryTree> _categoryTree = [];
  List<LibraryCategoryTree> get categoryTree => _categoryTree;
  String? _selectedCategoryId;
  String? get selectedCategoryId => _selectedCategoryId;

  // Products
  List<LibraryProduct> _products = [];
  List<LibraryProduct> get products => _products;
  String _productSearch = '';
  String get productSearch => _productSearch;

  // Recipes
  List<LibraryRecipe> _recipes = [];
  List<LibraryRecipe> get recipes => _recipes;
  String _recipeSearch = '';
  String get recipeSearch => _recipeSearch;

  // Designs
  List<LibraryDesign> _designs = [];
  List<LibraryDesign> get designs => _designs;
  String _designSearch = '';
  String get designSearch => _designSearch;
  String? _selectedDesignOccasion;
  String? get selectedDesignOccasion => _selectedDesignOccasion;
  String? _selectedDesignStyle;
  String? get selectedDesignStyle => _selectedDesignStyle;

  // Cards
  List<LibraryCardTemplate> _cards = [];
  List<LibraryCardTemplate> get cards => _cards;
  List<LibraryCardOccasionSummary> _cardOccasions = [];
  List<LibraryCardOccasionSummary> get cardOccasions => _cardOccasions;
  String _cardSearch = '';
  String get cardSearch => _cardSearch;
  String? _selectedCardOccasion;
  String? get selectedCardOccasion => _selectedCardOccasion;
  String? _selectedCardTone;
  String? get selectedCardTone => _selectedCardTone;

  // Tutorials
  List<LibraryTutorial> _tutorials = [];
  List<LibraryTutorial> get tutorials => _tutorials;
  String _tutorialSearch = '';
  String get tutorialSearch => _tutorialSearch;
  String? _selectedDifficulty;
  String? get selectedDifficulty => _selectedDifficulty;

  // Festivals
  List<LibraryFestival> _festivals = [];
  List<LibraryFestival> get festivals => _festivals;
  String _festivalSearch = '';
  String get festivalSearch => _festivalSearch;
  int? _selectedFestivalMonth;
  int? get selectedFestivalMonth => _selectedFestivalMonth;

  // Wedding Dates
  List<LibraryWeddingDate> _weddingDates = [];
  List<LibraryWeddingDate> get weddingDates => _weddingDates;
  String _weddingDateSearch = '';
  String get weddingDateSearch => _weddingDateSearch;
  String? _selectedWeddingSeason;
  String? get selectedWeddingSeason => _selectedWeddingSeason;
  String? _selectedWeddingDemand;
  String? get selectedWeddingDemand => _selectedWeddingDemand;

  void setTab(LibraryTab tab) {
    _activeTab = tab;
    notifyListeners();
    _loadTabContent(tab);
  }

  Future<void> init() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _manifest = await _repo.getManifest();
      _categoryTree = await _repo.getCategoryTree();
      await _loadTabContent(_activeTab);
    } catch (e) {
      _errorMessage = 'Could not load library: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadTabContent(LibraryTab tab) async {
    switch (tab) {
      case LibraryTab.products:
        await searchProducts();
        break;
      case LibraryTab.recipes:
        await searchRecipes();
        break;
      case LibraryTab.designs:
        await searchDesigns();
        break;
      case LibraryTab.cards:
        await loadCardsAndOccasions();
        break;
      case LibraryTab.tutorials:
        await searchTutorials();
        break;
      case LibraryTab.festivals:
        await searchFestivals();
        break;
      case LibraryTab.weddingDates:
        await searchWeddingDates();
        break;
    }
  }

  void selectCategory(String? categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
    switch (_activeTab) {
      case LibraryTab.products:
        searchProducts();
        break;
      case LibraryTab.recipes:
        searchRecipes();
        break;
      case LibraryTab.designs:
        searchDesigns();
        break;
      case LibraryTab.cards:
        searchCards();
        break;
      case LibraryTab.tutorials:
        searchTutorials();
        break;
      case LibraryTab.festivals:
        searchFestivals();
        break;
      case LibraryTab.weddingDates:
        searchWeddingDates();
        break;
    }
  }

  // ================= Products =================

  Future<void> searchProducts([String? query]) async {
    if (query != null) _productSearch = query;
    _isLoading = true;
    notifyListeners();

    try {
      _products = await _repo.getProducts(
        search: _productSearch,
        categoryId: _selectedCategoryId,
      );
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load products: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<LibraryImportResult> importProduct(
    String id, {
    String? customSku,
    double? customRetailPrice,
    double? customCostPrice,
  }) async {
    _isImporting = true;
    notifyListeners();

    try {
      final result = await _repo.importProduct(
        id,
        customSku: customSku,
        customRetailPrice: customRetailPrice,
        customCostPrice: customCostPrice,
      );
      return result;
    } finally {
      _isImporting = false;
      notifyListeners();
    }
  }

  // ================= Recipes =================

  Future<void> searchRecipes([String? query]) async {
    if (query != null) _recipeSearch = query;
    _isLoading = true;
    notifyListeners();

    try {
      _recipes = await _repo.getRecipes(
        search: _recipeSearch,
        categoryId: _selectedCategoryId,
      );
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load recipes: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<LibraryImportResult> importRecipe(String id) async {
    _isImporting = true;
    notifyListeners();

    try {
      final result = await _repo.importRecipe(id);
      return result;
    } finally {
      _isImporting = false;
      notifyListeners();
    }
  }

  // ================= Designs =================

  void setDesignFilters({String? occasion, String? style}) {
    _selectedDesignOccasion = occasion;
    _selectedDesignStyle = style;
    notifyListeners();
    searchDesigns();
  }

  Future<void> searchDesigns([String? query]) async {
    if (query != null) _designSearch = query;
    _isLoading = true;
    notifyListeners();

    try {
      _designs = await _repo.getDesigns(
        search: _designSearch,
        categoryId: _selectedCategoryId,
        occasion: _selectedDesignOccasion,
        style: _selectedDesignStyle,
      );
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load designs: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<LibraryImportResult> importDesign(String id) async {
    _isImporting = true;
    notifyListeners();

    try {
      final result = await _repo.importDesign(id);
      return result;
    } finally {
      _isImporting = false;
      notifyListeners();
    }
  }

  // ================= Cards =================

  void setCardFilters({String? occasion, String? tone}) {
    _selectedCardOccasion = occasion;
    _selectedCardTone = tone;
    notifyListeners();
    searchCards();
  }

  Future<void> loadCardsAndOccasions() async {
    _isLoading = true;
    notifyListeners();

    try {
      _cardOccasions = await _repo.getCardOccasions();
      _cards = await _repo.getCards(
        search: _cardSearch,
        occasion: _selectedCardOccasion,
        tone: _selectedCardTone,
      );
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load card sentiments: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchCards([String? query]) async {
    if (query != null) _cardSearch = query;
    _isLoading = true;
    notifyListeners();

    try {
      _cards = await _repo.getCards(
        search: _cardSearch,
        occasion: _selectedCardOccasion,
        tone: _selectedCardTone,
      );
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to search card sentiments: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ================= Tutorials =================

  void setDifficultyFilter(String? difficulty) {
    _selectedDifficulty = difficulty;
    notifyListeners();
    searchTutorials();
  }

  Future<void> searchTutorials([String? query]) async {
    if (query != null) _tutorialSearch = query;
    _isLoading = true;
    notifyListeners();

    try {
      _tutorials = await _repo.getTutorials(
        search: _tutorialSearch,
        categoryId: _selectedCategoryId,
        difficultyLevel: _selectedDifficulty,
      );
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load tutorials: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ================= Festivals =================

  void setFestivalMonth(int? month) {
    _selectedFestivalMonth = month;
    notifyListeners();
    searchFestivals();
  }

  Future<void> searchFestivals([String? query]) async {
    if (query != null) _festivalSearch = query;
    _isLoading = true;
    notifyListeners();

    try {
      _festivals = await _repo.getFestivals(
        search: _festivalSearch,
        month: _selectedFestivalMonth,
      );
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load festivals: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ================= Wedding Dates =================

  void setWeddingDateFilters({String? season, String? demandLevel}) {
    _selectedWeddingSeason = season;
    _selectedWeddingDemand = demandLevel;
    notifyListeners();
    searchWeddingDates();
  }

  Future<void> searchWeddingDates([String? query]) async {
    if (query != null) _weddingDateSearch = query;
    _isLoading = true;
    notifyListeners();

    try {
      _weddingDates = await _repo.getWeddingDates(
        search: _weddingDateSearch,
        season: _selectedWeddingSeason,
        demandLevel: _selectedWeddingDemand,
      );
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load wedding dates: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

