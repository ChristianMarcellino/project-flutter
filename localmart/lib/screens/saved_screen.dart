import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:localmart/models/product.dart';
import 'package:localmart/services/product_service.dart';
import 'package:localmart/theme/app_theme.dart';
import 'package:localmart/widgets/grid_product_card.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: Text("Please log in to see saved items", style: AppTheme.body),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        centerTitle: true,
        title: Text("Saved Items", style: AppTheme.h2),
      ),
      body: StreamBuilder<List<Product>>(
        stream: ProductService().getAllProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }

          final all = snapshot.data ?? [];
          final saved = all.where((p) => p.likedBy.contains(user.uid)).toList();

          if (saved.isEmpty) {
            return _buildEmptyState();
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            physics: const BouncingScrollPhysics(),
            itemCount: saved.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              mainAxisExtent: 240,
            ),
            itemBuilder: (context, index) => GridProductCard(product: saved[index]),
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
          Icon(Icons.favorite_border_rounded, size: 64, color: AppTheme.textSecondary),
          const SizedBox(height: 16),
          Text("Nothing saved yet", style: AppTheme.h2),
          Text("Heart items to see them here", style: AppTheme.body),
        ],
      ),
    );
  }
}
