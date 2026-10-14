import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/data_service.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/three_d.dart';

Future<void> showOdometerSheet(BuildContext context, Vehicle v) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _OdometerSheet(vehicle: v),
  );
}

class _OdometerSheet extends StatefulWidget {
  final Vehicle vehicle;
  const _OdometerSheet({required this.vehicle});

  @override
  State<_OdometerSheet> createState() => _OdometerSheetState();
}

class _OdometerSheetState extends State<_OdometerSheet> {
  late final TextEditingController _ctrl = TextEditingController(
    text: widget.vehicle.estimatedKm.toString(),
  );
  bool _saving = false;

  Future<void> _save() async {
    final value = parseInt(_ctrl.text);
    final data = context.read<DataService>();
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    if (value < widget.vehicle.currentKm) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('KM lebih kecil'),
          content: Text(
            'Nilai baru (${km(value)}) lebih kecil dari KM sebelumnya (${km(widget.vehicle.currentKm)}). Tetap simpan?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Simpan'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    setState(() => _saving = true);
    try {
      await data.updateOdometer(widget.vehicle, value);
      nav.pop();
      messenger.showSnackBar(
        SnackBar(content: Text('Odometer diperbarui: ${km(value)}')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
      if (mounted) setState(() => _saving = false);
    }
  }

  void _bump(int d) {
    final v = parseInt(_ctrl.text) + d;
    _ctrl.text = v.toString();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vehicle;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        22,
        14,
        22,
        MediaQuery.of(context).viewInsets.bottom + 22,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD0F0),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              IconTile3D(icon: Icons.speed_rounded, color: v.color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Update Odometer',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${v.name} • terakhir ${km(v.currentKm)} (${dateFmt(v.kmUpdatedAt)})',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Card3D(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: AppColors.primary,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                suffixText: 'km',
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final d in [10, 50, 100, 500])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: OutlinedButton(
                      onPressed: () => _bump(d),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('+$d'),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Estimasi saat ini: ${km(v.estimatedKm)} (rata-rata ${v.avgKmPerDay} km/hari)',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 18),
          Button3D(
            label: 'Simpan KM',
            icon: Icons.save_rounded,
            loading: _saving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
