import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/data_service.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/three_d.dart';

class VehicleFormScreen extends StatefulWidget {
  final Vehicle? vehicle;
  const VehicleFormScreen({super.key, this.vehicle});

  @override
  State<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends State<VehicleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final Vehicle? v = widget.vehicle;
  late final _name = TextEditingController(text: v?.name ?? '');
  late final _brand = TextEditingController(text: v?.brand ?? '');
  late final _plate = TextEditingController(text: v?.plate ?? '');
  late final _year = TextEditingController(
    text: (v?.year ?? DateTime.now().year).toString(),
  );
  late final _km = TextEditingController(text: (v?.currentKm ?? 0).toString());
  late final _avg = TextEditingController(
    text: (v?.avgKmPerDay ?? 30).toString(),
  );
  late VehicleType _type = v?.type ?? VehicleType.motor;
  late int _color = v?.colorValue ?? vehicleColors.first;
  bool _addPresets = true;
  bool _saving = false;

  bool get _isEdit => v != null;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final data = context.read<DataService>();
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final kmVal = parseInt(_km.text);
    final kmChanged = !_isEdit || kmVal != v!.currentKm;
    final vehicle = Vehicle(
      id: v?.id ?? '',
      name: _name.text.trim(),
      brand: _brand.text.trim(),
      plate: _plate.text.trim().toUpperCase(),
      year: parseInt(_year.text),
      type: _type,
      currentKm: kmVal,
      avgKmPerDay: parseInt(_avg.text).clamp(1, 1000),
      kmUpdatedAt: kmChanged ? DateTime.now() : v!.kmUpdatedAt,
      colorValue: _color,
      createdAt: v?.createdAt ?? DateTime.now(),
    );
    try {
      if (_isEdit) {
        await data.saveVehicle(vehicle);
      } else {
        final id = await data.addVehicle(vehicle);
        if (_addPresets) {
          await data.addReminders([
            for (final key in ['oli', 'servis', 'pajak'])
              ServiceReminder(
                id: '',
                vehicleId: id,
                title: presetFor(key).title,
                category: key,
                mode: presetFor(key).mode,
                intervalMonths: presetFor(key).months,
                intervalKm: _type == VehicleType.motor
                    ? presetFor(key).kmMotor
                    : presetFor(key).kmMobil,
                lastServiceDate: DateTime.now(),
                lastServiceKm: kmVal,
                notifyDaysBefore: 7,
                notifyKmBefore: _type == VehicleType.motor ? 200 : 500,
                active: true,
                notes: '',
                createdAt: DateTime.now(),
              ),
          ]);
        }
      }
      nav.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _isEdit
                ? 'Kendaraan diperbarui.'
                : 'Kendaraan ${vehicle.name} ditambahkan!',
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
    final color = Color(_color);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Kendaraan' : 'Tambah Kendaraan'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
            children: [
              // Live 3D preview card
              Card3D(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color.lerp(color, Colors.white, 0.25)!, color],
                ),
                depthColor: Color.lerp(color, Colors.black, 0.4),
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(
                        _type == VehicleType.motor
                            ? Icons.two_wheeler_rounded
                            : Icons.directions_car_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _name.text.isEmpty ? 'Nama kendaraan' : _name.text,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            _plate.text.isEmpty
                                ? 'Plat nomor'
                                : _plate.text.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const _Label('Jenis kendaraan'),
              Row(
                children: [
                  Expanded(
                    child: _TypeOption(
                      icon: Icons.two_wheeler_rounded,
                      label: 'Motor',
                      selected: _type == VehicleType.motor,
                      onTap: () => setState(() => _type = VehicleType.motor),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TypeOption(
                      icon: Icons.directions_car_rounded,
                      label: 'Mobil',
                      selected: _type == VehicleType.mobil,
                      onTap: () => setState(() => _type = VehicleType.mobil),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const _Label('Detail'),
              Input3D(
                controller: _name,
                hint: 'Nama kendaraan (mis. Vario 160)',
                icon: Icons.label_rounded,
                onChanged: (_) => setState(() {}),
                validator: (s) =>
                    (s == null || s.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Input3D(
                      controller: _brand,
                      hint: 'Merek',
                      icon: Icons.factory_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Input3D(
                      controller: _year,
                      hint: 'Tahun',
                      icon: Icons.calendar_today_rounded,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Input3D(
                controller: _plate,
                hint: 'Plat nomor (mis. B 1234 XYZ)',
                icon: Icons.pin_rounded,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 18),
              const _Label('Odometer & pemakaian'),
              Input3D(
                controller: _km,
                hint: 'KM saat ini',
                icon: Icons.speed_rounded,
                keyboardType: TextInputType.number,
                validator: (s) =>
                    (s == null || s.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 14),
              Input3D(
                controller: _avg,
                hint: 'Rata-rata km per hari',
                icon: Icons.route_rounded,
                keyboardType: TextInputType.number,
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(6, 8, 6, 0),
                child: Text(
                  'Rata-rata km/hari dipakai untuk memperkirakan kapan servis berbasis KM jatuh tempo.',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ),
              const SizedBox(height: 18),
              const _Label('Warna kartu'),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final c in vehicleColors)
                    GestureDetector(
                      onTap: () => setState(() => _color = c),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Color(c),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _color == c
                                ? Colors.white
                                : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color.lerp(Color(c), Colors.black, 0.4)!,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: _color == c
                            ? const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ),
                ],
              ),
              if (!_isEdit) ...[
                const SizedBox(height: 18),
                Card3D(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: SwitchListTile(
                    value: _addPresets,
                    onChanged: (b) => setState(() => _addPresets = b),
                    title: const Text(
                      'Buat pengingat standar',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: const Text(
                      'Ganti oli, servis berkala & pajak STNK otomatis dibuat.',
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 26),
              Button3D(
                label: _isEdit ? 'Simpan Perubahan' : 'Tambah Kendaraan',
                icon: Icons.save_rounded,
                loading: _saving,
                onPressed: _save,
              ),
            ],
          ),
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

class _TypeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TypeOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card3D(
      onTap: onTap,
      depth: selected ? 6 : 4,
      gradient: selected ? AppColors.primaryGradient : null,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Icon(
            icon,
            size: 34,
            color: selected ? Colors.white : AppColors.primary,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: selected ? Colors.white : AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
