import 'package:go_router/go_router.dart';
import 'package:localmart/main.dart';
import 'package:localmart/screens/register_screen.dart';
import 'package:localmart/services/auth_service.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/register',
  
  redirect: (context, state) {
    final user = authService.value.currentUser; // or however you get current user
    final isLoggedIn = user != null;
    final isOnRegister = 
        state.matchedLocation == '/register';

    if (!isLoggedIn && !isOnRegister) return '/register';
    if (isLoggedIn && isOnRegister) return '/';
    return null;
  },

  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => MainScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => RegisterScreen(),
    ),
  ],
);