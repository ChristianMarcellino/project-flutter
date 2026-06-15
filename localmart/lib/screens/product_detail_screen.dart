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
import 'package:share_plus/share_plus.dart';

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

    final userProfile = await UserService.getUser(user.uid);

    if (userProfile == null) return;

    await _productService.toggleLike(
      product: product,
      userId: user.uid,
      username: userProfile['username'] ?? 'User',
      profilePicture: userProfile['avatar'],
    );
  }

  Future<void> _openWhatsApp(String phone, String title) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');

    final message = Uri.encodeComponent(
      "Hi, I'm interested in your item: $title on LocalMart",
    );

    final Uri uri = Uri.parse("https://wa.me/$cleanPhone?text=$message");

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("Could not launch WhatsApp: $e");
    }
  }

  Future<void> _shareProduct(Product product) async {
    final link = "https://localmart123123.web.app/product/${product.id}";

    final text =
        '''
*${product.title}*

*${FormatUtils.formatPrice(product.price)}*
${product.locationName}

${product.description}

Check it out on LocalMart! 
$link

LocalMart - Shop Local, Save More!_
''';

    await SharePlus.instance.share(ShareParams(text: text));
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
          return Scaffold(
            backgroundColor: AppTheme.background,
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
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryLight,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              product.category,
                              style: AppTheme.label.copyWith(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w700,
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
                      const SizedBox(height: 12),
                      Text(
                        "Location: ${product.locationName}",
                        style: AppTheme.body.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      if (product.sellerId == authService.currentUser?.uid)
                        ElevatedButton.icon(
                          onPressed: () async {
                            await ProductService().updateProductStatus(
                              product,
                              product.status == 'available'
                                  ? 'sold'
                                  : 'available',
                            );
                          },
                          icon: Icon(
                            product.status == 'available'
                                ? Icons.check_circle
                                : Icons.inventory_2,
                          ),
                          label: Text(
                            product.status == 'available'
                                ? 'Mark as Sold'
                                : 'Mark as Available',
                          ),
                        ),

                      const SizedBox(height: 40),

                      Text(
                        "Comments (${product.commentsCount})",
                        style: AppTheme.h2,
                      ),

                      _buildCommentInput(product, product.id),

                      _buildCommentsList(product),
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
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/');
          }
        },
      ),

      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.black26,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.share_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          onPressed: () => _shareProduct(product),
        ),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.sellerName,
                      style: AppTheme.body.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Seller',
                      style: AppTheme.caption.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  context.push('/profile/${product.sellerId}');
                },
                child: const Icon(Icons.arrow_back_ios, size: 20),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommentInput(Product product, String pid) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              cursorColor: AppTheme.primary,
              style: TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: "Ask a question...",
                hintStyle: TextStyle(color: AppTheme.textSecondary),
                filled: true,
                fillColor: AppTheme.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.primary, width: 1.5),
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

              await _commentService.addComment(product: product, text: text);
            },
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.send_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsList(Product product) {
    return StreamBuilder<QuerySnapshot>(
      stream: _commentService.streamComments(product.id),
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

            return _CommentTile(
              product: product,
              commentId: commentDoc.id,
              data: data,
            );
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
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                label: Text(
                  "Chat Seller",
                  style: AppTheme.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: const StadiumBorder(),
                  elevation: 0,
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
  final Product product;
  final String commentId;
  final Map<String, dynamic> data;

  const _CommentTile({
    required this.product,
    required this.commentId,
    required this.data,
  });

  @override
  State<_CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<_CommentTile> {
  bool showReplies = false;

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
    final replyCount = data['replyCount'] ?? 0;
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
              InkWell(
                onTap: () {
                  final uid = data['userId'];

                  if (uid != null) {
                    context.push('/profile/$uid');
                  }
                },
                child: ClipRRect(
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
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        final uid = data['userId'];

                        if (uid != null) {
                          context.push('/profile/$uid');
                        }
                      },
                      child: Text(
                        data['userName'] ?? 'User',
                        style: AppTheme.label.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      data['text'] ?? '',
                      style: AppTheme.body.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (authService.currentUser != null) ...[
            Padding(
              padding: const EdgeInsets.only(left: 54),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () {
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
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                  ),

                  TextButton(
                    onPressed: () {
                      setState(() {
                        showReplies = !showReplies;
                      });
                    },
                    child: Text(
                      showReplies
                          ? "Hide replies"
                          : "View replies ($replyCount)",
                    ),
                  ),
                ],
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
                          product: widget.product,
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
            if (showReplies)
              Padding(
                padding: const EdgeInsets.only(left: 54, top: 12),
                child: StreamBuilder<QuerySnapshot>(
                  stream: _commentService.streamReplies(
                    productId: widget.product.id,
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
                              InkWell(
                                onTap: () {
                                  final uid = reply['userId'];

                                  if (uid != null) {
                                    context.push('/profile/$uid');
                                  }
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(100),
                                  child:
                                      reply['userAvatar'] != null &&
                                          reply['userAvatar']
                                              .toString()
                                              .isNotEmpty
                                      ? Image.memory(
                                          base64Decode(reply['userAvatar']),
                                          width: 28,
                                          height: 28,
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          width: 50,
                                          height: 50,
                                          color: AppTheme.border,
                                          child: const Icon(Icons.person),
                                        ),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          final uid = reply['userId'];

                                          if (uid != null) {
                                            context.push('/profile/$uid');
                                          }
                                        },
                                        child: Text(
                                          reply['userName'] ?? 'User',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: AppTheme.textPrimary,
                                          ),
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
        ],
      ),
    );
  }
}
