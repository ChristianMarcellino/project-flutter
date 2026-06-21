import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localmart/constants.dart';
import 'package:localmart/models/product.dart';
import 'package:localmart/services/auth_service.dart';
import 'package:localmart/services/product_service.dart';
import 'package:localmart/services/user_service.dart';
import 'package:localmart/theme/app_theme.dart';
import 'package:localmart/utils/format_utils.dart';
import 'package:localmart/widgets/grid_product_card.dart';
import 'package:go_router/go_router.dart';

enum SearchMode { item, seller }

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
  SearchMode _searchMode = SearchMode.item;
  Timer? _searchDebounce;
  Timer? _priceDebounce;

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
    _searchDebounce?.cancel();
    _priceDebounce?.cancel();
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

  List<Map<String, dynamic>> sortUsersByDistance(
    List<Map<String, dynamic>> users,
  ) {
    if (_userLat == 0 && _userLong == 0) {
      return users;
    }
    return [...users]..sort((a, b) {
      final aLat = a['latitude'];
      final aLong = a['longitude'];

      final bLat = b['latitude'];
      final bLong = b['longitude'];

      if (aLat == null || aLong == null) return 1;
      if (bLat == null || bLong == null) return -1;

      final da = Geolocator.distanceBetween(
        _userLat,
        _userLong,
        (aLat as num).toDouble(),
        (aLong as num).toDouble(),
      );

      final db = Geolocator.distanceBetween(
        _userLat,
        _userLong,
        (bLat as num).toDouble(),
        (bLong as num).toDouble(),
      );

      return da.compareTo(db);
    });
  }

  Widget _buildProductResults() {
    return StreamBuilder<List<Product>>(
      stream: ProductService().getAllProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        }

        final results = _applyFilters(snapshot.data ?? []);

        if (_userLat != 0 || _userLong != 0) {
          results.sort((a, b) {
            final da = Geolocator.distanceBetween(
              _userLat,
              _userLong,
              a.latitude,
              a.longitude,
            );

            final db = Geolocator.distanceBetween(
              _userLat,
              _userLong,
              b.latitude,
              b.longitude,
            );

            return da.compareTo(db);
          });
        }
        if (_query.isEmpty && !_hasActiveFilter()) {
          return _buildIdleState();
        }

        if (results.isEmpty) return _buildNoResults();

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          itemCount: results.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            mainAxisExtent: 245,
          ),
          itemBuilder: (context, index) => GridProductCard(
            product: results[index],
            userLat: _userLat,
            userLong: _userLong,
          ),
        );
      },
    );
  }

  Widget _buildSellerResults() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: UserService.getAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        }

        final users = snapshot.data ?? [];
        final q = _query.toLowerCase();

        final currentUid = authService.currentUser?.uid;

        final filtered = users.where((u) {
          if (u['uid'] == currentUid) return false;

          final name = (u['name'] ?? '').toString().toLowerCase();
          final username = (u['username'] ?? '').toString().toLowerCase();
          final bio = (u['bio'] ?? '').toString().toLowerCase();
          final location = (u['locationName'] ?? '').toString().toLowerCase();

          return q.isEmpty ||
              name.contains(q) ||
              username.contains(q) ||
              bio.contains(q) ||
              location.contains(q);
        }).toList();
        final sortedUsers = sortUsersByDistance(filtered);
        if (filtered.isEmpty) return _buildNoResults();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedUsers.length,
          itemBuilder: (context, index) {
            final user = sortedUsers[index];
            String? distanceText;

            if (user['latitude'] != null && user['longitude'] != null) {
              final distanceMeters = Geolocator.distanceBetween(
                _userLat,
                _userLong,
                (user['latitude'] as num).toDouble(),
                (user['longitude'] as num).toDouble(),
              );

              distanceText = distanceMeters < 1000
                  ? "${distanceMeters.round()} m away"
                  : "${(distanceMeters / 1000).toStringAsFixed(1)} km away";
            }
            final avatar = user['avatar'] ?? '';
            final username = user['username'] ?? '';
            final bio = user['bio'] ?? '';
            final location = user['locationName'] ?? '';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.border.withValues(alpha: 0.3),
                ),
                boxShadow: AppTheme.isDark
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    context.push('/profile/${user['uid']}');
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: AppTheme.border.withValues(
                            alpha: 0.4,
                          ),
                          backgroundImage: avatar.isNotEmpty
                              ? MemoryImage(base64Decode(avatar))
                              : null,
                          child: avatar.isEmpty
                              ? Icon(
                                  Icons.person_outline_rounded,
                                  color: AppTheme.textSecondary,
                                )
                              : null,
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                username,
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: AppTheme.textPrimary,
                                ),
                              ),

                              if (location.isNotEmpty ||
                                  distanceText != null) ...[
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_rounded,
                                      size: 12,
                                      color: AppTheme.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        location.isEmpty
                                            ? "Location unavailable"
                                            : distanceText == null
                                            ? location
                                            : "$location • $distanceText",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          color: AppTheme.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],

                              if (bio.toString().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  bio,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        Icon(
                          Icons.chevron_right_rounded,
                          color: AppTheme.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      body: SafeArea(
        bottom: true,
        child: Column(
          children: [
            _buildSearchBar(context),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text("Items"),
                    selected: _searchMode == SearchMode.item,
                    onSelected: (_) =>
                        setState(() => _searchMode = SearchMode.item),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text("Sellers"),
                    selected: _searchMode == SearchMode.seller,
                    onSelected: (_) =>
                        setState(() => _searchMode = SearchMode.seller),
                  ),
                ],
              ),
            ),
            if (_searchMode == SearchMode.item && _filtersVisible)
              _buildFilterPanel(),

            if (_searchMode == SearchMode.item) _buildActiveFilters(),
            Expanded(
              child: _searchMode == SearchMode.item
                  ? _buildProductResults()
                  : _buildSellerResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final isDark = AppTheme.isDark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: AppTheme.scaffoldBackground,
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
              height: 52,
              decoration: BoxDecoration(
                color: AppTheme.surface.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(16),
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  if (_searchDebounce?.isActive ?? false) {
                    _searchDebounce!.cancel();
                  }

                  _searchDebounce = Timer(
                    const Duration(milliseconds: 400),
                    () {
                      if (!mounted) return;
                      setState(() {
                        _query = _searchController.text;
                      });
                    },
                  );
                },
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Search products, seller, city...',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textSecondary.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: AppTheme.textSecondary,
                    size: 22,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),

          if (_searchMode == SearchMode.item) ...[
            const SizedBox(width: 12),

            GestureDetector(
              onTap: () => setState(() {
                _filtersVisible = !_filtersVisible;
              }),
              child: Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  color: _filtersVisible
                      ? AppTheme.primary
                      : AppTheme.surface.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.tune_rounded,
                  color: _filtersVisible ? Colors.white : AppTheme.textPrimary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterPanel() {
    final isDark = AppTheme.isDark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      color: AppTheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Category',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
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
                      color: selected
                          ? AppTheme.primary
                          : (isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        cat,
                        style: GoogleFonts.plusJakartaSans(
                          color: selected ? Colors.white : AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
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
              Text(
                'Price Range',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                '${FormatUtils.formatPrice(_minPrice)} - ${_maxPrice == null ? 'Unlimited' : FormatUtils.formatPrice(_maxPrice!)}',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w800,
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
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                  ),
                  decoration: AppTheme.inputDecoration(hintText: 'Min Price'),
                  onChanged: (value) {
                    if (_priceDebounce?.isActive ?? false)
                      _priceDebounce!.cancel();

                    _priceDebounce = Timer(
                      const Duration(milliseconds: 400),
                      () {
                        setState(() {
                          _minPrice = double.tryParse(value) ?? 0;
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _maxPriceController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                  ),
                  decoration: AppTheme.inputDecoration(
                    hintText: 'Max Price (Optional)',
                  ),
                  onChanged: (value) {
                    if (_priceDebounce?.isActive ?? false)
                      _priceDebounce!.cancel();

                    _priceDebounce = Timer(
                      const Duration(milliseconds: 400),
                      () {
                        setState(() {
                          _maxPrice = value.isEmpty
                              ? null
                              : double.tryParse(value);
                        });
                      },
                    );
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      alignment: Alignment.centerLeft,
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
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
      deleteIcon: const Icon(Icons.close, size: 14),
      onDeleted: onRemove,
      backgroundColor: AppTheme.primaryLight,
      labelStyle: TextStyle(
        color: AppTheme.isDark ? const Color(0xFF4EDEA3) : AppTheme.primaryDark,
      ),
      deleteIconColor: AppTheme.isDark
          ? const Color(0xFF4EDEA3)
          : AppTheme.primaryDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.15)),
    );
  }

  Widget _buildIdleState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_rounded, size: 64, color: AppTheme.textSecondary),
          const SizedBox(height: 16),
          Text(
            'Find what you need',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try searching for title, seller, or city',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
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
          Text(
            'No results found',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try adjusting your query or filters',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
