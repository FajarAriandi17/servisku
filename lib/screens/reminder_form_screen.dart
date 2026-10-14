import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/data_service.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/three_d.dart';

class ReminderFormScreen extends StatefulWidget {
  final Vehicle vehicle;
  final ServiceReminder? reminder;
  const ReminderFormScreen({super.key, required this.vehicle, this.reminder});

  @override
  State<ReminderFormScreen> createState() => _ReminderFormScreenState();
}

class _ReminderFormScreenState extends State<ReminderFormScreen> {
  late final ServiceReminder? r = widget.reminder;
  late Vehicle _vehicle = widget.vehicle;
  late String _category = r?.category ?? 'oli';
  late final _title = TextEditingController(
    text: r?.title ?? presetFor('oli').title,
  );
  late IntervalMode _mode = r?.mode ?? presetFor('oli').mode;
  late int _months = r?.intervalMonths ?? presetFor('oli').months;
  late final _intervalKm = TextEditingController(
    text: (r?.intervalKm ?? _presetKm(presetFor('oli'))).toString(),
  );
  late DateTime _lastDate = r?.lastServiceDate ?? DateTime.now();
  late final _lastKm = TextEditingController(
    text: (r?.lastServiceKm ?? widget.vehicle.currentKm).toString(),
  );
  late int _notifyDays = r?.notifyDaysBefore ?? 7;
  late final _notifyKm = TextEditingController(
    text: (r?.notifyKmBefore ?? 200).toString(),
  );
  late final _notes = TextEditingController(text: r?.notes ?? '');
  late bool _active = r?.active ?? true;
  bool _saving = false;

  bool get _isEdit => r != null;

  int _presetKm(ServicePreset p) =>
      _vehicleType == VehicleType.motor ? p.kmMotor : p.kmMobil;
  VehicleType get _vehicleType => widget.vehicle.type;

  void _applyPreset(ServicePreset p) {
    setState(() {
      _category = p.key;
      _title.text = p.title;
      _mode = p.mode;
      _months = p.months;
      final k = _presetKm(p);
      if (k > 0) _intervalKm.text = k.toString();
    });
  }

  ServiceReminder _build() => ServiceReminder(
    id: r?.id ?? '',
    vehicleId: _vehicle.id,
    title: _title.text.trim().isEmpty
        ? presetFor(_category).title
        : _title.text.trim(),
    category: _category,
    mode: _mode,
    intervalMonths: _months,
    intervalKm: parseInt(_intervalKm.text).clamp(1, 1000000),
    lastServiceDate: _lastDate,
    lastServiceKm: parseInt(_lastKm.text),
    notifyDaysBefore: _notifyDays,
    notifyKmBefore: parseInt(_notifyKm.text),
    active: _active,
    notes: _notes.text.trim(),
    createdAt: r?.createdAt ?? DateTime.now(),
  );

  Future<void> _save() async {
    setState(() => _saving = true);
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<DataService>().saveReminder(_build());
      nav.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _isEdit ? 'Pengingat diperbarui.' : 'Pengingat dibuat!',
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final data = context.read<DataService>();
    final nav = Navigator.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus pengingat?'),
        content: Text('"${r!.title}" akan dihapus.'),
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
      await data.deleteReminder(r!.id);
      nav.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataService>();
    final preview = _build();
    final dueDate = preview.dueDate;
    final dueKm = preview.dueKm;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Pengingat' : 'Pengingat Baru'),
        actions: [
          if (_isEdit)
            IconButton(
              icon: const Icon(Icons.delete_rounded, color: AppColors.danger),
              onPressed: _delete,
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
          children: [
            if (!_isEdit && data.vehicles.length > 1) ...[
              const _Label('Kendaraan'),
              Card3D(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _vehicle.id,
                    items: [
                      for (final v in data.vehicles)
                        DropdownMenuItem(
                          value: v.id,
                          child: Row(
                            children: [
                              Icon(v.icon, color: v.color),
                              const SizedBox(width: 10),
                              Text(
                                v.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                    onChanged: (id) => setState(() {
                      _vehicle = data.vehicleById(id!)!;
                      _lastKm.text = _vehicle.currentKm.toString();
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 18),
            ],
            const _Label('Jenis servis'),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.82,
              children: [
                for (final p in servicePresets)
                  _PresetTile(
                    preset: p,
                    selected: _category == p.key,
                    onTap: () => _applyPreset(p),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Input3D(
              controller: _title,
              hint: 'Nama pengingat',
              icon: Icons.edit_note_rounded,
            ),
            const SizedBox(height: 20),
            const _Label('Interval pengingat'),
            Card3D(
              padding: const EdgeInsets.all(6),
              child: Row(
                children: [
                  for (final m in IntervalMode.values)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _mode = m),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            gradient: _mode == m
                                ? AppColors.primaryGradient
                                : null,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: _mode == m
                                ? const [
                                    BoxShadow(
                                      color: AppColors.primaryDark,
                                      offset: Offset(0, 3),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            children: [
                              Icon(
                                switch (m) {
                                  IntervalMode.month =>
                                    Icons.calendar_month_rounded,
                                  IntervalMode.km => Icons.speed_rounded,
                                  IntervalMode.both => Icons.join_full_rounded,
                                },
                                color: _mode == m
                                    ? Colors.white
                                    : AppColors.primary,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                m.label,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12.5,
                                  color: _mode == m
                                      ? Colors.white
                                      : AppColors.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (_mode != IntervalMode.km) ...[
              Card3D(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_month_rounded,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Setiap',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        _Stepper(
                          value: _months,
                          suffix: 'bulan',
                          min: 1,
                          max: 60,
                          onChanged: (v) => setState(() => _months = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final m in [1, 2, 3, 6, 12])
                          ChoiceChip(
                            label: Text('$m bln'),
                            selected: _months == m,
                            onSelected: (_) => setState(() => _months = m),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
            if (_mode != IntervalMode.month) ...[
              Input3D(
                controller: _intervalKm,
                hint: 'Setiap berapa KM',
                icon: Icons.speed_rounded,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                suffix: const Padding(
                  padding: EdgeInsets.only(right: 16, top: 16),
                  child: Text(
                    'km',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.muted,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final k
                      in _vehicleType == VehicleType.motor
                          ? [1000, 2000, 4000, 8000]
                          : [5000, 10000, 20000, 40000])
                    ChoiceChip(
                      label: Text(numFmt(k)),
                      selected: parseInt(_intervalKm.text) == k,
                      onSelected: (_) =>
                          setState(() => _intervalKm.text = k.toString()),
                    ),
                ],
              ),
              const SizedBox(height: 14),
            ],
            const SizedBox(height: 6),
            const _Label('Servis terakhir'),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _lastDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (d != null) setState(() => _lastDate = d);
                    },
                    child: AbsorbPointer(
                      child: Input3D(
                        controller: TextEditingController(
                          text: dateFmt(_lastDate),
                        ),
                        hint: 'Tanggal',
                        icon: Icons.event_rounded,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Input3D(
                    controller: _lastKm,
                    hint: 'KM',
                    icon: Icons.speed_rounded,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const _Label('Ingatkan saya'),
            Card3D(
              child: Column(
                children: [
                  if (_mode != IntervalMode.km)
                    Row(
                      children: [
                        const Icon(
                          Icons.notifications_active_rounded,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Hari sebelum jatuh tempo',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        _Stepper(
                          value: _notifyDays,
                          suffix: 'hari',
                          min: 0,
                          max: 60,
                          onChanged: (v) => setState(() => _notifyDays = v),
                        ),
                      ],
                    ),
                  if (_mode == IntervalMode.both) const Divider(height: 22),
                  if (_mode != IntervalMode.month)
                    Row(
                      children: [
                        const Icon(
                          Icons.route_rounded,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'KM sebelum jatuh tempo',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        SizedBox(
                          width: 100,
                          child: TextField(
                            controller: _notifyKm,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                            decoration: const InputDecoration(
                              isDense: true,
                              suffixText: ' km',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Input3D(
              controller: _notes,
              hint: 'Catatan (mis. oli Motul 10W-40)',
              icon: Icons.notes_rounded,
              maxLines: 2,
            ),
            if (_isEdit) ...[
              const SizedBox(height: 14),
              Card3D(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: SwitchListTile(
                  value: _active,
                  onChanged: (b) => setState(() => _active = b),
                  title: const Text(
                    'Pengingat aktif',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            // Preview
            Card3D(
              gradient: AppColors.primaryGradient,
              child: Row(
                children: [
                  const Icon(Icons.flag_rounded, color: Colors.white, size: 30),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Servis berikutnya',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          [
                            if (dueDate != null) dateFmt(dueDate),
                            if (dueKm != null) km(dueKm),
                          ].join('  atau  '),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (_mode == IntervalMode.both)
                          const Text(
                            '(mana yang lebih dulu tercapai)',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Button3D(
              label: _isEdit ? 'Simpan Perubahan' : 'Buat Pengingat',
              icon: Icons.alarm_on_rounded,
              loading: _saving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
    child: Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        color: AppColors.muted,
      ),
    ),
  );
}

class _PresetTile extends StatelessWidget {
  final ServicePreset preset;
  final bool selected;
  final VoidCallback onTap;
  const _PresetTile({
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: selected ? preset.color.withValues(alpha: 0.14) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? preset.color : Colors.transparent,
            width: 2,
          ),
          boxShadow: const [
            BoxShadow(color: Color(0xFFD4D8F5), offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconTile3D(icon: preset.icon, color: preset.color, size: 36),
            const SizedBox(height: 6),
            Text(
              preset.title,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  final int value;
  final String suffix;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  const _Stepper({
    required this.value,
    required this.suffix,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _btn(
          Icons.remove_rounded,
          value > min ? () => onChanged(value - 1) : null,
        ),
        SizedBox(
          width: 72,
          child: Text(
            '$value $suffix',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        _btn(
          Icons.add_rounded,
          value < max ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }

  Widget _btn(IconData i, VoidCallback? onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: onTap == null
            ? AppColors.bg
            : AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        i,
        size: 18,
        color: onTap == null ? AppColors.muted : AppColors.primary,
      ),
    ),
  );
}
