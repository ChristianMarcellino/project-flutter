import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:localmart/firebase_options.dart';
import 'package:localmart/routers/router.dart';
import 'package:localmart/screens/add_product_screen.dart';
import 'package:localmart/screens/home_screen.dart';
import 'package:localmart/screens/profile_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:localmart/screens/saved_screen.dart';
import 'package:localmart/screens/search_screen.dart';
import 'package:localmart/services/global_pref_service.dart';
import 'package:localmart/theme/app_theme.dart';
import 'package:app_links/app_links.dart';

final ValueNotifier<bool> darkModeNotifier = ValueNotifier(false);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await PrefsService.init();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  darkModeNotifier.value = PrefsService.isDarkMode;
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final AppLinks _appLinks = AppLinks();
  void _initDeepLinks() {
    _appLinks.uriLinkStream.listen((Uri uri) {
      if (!mounted) return;

      print("Incoming URI: $uri");

      final segments = uri.pathSegments;

      if (segments.isNotEmpty && segments[0] == 'product') {
        final id = segments.length > 1 ? segments[1] : null;

        if (id != null) {
          context.go('/product/$id');
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: "Localmart",
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = const [
    HomeScreen(),
    SearchScreen(),
    SavedScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, isDark, _) {
        return Scaffold(
          backgroundColor: AppTheme.scaffoldBackground,
          body: _screens[_currentIndex],
          bottomNavigationBar: Container(
            height: 78,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    0,
                    isDark ? Icons.home : Icons.home_outlined,
                    "Home",
                    isDark,
                  ),
                  _buildNavItem(1, Icons.search, "Search", isDark),
                  _buildAddButton(),
                  _buildNavItem(
                    2,
                    _currentIndex == 2 ? Icons.favorite : Icons.favorite_border,
                    "Saved",
                    isDark,
                  ),
                  _buildNavItem(
                    3,
                    _currentIndex == 3 ? Icons.person : Icons.person_outline,
                    "Profile",
                    isDark,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, bool isDark) {
    final isSelected = _currentIndex == index;
    final activeColor = AppTheme.primary;
    final inactiveColor = AppTheme.textSecondary;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isSelected ? activeColor : inactiveColor),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? activeColor : inactiveColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddProductScreen()),
        );
      },
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.primary,
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }
}
