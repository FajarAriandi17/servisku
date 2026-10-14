import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../theme.dart';
import '../../widgets/three_d.dart';
import '../splash_screen.dart';
import 'phone_auth_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  bool _googleLoading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _loginEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await context.read<AuthService>().signInWithEmail(
        _email.text,
        _password.text,
      );
    } catch (e) {
      _toast(authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loginGoogle() async {
    setState(() => _googleLoading = true);
    try {
      await context.read<AuthService>().signInWithGoogle();
    } catch (e) {
      _toast(authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  Future<void> _forgot() async {
    final ctrl = TextEditingController(text: _email.text);
    final auth = context.read<AuthService>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Lupa Kata Sandi',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Masukkan email Anda. Kami akan mengirim tautan untuk mengatur ulang kata sandi.',
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            Input3D(
              controller: ctrl,
              hint: 'Email',
              icon: Icons.mail_rounded,
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
    if (ok != true || ctrl.text.trim().isEmpty) return;
    try {
      await auth.sendPasswordReset(ctrl.text);
      _toast('Tautan reset telah dikirim ke ${ctrl.text.trim()}');
    } catch (e) {
      _toast(authErrorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const BrandLogo(size: 96),
                    const SizedBox(height: 32),
                    const Text(
                      'Masuk ke akun Anda',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Jangan lewatkan jadwal servis kendaraan lagi.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: 20),
                    Input3D(
                      controller: _email,
                      hint: 'Email',
                      icon: Icons.mail_rounded,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => (v == null || !v.contains('@'))
                          ? 'Masukkan email yang valid'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    Input3D(
                      controller: _password,
                      hint: 'Kata sandi',
                      icon: Icons.lock_rounded,
                      obscure: _obscure,
                      validator: (v) => (v == null || v.length < 6)
                          ? 'Minimal 6 karakter'
                          : null,
                      suffix: IconButton(
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                          color: AppColors.muted,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _forgot,
                        child: const Text(
                          'Lupa kata sandi?',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    Button3D(
                      label: 'Masuk',
                      icon: Icons.login_rounded,
                      loading: _loading,
                      onPressed: _loginEmail,
                    ),
                    const SizedBox(height: 22),
                    const Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'atau masuk dengan',
                            style: TextStyle(color: AppColors.muted),
                          ),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Button3D.white(
                      label: 'Lanjutkan dengan Google',
                      leading: const _GoogleMark(),
                      loading: _googleLoading,
                      onPressed: _loginGoogle,
                    ),
                    const SizedBox(height: 12),
                    Button3D.white(
                      label: 'Masuk dengan Nomor HP',
                      leading: const Icon(
                        Icons.phone_iphone_rounded,
                        color: AppColors.primary,
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PhoneAuthScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Belum punya akun?',
                          style: TextStyle(color: AppColors.muted),
                        ),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ),
                          ),
                          child: const Text(
                            'Daftar sekarang',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE3E6F5)),
      ),
      child: ShaderMask(
        shaderCallback: (r) => const SweepGradient(
          colors: [
            Color(0xFFEA4335),
            Color(0xFFFBBC05),
            Color(0xFF34A853),
            Color(0xFF4285F4),
            Color(0xFFEA4335),
          ],
        ).createShader(r),
        child: const Text(
          'G',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 17,
          ),
        ),
      ),
    );
  }
}
