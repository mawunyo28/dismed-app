import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? _user;
  bool _loading = true;
  String? _error;

  late final StreamSubscription<AuthState> _authSub;

  User? get user => _user;
  bool get isLoading => _loading;
  bool get isAuthenticated => _user != null;
  String? get error => _error;

  AuthProvider() {
    _init();
  }

  void _init() {
    _user = _supabase.auth.currentUser;

    _loading = false;

    notifyListeners();

    _authSub = _supabase.auth.onAuthStateChange.listen((data) {
      _user = data.session?.user;

      notifyListeners();
    });
  }

  Future<bool> signIn(String email, String password) async {
    _error = null;

    try {
      await _supabase.auth.signInWithPassword(password: password, email: email);
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp(String email, String password, String name) async {
    _error = null;
    try {
      await _supabase.auth.signUp(password: password, email: email, data: {"name": name});
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  void clearError() {
    _error = null;

    notifyListeners();
  }

  @override
  void dispose() {
    _authSub.cancel();
    notifyListeners();
    super.dispose();
  }
}
