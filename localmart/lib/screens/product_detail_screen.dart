import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:localmart/models/product.dart';
import 'package:localmart/services/auth_service.dart';
import 'package:localmart/services/comment_service.dart';
import 'package:localmart/services/product_service.dart';
import 'package:localmart/services/user_service.dart';
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
  final CommentService _commentService = CommentService();

  final TextEditingController _commentController = TextEditingController();

  Future<void> _toggleLike(Product product) async {
    final user = authService.currentUser;

    if (user == null) return;

    await _productService.toggleLike(product.id, user.uid);
  }

  Future<void> _openWhatsApp(String phone, String title) async {
  final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');

  final message = Uri.encodeComponent(
    "Hi, I'm interested in your item: $title on LocalMart",
  );

  final Uri uri = Uri.parse(
    "https://wa.me/$cleanPhone?text=$message",
  );

  try {
    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  } catch (e) {
    debugPrint("Could not launch WhatsApp: $e");
  }
}

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Product?>(
      stream: _productService.streamProductById(widget.productId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final product = snapshot.data!;

        final user = authService.currentUser;

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
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              product.category,
                              style: TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      Text(product.title, style: AppTheme.h1),

                      const SizedBox(height: 8),

                      Text(
                        FormatUtils.formatPrice(product.price),
                        style: AppTheme.h1.copyWith(
                          color: AppTheme.primary,
                          fontSize: 26,
                        ),
                      ),

                      const SizedBox(height: 24),

                      _buildSellerCard(product),

                      const SizedBox(height: 32),

                      Text("Description", style: AppTheme.h2),

                      const SizedBox(height: 12),

                      Text(product.description, style: AppTheme.body),

                      const SizedBox(height: 40),

                      Text(
                        "Comments (${product.commentsCount})",
                        style: AppTheme.h2,
                      ),

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
          decoration: const BoxDecoration(
            color: Colors.black26,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
        onPressed: () => context.pop(),
      ),

      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.black26,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isLiked ? AppTheme.error : Colors.white,
              size: 20,
            ),
          ),
          onPressed: () => _toggleLike(product),
        ),
      ],

      flexibleSpace: FlexibleSpaceBar(
        background: product.images.isNotEmpty
            ? PageView.builder(
                itemCount: product.images.length,
                itemBuilder: (context, index) {
                  return Image.memory(
                    base64Decode(product.images[index]),
                    fit: BoxFit.cover,
                  );
                },
              )
            : Container(color: AppTheme.border),
      ),
    );
  }

  Widget _buildSellerCard(Product product) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: UserService.getUser(product.sellerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.cardDecoration,
            child: Row(
              children: [
                CircleAvatar(radius: 25, backgroundColor: AppTheme.border),

                const SizedBox(width: 12),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppTheme.border,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Container(
                      width: 80,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppTheme.border,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox();
        }

        final seller = snapshot.data!;

        final avatar = seller["avatar"]?.toString() ?? "";

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.cardDecoration,
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: avatar.isNotEmpty
                    ? Image.memory(
                        base64Decode(avatar),
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) {
                          return Container(
                            width: 50,
                            height: 50,
                            color: AppTheme.border,
                            child: const Icon(Icons.person),
                          );
                        },
                      )
                    : Container(
                        width: 50,
                        height: 50,
                        color: AppTheme.border,
                        child: const Icon(Icons.person),
                      ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  product.sellerName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          IconButton.filled(
            onPressed: () async {
              if (_commentController.text.trim().isEmpty) return;

              final text = _commentController.text.trim();

              _commentController.clear();

              await _commentService.addComment(productId: pid, text: text);
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
      stream: _commentService.streamComments(pid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final docs = snapshot.data!.docs;

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          separatorBuilder: (_, _) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final commentDoc = docs[index];

            final data = commentDoc.data() as Map<String, dynamic>;

            return _CommentTile(pid: pid, commentId: commentDoc.id, data: data);
          },
        );
      },
    );
  }

  Widget _buildBottomBar(Product product) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () =>
                    _openWhatsApp(product.sellerPhoneNumber, product.title),
                icon: const Icon(Icons.chat_bubble_outline_rounded),
                label: const Text(
                  "Chat Seller",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentTile extends StatefulWidget {
  final String pid;
  final String commentId;
  final Map<String, dynamic> data;

  const _CommentTile({
    required this.pid,
    required this.commentId,
    required this.data,
  });

  @override
  State<_CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<_CommentTile> {
  final CommentService _commentService = CommentService();

  final TextEditingController _replyController = TextEditingController();

  bool showReplyField = false;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child:
                    data['userAvatar'] != null &&
                        data['userAvatar'].toString().isNotEmpty
                    ? Image.memory(
                        base64Decode(data['userAvatar']),
                        width: 42,
                        height: 42,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 42,
                        height: 42,
                        color: AppTheme.border,
                        child: const Icon(Icons.person, size: 18),
                      ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['userName'] ?? 'User',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      data['text'] ?? '',
                      style: TextStyle(color: AppTheme.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.only(left: 54),
            child: TextButton(
              onPressed: () {
                if (!mounted) return;

                setState(() {
                  showReplyField = !showReplyField;
                });
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
              ),
              child: Text(
                "Reply",
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
              ),
            ),
          ),

          if (showReplyField)
            Padding(
              padding: const EdgeInsets.only(left: 54),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _replyController,
                      decoration: InputDecoration(
                        hintText: "Write a reply...",
                        isDense: true,
                        filled: true,
                        fillColor: AppTheme.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  IconButton(
                    onPressed: () async {
                      if (_replyController.text.trim().isEmpty) {
                        return;
                      }

                      await _commentService.addReply(
                        productId: widget.pid,
                        commentId: widget.commentId,
                        text: _replyController.text.trim(),
                      );

                      if (!mounted) return;
                      _replyController.clear();
                      setState(() {
                        showReplyField = false;
                      });
                    },
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.only(left: 54, top: 12),
            child: StreamBuilder<QuerySnapshot>(
              stream: _commentService.streamReplies(
                productId: widget.pid,
                commentId: widget.commentId,
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox();
                }

                final replies = snapshot.data!.docs;

                return Column(
                  children: replies.map((replyDoc) {
                    final reply = replyDoc.data() as Map<String, dynamic>;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child:
                                reply['userAvatar'] != null &&
                                    reply['userAvatar'].toString().isNotEmpty
                                ? Image.memory(
                                    base64Decode(reply['userAvatar']),
                                    width: 28,
                                    height: 28,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    width: 28,
                                    height: 28,
                                    color: AppTheme.border,
                                  ),
                          ),

                          const SizedBox(width: 8),

                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.background,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    reply['userName'] ?? 'User',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),

                                  const SizedBox(height: 2),

                                  Text(
                                    reply['text'] ?? '',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
