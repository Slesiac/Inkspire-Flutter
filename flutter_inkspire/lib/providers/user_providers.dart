import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/user_repository.dart';
import '../models/user_profile.dart';
import '../models/user_profile_vw.dart';

final userRepositoryProvider = Provider<UserRepository>((_) => UserRepository());

// ID utente corrente
final currentUserIdProvider = Provider<String?>(
  (ref) => ref.watch(userRepositoryProvider).getCurrentUserId(),
);

// Profilo utente corrente
final myProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final repo = ref.watch(userRepositoryProvider);
  return repo.myProfile();
});

// Profilo per ID (tabella user_profile)
final userProfileByIdProvider = FutureProvider.family<UserProfile?, String>((ref, userId) async {
  final repo = ref.watch(userRepositoryProvider);
  return repo.getUserProfileById(userId);
});

// Vista profilo per ID (user_profile_vw, con created/completed)
final userProfileVWByIdProvider = FutureProvider.family<UserProfileVW?, String>((ref, userId) async {
  final repo = ref.watch(userRepositoryProvider);
  return repo.getUserProfileVWById(userId);
});

// Ricerca utenti
final userSearchProvider = StateProvider<String>((_) => '');

// Elenco utenti (vista) filtrato per ricerca
final userListProvider = FutureProvider.autoDispose<List<UserProfileVW>>((ref) async {
  final repo = ref.watch(userRepositoryProvider);
  final q = ref.watch(userSearchProvider);
  return repo.listUsers(search: q.isEmpty ? null : q);
});