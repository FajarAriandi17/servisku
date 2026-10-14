import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/reminder_tile.dart';
import '../widgets/three_d.dart';
import 'complete_service_sheet.dart';
import 'odometer_sheet.dart';
import 'reminder_form_screen.dart';
import 'vehicle_detail_screen.dart';
import 'vehicle_form_screen.dart';

class DashboardScreen extends StatelessWidget {
  final VoidCallback onSeeVehicles;
  const DashboardScreen({super.key, required this.onSeeVehicles});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final data = context.watch<DataService>();
    final upcoming = data.upcoming;
    final overdue = data.countStatus(DueStatus.overdue);
    final soon = data.countStatus(DueStatus.soon);
    final ok = data.countStatus(DueStatus.ok);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: GradientHeader(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Image.asset('assets/images/logo.png', width: 44),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${greeting()},',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                auth.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _NotifBadge(count: overdue + soon),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: _StatBox(
                            value: '$overdue',
                            label: 'Terlambat',
                            color: AppColors.danger,
                            icon: Icons.warning_rounded,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatBox(
                            value: '$soon',
                            label: 'Segera',
                            color: AppColors.warning,
                            icon: Icons.schedule_rounded,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatBox(
                            value: '$ok',
                            label: 'Aman',
                            color: AppColors.success,
                            icon: Icons.verified_rounded,
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
        if (data.loading)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (data.error != null)
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              icon: Icons.cloud_off_rounded,
              title: 'Tidak dapat memuat data',
              message: data.error!,
            ),
          )
        else if (data.vehicles.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              icon: Icons.two_wheeler_rounded,
              title: 'Belum ada kendaraan',
              message:
                  'Tambahkan motor atau mobil Anda untuk mulai membuat pengingat servis per bulan atau per KM.',
              action: SizedBox(
                width: 240,
                child: Button3D(
                  label: 'Tambah Kendaraan',
                  icon: Icons.add_rounded,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const VehicleFormScreen(),
                    ),
                  ),
                ),
              ),
            ),
          )
        else ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
              child: SectionTitle(
                'Kendaraan Saya',
                trailing: TextButton(
                  onPressed: onSeeVehicles,
                  child: const Text(
                    'Lihat semua',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 172,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: data.vehicles.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (ctx, i) =>
                    _VehicleMiniCard(vehicle: data.vehicles[i]),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: SectionTitle(
                'Jadwal Servis Terdekat',
                trailing: Text(
                  '${upcoming.length} aktif',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          if (upcoming.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Card3D(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ReminderFormScreen(vehicle: data.vehicles.first),
                    ),
                  ),
                  child: const Row(
                    children: [
                      IconTile3D(icon: Icons.alarm_add_rounded),
                      SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Belum ada pengingat. Ketuk untuk membuat jadwal servis pertama Anda.',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              sliver: SliverList.builder(
                itemCount: upcoming.length > 8 ? 8 : upcoming.length,
                itemBuilder: (ctx, i) {
                  final (r, v) = upcoming[i];
                  return ReminderTile(
                    reminder: r,
                    vehicle: v,
                    onTap: () => Navigator.push(
                      ctx,
                      MaterialPageRoute(
                        builder: (_) =>
                            ReminderFormScreen(vehicle: v, reminder: r),
                      ),
                    ),
                    onDone: () =>
                        showCompleteServiceSheet(ctx, vehicle: v, reminder: r),
                  );
                },
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 130),
              child: Card3D(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    const IconTile3D(
                      icon: Icons.account_balance_wallet_rounded,
                      color: AppColors.violet,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Biaya servis ${DateTime.now().year}',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            rupiah(data.costThisYear()),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${data.records.length}x\nservis',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _NotifBadge extends StatelessWidget {
  final int count;
  const _NotifBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white24),
          ),
          child: const Icon(Icons.notifications_rounded, color: Colors.white),
        ),
        if (count > 0)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(5),
              constraints: const BoxConstraints(minWidth: 22),
              decoration: BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Text(
                '$count',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData icon;
  const _StatBox({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: AppColors.primaryDark, offset: Offset(0, 5)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleMiniCard extends StatelessWidget {
  final Vehicle vehicle;
  const _VehicleMiniCard({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final v = vehicle;
    final dark = Color.lerp(v.color, Colors.black, 0.4)!;
    return SizedBox(
      width: 220,
      child: Card3D(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(v.color, Colors.white, 0.25)!, v.color],
        ),
        depthColor: dark,
        padding: const EdgeInsets.all(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VehicleDetailScreen(vehicleId: v.id),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(v.icon, color: Colors.white),
                ),
                const Spacer(),
                if (v.plate.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.ink,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white54),
                    ),
                    child: Text(
                      v.plate,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              v.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.speed_rounded,
                  color: Colors.white70,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    km(v.currentKm),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => showOdometerSheet(context, v),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Update KM',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
