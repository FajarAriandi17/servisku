import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../theme.dart';

DateTime _toDate(dynamic v) {
  if (v is Timestamp) return v.toDate();
  if (v is DateTime) return v;
  if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
  if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
  return DateTime.now();
}

int _toInt(dynamic v, [int def = 0]) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? def;
  return def;
}

enum VehicleType { motor, mobil }

class Vehicle {
  final String id;
  final String name;
  final String brand;
  final String plate;
  final int year;
  final VehicleType type;
  final int currentKm;
  final int avgKmPerDay;
  final DateTime kmUpdatedAt;
  final int colorValue;
  final DateTime createdAt;

  Vehicle({
    required this.id,
    required this.name,
    required this.brand,
    required this.plate,
    required this.year,
    required this.type,
    required this.currentKm,
    required this.avgKmPerDay,
    required this.kmUpdatedAt,
    required this.colorValue,
    required this.createdAt,
  });

  Color get color => Color(colorValue);
  IconData get icon => type == VehicleType.motor
      ? Icons.two_wheeler_rounded
      : Icons.directions_car_rounded;
  String get typeLabel => type == VehicleType.motor ? 'Motor' : 'Mobil';

  /// Odometer estimate for today based on daily average usage.
  int get estimatedKm {
    final days = DateTime.now().difference(kmUpdatedAt).inDays;
    return currentKm + (days > 0 ? days * avgKmPerDay : 0);
  }

  factory Vehicle.fromMap(String id, Map<String, dynamic> d) => Vehicle(
    id: id,
    name: (d['name'] as String?) ?? 'Kendaraan',
    brand: (d['brand'] as String?) ?? '',
    plate: (d['plate'] as String?) ?? '',
    year: _toInt(d['year'], DateTime.now().year),
    type: (d['type'] as String?) == 'mobil'
        ? VehicleType.mobil
        : VehicleType.motor,
    currentKm: _toInt(d['currentKm']),
    avgKmPerDay: _toInt(d['avgKmPerDay'], 30),
    kmUpdatedAt: _toDate(d['kmUpdatedAt']),
    colorValue: _toInt(d['color'], AppColors.primary.toARGB32()),
    createdAt: _toDate(d['createdAt']),
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'brand': brand,
    'plate': plate,
    'year': year,
    'type': type.name,
    'currentKm': currentKm,
    'avgKmPerDay': avgKmPerDay,
    'kmUpdatedAt': Timestamp.fromDate(kmUpdatedAt),
    'color': colorValue,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}

/// How a reminder interval is measured.
enum IntervalMode { month, km, both }

extension IntervalModeX on IntervalMode {
  String get label => switch (this) {
    IntervalMode.month => 'Per Bulan',
    IntervalMode.km => 'Per KM',
    IntervalMode.both => 'Bulan & KM',
  };
}

enum DueStatus { ok, soon, overdue }

extension DueStatusX on DueStatus {
  String get label => switch (this) {
    DueStatus.ok => 'Aman',
    DueStatus.soon => 'Segera',
    DueStatus.overdue => 'Terlambat',
  };
  Color get color => switch (this) {
    DueStatus.ok => AppColors.success,
    DueStatus.soon => AppColors.warning,
    DueStatus.overdue => AppColors.danger,
  };
}

class ServiceReminder {
  final String id;
  final String vehicleId;
  final String title;
  final String category;
  final IntervalMode mode;
  final int intervalMonths;
  final int intervalKm;
  final DateTime lastServiceDate;
  final int lastServiceKm;
  final int notifyDaysBefore;
  final int notifyKmBefore;
  final bool active;
  final String notes;
  final DateTime createdAt;

  ServiceReminder({
    required this.id,
    required this.vehicleId,
    required this.title,
    required this.category,
    required this.mode,
    required this.intervalMonths,
    required this.intervalKm,
    required this.lastServiceDate,
    required this.lastServiceKm,
    required this.notifyDaysBefore,
    required this.notifyKmBefore,
    required this.active,
    required this.notes,
    required this.createdAt,
  });

  bool get usesMonth => mode != IntervalMode.km;
  bool get usesKm => mode != IntervalMode.month;

  DateTime? get dueDate {
    if (!usesMonth) return null;
    final d = lastServiceDate;
    return DateTime(d.year, d.month + intervalMonths, d.day, 9);
  }

  int? get dueKm => usesKm ? lastServiceKm + intervalKm : null;

  int? daysLeft() {
    final dd = dueDate;
    if (dd == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return DateTime(dd.year, dd.month, dd.day).difference(today).inDays;
  }

  int? kmLeft(Vehicle v) => usesKm ? dueKm! - v.estimatedKm : null;

  /// Best estimate of when the service will be due (used for notifications
  /// and sorting). For KM mode it uses the vehicle's daily average.
  DateTime estimatedDueDate(Vehicle v) {
    DateTime? byDate = dueDate;
    DateTime? byKm;
    if (usesKm) {
      final left = kmLeft(v)!;
      final perDay = v.avgKmPerDay <= 0 ? 1 : v.avgKmPerDay;
      final days = (left / perDay).floor();
      final now = DateTime.now();
      byKm = DateTime(
        now.year,
        now.month,
        now.day,
        9,
      ).add(Duration(days: days));
    }
    if (byDate != null && byKm != null) {
      return byDate.isBefore(byKm) ? byDate : byKm;
    }
    return byDate ?? byKm!;
  }

  double progress(Vehicle v) {
    double p = 0;
    if (usesMonth) {
      final total = dueDate!.difference(lastServiceDate).inHours;
      final done = DateTime.now().difference(lastServiceDate).inHours;
      if (total > 0) p = done / total;
    }
    if (usesKm && intervalKm > 0) {
      final kp = (v.estimatedKm - lastServiceKm) / intervalKm;
      if (kp > p) p = kp;
    }
    return p.clamp(0, 1.2);
  }

  DueStatus status(Vehicle v) {
    bool overdue = false;
    bool soon = false;
    final dl = daysLeft();
    if (dl != null) {
      if (dl < 0) overdue = true;
      if (dl <= notifyDaysBefore) soon = true;
    }
    final kl = kmLeft(v);
    if (kl != null) {
      if (kl < 0) overdue = true;
      if (kl <= notifyKmBefore) soon = true;
    }
    if (overdue) return DueStatus.overdue;
    if (soon) return DueStatus.soon;
    return DueStatus.ok;
  }

  factory ServiceReminder.fromMap(String id, Map<String, dynamic> d) {
    final m = (d['mode'] as String?) ?? 'month';
    return ServiceReminder(
      id: id,
      vehicleId: (d['vehicleId'] as String?) ?? '',
      title: (d['title'] as String?) ?? 'Servis',
      category: (d['category'] as String?) ?? 'servis',
      mode: IntervalMode.values.firstWhere(
        (e) => e.name == m,
        orElse: () => IntervalMode.month,
      ),
      intervalMonths: _toInt(d['intervalMonths'], 3),
      intervalKm: _toInt(d['intervalKm'], 2000),
      lastServiceDate: _toDate(d['lastServiceDate']),
      lastServiceKm: _toInt(d['lastServiceKm']),
      notifyDaysBefore: _toInt(d['notifyDaysBefore'], 7),
      notifyKmBefore: _toInt(d['notifyKmBefore'], 200),
      active: (d['active'] as bool?) ?? true,
      notes: (d['notes'] as String?) ?? '',
      createdAt: _toDate(d['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'vehicleId': vehicleId,
    'title': title,
    'category': category,
    'mode': mode.name,
    'intervalMonths': intervalMonths,
    'intervalKm': intervalKm,
    'lastServiceDate': Timestamp.fromDate(lastServiceDate),
    'lastServiceKm': lastServiceKm,
    'notifyDaysBefore': notifyDaysBefore,
    'notifyKmBefore': notifyKmBefore,
    'active': active,
    'notes': notes,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}

class ServiceRecord {
  final String id;
  final String vehicleId;
  final String? reminderId;
  final String title;
  final String category;
  final DateTime date;
  final int km;
  final int cost;
  final String workshop;
  final String notes;

  ServiceRecord({
    required this.id,
    required this.vehicleId,
    this.reminderId,
    required this.title,
    required this.category,
    required this.date,
    required this.km,
    required this.cost,
    required this.workshop,
    required this.notes,
  });

  factory ServiceRecord.fromMap(String id, Map<String, dynamic> d) =>
      ServiceRecord(
        id: id,
        vehicleId: (d['vehicleId'] as String?) ?? '',
        reminderId: d['reminderId'] as String?,
        title: (d['title'] as String?) ?? 'Servis',
        category: (d['category'] as String?) ?? 'servis',
        date: _toDate(d['date']),
        km: _toInt(d['km']),
        cost: _toInt(d['cost']),
        workshop: (d['workshop'] as String?) ?? '',
        notes: (d['notes'] as String?) ?? '',
      );

  Map<String, dynamic> toMap() => {
    'vehicleId': vehicleId,
    'reminderId': reminderId,
    'title': title,
    'category': category,
    'date': Timestamp.fromDate(date),
    'km': km,
    'cost': cost,
    'workshop': workshop,
    'notes': notes,
  };
}

/// Ready-made service templates for quick setup.
class ServicePreset {
  final String key;
  final String title;
  final IconData icon;
  final Color color;
  final IntervalMode mode;
  final int months;
  final int kmMotor;
  final int kmMobil;

  const ServicePreset(
    this.key,
    this.title,
    this.icon,
    this.color,
    this.mode,
    this.months,
    this.kmMotor,
    this.kmMobil,
  );
}

const servicePresets = <ServicePreset>[
  ServicePreset(
    'oli',
    'Ganti Oli Mesin',
    Icons.oil_barrel_rounded,
    Color(0xFFFFA726),
    IntervalMode.both,
    2,
    2000,
    5000,
  ),
  ServicePreset(
    'servis',
    'Servis Berkala',
    Icons.build_circle_rounded,
    Color(0xFF5B6CFF),
    IntervalMode.both,
    4,
    4000,
    10000,
  ),
  ServicePreset(
    'filter',
    'Filter Udara',
    Icons.air_rounded,
    Color(0xFF26C6DA),
    IntervalMode.km,
    6,
    8000,
    20000,
  ),
  ServicePreset(
    'busi',
    'Ganti Busi',
    Icons.bolt_rounded,
    Color(0xFFFFCA28),
    IntervalMode.km,
    6,
    8000,
    20000,
  ),
  ServicePreset(
    'rem',
    'Kampas Rem',
    Icons.album_rounded,
    Color(0xFFFF5470),
    IntervalMode.km,
    12,
    10000,
    30000,
  ),
  ServicePreset(
    'ban',
    'Cek / Ganti Ban',
    Icons.tire_repair_rounded,
    Color(0xFF7E57C2),
    IntervalMode.km,
    24,
    15000,
    40000,
  ),
  ServicePreset(
    'aki',
    'Cek Aki',
    Icons.battery_charging_full_rounded,
    Color(0xFF22C38E),
    IntervalMode.month,
    6,
    0,
    0,
  ),
  ServicePreset(
    'gardan',
    'Oli Gardan / Transmisi',
    Icons.settings_rounded,
    Color(0xFF8D6E63),
    IntervalMode.km,
    6,
    8000,
    40000,
  ),
  ServicePreset(
    'pajak',
    'Pajak Kendaraan (STNK)',
    Icons.receipt_long_rounded,
    Color(0xFF42A5F5),
    IntervalMode.month,
    12,
    0,
    0,
  ),
  ServicePreset(
    'lainnya',
    'Lainnya',
    Icons.handyman_rounded,
    Color(0xFF78909C),
    IntervalMode.month,
    3,
    3000,
    5000,
  ),
];

ServicePreset presetFor(String key) => servicePresets.firstWhere(
  (p) => p.key == key,
  orElse: () => servicePresets.last,
);

const vehicleColors = <int>[
  0xFF5B6CFF,
  0xFF6A4DFF,
  0xFFFF5470,
  0xFFFFA726,
  0xFF22C38E,
  0xFF26C6DA,
  0xFF1C2238,
  0xFF8D6E63,
];
