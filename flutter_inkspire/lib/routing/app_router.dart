import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/splash/splash_page.dart';
import '../features/auth/login_page.dart';
import '../features/auth/signup_page.dart';
import '../features/shell/app_scaffold.dart';
import '../features/home/home_page.dart';
import '../features/users/user_list_page.dart';
import '../features/challenge/challenge_form_page.dart';
import '../features/challenge/view_challenge_page.dart';
import '../features/profile/user_profile_page.dart';
import '../features/profile/edit_my_profile_page.dart';

import '../providers/auth_providers.dart';
import 'router_refresh.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final authRepo = ref.read(authRepositoryProvider);

  // refresha il router ad ogni variazione di auth
  final refresh = GoRouterRefreshStream(authRepo.onAuthStateChange);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final path = state.uri.path;
      final isAuthed = authRepo.currentUser != null;

      // la pagina splash indirizza automaticamente verso login o home autenticata
      if (path == '/splash') {
        return isAuthed ? '/app/home' : '/login';
      }

      // flusso pubblico
      final inPublic = path == '/login' || path == '/signup';

      // Protezione rotte
      if (!isAuthed && !inPublic) return '/login';
      if (isAuthed && inPublic) return '/app/home';

      return null;
    },
    routes: [
      // Pubbliche, statiche
      GoRoute(path: '/splash', builder: (_, __) => const SplashPage()),
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/signup', builder: (_, __) => const SignUpPage()),

      // Pagine di dettaglio (niente bottom nav, AppBar in alto)
      // Alcune delle quali sono rotte dinamiche con regex (\d+) = '1+ cifre per il valore dell'id'
      GoRoute(
        path: '/app/challenge/add',
        builder: (_, __) => const ChallengeFormPage(),
      ),
      GoRoute(
        path: '/app/challenge/:id(\\d+)',
        builder: (_, st) => ViewChallengePage(id: int.parse(st.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/app/challenge/:id(\\d+)/edit',
        builder: (_, st) => ChallengeFormPage(challengeId: int.parse(st.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/app/user/:id',
        builder: (_, st) => UserProfilePage(userId: st.pathParameters['id']!, showLocalAppBar: true),
      ),
      GoRoute(
        path: '/app/profile/edit',
        builder: (_, __) => const EditMyProfilePage(),
      ),

      // Pagine principali con layout comune (AppBar, bottom nav + FAB)
      ShellRoute(
        builder: (_, __, child) => AppScaffold(child: child),
        routes: [
          GoRoute(path: '/app/home',    builder: (_, __) => const HomePage()),
          GoRoute(path: '/app/artists', builder: (_, __) => const UserListPage()),
          // Niente AppBar per My Profile (user_profile_page la disattiva)
          GoRoute(path: '/app/profile', builder: (_, __) => const UserProfilePage(showLocalAppBar: false)),
        ],
      ),
    ],
  );
});