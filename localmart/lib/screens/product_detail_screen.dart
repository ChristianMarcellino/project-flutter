import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:localmart/constants.dart';
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

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _openManageProductSheet(BuildContext context, Product product) {
    final titleController = TextEditingController(text: product.title);
    final priceController = TextEditingController(
      text: product.price.toString(),
    );
    final descController = TextEditingController(text: product.description);
    String category = product.category;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: AppTheme.cardDecoration.copyWith(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: StatefulBuilder(
              builder: (context, setModalState) {
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 5,
                          decoration: BoxDecoration(
                            color: AppTheme.border.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      Text("Manage Product", style: AppTheme.h2),

                      const SizedBox(height: 16),

                      TextField(
                        controller: titleController,
                        style: TextStyle(color: AppTheme.textPrimary),
                        decoration: AppTheme.inputDecoration(hintText: "Title"),
                      ),

                      const SizedBox(height: 12),

                      TextField(
                        controller: priceController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: AppTheme.textPrimary),
                        decoration: AppTheme.inputDecoration(hintText: "Price"),
                      ),

                      const SizedBox(height: 12),

                      TextField(
                        controller: descController,
                        maxLines: 3,
                        style: TextStyle(color: AppTheme.textPrimary),
                        decoration: AppTheme.inputDecoration(
                          hintText: "Description",
                        ),
                      ),

                      const SizedBox(height: 12),

                      DropdownButtonFormField<String>(
                        value: category,
                        dropdownColor: AppTheme.surface,
                        style: TextStyle(color: AppTheme.textPrimary),
                        items: AppConstants.categories
                            .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() => category = val);
                          }
                        },
                        decoration: AppTheme.inputDecoration(
                          hintText: "Category",
                        ),
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () async {
                            await ProductService().updateProduct(
                              productId: product.id,
                              title: titleController.text.trim(),
                              description: descController.text.trim(),
                              price:
                                  double.tryParse(priceController.text) ??
                                  product.price,
                              category: category,
                            );

                            if (context.mounted) Navigator.pop(context);
                          },
                          child: const Text(
                            "Save Changes",
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primary,
                            side: BorderSide(
                              color: AppTheme.primary.withValues(alpha: 0.3),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () async {
                            await ProductService().updateProduct(
                              productId: product.id,
                              status: product.status == 'available'
                                  ? 'sold'
                                  : 'available',
                            );

                            if (context.mounted) Navigator.pop(context);
                          },
                          child: Text(
                            product.status == 'available'
                                ? "Mark as Sold"
                                : "Mark as Available",
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.error,
                          ),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                backgroundColor: AppTheme.surface,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                title: Text(
                                  "Delete Product?",
                                  style: TextStyle(color: AppTheme.textPrimary),
                                ),
                                content: Text(
                                  "This action cannot be undone.",
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: Text(
                                      "Cancel",
                                      style: TextStyle(
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.error,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text("Delete"),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await ProductService().deleteProduct(product.id);

                              if (context.mounted) {
                                Navigator.pop(context);
                                context.pop();
                              }
                            }
                          },
                          child: const Text(
                            "Delete Product",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
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
  Widget build(BuildContext context) {
    return StreamBuilder<Product?>(
      key: ValueKey(widget.productId),
      stream: _productService.streamProductById(widget.productId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: AppTheme.background,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final product = snapshot.data!;

        return Scaffold(
          backgroundColor: AppTheme.background,
          body: CustomScrollView(
            slivers: [
              _buildAppBar(context, product),

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

  Widget _buildAppBar(BuildContext context, Product product) {
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
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppTheme.textPrimary,
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
        _LikeButton(product: product),
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
              if (product.sellerId == authService.currentUser?.uid) ...[
                const SizedBox(height: 12),

                OutlinedButton.icon(
                  onPressed: () => _openManageProductSheet(context, product),
                  icon: const Icon(Icons.settings),
                  label: const Text("Manage Product"),
                ),
              ] else ...[
                InkWell(
                  onTap: () {
                    context.push('/profile/${product.sellerId}');
                  },
                  child: Icon(
                    Icons.arrow_back_ios,
                    size: 20,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
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
          padding: EdgeInsets.zero,
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

class _LikeButton extends StatefulWidget {
  final Product product;

  const _LikeButton({required this.product});

  @override
  State<_LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<_LikeButton>
    with SingleTickerProviderStateMixin {
  final ProductService _productService = ProductService();

  late bool _isLiked;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    final user = authService.currentUser;
    _isLiked = user != null && widget.product.likedBy.contains(user.uid);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.5,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.5,
          end: 0.85,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.85,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 30,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    final user = authService.currentUser;
    if (user == null) return;

    final userProfile = await UserService.getUser(user.uid);
    if (userProfile == null) return;

    final wasLiked = _isLiked;

    setState(() {
      _isLiked = !wasLiked;
    });

    _controller.forward(from: 0);

    try {
      await _productService.toggleLike(
        product: widget.product,
        userId: user.uid,
        username: userProfile['username'] ?? 'User',
        profilePicture: userProfile['avatar'],
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLiked = wasLiked;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Colors.black26,
          shape: BoxShape.circle,
        ),
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, _) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: Icon(
                  _isLiked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  key: ValueKey(_isLiked),
                  color: _isLiked ? AppTheme.error : Colors.white,
                  size: 20,
                ),
              ),
            );
          },
        ),
      ),
      onPressed: _toggle,
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
                                          width: 36,
                                          height: 36,
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          width: 36,
                                          height: 36,
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
