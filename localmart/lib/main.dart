import 'dart:convert';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localmart/firebase_options.dart';
import 'package:localmart/routers/router.dart';
import 'package:localmart/screens/add_product_screen.dart';
import 'package:localmart/screens/home_screen.dart';
import 'package:localmart/screens/profile_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:localmart/screens/saved_screen.dart';
import 'package:localmart/screens/search_screen.dart';
import 'package:localmart/services/auth_service.dart';
import 'package:localmart/services/global_pref_service.dart';
import 'package:localmart/services/user_service.dart';
import 'package:localmart/theme/app_theme.dart';
import 'package:app_links/app_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

final ValueNotifier<bool> darkModeNotifier = ValueNotifier(false);
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
Future<void> requestNotificationPermission() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    debugPrint("Permission Granted");
  } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    debugPrint("Izin notifikasi sementara diberikan");
  } else {
    debugPrint("Izin notifikasi ditolak");
  }
}

Future<void> showBasicNotification(String? title, String? body) async {
  final android = AndroidNotificationDetails(
    'default_channel',
    'Notifikasi Default',
    channelDescription: "Notifikasi masuk dari FCM",
    importance: Importance.high,
    priority: Priority.high,
    showWhen: true,
  );
  final platform = NotificationDetails(android: android);
  await flutterLocalNotificationsPlugin.show(
    id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
    title: title,
    body: body,
    notificationDetails: platform,
  );
}

Future<String?> _networkImageToBase64(String url) async {
  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return base64Encode(response.bodyBytes);
    }
  } catch (_) {}
  return null;
}

Future<void> showNotificationFromData(Map<String, dynamic> data) async {
  final title = data["title"] ?? "Pesan Baru ";
  final body = data["body"] ?? '';
  final sender = data["senderName"] ?? 'Pengirim tidak diketahui';
  final time = data["sentAt"] ?? '';
  final photoUrl = data["senderPhotoUrl"] ?? '';

  ByteArrayAndroidBitmap? largeIconBitmap;
  if (photoUrl.isNotEmpty) {
    final base64 = await _networkImageToBase64(photoUrl);
    if (base64 != null) {
      largeIconBitmap = ByteArrayAndroidBitmap.fromBase64String(base64);
    }
  }

  final styleInfo = largeIconBitmap != null
      ? BigPictureStyleInformation(
          largeIconBitmap,
          contentTitle: title,
          summaryText: '$body\n\nDari : $sender - $time',
          largeIcon: largeIconBitmap,
          hideExpandedLargeIcon: true,
        )
      : BigTextStyleInformation(
          '$body\n\nDari : $sender - $time',
          contentTitle: title,
        );
  final androidDetails = AndroidNotificationDetails(
    'default_channel',
    'Notifikasi Default',
    channelDescription: "Notifikasi dengan detail tambahan",
    styleInformation: styleInfo,
    largeIcon: largeIconBitmap,
    importance: Importance.max,
    priority: Priority.max,
    showWhen: true,
  );
  final platform = NotificationDetails(android: androidDetails);
  await flutterLocalNotificationsPlugin.show(
    id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
    title: title,
    body: body,
    notificationDetails: platform,
  );
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Handling background message: ${message.messageId}');
  if (message.data.isNotEmpty) {
    await showNotificationFromData(message.data);
  } else {
    await showBasicNotification(
      message.notification!.title,
      message.notification!.body,
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await PrefsService.init();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  darkModeNotifier.value = PrefsService.isDarkMode;
  await requestNotificationPermission();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  const AndroidInitializationSettings androidInit =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings iosInit = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  final InitializationSettings settings = InitializationSettings(
    android: androidInit,
    iOS: iosInit,
  );

  const AndroidNotificationChannel defaultChannel = AndroidNotificationChannel(
    'default_channel',
    'Notifikasi Default',
    description: 'Notifikasi masuk dari FCM',
    importance: Importance.high,
  );

  const AndroidNotificationChannel detailedChannel = AndroidNotificationChannel(
    'detailed_channel',
    'Notifikasi Detail',
    description: 'Notifikasi dengan detail tambahan',
    importance: Importance.max,
  );

  final androidPlugin = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  await androidPlugin?.createNotificationChannel(defaultChannel);
  await androidPlugin?.createNotificationChannel(detailedChannel);
  await flutterLocalNotificationsPlugin.initialize(settings: settings);
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

      debugPrint("Incoming URI: $uri");

      final segments = uri.pathSegments;

      if (segments.isNotEmpty && segments[0] == 'product') {
        final id = segments.length > 1 ? segments[1] : null;

        if (id != null) {
          context.go('/product/$id');
        }
      }
    });
  }

  Future<void> setupFirebaseMessaging() async {
    final messaging = FirebaseMessaging.instance;

    await messaging.requestPermission(alert: true, badge: true, sound: true);

    FirebaseMessaging.onMessage.listen((message) {
      if (message.data.isNotEmpty) {
        showNotificationFromData(message.data);
      } else if (message.notification != null) {
        showBasicNotification(
          message.notification!.title,
          message.notification!.body,
        );
      }
    });

    messaging.onTokenRefresh.listen((token) async {
      final user = authService.currentUser;
      if (user != null) {
        await UserService.updateToken(user.uid, token);
      }
    });

    authService.authStateChanges.listen((user) async {
      if (user == null) return;

      final token = await messaging.getToken();
      if (token == null) return;

      await UserService.updateToken(user.uid, token);
    });
  }

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
    setupFirebaseMessaging();
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
  final List<Widget> _screens = [
    HomeScreen(),
    SearchScreen(),
    SavedScreen(),
    ProfileScreen(userId: authService.currentUser!.uid),
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, isDark, _) {
        return Scaffold(
          extendBody: true,
          backgroundColor: AppTheme.scaffoldBackground,
          body: _screens[_currentIndex],
          bottomNavigationBar: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                height: 90,
                decoration: BoxDecoration(
                  color: AppTheme.surface.withValues(
                    alpha: isDark ? 0.85 : 0.8,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? const Color(0xFF334155).withValues(alpha: 0.5)
                          : const Color(0xFFBBCABF).withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                ),
                child: SafeArea(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(
                        0,
                        _currentIndex == 0
                            ? Icons.home_rounded
                            : Icons.home_outlined,
                        "Home",
                        isDark,
                      ),
                      _buildNavItem(1, Icons.search_rounded, "Search", isDark),
                      _buildAddButton(),
                      _buildNavItem(
                        2,
                        _currentIndex == 2
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        "Saved",
                        isDark,
                      ),
                      _buildNavItem(
                        3,
                        _currentIndex == 3
                            ? Icons.person_rounded
                            : Icons.person_outline_rounded,
                        "Profile",
                        isDark,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, bool isDark) {
    final isSelected = _currentIndex == index;
    final activeColor = isDark ? const Color(0xFF4EDEA3) : AppTheme.primaryDark;
    final inactiveColor = AppTheme.textSecondary;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : inactiveColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
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
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.primary,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }
}
