import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/challenge_repository.dart';
import '../models/challenge_vw.dart';

final challengeRepositoryProvider = Provider<ChallengeRepository>((ref) => ChallengeRepository());

final challengeSearchProvider = StateProvider<String>((_) => '');

final challengeListVWProvider = FutureProvider.autoDispose<List<ChallengeVW>>((ref) async {
  final repo = ref.watch(challengeRepositoryProvider);
  final q = ref.watch(challengeSearchProvider);
  return repo.listAllVW(search: q.isEmpty ? null : q);
});

final challengeByIdProvider = FutureProvider.family<ChallengeVW?, int>((ref, id) async {
  final repo = ref.watch(challengeRepositoryProvider);
  return repo.getVW(id);
});

final challengesByUserProvider = FutureProvider.family<List<ChallengeVW>, String>((ref, userId) async {
  final repo = ref.watch(challengeRepositoryProvider);
  return repo.listByUserVW(userId);
});