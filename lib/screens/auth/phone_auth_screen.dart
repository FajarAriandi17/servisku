import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../theme.dart';
import '../../widgets/three_d.dart';

class PhoneAuthScreen extends StatefulWidget {
  final bool isRegister;
  const PhoneAuthScreen({super.key, this.isRegister = false});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _otp = TextEditingController();
  bool _codeSent = false;
  bool _loading = false;
  int _countdown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _name.dispose();
    _phone.dispose();
    _otp.dispose();
    super.dispose();
  }

  String get _e164 {
    var p = _phone.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (p.startsWith('0')) p = p.substring(1);
    if (p.startsWith('62')) p = p.substring(2);
    return '+62$p';
  }

  void _toast(String m) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(m)));

  void _startTimer() {
    _timer?.cancel();
    setState(() => _countdown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _countdown--);
      if (_countdown <= 0) t.cancel();
    });
  }

  Future<void> _send() async {
    final digits = _phone.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 9) {
      _toast('Masukkan nomor HP yang valid.');
      return;
    }
    if (widget.isRegister && _name.text.trim().length < 2) {
      _toast('Masukkan nama Anda.');
      return;
    }
    setState(() => _loading = true);
    final nav = Navigator.of(context);
    await context.read<AuthService>().sendOtp(
      _e164,
      onCodeSent: () {
        if (!mounted) return;
        setState(() {
          _codeSent = true;
          _loading = false;
        });
        _startTimer();
        _toast('Kode OTP dikirim ke $_e164');
      },
      onAutoVerified: () {
        if (mounted) nav.popUntil((r) => r.isFirst);
      },
      onError: (m) {
        if (!mounted) return;
        setState(() => _loading = false);
        _toast(m);
      },
    );
  }

  Future<void> _verify() async {
    if (_otp.text.trim().length < 6) {
      _toast('Masukkan 6 digit kode OTP.');
      return;
    }
    setState(() => _loading = true);
    final nav = Navigator.of(context);
    try {
      await context.read<AuthService>().verifyOtp(_otp.text, name: _name.text);
      nav.popUntil((r) => r.isFirst);
    } catch (e) {
      _toast(authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isRegister ? 'Daftar Nomor HP' : 'Masuk Nomor HP'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(
                    child: IconTile3D(icon: Icons.sms_rounded, size: 84),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    _codeSent ? 'Verifikasi Kode OTP' : 'Masukkan Nomor HP',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _codeSent
                        ? 'Kami telah mengirim 6 digit kode ke $_e164'
                        : 'Kami akan mengirim kode verifikasi melalui SMS.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 26),
                  if (!_codeSent) ...[
                    if (widget.isRegister) ...[
                      Input3D(
                        controller: _name,
                        hint: 'Nama lengkap',
                        icon: Icons.person_rounded,
                      ),
                      const SizedBox(height: 14),
                    ],
                    Input3D(
                      controller: _phone,
                      hint: '812 3456 7890',
                      prefixText: '+62 ',
                      icon: Icons.phone_rounded,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 22),
                    Button3D(
                      label: 'Kirim Kode OTP',
                      icon: Icons.send_rounded,
                      loading: _loading,
                      onPressed: _send,
                    ),
                  ] else ...[
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0xFFD4D8F5),
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _otp,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 6,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: const TextStyle(
                          fontSize: 28,
                          letterSpacing: 12,
                          fontWeight: FontWeight.w900,
                        ),
                        decoration: const InputDecoration(
                          counterText: '',
                          border: InputBorder.none,
                          hintText: '••••••',
                          contentPadding: EdgeInsets.symmetric(vertical: 18),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Button3D(
                      label: 'Verifikasi',
                      icon: Icons.verified_rounded,
                      loading: _loading,
                      onPressed: _verify,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: _countdown > 0 || _loading ? null : _send,
                          child: Text(
                            _countdown > 0
                                ? 'Kirim ulang dalam ${_countdown}s'
                                : 'Kirim ulang kode',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        TextButton(
                          onPressed: () => setState(() {
                            _codeSent = false;
                            _otp.clear();
                          }),
                          child: const Text('Ubah nomor'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
