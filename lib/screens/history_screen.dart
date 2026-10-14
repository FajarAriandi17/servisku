import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/data_service.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/three_d.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String? _vehicleFilter;

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataService>();
    final records = _vehicleFilter == null
        ? data.records
        : data.records.where((r) => r.vehicleId == _vehicleFilter).toList();
    final total = records.fold<int>(0, (a, r) => a + r.cost);

    // Monthly spend for the last 6 months
    final now = DateTime.now();
    final months = List.generate(
      6,
      (i) => DateTime(now.year, now.month - 5 + i),
    );
    final monthly = months
        .map(
          (m) => records
              .where((r) => r.date.year == m.year && r.date.month == m.month)
              .fold<int>(0, (a, r) => a + r.cost),
        )
        .toList();
    final maxVal = monthly.fold<int>(0, (a, b) => a > b ? a : b);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 130),
        children: [
          const Text(
            'Riwayat Servis',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
          ),
          const Text(
            'Catatan & statistik biaya perawatan',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          if (data.vehicles.length > 1)
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: const Text('Semua'),
                      selected: _vehicleFilter == null,
                      onSelected: (_) => setState(() => _vehicleFilter = null),
                    ),
                  ),
                  for (final v in data.vehicles)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        avatar: Icon(v.icon, size: 18, color: v.color),
                        label: Text(v.name),
                        selected: _vehicleFilter == v.id,
                        onSelected: (_) =>
                            setState(() => _vehicleFilter = v.id),
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Card3D(
            gradient: AppColors.primaryGradient,
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total pengeluaran',
                            style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            rupiah(total),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${records.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Text(
                          'kali servis',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 110,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var i = 0; i < 6; i++)
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              _Bar3D(
                                fraction: maxVal == 0 ? 0 : monthly[i] / maxVal,
                                highlight: i == 5,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _monthAbbr(months[i].month),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
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
          const SizedBox(height: 18),
          if (records.isEmpty)
            const EmptyState(
              icon: Icons.receipt_long_rounded,
              title: 'Belum ada riwayat',
              message:
                  'Tandai pengingat sebagai selesai atau catat servis dari halaman kendaraan.',
            )
          else
            for (final r in records)
              RecordTile(record: r, vehicle: data.vehicleById(r.vehicleId)),
        ],
      ),
    );
  }

  String _monthAbbr(int m) => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ][m - 1];
}

class _Bar3D extends StatelessWidget {
  final double fraction;
  final bool highlight;
  const _Bar3D({required this.fraction, required this.highlight});

  @override
  Widget build(BuildContext context) {
    final h = 8 + 70 * fraction;
    final c = highlight ? AppColors.accent : Colors.white;
    return Container(
      width: 22,
      height: h + 4,
      alignment: Alignment.topCenter,
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.accentDark
            : Colors.white.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Container(
        width: 22,
        height: h,
        decoration: BoxDecoration(
          color: c.withValues(alpha: highlight ? 1 : 0.9),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class RecordTile extends StatelessWidget {
  final ServiceRecord record;
  final Vehicle? vehicle;
  const RecordTile({super.key, required this.record, this.vehicle});

  @override
  Widget build(BuildContext context) {
    final p = presetFor(record.category);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card3D(
        padding: const EdgeInsets.all(14),
        onTap: () => _showDetail(context),
        child: Row(
          children: [
            IconTile3D(icon: p.icon, color: p.color, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      dateFmt(record.date),
                      km(record.km),
                      if (vehicle != null) vehicle!.name,
                    ].join(' • '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              record.cost == 0 ? '-' : rupiah(record.cost),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final data = context.read<DataService>();
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              record.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            _row(
              Icons.directions_car_rounded,
              'Kendaraan',
              vehicle?.name ?? '-',
            ),
            _row(Icons.event_rounded, 'Tanggal', dateFmt(record.date)),
            _row(Icons.speed_rounded, 'Odometer', km(record.km)),
            _row(Icons.payments_rounded, 'Biaya', rupiah(record.cost)),
            if (record.workshop.isNotEmpty)
              _row(Icons.store_rounded, 'Bengkel', record.workshop),
            if (record.notes.isNotEmpty)
              _row(Icons.notes_rounded, 'Catatan', record.notes),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await data.deleteRecord(record.id);
                },
                icon: const Icon(Icons.delete_rounded),
                label: const Text('Hapus riwayat'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData i, String l, String v) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(i, size: 20, color: AppColors.primary),
        const SizedBox(width: 10),
        SizedBox(
          width: 90,
          child: Text(l, style: const TextStyle(color: AppColors.muted)),
        ),
        Expanded(
          child: Text(v, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
}
