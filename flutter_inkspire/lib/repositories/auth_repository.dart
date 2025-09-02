import 'dart:io'; // per SocketException
import 'dart:async'; // per TimeoutException
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/user_profile.dart';

class AuthRepository {
  final GoTrueClient _auth = SupabaseService.auth;
  final SupabaseClient _db = SupabaseService.client;

  User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.id;

  Stream<AuthState> get onAuthStateChange => _auth.onAuthStateChange;

  // Riconosce errori di rete
  bool _isNetworkError(Object e) {
    final s = e.toString().toLowerCase();
    return e is SocketException ||
           e is TimeoutException ||
           s.contains('socketexception') ||
           s.contains('failed host lookup') ||
           s.contains('dns') ||
           s.contains('network');
  }

  Future<void> signIn(String email, String password) async {
    try {
      await _auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      // Alcuni errori di rete arrivano come AuthException
      if (_isNetworkError(e)) {
        throw const AppAuthException('No internet connection.');
      }
      throw AppAuthException(_mapAuthException(e));
    } on SocketException {
      throw const AppAuthException('No internet connection.');
    } on TimeoutException {
      throw const AppAuthException('No internet connection.');
    } catch (e) {
      if (_isNetworkError(e)) {
        throw const AppAuthException('No internet connection.');
      }
      throw const AppAuthException('Unable to login. Please try again.');
    }
  }

  Future<void> signUp(String email, String password, String username) async {
    try {
      // 1. Check: unicità dello username
      final existing = await _db
          .from('user_profile')
          .select('id')
          .eq('username', username)
          .maybeSingle();

      if (existing != null) {
        throw const AppAuthException('Username already taken.');
      }

      // 2. Creazione utente (si ottiene subito la sessione)
      final res = await _auth.signUp(
        email: email,
        password: password,
        data: {'username': username},
      );

      final userId = res.user?.id ?? _auth.currentUser?.id;
      if (userId == null) {
        throw const AppAuthException('Sign up failed. Please try again.');
      }

      // 3. Inserimento/Aggiornamento profilo (idempotente, si può eseguire più volte senza errori)
      await _db.from('user_profile').upsert(
        {'id': userId, 'username': username},
        onConflict: 'id',
      );
    } on AppAuthException {
      rethrow;
    } on AuthException catch (e) {
      // Se l'errore è di rete (anche se è un AuthException), mostra "No internet connection."
      if (_isNetworkError(e)) {
        throw const AppAuthException('No internet connection.');
      }
      throw AppAuthException(_mapAuthException(e));
    } on SocketException {
      throw const AppAuthException('No internet connection.');
    } on TimeoutException {
      throw const AppAuthException('No internet connection.');
    } catch (e) {
      if (_isNetworkError(e)) {
        throw const AppAuthException('No internet connection.');
      }
      throw const AppAuthException('Unable to sign up. Please try again.');
    }
  }

  Future<void> signOut() => _auth.signOut();

  // Legge il profilo dell’utente loggato da user_profile e lo mappa in UserProfile (o null se assente).
  Future<UserProfile?> getMyProfile() async {
    final uid = currentUserId;
    if (uid == null) return null;

    final data = await _db
        .from('user_profile')
        .select()
        .eq('id', uid)
        .maybeSingle();

    if (data == null) return null;
    return UserProfile.fromMap(data);
  }

  Future<void> updateProfile({String? profilePic, String? bio}) async {
    final uid = currentUserId;
    if (uid == null) throw const AppAuthException('Not authenticated.');

    final payload = <String, dynamic>{};
    if (profilePic != null) payload['profile_pic'] = profilePic;
    if (bio != null) payload['bio'] = bio;
    if (payload.isEmpty) return;

    try {
      await _db.from('user_profile').update(payload).eq('id', uid);
    } on SocketException {
      throw const AppAuthException('No internet connection.');
    } on TimeoutException {
      // Anche i timeout sono "problemi di connessione"
      throw const AppAuthException('No internet connection.');
    } catch (e) {
      if (_isNetworkError(e)) {
        throw const AppAuthException('No internet connection.');
      }
      throw const AppAuthException('Unable to update profile.');
    }
  }

  // Helper privati che traducono gli errori Supabase in testi user-friendly
  String _mapAuthException(AuthException e) {
    final m = e.message.toLowerCase();
    if (m.contains('invalid') || m.contains('invalid login credentials')) {
      return 'Incorrect email or password.';
    }
    if (m.contains('user already registered') || m.contains('already exists')) {
      return 'Email already in use.';
    }
    if (m.contains('password') && m.contains('weak')) {
      return 'Password too weak.';
    }
    return 'Action failed: ${e.message}';
  }  
}

// Eccezione custom che incapsula solo il messaggio
class AppAuthException implements Exception {
  final String message;
  const AppAuthException(this.message);
  @override
  String toString() => message; // così in UI non si vede "Exception: ..."
}