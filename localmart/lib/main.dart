import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
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
    print("Permission Granted");
  } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    print("Izin notifikasi sementara diberikan");
  } else {
    print("Izin notifikasi ditolak");
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
  await flutterLocalNotificationsPlugin.initialize(settings: settings);

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

  String status = "Memulai. . .";
  String topic = "tes-notif";

  void setupFirebaseMessaging() async {
    final messaging = FirebaseMessaging.instance;
    try {
      final fcmToken = await messaging.getToken();
      debugPrint("FCM Token: $fcmToken");

      if (fcmToken == null) {
        setState(() {
          status = "Gagal mendapatkan token FCM";
        });
        return;
      } else {
        setState(() {
          status = "Token FCM berhasil didapatkan";
        });
      }
    } catch (e) {
      setState(() {
        status = "Error token FCM: $e";
      });
      debugPrint("Error getToken: $e");
      return;
    }

    messaging.onTokenRefresh.listen((token) {
      debugPrint("FCM token refreshed: $token");
    });

    if (!kIsWeb) {
      try {
        await messaging.subscribeToTopic(topic);
        setState(() {
          status = "Subscribe to topic: $topic";
        });
        debugPrint("Subscribed to topic: $topic");
      } catch (e) {
        setState(() {
          status = "Error subscribe topic: $e";
        });
        debugPrint("Error subscribing to topic: $e");
      }
    } else {
      setState(() {
        status = "Web siap menerima notifikasi";
      });
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Received foreground message: ${message.messageId}');

      if (kIsWeb) {
        // For web, just log the message - browser handles notifications
        debugPrint('Web notification: ${message.notification?.title}');
      } else {
        // For Android/iOS, show local notification
        if (message.data.isNotEmpty) {
          showNotificationFromData(message.data);
        } else if (message.notification != null) {
          showBasicNotification(
            message.notification!.title,
            message.notification!.body,
          );
        }
      }
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
