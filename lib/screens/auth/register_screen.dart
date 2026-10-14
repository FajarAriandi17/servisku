import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../theme.dart';
import '../../widgets/three_d.dart';
import 'phone_auth_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _agree = true;
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agree) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Setujui syarat & ketentuan terlebih dahulu.'),
        ),
      );
      return;
    }
    setState(() => _loading = true);
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<AuthService>().registerWithEmail(
        _name.text,
        _email.text,
        _password.text,
      );
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Akun berhasil dibuat! Email verifikasi telah dikirim.',
          ),
        ),
      );
      nav.popUntil((r) => r.isFirst);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(authErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Akun')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card3D(
                      gradient: AppColors.primaryGradient,
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Image.asset('assets/images/logo.png', width: 56),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Text(
                              'Buat akun gratis & simpan semua jadwal servis kendaraan Anda di cloud.',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    Input3D(
                      controller: _name,
                      hint: 'Nama lengkap',
                      icon: Icons.person_rounded,
                      validator: (v) => (v == null || v.trim().length < 2)
                          ? 'Masukkan nama Anda'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    Input3D(
                      controller: _email,
                      hint: 'Email',
                      icon: Icons.mail_rounded,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) =>
                          (v == null ||
                              !RegExp(
                                r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                              ).hasMatch(v.trim()))
                          ? 'Masukkan email yang valid'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    Input3D(
                      controller: _password,
                      hint: 'Kata sandi (min. 6 karakter)',
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
                    const SizedBox(height: 14),
                    Input3D(
                      controller: _confirm,
                      hint: 'Ulangi kata sandi',
                      icon: Icons.lock_outline_rounded,
                      obscure: _obscure,
                      validator: (v) =>
                          v != _password.text ? 'Kata sandi tidak sama' : null,
                    ),
                    const SizedBox(height: 10),
                    CheckboxListTile(
                      value: _agree,
                      onChanged: (v) => setState(() => _agree = v ?? false),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text(
                        'Saya menyetujui syarat & ketentuan serta kebijakan privasi ServisKu.',
                        style: TextStyle(fontSize: 13, color: AppColors.muted),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Button3D(
                      label: 'Daftar dengan Email',
                      icon: Icons.person_add_alt_1_rounded,
                      loading: _loading,
                      onPressed: _register,
                    ),
                    const SizedBox(height: 14),
                    Button3D.white(
                      label: 'Daftar dengan Nomor HP',
                      leading: const Icon(
                        Icons.phone_iphone_rounded,
                        color: AppColors.primary,
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const PhoneAuthScreen(isRegister: true),
                        ),
                      ),
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
