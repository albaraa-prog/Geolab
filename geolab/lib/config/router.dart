import 'package:geolab/config/ProtectedRoute.dart';
import 'package:geolab/features/Home/home_screen.dart';
import 'package:go_router/go_router.dart';

final router = GoRouter(
  initialLocation: '/sign-in',
  routes: [
    GoRoute(
      path: '/sign-in',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/sign-up',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const ProtectedRoute(
        child: HomePage(),
      ),
    ),
  ],
);
