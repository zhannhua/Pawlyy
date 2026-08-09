import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_config.dart';

class AuthController extends ChangeNotifier {
  AuthController(this._client) {
    _session = _client.auth.currentSession;
    _subscription = _client.auth.onAuthStateChange.listen((state) {
      _session = state.session;
      if (state.event == AuthChangeEvent.passwordRecovery) {
        _needsPasswordUpdate = true;
      } else if (state.event == AuthChangeEvent.signedOut) {
        _needsPasswordUpdate = false;
      }
      notifyListeners();
    });
  }

  final SupabaseClient _client;
  late final StreamSubscription<AuthState> _subscription;
  Session? _session;
  bool _needsPasswordUpdate = false;

  User? get user => _session?.user;
  bool get isSignedIn => user != null;
  bool get needsPasswordUpdate => _needsPasswordUpdate;

  Future<void> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Returns true when the user needs to confirm their email before signing in.
  Future<bool> signUp({
    required String displayName,
    required String phone,
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'display_name': displayName.trim(), 'phone': phone.trim()},
      emailRedirectTo: AppConfig.authRedirectUrl,
    );
    return response.session == null;
  }

  Future<void> sendPasswordReset(String email) async {
    await _client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: AppConfig.authRedirectUrl,
    );
  }

  Future<void> resendEmailConfirmation(String email) => _client.auth.resend(
    type: OtpType.signup,
    email: email.trim(),
    emailRedirectTo: AppConfig.authRedirectUrl,
  );

  Future<void> updatePassword(String password) async {
    await _client.auth.updateUser(UserAttributes(password: password));
    _needsPasswordUpdate = false;
    notifyListeners();
  }

  Future<void> signOut() => _client.auth.signOut();

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
