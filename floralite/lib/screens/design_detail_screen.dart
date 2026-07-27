import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class DesignDetailScreen extends StatefulWidget {
  final String designId;
  final String occasion;
  final String price;
  final String image;
  final String flower;
  final String color;
  final String status;
  final bool isFavorite;
  final int photoCount;

  const DesignDetailScreen({
    super.key,
    required this.designId,
    required this.occasion,
    required this.price,
    required this.image,
    required this.flower,
    required this.color,
    this.status = 'needs_review',
    required this.isFavorite,
    required this.photoCount,
  });

  @override
  State<DesignDetailScreen> createState() => _DesignDetailScreenState();
}

class _DesignDetailScreenState extends State<DesignDetailScreen> {
  late bool _isFavorite;
  int _currentPhotoIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.isFavorite;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final l10n = AppLocalizations.of(context)!;
    final normalizedStatus = _normalizeStatus(widget.status);
    final isReady = normalizedStatus == 'ready';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildPhotoGallery(colorScheme),
            ),
            actions: [
              IconButton(
                icon:
                    Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
                color: _isFavorite ? Colors.red : Colors.white,
                onPressed: () {
                  setState(() => _isFavorite = !_isFavorite);
                },
              ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {},
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {},
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
                  PopupMenuItem(
                      value: 'duplicate', child: Text(l10n.duplicate)),
                  PopupMenuItem(value: 'print', child: Text(l10n.print)),
                  PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
                ],
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomInset),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.designId,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              widget.occasion,
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isReady
                                  ? Colors.green.shade700
                                  : Colors.orange.shade700,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isReady ? 'Ready' : 'Needs Review',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        widget.price,
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Cost: ₹${(int.parse(widget.price.replaceAll('₹', '').replaceAll(',', '')) * 0.6).toInt()}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildInfoSection(
                      'Flowers', [widget.flower, 'Baby Breath', 'Eucalyptus']),
                  const SizedBox(height: 16),
                  _buildInfoSection('Colors', [widget.color, 'Green']),
                  const SizedBox(height: 16),
                  _buildTagsSection(),
                  const SizedBox(height: 16),
                  _buildNotesSection(),
                  const SizedBox(height: 24),
                  _buildQRCodeSection(),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.edit),
                          label: Text(l10n.edit),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.content_copy),
                          label: Text(l10n.duplicate),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.print),
                          label: Text(l10n.print),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGallery(ColorScheme colorScheme) {
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() => _currentPhotoIndex = index);
          },
          itemCount: widget.photoCount,
          itemBuilder: (context, index) {
            return Container(
              color: colorScheme.primaryContainer,
              child: Center(
                child: Text(
                  widget.image,
                  style: const TextStyle(fontSize: 120),
                ),
              ),
            );
          },
        ),
        if (widget.photoCount > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.photoCount,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index == _currentPhotoIndex
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(item),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTagsSection() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tags',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(label: Text(l10n.wedding)),
            Chip(label: Text(l10n.premium)),
            Chip(label: Text(l10n.popular)),
            Chip(label: Text(l10n.seasonal)),
          ],
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notes',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Best for evening events. Requires 2 hours preparation time. Keep refrigerated until delivery.',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQRCodeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'QR Code',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Center(
            child: Icon(
              Icons.qr_code_2,
              size: 80,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}

String _normalizeStatus(String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized == 'ready') return 'ready';
  if (normalized == 'needs review') return 'needs_review';
  if (normalized == 'needs_review') return 'needs_review';
  if (normalized == 'draft') return 'needs_review';
  return 'needs_review';
}
