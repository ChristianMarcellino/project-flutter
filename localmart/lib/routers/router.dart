import 'package:go_router/go_router.dart';
import 'package:localmart/main.dart';
import 'package:localmart/screens/login_screen.dart';
import 'package:localmart/screens/product_detail_screen.dart';
import 'package:localmart/screens/products_screen.dart';
import 'package:localmart/screens/register_screen.dart';
import 'package:localmart/screens/search_screen.dart';
import 'package:localmart/screens/verify_email_screen.dart';
import 'package:localmart/services/auth_service.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  refreshListenable: authService,
  redirect: (context, state) {
    final user = authService.currentUser;
    final isLoggedIn = user != null;
    final isVerified = user?.emailVerified ?? false;
    final currentPath = state.uri.path;

    final isOnRegister = currentPath == '/register';
    final isOnVerifyEmail = currentPath == '/verify-email';
    final isOnLogin = currentPath == '/login';

    if (!isLoggedIn) {
      if (isOnRegister || isOnVerifyEmail || isOnLogin) return null;
      return '/login';
    }

    if (!isVerified) {
      if (isOnVerifyEmail) return null;
      return '/verify-email';
    }

    if (isOnRegister || isOnVerifyEmail || isOnLogin) {
      return '/';
    }

    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (context, state) => const MainScreen()),
    GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
    GoRoute(
      path: '/verify-email',
      builder: (context, state) => const VerifyEmailScreen(),
    ),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/search', builder: (context, state) => const SearchScreen(showBack: true)),
    GoRoute(
      path: '/products',
      builder: (context, state) {
        final section = state.extra as String? ?? 'nearby';
        return ProductsScreen(section: section);
      },
    ),
    GoRoute(
      path: '/product/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return ProductDetailScreen(productId: id);
      },
    ),
  ],
);