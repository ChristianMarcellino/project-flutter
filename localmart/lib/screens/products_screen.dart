import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:localmart/models/product.dart';
import 'package:localmart/services/auth_service.dart';
import 'package:localmart/services/user_service.dart';
import 'package:localmart/services/product_service.dart';
import 'package:localmart/theme/app_theme.dart';
import 'package:localmart/widgets/grid_product_card.dart';

class ProductsScreen extends StatefulWidget {
  final String section;
  final String? sellerId;

  const ProductsScreen({super.key, required this.section, this.sellerId});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  static const int _pageSize = 6;
  List<Product> _products = [];
  DocumentSnapshot? _lastDoc;
  bool _isLoadingMore = false;
  bool _hasMore = true;

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

  Future<void> _loadInitial() async {
    Query query = ProductService.productsRef
        .orderBy('createdAt', descending: true)
        .limit(_pageSize);

    if (widget.section == 'seller' && widget.sellerId != null) {
      query = query.where('sellerId', isEqualTo: widget.sellerId);
    }

    final snapshot = await query.get();

    final items = snapshot.docs.map((doc) {
      return Product.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }).toList();

    setState(() {
      _products = items;
      _lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
      _hasMore = snapshot.docs.length == _pageSize;
    });
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _lastDoc == null) return;

    setState(() => _isLoadingMore = true);

    Query query = ProductService.productsRef
        .orderBy('createdAt', descending: true)
        .startAfterDocument(_lastDoc!)
        .limit(_pageSize);

    if (widget.section == 'seller' && widget.sellerId != null) {
      query = query.where('sellerId', isEqualTo: widget.sellerId);
    }

    final snapshot = await query.get();

    final items = snapshot.docs.map((doc) {
      return Product.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }).toList();

    setState(() {
      _products.addAll(items);
      _lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : _lastDoc;
      _hasMore = snapshot.docs.length == _pageSize;
      _isLoadingMore = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadInitial();
  }

  String get _title {
    switch (widget.section) {
      case 'seller':
        return 'Seller Listings';

      case 'trending':
        return 'Trending Deals';

      case 'listing':
        return 'My Active Listings';

      default:
        return 'Nearby Products';
    }
  }

  String get _subtitle {
    switch (widget.section) {
      case 'seller':
        return 'Products from this seller';

      case 'trending':
        return 'Most popular items';

      case 'listing':
        return 'Products you are selling';

      default:
        return 'Items close to you';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppTheme.textPrimary,
            size: 18,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        title: Column(
          children: [
            Text(
              _title,
              style: AppTheme.h2.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              _subtitle,
              style: AppTheme.caption.copyWith(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (scroll) {
          if (scroll.metrics.pixels >= scroll.metrics.maxScrollExtent - 300) {
            _loadMore();
          }
          return false;
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            if (_products.isEmpty)
              SliverFillRemaining(child: _buildEmptyState())
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final product = _products[index];

                    return GridProductCard(
                      product: product,
                      userLat: _userLat,
                      userLong: _userLong,
                    );
                  }, childCount: _products.length),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: 16),
          Text("No items available", style: AppTheme.h2),
          Text("Check back later for new updates", style: AppTheme.body),
        ],
      ),
    );
  }
}
