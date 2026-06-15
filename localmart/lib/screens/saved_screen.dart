import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localmart/models/product.dart';
import 'package:localmart/services/auth_service.dart';
import 'package:localmart/services/product_service.dart';
import 'package:localmart/services/user_service.dart';
import 'package:localmart/theme/app_theme.dart';
import 'package:localmart/widgets/grid_product_card.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
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
  Widget build(BuildContext context) {
    final user = authService.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: AppTheme.scaffoldBackground,
        body: Center(
          child: Text(
            'Please log in to see saved items',
            style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontSize: 14),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.scaffoldBackground,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Saved Items',
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
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

          final all = snapshot.data ?? [];
          final saved = all.where((p) => p.likedBy.contains(user.uid)).toList();

          if (saved.isEmpty) {
            return _buildEmptyState();
          }

          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            physics: const BouncingScrollPhysics(),
            itemCount: saved.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              mainAxisExtent: 245,
            ),
            itemBuilder: (context, index) => GridProductCard(
              product: saved[index],
              userLat: _userLat,
              userLong: _userLong,
            ),
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
            Icons.favorite_border_rounded,
            size: 64,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'Nothing saved yet',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Heart items to see them here',
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
