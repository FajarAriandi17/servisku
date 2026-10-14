import 'package:flutter/material.dart';

import '../theme.dart';
import 'dashboard_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'vehicle_form_screen.dart';
import 'vehicles_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  void goTo(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(onSeeVehicles: () => goTo(1)),
      const VehiclesScreen(),
      const HistoryScreen(),
      const ProfileScreen(),
    ];
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: pages),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _index <= 1
          ? _Fab3D(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VehicleFormScreen()),
              ),
            )
          : null,
      bottomNavigationBar: _BottomBar3D(
        index: _index,
        onTap: goTo,
        hasFab: _index <= 1,
      ),
    );
  }
}

class _Fab3D extends StatefulWidget {
  final VoidCallback onTap;
  const _Fab3D({required this.onTap});

  @override
  State<_Fab3D> createState() => _Fab3DState();
}

class _Fab3DState extends State<_Fab3D> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: Container(
        width: 64,
        height: 68,
        alignment: Alignment.topCenter,
        decoration: BoxDecoration(
          color: AppColors.accentDark,
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.45),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          margin: EdgeInsets.only(top: _down ? 4 : 0),
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFC651), AppColors.accent],
            ),
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 34),
        ),
      ),
    );
  }
}

class _BottomBar3D extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  final bool hasFab;
  const _BottomBar3D({
    required this.index,
    required this.onTap,
    required this.hasFab,
  });

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.speed_rounded, 'Beranda'),
      (Icons.garage_rounded, 'Kendaraan'),
      (Icons.receipt_long_rounded, 'Riwayat'),
      (Icons.person_rounded, 'Profil'),
    ];
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        height: 74,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            const BoxShadow(color: Color(0xFFD4D8F5), offset: Offset(0, 5)),
            BoxShadow(
              color: AppColors.primaryDark.withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (hasFab && i == 2) const SizedBox(width: 70),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: index == i
                              ? AppColors.primary.withValues(alpha: 0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          items[i].$1,
                          color: index == i
                              ? AppColors.primary
                              : AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        items[i].$2,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: index == i
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: index == i
                              ? AppColors.primary
                              : AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
