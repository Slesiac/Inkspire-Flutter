import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/user_profile.dart';
import '../models/user_profile_vw.dart';

class UserRepository {
  final SupabaseClient _db = SupabaseService.client;

  String? getCurrentUserId() => _db.auth.currentUser?.id;

  Future<UserProfile?> myProfile() async {
    final uid = getCurrentUserId();
    if (uid == null) return null;
    return getUserProfileById(uid);
  }

  Future<UserProfile?> getUserProfileById(String userId) async {
    final res = await _db.from('user_profile').select().eq('id', userId).maybeSingle();
    return res == null ? null : UserProfile.fromMap(res);
  }

  Future<UserProfileVW?> getUserProfileVWById(String userId) async {
    final res = await _db.from('user_profile_vw').select().eq('id', userId).maybeSingle();
    return res == null ? null : UserProfileVW.fromMap(res);
  }

  // Update profilo corrente: campi opzionali; invia solo quelli presenti.
  Future<void> updateMyProfile({
    String? username,
    String? bio,
    String? profilePic,
  }) async {
    final uid = getCurrentUserId();
    if (uid == null) throw Exception('Not authenticated');

    final payload = <String, dynamic>{};
    if (username != null) payload['username'] = username;
    if (bio != null) payload['bio'] = bio;
    if (profilePic != null) payload['profile_pic'] = profilePic;

    if (payload.isEmpty) return;
    await _db.from('user_profile').update(payload).eq('id', uid);
  }

  Future<List<UserProfileVW>> listUsers({String? search}) async {
    final s = search?.trim();
    final base = _db.from('user_profile_vw').select();

    final filtered = (s != null && s.isNotEmpty)
        ? base.ilike('username', '%$s%')
        : base;

    final res = await filtered.order('created_count', ascending: false);
    return (res as List)
        .map((m) => UserProfileVW.fromMap(m as Map<String, dynamic>))
        .toList();
  }
}