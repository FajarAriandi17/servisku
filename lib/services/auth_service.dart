import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  bool _initialized = false;
  StreamSubscription<User?>? _sub;

  // Phone auth state
  String? _verificationId;
  int? _resendToken;
  ConfirmationResult? _webConfirmation;

  AuthService() {
    _sub = _auth.userChanges().listen((u) {
      _user = u;
      _initialized = true;
      notifyListeners();
    });
  }

  User? get user => _user;
  bool get initialized => _initialized;
  bool get isLoggedIn => _user != null;

  String get displayName {
    final u = _user;
    if (u == null) return '';
    if ((u.displayName ?? '').isNotEmpty) return u.displayName!;
    if ((u.email ?? '').isNotEmpty) return u.email!.split('@').first;
    if ((u.phoneNumber ?? '').isNotEmpty) return u.phoneNumber!;
    return 'Pengguna';
  }

  String get providerLabel {
    final ids = _user?.providerData.map((p) => p.providerId).toList() ?? [];
    if (ids.contains('google.com')) return 'Google';
    if (ids.contains('phone')) return 'Nomor HP';
    return 'Email';
  }

  Future<void> _saveProfile(User u, {String? name}) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(u.uid).set({
        'uid': u.uid,
        'name': name ?? u.displayName ?? '',
        'email': u.email ?? '',
        'phone': u.phoneNumber ?? '',
        'photoUrl': u.photoURL ?? '',
        'provider': providerLabel,
        'lastLoginAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Save profile failed: $e');
    }
  }

  // ---------- Google ----------
  Future<void> signInWithGoogle() async {
    final provider = GoogleAuthProvider()
      ..addScope('email')
      ..setCustomParameters({'prompt': 'select_account'});
    final UserCredential cred;
    if (kIsWeb) {
      cred = await _auth.signInWithPopup(provider);
    } else {
      cred = await _auth.signInWithProvider(provider);
    }
    if (cred.user != null) await _saveProfile(cred.user!);
  }

  // ---------- Email ----------
  Future<void> signInWithEmail(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    if (cred.user != null) await _saveProfile(cred.user!);
  }

  Future<void> registerWithEmail(
    String name,
    String email,
    String password,
  ) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final u = cred.user;
    if (u != null) {
      await u.updateDisplayName(name.trim());
      try {
        await u.sendEmailVerification();
      } catch (_) {}
      await u.reload();
      await _saveProfile(_auth.currentUser ?? u, name: name.trim());
    }
  }

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  Future<void> resendVerification() async {
    await _user?.sendEmailVerification();
  }

  // ---------- Phone ----------
  /// Sends an OTP. Calls [onCodeSent] when the SMS was sent and
  /// [onAutoVerified] if Android verified the number automatically.
  Future<void> sendOtp(
    String phone, {
    required VoidCallback onCodeSent,
    required VoidCallback onAutoVerified,
    required void Function(String message) onError,
  }) async {
    if (kIsWeb) {
      try {
        _webConfirmation = await _auth.signInWithPhoneNumber(phone);
        onCodeSent();
      } on FirebaseAuthException catch (e) {
        onError(authErrorMessage(e));
      } catch (e) {
        onError('Gagal mengirim OTP: $e');
      }
      return;
    }
    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      forceResendingToken: _resendToken,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          final cred = await _auth.signInWithCredential(credential);
          if (cred.user != null) await _saveProfile(cred.user!);
          onAutoVerified();
        } on FirebaseAuthException catch (e) {
          onError(authErrorMessage(e));
        }
      },
      verificationFailed: (FirebaseAuthException e) =>
          onError(authErrorMessage(e)),
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        _resendToken = resendToken;
        onCodeSent();
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  Future<void> verifyOtp(String code, {String? name}) async {
    UserCredential cred;
    if (kIsWeb) {
      if (_webConfirmation == null) {
        throw FirebaseAuthException(
          code: 'missing-verification-id',
          message: 'Kirim OTP terlebih dahulu.',
        );
      }
      cred = await _webConfirmation!.confirm(code.trim());
    } else {
      if (_verificationId == null) {
        throw FirebaseAuthException(
          code: 'missing-verification-id',
          message: 'Kirim OTP terlebih dahulu.',
        );
      }
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: code.trim(),
      );
      cred = await _auth.signInWithCredential(credential);
    }
    final u = cred.user;
    if (u != null) {
      if ((name ?? '').trim().isNotEmpty && (u.displayName ?? '').isEmpty) {
        await u.updateDisplayName(name!.trim());
      }
      await _saveProfile(u, name: name);
    }
  }

  Future<void> updateName(String name) async {
    await _user?.updateDisplayName(name.trim());
    await _user?.reload();
    if (_auth.currentUser != null) {
      await _saveProfile(_auth.currentUser!, name: name.trim());
    }
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
  if (e is FirebaseAuthException) {
    switch (e.code) {
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'user-disabled':
        return 'Akun ini telah dinonaktifkan.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'INVALID_LOGIN_CREDENTIALS':
        return 'Email atau kata sandi salah.';
      case 'email-already-in-use':
        return 'Email sudah terdaftar. Silakan masuk.';
      case 'weak-password':
        return 'Kata sandi terlalu lemah (min. 6 karakter).';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi nanti.';
      case 'network-request-failed':
        return 'Tidak ada koneksi internet.';
      case 'invalid-phone-number':
        return 'Nomor HP tidak valid. Gunakan format +62...';
      case 'invalid-verification-code':
        return 'Kode OTP salah.';
      case 'session-expired':
      case 'code-expired':
        return 'Kode OTP kedaluwarsa. Kirim ulang kode.';
      case 'popup-closed-by-user':
      case 'cancelled-popup-request':
      case 'web-context-canceled':
      case 'canceled':
        return 'Login dibatalkan.';
      case 'operation-not-allowed':
        return 'Metode login ini belum diaktifkan di Firebase Console.';
      case 'configuration-not-found':
        return 'Firebase Authentication belum diaktifkan. Buka Firebase Console → Authentication → Get started.';
      case 'account-exists-with-different-credential':
        return 'Email sudah terdaftar dengan metode login lain.';
      case 'requires-recent-login':
        return 'Silakan login ulang untuk melanjutkan.';
      case 'unauthorized-domain':
        return 'Domain belum diizinkan di Firebase Authentication.';
      default:
        return e.message ?? 'Terjadi kesalahan (${e.code}).';
    }
  }
  return 'Terjadi kesalahan: $e';
}
