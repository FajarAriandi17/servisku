import 'package:flutter/material.dart';

import '../theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/logo.png', width: 120),
              const SizedBox(height: 20),
              const Text(
                'ServisKu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 24),
              const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BrandLogo extends StatelessWidget {
  final double size;
  final bool light;
  const BrandLogo({super.key, this.size = 84, this.light = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset('assets/images/logo.png', width: size, height: size),
        const SizedBox(height: 14),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: size * 0.38,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
            children: [
              TextSpan(
                text: 'Servis',
                style: TextStyle(color: light ? Colors.white : AppColors.ink),
              ),
              TextSpan(
                text: 'Ku',
                style: TextStyle(
                  color: light ? AppColors.accent : AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'PENGINGAT SERVIS KENDARAAN',
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 2.4,
            fontWeight: FontWeight.w600,
            color: light ? Colors.white70 : AppColors.muted,
          ),
        ),
      ],
    );
  }
}
