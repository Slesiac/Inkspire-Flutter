import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/challenge.dart';
import '../models/challenge_vw.dart';
import 'dart:math';

class ChallengeRepository {
  final SupabaseClient _db = SupabaseService.client;

  Future<List<ChallengeVW>> listAllVW({String? search}) async {
    final s = search?.trim();
    final base = _db.from('challenge_vw').select();

    final filtered = (s != null && s.isNotEmpty)
        ? base.or(
            'title.ilike.%$s%,concept.ilike.%$s%,art_constraint.ilike.%$s%,username.ilike.%$s%',
          )
        : base;

    final res = await filtered.order('updated_at', ascending: false);
    return (res as List)
        .map((e) => ChallengeVW.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<ChallengeVW?> getVW(int id) async {
    final res = await _db
        .from('challenge_vw')
        .select()
        .eq('id', id)
        .maybeSingle();
    return res == null ? null : ChallengeVW.fromMap(res);
  }

  Future<List<ChallengeVW>> listByUserVW(String userId) async {
    final res = await _db
        .from('challenge_vw')
        .select()
        .eq('user_id', userId)
        .order('updated_at', ascending: false);
    return (res as List)
        .map((e) => ChallengeVW.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> create(Challenge c) async {
    final res = await _db
        .from('challenge')
        .insert(c.toInsert())
        .select('id')
        .single();
    return (res['id'] as num).toInt();
  }

  Future<void> update(int id, Challenge c) async {
    await _db.from('challenge').update(c.toUpdate()).eq('id', id);
  }

  Future<void> delete(int id) async {
    await _db.from('challenge').delete().eq('id', id);
  }

  Future<String?> getRandomConcept() async {
    final res = await _db.from('concept').select('concept');
    final list = (res as List)
        .map((e) => (e as Map<String, dynamic>)['concept']?.toString())
        .whereType<String>()
        .toList();
    if (list.isEmpty) return null;
    list.shuffle(Random());
    return list.first;
  }

  Future<String?> getRandomArtConstraint() async {
    final res = await _db.from('art_constraint').select('art_constraint');
    final list = (res as List)
        .map((e) => (e as Map<String, dynamic>)['art_constraint']?.toString())
        .whereType<String>()
        .toList();
    if (list.isEmpty) return null;
    list.shuffle(Random());
    return list.first;
  }
}