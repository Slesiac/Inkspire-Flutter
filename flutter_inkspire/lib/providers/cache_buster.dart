import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'user_providers.dart';
import 'challenge_providers.dart';

void invalidateAfterAuthChange(WidgetRef ref) {
  ref.invalidate(currentUserIdProvider);
  ref.invalidate(myProfileProvider);
  ref.invalidate(userListProvider);
  ref.invalidate(challengeListVWProvider);
}

void invalidateProfileCaches(WidgetRef ref, String userId) {
  ref.invalidate(userProfileByIdProvider(userId));
  ref.invalidate(userProfileVWByIdProvider(userId));
  ref.invalidate(challengesByUserProvider(userId));
}

void invalidateChallengeCaches(WidgetRef ref, {int? challengeId}) {
  ref.invalidate(challengeListVWProvider);
  if (challengeId != null) ref.invalidate(challengeByIdProvider(challengeId));
}