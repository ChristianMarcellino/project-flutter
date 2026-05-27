import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:localmart/models/product.dart';
import 'package:localmart/services/auth_service.dart';
import 'package:localmart/services/product_service.dart';
import 'package:localmart/theme/app_theme.dart';
import 'package:localmart/utils/format_utils.dart';

class GridProductCard extends StatefulWidget {
  final Product product;
  final double userLat;
  final double userLong;

  const GridProductCard({
    super.key,
    required this.product,
    required this.userLat,
    required this.userLong,
  });

  @override
  State<GridProductCard> createState() => _GridProductCardState();
}

class _GridProductCardState extends State<GridProductCard> {
  bool _likeLoading = false;

  Future<void> _toggleLike() async {
    final user = authService.currentUser;
    if (user == null || _likeLoading) return;
    setState(() => _likeLoading = true);
    await ProductService().toggleLike(widget.product.id, user.uid);
    if (mounted) setState(() => _likeLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final distanceKm =
        Geolocator.distanceBetween(
          widget.userLat,
          widget.userLong,
          widget.product.latitude,
          widget.product.longitude,
        ) /
        1000;
    String distanceText() {
      if (widget.userLat == 0 || widget.userLong == 0) {
        return "Unknown distance";
      }

      if (distanceKm < 1) {
        return "${(distanceKm * 1000).round()} m away";
      }

      return "${distanceKm.toStringAsFixed(1)} km away";
    }

    final imageBytes = widget.product.images.isNotEmpty
        ? widget.product.images.first
        : "";
    final user = authService.currentUser;
    final isLiked = user != null && widget.product.likedBy.contains(user.uid);

    return GestureDetector(
      onTap: () => context.push("/product/${widget.product.id}"),
      child: Container(
        decoration: AppTheme.cardDecoration,
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  widget.product.images.isNotEmpty
                      ? Image.memory(
                          base64Decode(imageBytes),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                color: AppTheme.border,
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppTheme.border, AppTheme.background],
                            ),
                          ),
                          child: Icon(
                            Icons.image_outlined,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: _toggleLike,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.surface.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: _likeLoading
                            ? SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: AppTheme.error,
                                ),
                              )
                            : Icon(
                                isLiked
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                size: 16,
                                color: isLiked
                                    ? AppTheme.error
                                    : AppTheme.textSecondary,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      FormatUtils.formatPrice(widget.product.price),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.product.locationName,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      distanceText(),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
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
