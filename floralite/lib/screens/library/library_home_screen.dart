import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/library_models.dart';
import '../../providers/library_provider.dart';

class LibraryHomeScreen extends StatefulWidget {
  const LibraryHomeScreen({super.key, this.initialTab});

  final LibraryTab? initialTab;

  @override
  State<LibraryHomeScreen> createState() => _LibraryHomeScreenState();
}

class _LibraryHomeScreenState extends State<LibraryHomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<LibraryProvider>();
      if (widget.initialTab != null) {
        provider.setTab(widget.initialTab!);
      }
      provider.init();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<LibraryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book_rounded, color: Color(0xFF2E7D32)),
            SizedBox(width: 8),
            Text(
              'Floraprise Library',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Library',
            onPressed: () => provider.init(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(116),
          child: Column(
            children: [
              // Search Input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: _getSearchHint(provider.activeTab),
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              _onSearch('', provider);
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  ),
                  onSubmitted: (val) => _onSearch(val, provider),
                ),
              ),

              // Module Tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  children: [
                    _buildTabChip(
                      label: 'Products',
                      icon: Icons.local_florist_rounded,
                      tab: LibraryTab.products,
                      current: provider.activeTab,
                      onTap: () => _selectTab(LibraryTab.products, provider),
                    ),
                    const SizedBox(width: 8),
                    _buildTabChip(
                      label: 'Recipes',
                      icon: Icons.receipt_long_rounded,
                      tab: LibraryTab.recipes,
                      current: provider.activeTab,
                      onTap: () => _selectTab(LibraryTab.recipes, provider),
                    ),
                    const SizedBox(width: 8),
                    _buildTabChip(
                      label: 'Design Gallery',
                      icon: Icons.palette_rounded,
                      tab: LibraryTab.designs,
                      current: provider.activeTab,
                      onTap: () => _selectTab(LibraryTab.designs, provider),
                    ),
                    const SizedBox(width: 8),
                    _buildTabChip(
                      label: 'Card Sentiments',
                      icon: Icons.card_giftcard_rounded,
                      tab: LibraryTab.cards,
                      current: provider.activeTab,
                      onTap: () => _selectTab(LibraryTab.cards, provider),
                    ),
                    const SizedBox(width: 8),
                    _buildTabChip(
                      label: 'Tutorials',
                      icon: Icons.school_rounded,
                      tab: LibraryTab.tutorials,
                      current: provider.activeTab,
                      onTap: () => _selectTab(LibraryTab.tutorials, provider),
                    ),
                    const SizedBox(width: 8),
                    _buildTabChip(
                      label: 'Festivals',
                      icon: Icons.celebration_rounded,
                      tab: LibraryTab.festivals,
                      current: provider.activeTab,
                      onTap: () => _selectTab(LibraryTab.festivals, provider),
                    ),
                    const SizedBox(width: 8),
                    _buildTabChip(
                      label: 'Wedding Dates',
                      icon: Icons.favorite_rounded,
                      tab: LibraryTab.weddingDates,
                      current: provider.activeTab,
                      onTap: () => _selectTab(LibraryTab.weddingDates, provider),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildTabBody(provider),
    );
  }

  void _selectTab(LibraryTab tab, LibraryProvider provider) {
    _searchController.clear();
    provider.setTab(tab);
  }

  void _onSearch(String query, LibraryProvider provider) {
    switch (provider.activeTab) {
      case LibraryTab.products:
        provider.searchProducts(query);
        break;
      case LibraryTab.recipes:
        provider.searchRecipes(query);
        break;
      case LibraryTab.designs:
        provider.searchDesigns(query);
        break;
      case LibraryTab.cards:
        provider.searchCards(query);
        break;
      case LibraryTab.tutorials:
        provider.searchTutorials(query);
        break;
      case LibraryTab.festivals:
        provider.searchFestivals(query);
        break;
      case LibraryTab.weddingDates:
        provider.searchWeddingDates(query);
        break;
    }
  }

  String _getSearchHint(LibraryTab tab) {
    switch (tab) {
      case LibraryTab.products:
        return 'Search flower stems, foliage, supplies...';
      case LibraryTab.recipes:
        return 'Search bouquet recipes, arrangements...';
      case LibraryTab.designs:
        return 'Search design styles, occasions, flowers...';
      case LibraryTab.cards:
        return 'Search greetings, sentiments, tones...';
      case LibraryTab.tutorials:
        return 'Search tutorials, techniques, care guides...';
      case LibraryTab.festivals:
        return 'Search festivals, holidays, flower demand...';
      case LibraryTab.weddingDates:
        return 'Search wedding muhurats, tithi, nakshatra...';
    }
  }

  Widget _buildTabChip({
    required String label,
    required IconData icon,
    required LibraryTab tab,
    required LibraryTab current,
    required VoidCallback onTap,
  }) {
    final isSelected = tab == current;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : const Color(0xFF2E7D32)),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selectedColor: const Color(0xFF2E7D32),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (_) => onTap(),
    );
  }

  Widget _buildTabBody(LibraryProvider provider) {
    if (provider.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text(provider.errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => provider.init(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    switch (provider.activeTab) {
      case LibraryTab.products:
        return _buildProductsView(provider);
      case LibraryTab.recipes:
        return _buildRecipesView(provider);
      case LibraryTab.designs:
        return _buildDesignsView(provider);
      case LibraryTab.cards:
        return _buildCardsView(provider);
      case LibraryTab.tutorials:
        return _buildTutorialsView(provider);
      case LibraryTab.festivals:
        return _buildFestivalsView(provider);
      case LibraryTab.weddingDates:
        return _buildWeddingDatesView(provider);
    }
  }

  // ================= Products View =================

  Widget _buildProductsView(LibraryProvider provider) {
    if (provider.products.isEmpty) {
      return const Center(child: Text('No library products found.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: provider.products.length,
      itemBuilder: (context, index) {
        final p = provider.products[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFE8F5E9),
              child: Icon(Icons.local_florist, color: Color(0xFF2E7D32)),
            ),
            title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${p.categoryName ?? "General"} • ${p.standardUnit} • SKU: ${p.standardSku ?? "Auto"}'),
            trailing: FilledButton.tonalIcon(
              icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
              label: const Text('Import'),
              onPressed: () => _handleImportProduct(provider, p),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleImportProduct(LibraryProvider provider, LibraryProduct product) async {
    final result = await provider.importProduct(product.id);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.alreadyImported ? Colors.orange : Colors.green,
      ),
    );
  }

  // ================= Recipes View =================

  Widget _buildRecipesView(LibraryProvider provider) {
    if (provider.recipes.isEmpty) {
      return const Center(child: Text('No library recipes found.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: provider.recipes.length,
      itemBuilder: (context, index) {
        final r = provider.recipes[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        r.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    FilledButton.tonalIcon(
                      icon: const Icon(Icons.download_rounded, size: 16),
                      label: const Text('Import Recipe'),
                      onPressed: () => _handleImportRecipe(provider, r),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  r.description ?? 'Standard florist arrangement recipe.',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Chip(
                      label: Text('Yield: ${r.yieldQuantity.toStringAsFixed(0)} ${r.yieldUnit ?? "Piece"}'),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    const SizedBox(width: 8),
                    if (r.itemCount > 0)
                      Chip(
                        label: Text('${r.itemCount} Components'),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleImportRecipe(LibraryProvider provider, LibraryRecipe recipe) async {
    final result = await provider.importRecipe(recipe.id);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.alreadyImported ? Colors.orange : Colors.green,
      ),
    );
  }

  // ================= Designs View =================

  Widget _buildDesignsView(LibraryProvider provider) {
    if (provider.designs.isEmpty) {
      return const Center(child: Text('No library designs found.'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.78,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: provider.designs.length,
      itemBuilder: (context, index) {
        final d = provider.designs[index];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  color: Colors.grey.shade200,
                  width: double.infinity,
                  child: d.imageUrl != null && d.imageUrl!.isNotEmpty
                      ? Image.network(d.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 40))
                      : const Icon(Icons.palette_rounded, size: 40, color: Color(0xFF2E7D32)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (d.occasion != null)
                      Text(
                        d.occasion!,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                      ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonal(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () => _handleImportDesign(provider, d),
                        child: const Text('Import Design', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleImportDesign(LibraryProvider provider, LibraryDesign design) async {
    final result = await provider.importDesign(design.id);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.alreadyImported ? Colors.orange : Colors.green,
      ),
    );
  }

  // ================= Cards View =================

  Widget _buildCardsView(LibraryProvider provider) {
    return Column(
      children: [
        // Occasion filter chips
        if (provider.cardOccasions.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: provider.selectedCardOccasion == null,
                  onSelected: (_) => provider.setCardFilters(occasion: null),
                ),
                ...provider.cardOccasions.map((o) => Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: ChoiceChip(
                        label: Text('${o.occasion} (${o.count})'),
                        selected: provider.selectedCardOccasion == o.occasion,
                        onSelected: (_) => provider.setCardFilters(occasion: o.occasion),
                      ),
                    )),
              ],
            ),
          ),

        Expanded(
          child: provider.cards.isEmpty
              ? const Center(child: Text('No card sentiments found.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: provider.cards.length,
                  itemBuilder: (context, index) {
                    final c = provider.cards[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  c.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                if (c.tone != null)
                                  Chip(
                                    label: Text(c.tone!),
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '"${c.content}"',
                              style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 14),
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.copy_rounded, size: 14),
                                label: const Text('Copy Message'),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: c.content));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Message copied to clipboard!'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ================= Tutorials View =================

  Widget _buildTutorialsView(LibraryProvider provider) {
    if (provider.tutorials.isEmpty) {
      return const Center(child: Text('No tutorials found.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: provider.tutorials.length,
      itemBuilder: (context, index) {
        final t = provider.tutorials[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFE8F5E9),
              child: Icon(Icons.menu_book_rounded, color: Color(0xFF2E7D32)),
            ),
            title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${t.summary ?? "Tutorial & Guide"} • ${t.difficultyLevel} • ${t.estimatedReadingMinutes ?? 5} min read'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _openTutorial(context, t),
          ),
        );
      },
    );
  }

  void _openTutorial(BuildContext context, LibraryTutorial tutorial) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(20.0),
          child: ListView(
            controller: scrollController,
            children: [
              Text(
                tutorial.title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Chip(label: Text(tutorial.difficultyLevel)),
                  const SizedBox(width: 8),
                  Chip(label: Text('${tutorial.estimatedReadingMinutes ?? 5} min read')),
                ],
              ),
              const Divider(height: 24),
              Text(
                tutorial.contentMarkdown,
                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= Festivals View =================

  Widget _buildFestivalsView(LibraryProvider provider) {
    final monthLabels = [
      'All',
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
      'Dec'
    ];

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: List.generate(13, (index) {
              final monthVal = index == 0 ? null : index;
              final isSelected = provider.selectedFestivalMonth == monthVal;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(monthLabels[index]),
                  selected: isSelected,
                  onSelected: (_) => provider.setFestivalMonth(monthVal),
                ),
              );
            }),
          ),
        ),
        Expanded(
          child: provider.festivals.isEmpty
              ? const Center(child: Text('No festivals found.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: provider.festivals.length,
                  itemBuilder: (context, index) {
                    final f = provider.festivals[index];
                    final formattedDate =
                        '${f.day} ${_monthName(f.month)} ${f.festivalDate.year > 2000 ? f.festivalDate.year : ""}';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const CircleAvatar(
                                  backgroundColor: Color(0xFFFFF3E0),
                                  child: Icon(Icons.celebration_rounded, color: Colors.orange),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        f.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        formattedDate.trim(),
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF2E7D32),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  icon: const Icon(Icons.alarm_add_rounded, size: 16),
                                  label: const Text('Create Reminder', style: TextStyle(fontSize: 12)),
                                  onPressed: () => _navigateToCreateReminder(
                                    context,
                                    occasion: f.name,
                                    date: DateTime(f.festivalDate.year, f.month, f.day),
                                    notes:
                                        'Festival: ${f.name}. Recommended flowers: ${f.flowerDemands ?? "General"}.',
                                  ),
                                ),
                              ],
                            ),
                            if (f.description != null && f.description!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                f.description!,
                                style: TextStyle(color: Colors.grey.shade800, fontSize: 13),
                              ),
                            ],
                            if (f.flowerDemands != null && f.flowerDemands!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  Chip(
                                    avatar: const Icon(Icons.local_florist, size: 14, color: Color(0xFF2E7D32)),
                                    label: Text(
                                      'Flowers: ${f.flowerDemands}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ================= Wedding Dates View =================

  Widget _buildWeddingDatesView(LibraryProvider provider) {
    final seasons = ['All', 'Winter', 'Spring', 'Summer', 'Post-Monsoon'];

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: seasons.map((s) {
              final seasonVal = s == 'All' ? null : s;
              final isSelected = provider.selectedWeddingSeason == seasonVal;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(s),
                  selected: isSelected,
                  onSelected: (_) => provider.setWeddingDateFilters(
                    season: seasonVal,
                    demandLevel: provider.selectedWeddingDemand,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: provider.weddingDates.isEmpty
              ? const Center(child: Text('No wedding muhurat dates found.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: provider.weddingDates.length,
                  itemBuilder: (context, index) {
                    final w = provider.weddingDates[index];
                    final formattedDate =
                        '${w.weddingDate.day} ${_monthName(w.weddingDate.month)} ${w.weddingDate.year}';
                    final demandIsHigh = w.demandLevel.toLowerCase().contains('high') ||
                        w.demandLevel.toLowerCase().contains('peak');

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const CircleAvatar(
                                  backgroundColor: Color(0xFFFCE4EC),
                                  child: Icon(Icons.favorite_rounded, color: Colors.pink),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        w.title,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        formattedDate,
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF2E7D32),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  icon: const Icon(Icons.alarm_add_rounded, size: 16),
                                  label: const Text('Create Reminder', style: TextStyle(fontSize: 12)),
                                  onPressed: () => _navigateToCreateReminder(
                                    context,
                                    occasion: 'Wedding / Vivah Muhurat',
                                    date: w.weddingDate,
                                    notes:
                                        '${w.title} • Tithi: ${w.tithi ?? "-"} • Nakshatra: ${w.nakshatra ?? "-"} • Season: ${w.season ?? "-"}.',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                if (w.tithi != null && w.tithi!.isNotEmpty)
                                  Chip(
                                    label: Text('Tithi: ${w.tithi}', style: const TextStyle(fontSize: 11)),
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                if (w.nakshatra != null && w.nakshatra!.isNotEmpty)
                                  Chip(
                                    label: Text('Nakshatra: ${w.nakshatra}', style: const TextStyle(fontSize: 11)),
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                if (w.season != null && w.season!.isNotEmpty)
                                  Chip(
                                    label: Text(w.season!, style: const TextStyle(fontSize: 11)),
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                Chip(
                                  avatar: Icon(
                                    Icons.trending_up_rounded,
                                    size: 14,
                                    color: demandIsHigh ? Colors.red : Colors.blue,
                                  ),
                                  label: Text(
                                    '${w.demandLevel} Demand',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: demandIsHigh ? Colors.red.shade900 : Colors.blue.shade900,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  backgroundColor: demandIsHigh ? Colors.red.shade50 : Colors.blue.shade50,
                                  padding: EdgeInsets.zero,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ],
                            ),
                            if (w.notes != null && w.notes!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                w.notes!,
                                style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _navigateToCreateReminder(
    BuildContext context, {
    required String occasion,
    required DateTime date,
    String? notes,
  }) {
    Navigator.of(context).pushNamed(
      '/reminders',
      arguments: {
        'autoOpenAdd': true,
        'occasion': occasion,
        'date': date,
        'notes': notes,
      },
    );
  }

  String _monthName(int month) {
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
      'Dec'
    ];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }
}

