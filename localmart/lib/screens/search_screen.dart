import 'package:flutter/material.dart';
import 'package:localmart/constants.dart';
import 'package:localmart/models/product.dart';
import 'package:localmart/services/auth_service.dart';
import 'package:localmart/services/product_service.dart';
import 'package:localmart/services/user_service.dart';
import 'package:localmart/theme/app_theme.dart';
import 'package:localmart/utils/format_utils.dart';
import 'package:localmart/widgets/grid_product_card.dart';
import 'package:go_router/go_router.dart';

class SearchScreen extends StatefulWidget {
  final bool showBack;

  const SearchScreen({super.key, this.showBack = false});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  String _query = '';
  String? _selectedCategory;

  double _minPrice = 0;
  double? _maxPrice;

  bool _filtersVisible = false;

  double _userLat = 0.0;
  double _userLong = 0.0;

  Future<void> _loadUser() async {
    final user = await UserService.getUser(authService.currentUser!.uid);
    final userLat = (user?['latitude'] ?? 0).toDouble();
    final userLong = (user?['longitude'] ?? 0).toDouble();

    if (mounted) {
      setState(() {
        _userLat = userLat;
        _userLong = userLong;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  bool _hasActiveFilter() {
    return _selectedCategory != null || _minPrice > 0 || _maxPrice != null;
  }

  List<Product> _applyFilters(List<Product> all) {
    return all.where((p) {
      final q = _query.toLowerCase();

      final matchesQuery =
          q.isEmpty ||
          p.title.toLowerCase().contains(q) ||
          p.sellerName.toLowerCase().contains(q) ||
          p.locationName.toLowerCase().contains(q);

      final matchesCategory =
          _selectedCategory == null || p.category == _selectedCategory;

      final matchesPrice =
          p.price >= _minPrice && (_maxPrice == null || p.price <= _maxPrice!);

      return matchesQuery && matchesCategory && matchesPrice;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(context),
            if (_filtersVisible) _buildFilterPanel(),
            _buildActiveFilters(),
            Expanded(
              child: StreamBuilder<List<Product>>(
                stream: ProductService().getAllProducts(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    );
                  }

                  final results = _applyFilters(snapshot.data ?? []);

                  if (_query.isEmpty && !_hasActiveFilter()) {
                    return _buildIdleState();
                  }

                  if (results.isEmpty) {
                    return _buildNoResults();
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    physics: const BouncingScrollPhysics(),
                    itemCount: results.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          mainAxisExtent: 240,
                        ),
                    itemBuilder: (context, index) => GridProductCard(
                      product: results[index],
                      userLat: _userLat,
                      userLong: _userLong,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.background,
      child: Row(
        children: [
          if (widget.showBack)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppTheme.textPrimary,
                  size: 18,
                ),
                onPressed: () => context.pop(),
              ),
            ),

          Expanded(
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _query = val),
                style: TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search products, seller, city...',
                  hintStyle: TextStyle(color: AppTheme.textSecondary),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: AppTheme.textSecondary,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          GestureDetector(
            onTap: () => setState(() {
              _filtersVisible = !_filtersVisible;
            }),
            child: Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: _filtersVisible ? AppTheme.primary : AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _filtersVisible ? AppTheme.primary : AppTheme.border,
                ),
              ),
              child: Icon(
                Icons.tune_rounded,
                color: _filtersVisible ? Colors.white : AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Category', style: AppTheme.h2.copyWith(fontSize: 16)),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: AppConstants.categories.map((cat) {
                final selected = _selectedCategory == cat;

                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedCategory = selected ? null : cat;
                  }),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.primary : AppTheme.background,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? AppTheme.primary : AppTheme.border,
                      ),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        color: selected ? Colors.white : AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Price Range', style: AppTheme.h2.copyWith(fontSize: 16)),
              Text(
                '${FormatUtils.formatPrice(_minPrice)} - ${_maxPrice == null ? 'Unlimited' : FormatUtils.formatPrice(_maxPrice!)}',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minPriceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Min Price',
                    filled: true,
                    fillColor: AppTheme.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _minPrice = double.tryParse(value) ?? 0;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _maxPriceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Max Price (Optional)',
                    filled: true,
                    fillColor: AppTheme.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _maxPrice = value.isEmpty ? null : double.tryParse(value);
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilters() {
    if (!_hasActiveFilter()) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        children: [
          if (_selectedCategory != null)
            _filterChip(
              _selectedCategory!,
              () => setState(() {
                _selectedCategory = null;
              }),
            ),
          if (_minPrice > 0 || _maxPrice != null)
            _filterChip(
              'Price Filter',
              () => setState(() {
                _minPrice = 0;
                _maxPrice = null;
                _minPriceController.clear();
                _maxPriceController.clear();
              }),
            ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, VoidCallback onRemove) {
    return Chip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
      deleteIcon: const Icon(Icons.close, size: 14),
      onDeleted: onRemove,
      backgroundColor: AppTheme.primaryLight,
      labelStyle: TextStyle(color: AppTheme.primary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.1)),
    );
  }

  Widget _buildIdleState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_rounded, size: 64, color: AppTheme.textSecondary),
          const SizedBox(height: 16),
          Text('Find what you need', style: AppTheme.h2),
          Text(
            'Try searching for title, seller, or city',
            style: AppTheme.body,
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: 16),
          Text('No results found', style: AppTheme.h2),
          Text('Try adjusting your filters', style: AppTheme.body),
        ],
      ),
    );
  }
}
