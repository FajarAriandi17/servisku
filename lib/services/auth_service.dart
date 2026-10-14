import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

/// Authentication with Supabase:
/// - Google (OAuth)
/// - Email + password (sign up with email confirmation)
/// - Phone number (SMS OTP via the SMS provider configured in Supabase)
class AuthService extends ChangeNotifier {
  final GoTrueClient _auth = Supabase.instance.client.auth;
  StreamSubscription<AuthState>? _sub;
  User? _user;
  bool _initialized = false;

  AuthService() {
    _user = _auth.currentUser;
    _initialized = true;
    _sub = _auth.onAuthStateChange.listen((state) {
      _user = state.session?.user;
      if (state.event == AuthChangeEvent.signedIn && _user != null) {
        _saveProfile(_user!);
      }
      notifyListeners();
    });
  }

  User? get user => _user;
  bool get initialized => _initialized;
  bool get isLoggedIn => _user != null;

  Map<String, dynamic> get _meta => _user?.userMetadata ?? const {};

  String get email => _user?.email ?? '';
  String get phone {
    final p = _user?.phone ?? '';
    if (p.isEmpty) return '';
    return p.startsWith('+') ? p : '+$p';
  }

  String get avatarUrl =>
      (_meta['avatar_url'] as String?) ?? (_meta['picture'] as String?) ?? '';

  String get rawName =>
      (_meta['full_name'] as String?) ?? (_meta['name'] as String?) ?? '';

  String get displayName {
    if (_user == null) return '';
    if (rawName.isNotEmpty) return rawName;
    if (email.isNotEmpty) return email.split('@').first;
    if (phone.isNotEmpty) return phone;
    return 'Pengguna';
  }

  bool get emailVerified => _user?.emailConfirmedAt != null;

  String get providerLabel {
    final p = (_user?.appMetadata['provider'] as String?) ?? 'email';
    switch (p) {
      case 'google':
        return 'Google';
      case 'phone':
        return 'Nomor HP';
      default:
        return 'Email';
    }
  }

  String get _redirect =>
      kIsWeb ? Uri.base.origin : SupabaseConfig.mobileRedirect;

  Future<void> _saveProfile(User u) async {
    try {
      await Supabase.instance.client.from('profiles').upsert({
        'id': u.id,
        'name': rawName,
        'email': u.email ?? '',
        'phone': u.phone ?? '',
        'avatar_url': avatarUrl,
        'provider': providerLabel,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Save profile skipped: $e');
    }
  }

  // ---------- Google ----------
  Future<void> signInWithGoogle() async {
    await _auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: _redirect,
      authScreenLaunchMode: kIsWeb
          ? LaunchMode.platformDefault
          : LaunchMode.externalApplication,
      queryParams: const {'prompt': 'select_account'},
    );
  }

  // ---------- Email ----------
  Future<void> signInWithEmail(String email, String password) async {
    await _auth.signInWithPassword(email: email.trim(), password: password);
  }

  /// Returns true if the user is signed in immediately, false if the user
  /// must confirm their email first.
  Future<bool> registerWithEmail(
    String name,
    String email,
    String password,
  ) async {
    final res = await _auth.signUp(
      email: email.trim(),
      password: password,
      data: {'full_name': name.trim(), 'name': name.trim()},
      emailRedirectTo: _redirect,
    );
    // Supabase returns a user with no identities if the email already exists.
    if (res.user != null && (res.user!.identities?.isEmpty ?? false)) {
      throw const AuthException(
        'Email sudah terdaftar. Silakan masuk.',
        code: 'user_already_exists',
      );
    }
    return res.session != null;
  }

  Future<void> resendConfirmation(String email) async {
    await _auth.resend(
      type: OtpType.signup,
      email: email.trim(),
      emailRedirectTo: _redirect,
    );
  }

  Future<void> sendPasswordReset(String email) =>
      _auth.resetPasswordForEmail(email.trim(), redirectTo: _redirect);

  Future<void> resendVerification() async {
    if (email.isNotEmpty) await resendConfirmation(email);
  }

  // ---------- Phone (SMS OTP) ----------
  Future<void> sendOtp(String phone, {String? name}) async {
    final n = (name ?? '').trim();
    await _auth.signInWithOtp(
      phone: phone,
      data: n.isEmpty ? null : {'full_name': n, 'name': n},
    );
  }

  Future<void> verifyOtp(String phone, String code, {String? name}) async {
    await _auth.verifyOTP(phone: phone, token: code.trim(), type: OtpType.sms);
    if ((name ?? '').trim().isNotEmpty && rawName.isEmpty) {
      await updateName(name!);
    }
  }

  Future<void> updateName(String name) async {
    final res = await _auth.updateUser(
      UserAttributes(data: {'full_name': name.trim(), 'name': name.trim()}),
    );
    _user = res.user ?? _user;
    if (_user != null) await _saveProfile(_user!);
    notifyListeners();
  }

  Future<void> signOut() => _auth.signOut();

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

String authErrorMessage(Object e) {
  if (e is AuthException) {
    final code = e.code ?? '';
    final msg = e.message.toLowerCase();
    if (code == 'invalid_credentials' || msg.contains('invalid login')) {
      return 'Email atau kata sandi salah.';
    }
    if (code == 'email_not_confirmed' || msg.contains('not confirmed')) {
      return 'Email belum dikonfirmasi. Cek kotak masuk Anda dan klik tautan konfirmasi.';
    }
    if (code == 'user_already_exists' || msg.contains('already registered')) {
      return 'Email sudah terdaftar. Silakan masuk.';
    }
    if (code == 'weak_password' || msg.contains('password should be')) {
      return 'Kata sandi terlalu lemah (min. 6 karakter).';
    }
    if (code.startsWith('over_') || msg.contains('rate limit')) {
      return 'Terlalu banyak permintaan. Tunggu beberapa menit lalu coba lagi.';
    }
    if (code == 'phone_provider_disabled' ||
        msg.contains('unsupported phone provider')) {
      return 'Login nomor HP belum aktif. Aktifkan Phone provider & SMS provider di Supabase.';
    }
    if (code == 'sms_send_failed' || msg.contains('error sending')) {
      return 'Gagal mengirim SMS/email. Periksa konfigurasi provider di Supabase.';
    }
    if (code == 'otp_expired' || msg.contains('expired')) {
      return 'Kode OTP salah atau kedaluwarsa.';
    }
    if (code == 'validation_failed' && msg.contains('phone')) {
      return 'Nomor HP tidak valid. Gunakan format +62...';
    }
    if (code == 'email_address_invalid' || msg.contains('invalid format')) {
      return 'Format email tidak valid.';
    }
    if (code == 'provider_disabled') {
      return 'Metode login ini belum diaktifkan di Supabase.';
    }
    if (code == 'signup_disabled') {
      return 'Pendaftaran akun baru sedang dinonaktifkan.';
    }
    return e.message;
  }
  final s = e.toString();
  if (s.contains('SocketException') ||
      s.contains('Failed host lookup') ||
      s.contains('ClientException')) {
    return 'Tidak ada koneksi internet.';
  }
  return 'Terjadi kesalahan: $s';
}
