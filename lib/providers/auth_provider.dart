import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthProvider with ChangeNotifier {
  AuthStatus _status = AuthStatus.loading;
  User? _user;
  String? _errorMessage;

  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  String? get userId => _user?.id;

  final _supabase = Supabase.instance.client;

  AuthProvider() {
    _init();
  }

  void _init() {
    // ตรวจสอบ session ที่มีอยู่
    final session = _supabase.auth.currentSession;
    if (session != null) {
      _user = session.user;
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.unauthenticated;
    }

    // ฟัง auth state changes
    _supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      _user = data.session?.user;
      if (event == AuthChangeEvent.signedIn) {
        _status = AuthStatus.authenticated;
      } else if (event == AuthChangeEvent.signedOut) {
        _status = AuthStatus.unauthenticated;
      }
      notifyListeners();
    });
  }

  // ── Register ──────────────────────────────────────────
  Future<bool> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      _errorMessage = null;
      final res = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'display_name': displayName.trim()},
      );
      if (res.user != null) {
        _user = res.user;
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }
      _errorMessage = 'ไม่สามารถสร้างบัญชีได้';
      notifyListeners();
      return false;
    } on AuthException catch (e) {
      _errorMessage = _translateError(e.message);
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'เกิดข้อผิดพลาด กรุณาลองใหม่';
      notifyListeners();
      return false;
    }
  }

  // ── Login ─────────────────────────────────────────────
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      _errorMessage = null;
      final res = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      if (res.user != null) {
        _user = res.user;
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }
      _errorMessage = 'อีเมลหรือรหัสผ่านไม่ถูกต้อง';
      notifyListeners();
      return false;
    } on AuthException catch (e) {
      _errorMessage = _translateError(e.message);
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'เกิดข้อผิดพลาด กรุณาลองใหม่';
      notifyListeners();
      return false;
    }
  }

  // ── Logout ────────────────────────────────────────────
  Future<void> logout() async {
    await _supabase.auth.signOut();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  // ── Reset Password ────────────────────────────────────
  Future<bool> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email.trim());
      return true;
    } catch (_) {
      return false;
    }
  }

  String _translateError(String msg) {
    if (msg.contains('Invalid login credentials')) return 'อีเมลหรือรหัสผ่านไม่ถูกต้อง';
    if (msg.contains('Email not confirmed')) return 'กรุณายืนยันอีเมลก่อนเข้าสู่ระบบ';
    if (msg.contains('User already registered')) return 'อีเมลนี้ถูกใช้งานแล้ว';
    if (msg.contains('Password should be')) return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
    if (msg.contains('network')) return 'ไม่มีการเชื่อมต่ออินเทอร์เน็ต';
    return msg;
  }
}
