import 'package:go_router/go_router.dart';
import '../presentation/screens/login_screen.dart';
import '../presentation/screens/register_screen.dart';
import '../presentation/screens/home_screen.dart';
import '../presentation/screens/splash_screen.dart';
import '../presentation/screens/friends_screen.dart';
import 'package:quiz/presentation/screens/user_search_screen.dart';
import 'package:quiz/presentation/screens/question_screen.dart';
import 'package:quiz/presentation/screens/mode_selection_screen.dart';
class AppRoutes {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/loading',
        builder: (context, state) =>  SplashScreen(),
      ),
      GoRoute(
        path: '/mode-selection',
        builder: (context, state) =>  ModeSelectionScreen(),
      ),
      GoRoute(
        path: '/friends',
        builder: (context, state) =>  FriendScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) =>  ModeSelectionScreen(),
      ),
      // Add more routes as needed
    ],
  );
}
