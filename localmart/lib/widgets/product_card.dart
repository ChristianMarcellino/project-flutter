import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:localmart/models/product.dart';
import 'package:localmart/services/product_service.dart';
import 'package:localmart/theme/app_theme.dart';
import 'package:localmart/utils/format_utils.dart';

class ProductCard extends StatefulWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _likeLoading = false;

  Future<void> _toggleLike() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _likeLoading) return;
    setState(() => _likeLoading = true);
    await ProductService().toggleLike(widget.product.id, user.uid);
    if (mounted) setState(() => _likeLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final imageBytes = widget.product.images.isNotEmpty ? widget.product.images.first : "";
    final user = FirebaseAuth.instance.currentUser;
    final isLiked = user != null && widget.product.likedBy.contains(user.uid);

    return GestureDetector(
      onTap: () => context.push("/product/${widget.product.id}"),
      child: Container(
        width: 240,
        margin: const EdgeInsets.only(right: 16),
        decoration: AppTheme.cardDecoration,
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  widget.product.images.isNotEmpty
                      ? Image.memory(
                          base64Decode(imageBytes),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: AppTheme.border,
                            child: Icon(Icons.broken_image_outlined, color: AppTheme.textSecondary),
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppTheme.border, AppTheme.background],
                            ),
                          ),
                          child: Icon(Icons.image_outlined, color: AppTheme.textSecondary),
                        ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: _toggleLike,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.surface.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: _likeLoading
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.error,
                                ),
                              )
                            : Icon(
                                isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                size: 18,
                                color: isLiked ? AppTheme.error : AppTheme.textSecondary,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      FormatUtils.formatPrice(widget.product.price),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 12, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          FormatUtils.randomDistance(),
                          style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                        const Spacer(),
                        Icon(Icons.star_rounded, size: 12, color: AppTheme.warning),
                        const SizedBox(width: 2),
                        Text(
                          "4.8",
                          style: TextStyle(fontSize: 11, color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
