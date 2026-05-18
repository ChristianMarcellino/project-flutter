import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:localmart/models/product.dart';
import 'package:localmart/services/product_service.dart';
import 'package:localmart/theme/app_theme.dart';
import 'package:localmart/utils/format_utils.dart';
import 'package:url_launcher/url_launcher.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ProductService _productService = ProductService();
  final TextEditingController _commentController = TextEditingController();
  
  Future<void> _toggleLike(Product product) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _productService.toggleLike(product.id, user.uid);
  }

  Future<void> _openWhatsApp(String phone, String title) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final message = Uri.encodeComponent("Hi, I'm interested in your item: $title on LocalMart");
    final url = Uri.parse("https://wa.me/$cleanPhone?text=$message");
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Product?>(
      stream: _productService.streamProductById(widget.productId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final product = snapshot.data!;
        final user = FirebaseAuth.instance.currentUser;
        final isLiked = user != null && product.likedBy.contains(user.uid);

        return Scaffold(
          backgroundColor: AppTheme.background,
          body: CustomScrollView(
            slivers: [
              _buildAppBar(context, product, isLiked),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(8)),
                            child: Text(product.category, style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(product.title, style: AppTheme.h1),
                      const SizedBox(height: 8),
                      Text(FormatUtils.formatPrice(product.price), style: AppTheme.h1.copyWith(color: AppTheme.primary, fontSize: 26)),
                      const SizedBox(height: 24),
                      _buildSellerCard(product),
                      const SizedBox(height: 32),
                      Text("Description", style: AppTheme.h2),
                      const SizedBox(height: 12),
                      Text(product.description, style: AppTheme.body),
                      const SizedBox(height: 40),
                      Text("Comments (${product.commentsCount})", style: AppTheme.h2),
                      _buildCommentInput(product.id),
                      _buildCommentsList(product.id),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomBar(product),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context, Product product, bool isLiked) {
    return SliverAppBar(
      expandedHeight: 400,
      pinned: true,
      backgroundColor: AppTheme.background,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
        ),
        onPressed: () => context.pop(),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
            child: Icon(isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: isLiked ? AppTheme.error : Colors.white, size: 20),
          ),
          onPressed: () => _toggleLike(product),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: product.images.isNotEmpty
            ? PageView.builder(
                itemCount: product.images.length,
                itemBuilder: (context, index) => Image.memory(base64Decode(product.images[index]), fit: BoxFit.cover),
              )
            : Container(color: AppTheme.border),
      ),
    );
  }

  Widget _buildSellerCard(Product product) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Row(
        children: [
          CircleAvatar(backgroundColor: AppTheme.primary, child: Text(product.sellerName[0])),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(product.sellerName, style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput(String pid) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: "Ask a question...",
                filled: true,
                fillColor: AppTheme.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton.filled(
            onPressed: () async {
              if (_commentController.text.isEmpty) return;
              await FirebaseFirestore.instance.collection('products').doc(pid).collection('comments').add({
                'text': _commentController.text,
                'userName': FirebaseAuth.instance.currentUser?.displayName ?? 'User',
                'createdAt': FieldValue.serverTimestamp(),
              });
              await FirebaseFirestore.instance.collection('products').doc(pid).update({'commentsCount': FieldValue.increment(1)});
              _commentController.clear();
            },
            icon: const Icon(Icons.send_rounded),
            style: IconButton.styleFrom(backgroundColor: AppTheme.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsList(String pid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('products').doc(pid).collection('comments').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final docs = snapshot.data!.docs;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(data['userName'] ?? 'User', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary)),
              subtitle: Text(data['text'] ?? '', style: TextStyle(color: AppTheme.textPrimary)),
            );
          },
        );
      },
    );
  }

  Widget _buildBottomBar(Product product) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppTheme.surface, border: Border(top: BorderSide(color: AppTheme.border))),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _openWhatsApp(product.sellerPhoneNumber, product.title),
                icon: const Icon(Icons.chat_bubble_outline_rounded),
                label: const Text("Chat Seller", style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}