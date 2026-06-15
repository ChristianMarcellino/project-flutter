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
          final nearby = nearbyProducts(allProducts).take(6).toList();
          final trending = trendingProducts(allProducts).take(6).toList();

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
                    "Trending Now",
                    "Most popular this week",
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
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
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
              child: Text(
                "Later",
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.push("/profile/$uid");
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
              ),
              child: Text(
                "Go to Profile",
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
              ),
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
      centerTitle: false,

      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "LocalMart",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.primary,
              letterSpacing: -0.5,
            ),
          ),
          Row(
            children: [
              Icon(Icons.location_on, size: 13, color: AppTheme.primary),
              const SizedBox(width: 4),
              Text(
                _locationName,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
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

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined),
                      color: AppTheme.textPrimary,
                      onPressed: () {
                        context.push('/notifications');
                      },
                    ),

                    if (unreadCount > 0)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),

        Padding(
          padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: _buildAvatarWidget(40),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarWidget(double size) {
    if (_avatar.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.border.withValues(alpha: 0.5),
        ),
        child: Icon(
          Icons.person_outline_rounded,
          size: size * 0.5,
          color: AppTheme.textSecondary,
        ),
      );
    }
    return ClipOval(
      child: Image.memory(
        base64Decode(_avatar),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.border.withValues(alpha: 0.5),
          ),
          child: Icon(
            Icons.person_outline_rounded,
            size: size * 0.5,
            color: AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final isDark = AppTheme.isDark;
    return GestureDetector(
      onTap: () => context.push("/search"),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        child: Row(
          children: [
            Icon(Icons.search_rounded, color: AppTheme.textSecondary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Search electronics, fashion, home...",
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textSecondary.withValues(alpha: 0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.tune_rounded, color: AppTheme.primary, size: 20),
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
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: () => context.push("/products", extra: section),
          style: TextButton.styleFrom(
            backgroundColor: AppTheme.primaryLight,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: const StadiumBorder(),
          ),
          child: Text(
            "See All",
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.isDark
                  ? const Color(0xFF4EDEA3)
                  : AppTheme.primaryDark,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.storefront_outlined,
            size: 64,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            "No products found",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Be the first to list something nearby!",
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
