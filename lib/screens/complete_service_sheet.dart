import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/data_service.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/three_d.dart';

/// Bottom sheet to log a finished service (optionally tied to a reminder).
Future<void> showCompleteServiceSheet(
  BuildContext context, {
  required Vehicle vehicle,
  ServiceReminder? reminder,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _CompleteSheet(vehicle: vehicle, reminder: reminder),
  );
}

class _CompleteSheet extends StatefulWidget {
  final Vehicle vehicle;
  final ServiceReminder? reminder;
  const _CompleteSheet({required this.vehicle, this.reminder});

  @override
  State<_CompleteSheet> createState() => _CompleteSheetState();
}

class _CompleteSheetState extends State<_CompleteSheet> {
  late final _title = TextEditingController(text: widget.reminder?.title ?? '');
  late final _km = TextEditingController(
    text: widget.vehicle.estimatedKm.toString(),
  );
  final _cost = TextEditingController();
  final _workshop = TextEditingController();
  final _notes = TextEditingController();
  late String _category = widget.reminder?.category ?? 'servis';
  DateTime _date = DateTime.now();
  bool _saving = false;

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) {
      _title.text = presetFor(_category).title;
    }
    setState(() => _saving = true);
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<DataService>().completeService(
        vehicle: widget.vehicle,
        reminder: widget.reminder,
        title: _title.text.trim(),
        category: _category,
        date: _date,
        km: parseInt(_km.text),
        cost: parseInt(_cost.text),
        workshop: _workshop.text.trim(),
        notes: _notes.text.trim(),
      );
      nav.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            widget.reminder != null
                ? 'Servis dicatat! Jadwal berikutnya otomatis diperbarui.'
                : 'Riwayat servis berhasil disimpan.',
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.88,
      maxChildSize: 0.95,
      builder: (ctx, scroll) => ListView(
        controller: scroll,
        padding: EdgeInsets.fromLTRB(
          22,
          14,
          22,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
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
              const IconTile3D(
                icon: Icons.task_alt_rounded,
                color: AppColors.success,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.reminder != null
                          ? 'Tandai Servis Selesai'
                          : 'Catat Servis',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      widget.vehicle.name,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (widget.reminder == null) ...[
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final p in servicePresets)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        avatar: Icon(p.icon, size: 18, color: p.color),
                        label: Text(p.title),
                        selected: _category == p.key,
                        onSelected: (_) => setState(() {
                          _category = p.key;
                          _title.text = p.title;
                        }),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          Input3D(
            controller: _title,
            hint: 'Jenis servis',
            icon: Icons.build_rounded,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _pickDate,
                  child: AbsorbPointer(
                    child: Input3D(
                      controller: TextEditingController(text: dateFmt(_date)),
                      hint: 'Tanggal',
                      icon: Icons.event_rounded,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Input3D(
                  controller: _km,
                  hint: 'KM saat servis',
                  icon: Icons.speed_rounded,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Input3D(
            controller: _cost,
            hint: 'Biaya (Rp)',
            icon: Icons.payments_rounded,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 14),
          Input3D(
            controller: _workshop,
            hint: 'Bengkel (opsional)',
            icon: Icons.store_rounded,
          ),
          const SizedBox(height: 14),
          Input3D(
            controller: _notes,
            hint: 'Catatan (opsional)',
            icon: Icons.notes_rounded,
            maxLines: 3,
          ),
          const SizedBox(height: 22),
          Button3D(
            label: 'Simpan',
            icon: Icons.check_circle_rounded,
            color: AppColors.success,
            depthColor: AppColors.successDark,
            loading: _saving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
