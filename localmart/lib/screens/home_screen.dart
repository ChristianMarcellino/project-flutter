import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localmart/models/product.dart';
import 'package:localmart/services/notif_service.dart';
import 'package:localmart/services/product_service.dart';
import 'package:localmart/theme/app_theme.dart';
import 'package:localmart/widgets/grid_product_card.dart';
import 'package:localmart/widgets/product_card.dart';
import 'package:localmart/services/auth_service.dart';
import 'package:localmart/services/user_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProductService _productService = ProductService();
  String _locationName = "";
  double _userLat = 0.0;
  double _userLong = 0.0;
  String _avatar = "";

  List<Product> nearbyProducts(List<Product> products) {
    return [...products]..sort((a, b) {
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

  List<Product> trendingProducts(List<Product> products) {
    return [...products]..sort((a, b) => b.likesCount.compareTo(a.likesCount));
  }

  Future<void> _loadUser() async {
    final user = await UserService.getUser(authService.currentUser!.uid);

    final locationName = user?['locationName'] ?? '';
    final userLat = (user?['latitude'] ?? 0).toDouble();
    final userLong = (user?['longitude'] ?? 0).toDouble();
    final avatar = user?['avatar']?.toString() ?? "";

    if (mounted) {
      setState(() {
        _locationName = locationName;
        _userLat = userLat;
        _userLong = userLong;
        _avatar = avatar;
      });
    }
  }

  Future<void> _checkLocation() async {
    final user = authService.currentUser;
    if (user == null) return;

    final doc = await UserService.getUser(user.uid);
    if (doc == null) return;

    final location = doc["locationName"];
    if (location == null || location.toString().isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showLocationDialog(user.uid);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadUser();
    await _checkLocation();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = authService.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      body: StreamBuilder<List<Product>>(
        stream: _productService.getAllProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text("Error: ${snapshot.error}", style: AppTheme.body),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final allProducts = snapshot.data!;

          final filteredProducts = currentUserId == null
              ? allProducts
              : allProducts.where((p) => p.sellerId != currentUserId).toList();

          final nearby = nearbyProducts(filteredProducts).take(6).toList();
          final trending = trendingProducts(filteredProducts).take(6).toList();

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(context),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
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
                  height: 275,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    physics: const BouncingScrollPhysics(),
                    itemCount: nearby.length,
                    itemBuilder: (context, index) =>
                        ProductCard(product: nearby[index]),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
                  child: _buildSectionHeader(
                    context,
                    "Newest Products",
                    "Latest items added",
                    "trending",
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => GridProductCard(
                      product: trending[index],
                      userLat: _userLat,
                      userLong: _userLong,
                    ),
                    childCount: trending.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    mainAxisExtent: 245,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }

  void _showLocationDialog(String uid) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            "Complete Your Profile",
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          content: Text(
            "You haven't set your location yet. Please update it in your profile.",
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Later"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.push("/profile/$uid");
              },
              child: Text("Go to Profile"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final userId = authService.currentUser?.uid;

    return SliverAppBar(
      floating: true,
      backgroundColor: AppTheme.scaffoldBackground.withValues(alpha: 0.95),
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("LocalMart", style: AppTheme.h2),
          Row(
            children: [
              Icon(Icons.location_on, size: 13, color: AppTheme.primary),
              const SizedBox(width: 4),
              Text(_locationName, style: AppTheme.caption),
            ],
          ),
        ],
      ),
      actions: [
        if (userId != null)
          StreamBuilder<int>(
            stream: NotifService().getUnreadCount(userId),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;

              return IconButton(
                icon: Stack(
                  children: [
                    const Icon(Icons.notifications_outlined),
                    if (unreadCount > 0)
                      Positioned(
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unreadCount.toString(),
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: () => context.push('/notifications'),
              );
            },
          ),
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: CircleAvatar(
            backgroundColor: AppTheme.border,
            child: _avatar.isEmpty
                ? const Icon(Icons.person)
                : ClipOval(child: Image.memory(base64Decode(_avatar))),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push("/search"),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: AppTheme.textSecondary),
            const SizedBox(width: 12),
            Text("Search products...", style: AppTheme.body),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    String subtitle,
    String section,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTheme.h2),
            Text(subtitle, style: AppTheme.caption),
          ],
        ),
        TextButton(
          onPressed: () => context.push("/products", extra: section),
          child: Text("See All"),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(child: Text("No products found", style: AppTheme.body));
  }
}
