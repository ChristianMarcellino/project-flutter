import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:localmart/models/product.dart';
import 'package:localmart/services/auth_service.dart';
import 'package:localmart/services/user_service.dart';
import 'package:localmart/services/product_service.dart';
import 'package:localmart/theme/app_theme.dart';
import 'package:localmart/widgets/grid_product_card.dart';
import 'package:shimmer/shimmer.dart';

class ProductsScreen extends StatefulWidget {
  final String section;
  final String? sellerId;

  const ProductsScreen({super.key, required this.section, this.sellerId});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _PaginationCache {
  final List<Product> items;
  final DocumentSnapshot? lastDoc;
  final bool hasMore;

  _PaginationCache({
    required this.items,
    required this.lastDoc,
    required this.hasMore,
  });
}

class _ProductsScreenState extends State<ProductsScreen> {
  static const int _pageSize = 6;
  static final Map<String, _PaginationCache> _cache = {};

  List<Product> _products = [];
  List<Product> _displayProducts = [];

  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;

  bool _isInitialLoading = true;
  bool _isLoadingMore = false;

  bool _scrollLock = false;

  double _userLat = 0.0;
  double _userLong = 0.0;

  String get _cacheKey => "${widget.section}_${widget.sellerId ?? 'all'}";

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _loadUser();
    await _loadInitial();
  }

  Future<void> _refreshProducts() async {
    _cache.remove(_cacheKey);

    _products.clear();
    _displayProducts.clear();

    _lastDoc = null;
    _hasMore = true;

    await _loadInitial();
  }

  Future<void> _loadUser() async {
    final user = await UserService.getUser(authService.currentUser!.uid);

    if (!mounted) return;

    _userLat = (user?['latitude'] ?? 0).toDouble();
    _userLong = (user?['longitude'] ?? 0).toDouble();

    _recomputeDisplay();
  }

  Query _baseQuery() {
    Query q = ProductService.productsRef
        .orderBy('sellerId')
        .orderBy('createdAt', descending: true);

    final currentUser = authService.currentUser?.uid;

    if (widget.section == 'seller') {
      if (widget.sellerId != null) {
        q = q.where('sellerId', isEqualTo: widget.sellerId);
      }
      return q;
    }

    if (currentUser != null) {
      q = q.where('sellerId', isNotEqualTo: currentUser);
    }

    return q;
  }

  Future<void> _loadInitial() async {
    final cached = _cache[_cacheKey];

    if (cached != null) {
      _products = cached.items;
      _lastDoc = cached.lastDoc;
      _hasMore = cached.hasMore;

      if (mounted) {
        setState(() => _isInitialLoading = false);
      }

      _recomputeDisplay();
      return;
    }

    final snapshot = await _baseQuery().limit(_pageSize).get();

    final items = snapshot.docs
        .map((d) => Product.fromMap(d.data() as Map<String, dynamic>, d.id))
        .toList();

    _products = items;
    _lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
    _hasMore = snapshot.docs.length == _pageSize;

    _cache[_cacheKey] = _PaginationCache(
      items: _products,
      lastDoc: _lastDoc,
      hasMore: _hasMore,
    );

    if (!mounted) return;

    setState(() => _isInitialLoading = false);

    _recomputeDisplay();
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _lastDoc == null) return;

    setState(() => _isLoadingMore = true);

    final snapshot = await _baseQuery()
        .startAfterDocument(_lastDoc!)
        .limit(_pageSize)
        .get();

    final newItems = snapshot.docs
        .map((d) => Product.fromMap(d.data() as Map<String, dynamic>, d.id))
        .toList();

    _products = [..._products, ...newItems];

    _lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : _lastDoc;
    _hasMore = snapshot.docs.length == _pageSize;

    _cache[_cacheKey] = _PaginationCache(
      items: _products,
      lastDoc: _lastDoc,
      hasMore: _hasMore,
    );

    if (!mounted) return;

    setState(() => _isLoadingMore = false);

    _recomputeDisplay();
  }

  void _recomputeDisplay() {
    final list = [..._products];

    if (widget.section == 'trending') {
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else if (widget.section != 'seller') {
      list.sort((a, b) {
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

    if (!mounted) return;

    setState(() {
      _displayProducts = list;
    });
  }

  String get _title {
    switch (widget.section) {
      case 'seller':
        return 'Seller Listings';
      case 'trending':
        return 'Newest Products';
      default:
        return 'Nearby Products';
    }
  }

  String get _subtitle {
    switch (widget.section) {
      case 'seller':
        return 'Products from this seller';
      case 'trending':
        return 'Newest products available';
      default:
        return 'Items close to you';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark;

    final shimmerBase = isDark ? const Color(0xFF1E293B) : Colors.grey.shade300;

    final shimmerHighlight = isDark
        ? const Color(0xFF334155)
        : Colors.grey.shade100;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          color: AppTheme.textPrimary,
          onPressed: () => context.pop(),
        ),
        title: Column(
          children: [
            Text(_title, style: AppTheme.h2),
            Text(_subtitle, style: AppTheme.caption),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _refreshProducts();
        },
        color: AppTheme.primary,
        child: NotificationListener<ScrollNotification>(
          onNotification: (scroll) {
            if (_scrollLock) return false;

            if (scroll.metrics.pixels >= scroll.metrics.maxScrollExtent - 300) {
              _scrollLock = true;

              _loadMore().whenComplete(() {
                Future.delayed(const Duration(milliseconds: 400), () {
                  _scrollLock = false;
                });
              });
            }

            return false;
          },
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              if (_isInitialLoading)
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (_, __) => _shimmer(shimmerBase, shimmerHighlight),
                      childCount: 6,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          mainAxisExtent: 240,
                        ),
                  ),
                )
              else if (_displayProducts.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Text("No products found", style: AppTheme.body),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final product = _displayProducts[index];

                      return GridProductCard(
                        product: product,
                        userLat: _userLat,
                        userLong: _userLong,
                      );
                    }, childCount: _displayProducts.length),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          mainAxisExtent: 240,
                        ),
                  ),
                ),
              if (_isLoadingMore)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shimmer(Color base, Color highlight) {
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Container(
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
