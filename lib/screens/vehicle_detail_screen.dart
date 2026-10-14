import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/data_service.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/reminder_tile.dart';
import '../widgets/three_d.dart';
import 'complete_service_sheet.dart';
import 'history_screen.dart';
import 'odometer_sheet.dart';
import 'reminder_form_screen.dart';
import 'vehicle_form_screen.dart';

class VehicleDetailScreen extends StatelessWidget {
  final String vehicleId;
  const VehicleDetailScreen({super.key, required this.vehicleId});

  Future<void> _delete(BuildContext context, Vehicle v) async {
    final data = context.read<DataService>();
    final nav = Navigator.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus kendaraan?'),
        content: Text(
          '${v.name} beserta semua pengingat & riwayat servisnya akan dihapus permanen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok == true) {
      nav.pop();
      await data.deleteVehicle(v.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataService>();
    final v = data.vehicleById(vehicleId);
    if (v == null) {
      return const Scaffold(
        body: Center(child: Text('Kendaraan tidak ditemukan')),
      );
    }
    final reminders = data.remindersFor(v.id);
    final records = data.recordsFor(v.id);
    final totalCost = records.fold<int>(0, (a, r) => a + r.cost);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color.lerp(v.color, Colors.white, 0.25)!, v.color],
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color.lerp(v.color, Colors.black, 0.4)!,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 24),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(
                              Icons.edit_rounded,
                              color: Colors.white,
                            ),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => VehicleFormScreen(vehicle: v),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_rounded,
                              color: Colors.white,
                            ),
                            onPressed: () => _delete(context, v),
                          ),
                        ],
                      ),
                      Container(
                        width: 84,
                        height: 88,
                        alignment: Alignment.topCenter,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(26),
                        ),
                        child: Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(color: Colors.white38),
                          ),
                          child: Icon(v.icon, color: Colors.white, size: 46),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        v.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        [
                          v.brand,
                          if (v.year > 0) '${v.year}',
                          v.plate,
                        ].where((s) => s.isNotEmpty).join(' • '),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            _HeaderStat(
                              label: 'Odometer',
                              value: numFmt(v.currentKm),
                              unit: 'km',
                              onTap: () => showOdometerSheet(context, v),
                            ),
                            _HeaderStat(
                              label: 'Pengingat',
                              value: '${reminders.length}',
                              unit: 'jadwal',
                            ),
                            _HeaderStat(
                              label: 'Total biaya',
                              value: totalCost >= 1000000
                                  ? (totalCost / 1000000).toStringAsFixed(1)
                                  : numFmt((totalCost / 1000).round()),
                              unit: totalCost >= 1000000 ? 'jt' : 'rb',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Button3D(
                      label: 'Update KM',
                      icon: Icons.speed_rounded,
                      height: 50,
                      onPressed: () => showOdometerSheet(context, v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Button3D.accent(
                      label: 'Catat Servis',
                      icon: Icons.build_rounded,
                      height: 50,
                      onPressed: () =>
                          showCompleteServiceSheet(context, vehicle: v),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: SectionTitle(
                'Jadwal Servis',
                trailing: TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReminderFormScreen(vehicle: v),
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text(
                    'Tambah',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
          ),
          if (reminders.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Card3D(
                  child: Text(
                    'Belum ada jadwal. Tambahkan pengingat per bulan atau per KM.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList.builder(
                itemCount: reminders.length,
                itemBuilder: (ctx, i) => ReminderTile(
                  reminder: reminders[i],
                  vehicle: v,
                  showVehicle: false,
                  onTap: () => Navigator.push(
                    ctx,
                    MaterialPageRoute(
                      builder: (_) => ReminderFormScreen(
                        vehicle: v,
                        reminder: reminders[i],
                      ),
                    ),
                  ),
                  onDone: reminders[i].active
                      ? () => showCompleteServiceSheet(
                          ctx,
                          vehicle: v,
                          reminder: reminders[i],
                        )
                      : null,
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: SectionTitle('Riwayat Servis (${records.length})'),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            sliver: records.isEmpty
                ? const SliverToBoxAdapter(
                    child: Card3D(
                      child: Text(
                        'Belum ada riwayat servis.',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ),
                  )
                : SliverList.builder(
                    itemCount: records.length,
                    itemBuilder: (ctx, i) =>
                        RecordTile(record: records[i], vehicle: v),
                  ),
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final VoidCallback? onTap;
  const _HeaderStat({
    required this.label,
    required this.value,
    required this.unit,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white24),
          ),
          child: Column(
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    TextSpan(
                      text: ' $unit',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
