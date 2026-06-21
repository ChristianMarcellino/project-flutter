import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:localmart/constants.dart';
import 'package:localmart/models/product.dart';
import 'package:localmart/services/auth_service.dart';
import 'package:localmart/services/product_service.dart';
import 'package:localmart/services/user_service.dart';
import 'package:localmart/services/location_service.dart';
import 'package:localmart/theme/app_theme.dart';
import 'package:localmart/widgets/grid_product_card.dart';
import 'package:localmart/services/global_pref_service.dart';
import 'package:localmart/main.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool get isOwner => authService.currentUser?.uid == widget.userId;
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();
  late Future<Map<String, dynamic>> _userFuture;
  final ImagePicker _picker = ImagePicker();
  bool _uploadingAvatar = false;
  String _avatar = "";
  final user = authService.currentUser;

  double _userLat = 0.0;
  double _userLong = 0.0;
  String _bio = "";
  Future<Map<String, dynamic>> _loadUserData() async {
    if (user == null) return {};
    return await UserService.getUser(widget.userId) ?? {};
  }

  Future<void> _openWhatsApp(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');

    final message = Uri.encodeComponent(
      "Hi, I'm interested in your store on LocalMart",
    );

    final Uri uri = Uri.parse("https://wa.me/$cleanPhone?text=$message");

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("Could not launch WhatsApp: $e");
    }
  }

  void _showEditProfileDialog(Map<String, dynamic> userData) {
    _nameController.text = userData['username'] ?? '';
    _bioController.text = userData['bio'] ?? '';
    _phoneController.text = userData['phoneNumber'] ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
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

                      Text("Edit Profile", style: AppTheme.h2),

                      const SizedBox(height: 16),

                      TextField(
                        controller: _nameController,
                        style: TextStyle(color: AppTheme.textPrimary),
                        decoration: AppTheme.inputDecoration(
                          hintText: "Username",
                        ),
                      ),

                      const SizedBox(height: 12),

                      TextField(
                        controller: _bioController,
                        maxLines: 3,
                        style: TextStyle(color: AppTheme.textPrimary),
                        decoration: AppTheme.inputDecoration(hintText: "Bio"),
                      ),

                      const SizedBox(height: 12),

                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: TextStyle(color: AppTheme.textPrimary),
                        decoration: AppTheme.inputDecoration(
                          hintText: "Phone Number",
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
                            await UserService.updateProfile(
                              widget.userId,
                              username: _nameController.text.trim(),
                              bio: _bioController.text.trim(),
                              phoneNumber: _phoneController.text.trim(),
                            );

                            if (mounted) {
                              setState(() {
                                _userFuture = _loadUserData();
                              });
                              Navigator.pop(context);
                            }
                          },
                          child: const Text(
                            "Save Changes",
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),
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

  Widget _buildAvatarWidget(double size) {
    try {
      if (_avatar.isEmpty) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.border.withValues(alpha: 0.5),
          ),
          child: Icon(
            Icons.person,
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
          errorBuilder: (_, _, _) {
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.border.withValues(alpha: 0.5),
              ),
              child: Icon(
                Icons.person,
                size: size * 0.5,
                color: AppTheme.textSecondary,
              ),
            );
          },
        ),
      );
    } catch (e) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.border.withValues(alpha: 0.5),
        ),
        child: Icon(
          Icons.person,
          size: size * 0.5,
          color: AppTheme.textSecondary,
        ),
      );
    }
  }

  void _toggleDarkMode(bool value) async {
    await PrefsService.setDarkMode(value);
    darkModeNotifier.value = value;
  }

  Future<void> _updateLocation() async {
    if (user == null) return;

    final success = await LocationService.ensureAndUpdateLocation(
      widget.userId,
    );

    if (success) {
      await _loadUser();
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;
    if (!mounted) return;

    final cropped = await ImageCropper().cropImage(
      sourcePath: image.path,
      compressQuality: 70,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Avatar',
          lockAspectRatio: true,
          hideBottomControls: true,
          cropStyle: CropStyle.circle,
        ),
        WebUiSettings(context: context, presentStyle: WebPresentStyle.dialog),
      ],
    );

    if (cropped == null) return;

    setState(() {
      _uploadingAvatar = true;
    });

    final bytes = await cropped.readAsBytes();

    final compressed = await FlutterImageCompress.compressWithList(
      bytes,
      quality: 70,
    );

    final base64Avatar = base64Encode(compressed);

    final uid = widget.userId;

    await FirebaseFirestore.instance
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({'avatar': base64Avatar});

    if (mounted) {
      setState(() {
        _avatar = base64Avatar;
        _uploadingAvatar = false;
      });
    }
  }

  Future<void> _loadUser() async {
    if (user == null) return;

    final data = await UserService.getUser(widget.userId);

    if (!mounted) return;

    final userLat = (data?["latitude"] ?? 0).toDouble();
    final userLong = (data?["longitude"] ?? 0).toDouble();

    setState(() {
      _userLat = userLat;
      _userLong = userLong;
      _avatar = data?['avatar']?.toString() ?? "";
      _bio = data?['bio']?.toString() ?? "";
    });
  }

  @override
  void initState() {
    super.initState();
    _userFuture = _loadUserData();
    _loadUser();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, isDark, _) {
        return Scaffold(
          backgroundColor: AppTheme.scaffoldBackground,
          body: FutureBuilder<Map<String, dynamic>>(
            future: _userFuture,
            builder: (context, userSnap) {
              final userData = userSnap.data ?? {};
              final username = userData['username'] ?? 'User';
              final location =
                  userData['locationName'] as String? ?? 'Set location';
              final phoneNumber = userData['phoneNumber'] ?? '';

              return CustomScrollView(
                slivers: [
                  _buildHeader(username, _avatar, location, _bio, phoneNumber),
                  if (!isOwner)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _openWhatsApp(userData["phoneNumber"]);
                          },
                          icon: const Icon(Icons.chat_bubble_outline),
                          label: const Text("Contact Seller"),
                        ),
                      ),
                    ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isOwner) _buildSettingsSection(isDark),
                          const SizedBox(height: 32),
                          _buildSectionHeader(
                            isOwner ? "My Active Listings" : "Seller Listings",
                            widget.userId,
                          ),
                        ],
                      ),
                    ),
                  ),
                  StreamBuilder<List<Product>>(
                    stream: ProductService().getSomeProductsBySeller(
                      widget.userId,
                    ),
                    builder: (context, snap) {
                      final products = snap.data ?? [];
                      if (products.isEmpty) {
                        return const SliverToBoxAdapter(child: SizedBox());
                      }
                      return SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverGrid(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => GridProductCard(
                              product: products[index],
                              userLat: _userLat,
                              userLong: _userLong,
                            ),
                            childCount: products.length,
                          ),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                mainAxisExtent: 245,
                              ),
                        ),
                      );
                    },
                  ),
                  if (isOwner)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 32, 20, 100),
                        child: OutlinedButton(
                          onPressed: () => authService.signOut(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.error,
                            side: BorderSide(
                              color: AppTheme.error.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: const StadiumBorder(),
                          ),
                          child: Text(
                            "Sign Out",
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    String name,
    String? avatar,
    String loc,
    String bio,
    String phoneNumber,
  ) {
    final isDark = AppTheme.isDark;
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 64, 20, 32),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(32),
          ),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          children: [
            if (!isOwner)
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/');
                    }
                  },
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            Stack(
              children: [
                GestureDetector(
                  onTap: isOwner ? _pickAndUploadAvatar : null,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.primary, width: 3),
                    ),
                    child: _buildAvatarWidget(100),
                  ),
                ),
                if (_uploadingAvatar)
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.black26,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  ),
                if (isOwner)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickAndUploadAvatar,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.surface, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              name,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: isOwner ? _updateLocation : null,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on, size: 14, color: AppTheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      loc,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (bio.isNotEmpty) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  bio,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
            if (isOwner)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _showEditProfileDialog({
                    'username': name,
                    'bio': bio,
                    'phoneNumber': phoneNumber,
                  }),
                  icon: const Icon(Icons.edit),
                  label: const Text("Edit Profile"),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                color: AppTheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                "Dark Appearance",
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          Switch(
            value: isDark,
            onChanged: _toggleDarkMode,
            activeThumbColor: AppTheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String uid) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        TextButton(
          onPressed: () => context.push("/products/seller/$uid"),
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
}
