import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:localmart/models/product.dart';
import 'package:localmart/services/product_service.dart';
import 'package:localmart/theme/app_theme.dart';
import 'package:localmart/widgets/grid_product_card.dart';
import 'package:localmart/widgets/product_card.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final ProductService _productService = ProductService();

  List<Product> nearbyProducts(List<Product> products) {
    return products;
  }

  List<Product> trendingProducts(List<Product> products) {
    return [...products]..sort((a, b) => b.likesCount.compareTo(a.likesCount));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: StreamBuilder<List<Product>>(
        stream: _productService.getAllProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: AppTheme.body));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final allProducts = snapshot.data!;
          final nearby = nearbyProducts(allProducts).take(6).toList();
          final trending = trendingProducts(allProducts).take(6).toList();

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(context),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSearchBar(context),
                      const SizedBox(height: 24),
                      _buildSectionHeader(
                        context,
                        "Nearby Listings",
                        "Items close to you",
                        "nearby",
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 280,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    physics: const BouncingScrollPhysics(),
                    itemCount: nearby.length,
                    itemBuilder: (context, index) => ProductCard(product: nearby[index]),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
                  child: _buildSectionHeader(
                    context,
                    "Trending Now",
                    "Most popular this week",
                    "trending",
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => GridProductCard(product: trending[index]),
                    childCount: trending.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    mainAxisExtent: 240,
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

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      floating: true,
      backgroundColor: AppTheme.background,
      elevation: 0,
      centerTitle: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("LocalMart", style: AppTheme.h1),
          Row(
            children: [
              Icon(Icons.location_on, size: 12, color: AppTheme.primary),
              const SizedBox(width: 4),
              Text("Jakarta, Indonesia", style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ],
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.border),
            ),
            child: IconButton(
              icon: Icon(Icons.notifications_none_rounded, color: AppTheme.textPrimary),
              onPressed: () {},
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push("/search"),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded, color: AppTheme.textSecondary),
            const SizedBox(width: 12),
            Text("Search electronics, fashion...", style: TextStyle(color: AppTheme.textSecondary)),
            const Spacer(),
            Icon(Icons.tune_rounded, color: AppTheme.primary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, String subtitle, String section) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTheme.h2),
            Text(subtitle, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ],
        ),
        TextButton(
          onPressed: () => context.push("/products", extra: section),
          style: TextButton.styleFrom(
            backgroundColor: AppTheme.primaryLight,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text("See All", style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.storefront_rounded, size: 64, color: AppTheme.textSecondary),
          const SizedBox(height: 16),
          Text("No products found", style: AppTheme.h2),
          Text("Be the first to list something!", style: AppTheme.body),
        ],
      ),
    );
  }
}