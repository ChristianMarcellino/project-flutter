import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _uploadingAvatar = false;
  String _avatar = "";
  final user = authService.currentUser;

  double _userLat = 0.0;
  double _userLong = 0.0;

  Future<Map<String, dynamic>> _loadUserData() async {
    if (user == null) return {};
    return await UserService.getUser(user!.uid) ?? {};
  }

  Future<void> _updateUsername(String newName) async {
    if (newName.trim().isEmpty) return;
    if (user == null) return;

    await FirebaseFirestore.instance.collection(AppConstants.usersCollection).doc(user!.uid).update({
      'username': newName.trim(),
    });

    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Username updated")));
    }
  }

  void _showEditNameDialog(String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text("Edit Username", style: AppTheme.h2),
        content: TextField(
          controller: controller,
          style: TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: "New username",
            hintStyle: TextStyle(color: AppTheme.textSecondary),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppTheme.border),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              _updateUsername(controller.text);
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _toggleDarkMode(bool value) async {
    await PrefsService.setDarkMode(value);
    darkModeNotifier.value = value;
  }

  Future<void> _updateLocation() async {
    if (user == null) return;
    await LocationService.requestAndUpdateLocation(user!.uid);
    await _loadUser();
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

    final uid = user!.uid;

    await FirebaseFirestore.instance.collection(AppConstants.usersCollection).doc(uid).update({
      'avatar': base64Avatar,
    });

    if (mounted) {
      setState(() {
        _avatar = base64Avatar;
        _uploadingAvatar = false;
      });
    }
  }

  Future<void> _loadUser() async {
    final data = await UserService.getUser(user!.uid);
    final userLat = (data?["latitude"] ?? 0).toDouble();
    final userLong = (data?["longitude"] ?? 0).toDouble();

    setState(() {
      _userLat = userLat;
      _userLong = userLong;
      _avatar = data?['avatar'] ?? "";
    });
  }

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, isDark, _) {
        return Scaffold(
          backgroundColor: AppTheme.background,
          body: FutureBuilder<Map<String, dynamic>>(
            future: _loadUserData(),
            builder: (context, userSnap) {
              final userData = userSnap.data ?? {};
              final username = userData['username'] ?? 'User';
              final location =
                  userData['locationName'] as String? ?? 'Set location';

              return CustomScrollView(
                slivers: [
                  _buildHeader(username, _avatar, location),
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSettingsSection(isDark),
                          const SizedBox(height: 32),
                          _buildSectionHeader(
                            "My Active Listings",
                            userSnap.data?['uid'] ?? "",
                          ),
                        ],
                      ),
                    ),
                  ),
                  StreamBuilder<List<Product>>(
                    stream: ProductService().getProductsBySeller(
                      authService.currentUser!.uid,
                    ),
                    builder: (context, snap) {
                      final products = snap.data ?? [];
                      if (products.isEmpty) {
                        return const SliverToBoxAdapter(child: SizedBox());
                      }
                      return SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                mainAxisExtent: 240,
                              ),
                        ),
                      );
                    },
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: OutlinedButton(
                        onPressed: () => authService.signOut(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.error,
                          side: BorderSide(
                            color: AppTheme.error.withValues(alpha: 0.3),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          "Sign Out",
                          style: TextStyle(fontWeight: FontWeight.w700),
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

  Widget _buildHeader(String name, String? avatar, String loc) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 64, 20, 32),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(32),
          ),
        ),
        child: Column(
          children: [
            Stack(
              children: [
                GestureDetector(
                  onTap: _pickAndUploadAvatar,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.primary, width: 3),
                      image: _avatar != ""
                          ? DecorationImage(
                              image: MemoryImage(base64Decode(_avatar)),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _avatar == ""
                        ? Icon(
                            Icons.person,
                            size: 50,
                            color: AppTheme.textSecondary,
                          )
                        : null,
                  ),
                ),
                if (_uploadingAvatar)
                  const Positioned.fill(child: CircularProgressIndicator()),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(name, style: AppTheme.h1.copyWith(fontSize: 22)),
                IconButton(
                  onPressed: () => _showEditNameDialog(name),
                  icon: Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: _updateLocation,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  loc,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
                isDark ? Icons.dark_mode : Icons.light_mode,
                color: AppTheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                "Dark Appearance",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
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
        Text(title, style: AppTheme.h2),
        TextButton(
          onPressed: () => context.push("/products", extra: "listing"),
          child: const Text("See All"),
        ),
      ],
    );
  }
}
