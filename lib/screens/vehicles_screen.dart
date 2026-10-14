import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/data_service.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/three_d.dart';
import 'vehicle_detail_screen.dart';
import 'vehicle_form_screen.dart';

class VehiclesScreen extends StatelessWidget {
  const VehiclesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataService>();
    return SafeArea(
      bottom: false,
      child: data.vehicles.isEmpty
          ? Center(
              child: EmptyState(
                icon: Icons.garage_rounded,
                title: 'Garasi masih kosong',
                message: 'Tambahkan kendaraan pertama Anda.',
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
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 130),
              children: [
                const Text(
                  'Garasi Saya',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                ),
                Text(
                  '${data.vehicles.length} kendaraan terdaftar',
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 18),
                for (final v in data.vehicles) _VehicleCard(vehicle: v),
              ],
            ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  const _VehicleCard({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataService>();
    final v = vehicle;
    final rems = data.remindersFor(v.id).where((r) => r.active).toList();
    final worst = rems.isEmpty
        ? null
        : rems
              .map((r) => r.status(v))
              .reduce((a, b) => a.index >= b.index ? a : b);
    final next = rems.isEmpty ? null : rems.first;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card3D(
        padding: EdgeInsets.zero,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VehicleDetailScreen(vehicleId: v.id),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color.lerp(v.color, Colors.white, 0.25)!, v.color],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(v.icon, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          v.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          [
                            v.brand,
                            if (v.year > 0) '${v.year}',
                            v.typeLabel,
                          ].where((s) => s.isNotEmpty).join(' • '),
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  if (v.plate.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white54, width: 1.5),
                      ),
                      child: Text(
                        v.plate,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _Info(
                    icon: Icons.speed_rounded,
                    label: 'Odometer',
                    value: km(v.currentKm),
                  ),
                  _Info(
                    icon: Icons.alarm_rounded,
                    label: 'Pengingat',
                    value: '${rems.length} aktif',
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (worst != null)
                          StatusChip(label: worst.label, color: worst.color)
                        else
                          const StatusChip(
                            label: 'Belum ada',
                            color: AppColors.muted,
                          ),
                        const SizedBox(height: 4),
                        if (next != null)
                          Text(
                            next.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Info({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
