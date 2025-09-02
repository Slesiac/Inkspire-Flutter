import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/auth_repository.dart';

// Repo di autenticazione (Supabase)
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(),
  name: 'authRepositoryProvider',
);

// Stream cambi di stato (login/logout/refresh)
final authStateProvider = StreamProvider<AuthState>(
  (ref) => ref.watch(authRepositoryProvider).onAuthStateChange,
  name: 'authStateProvider',
);

// Utente corrente (null se non loggato)
final authUserProvider = Provider<User?>(
  (ref) => ref.watch(authRepositoryProvider).currentUser,
  name: 'authUserProvider',
);

// Boolean comodo per UI
final isAuthenticatedProvider = Provider<bool>(
  (ref) => ref.watch(authUserProvider) != null,
  name: 'isAuthenticatedProvider',
);