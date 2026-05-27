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

  const ProductsScreen({super.key, required this.section});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  static const int _pageSize = 10;
  int _currentPage = 1;

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

  String get _title {
    switch (widget.section) {
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
      case 'trending':
        return 'Most popular items';
      case 'listing':
        return 'Products you are selling';
      default:
        return 'Items close to you';
    }
  }

  List<Product> _filter(List<Product> products) {
    if (widget.section == 'trending') {
      return [...products]
        ..sort((a, b) => b.likesCount.compareTo(a.likesCount));
    } else if (widget.section == 'listing') {
      return products
          .where((element) => element.sellerId == authService.currentUser!.uid)
          .toList();
    }
    return products;
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
          onPressed: () => context.pop(),
        ),
        title: Column(
          children: [
            Text(
              _title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              _subtitle,
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
      body: StreamBuilder<List<Product>>(
        stream: ProductService().getAllProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final allFiltered = _filter(snapshot.data!);
          final visibleCount = (_currentPage * _pageSize).clamp(
            0,
            allFiltered.length,
          );
          final visible = allFiltered.sublist(0, visibleCount);
          final hasMore = visibleCount < allFiltered.length;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => GridProductCard(
                      product: visible[index],
                      userLat: _userLat,
                      userLong: _userLong,
                    ),
                    childCount: visible.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    mainAxisExtent: 240,
                  ),
                ),
              ),
              if (hasMore)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: ElevatedButton(
                        onPressed: () => setState(() => _currentPage++),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          "Load More",
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
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
