import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/models.dart';
import 'notification_service.dart';

/// Real-time Firestore data for the signed-in user.
/// Structure: users/{uid}/vehicles, users/{uid}/reminders, users/{uid}/records
class DataService extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;
  String? _uid;
  final List<StreamSubscription> _subs = [];

  List<Vehicle> vehicles = [];
  List<ServiceReminder> reminders = [];
  List<ServiceRecord> records = [];
  bool loading = false;
  String? error;
  final Set<String> _loaded = {};

  void bindUser(String? uid) {
    if (uid == _uid) return;
    _uid = uid;
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    vehicles = [];
    reminders = [];
    records = [];
    _loaded.clear();
    error = null;
    if (uid == null) {
      loading = false;
      NotificationService.instance.cancelAll();
      notifyListeners();
      return;
    }
    loading = true;
    notifyListeners();
    _listen('vehicles', (docs) {
      vehicles = docs.map((d) => Vehicle.fromMap(d.id, d.data())).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    });
    _listen('reminders', (docs) {
      reminders = docs
          .map((d) => ServiceReminder.fromMap(d.id, d.data()))
          .toList();
    });
    _listen('records', (docs) {
      records = docs.map((d) => ServiceRecord.fromMap(d.id, d.data())).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    });
  }

  void _listen(
    String name,
    void Function(List<QueryDocumentSnapshot<Map<String, dynamic>>>) apply,
  ) {
    _subs.add(
      _col(name).snapshots().listen(
        (snap) {
          apply(snap.docs);
          _loaded.add(name);
          if (_loaded.length >= 3) loading = false;
          error = null;
          notifyListeners();
          _reschedule();
        },
        onError: (e) {
          loading = false;
          error = e.toString().contains('permission')
              ? 'Akses database ditolak. Periksa Firestore Security Rules.'
              : e.toString().contains('not exist') ||
                    e.toString().contains('NOT_FOUND')
              ? 'Database Firestore belum dibuat di Firebase Console.'
              : 'Gagal memuat data: $e';
          notifyListeners();
        },
      ),
    );
  }

  CollectionReference<Map<String, dynamic>> _col(String name) =>
      _db.collection('users').doc(_uid).collection(name);

  Timer? _debounce;
  void _reschedule() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () {
      NotificationService.instance.scheduleAll(this);
    });
  }

  // ------------ Lookups ------------
  Vehicle? vehicleById(String id) {
    for (final v in vehicles) {
      if (v.id == id) return v;
    }
    return null;
  }

  List<ServiceReminder> remindersFor(String vehicleId) =>
      reminders.where((r) => r.vehicleId == vehicleId).toList()..sort((a, b) {
        final v = vehicleById(vehicleId);
        if (v == null) return 0;
        return a.estimatedDueDate(v).compareTo(b.estimatedDueDate(v));
      });

  List<ServiceRecord> recordsFor(String vehicleId) =>
      records.where((r) => r.vehicleId == vehicleId).toList();

  /// Active reminders sorted by urgency across all vehicles.
  List<(ServiceReminder, Vehicle)> get upcoming {
    final list = <(ServiceReminder, Vehicle)>[];
    for (final r in reminders) {
      if (!r.active) continue;
      final v = vehicleById(r.vehicleId);
      if (v != null) list.add((r, v));
    }
    list.sort(
      (a, b) =>
          a.$1.estimatedDueDate(a.$2).compareTo(b.$1.estimatedDueDate(b.$2)),
    );
    return list;
  }

  int countStatus(DueStatus s) =>
      upcoming.where((e) => e.$1.status(e.$2) == s).length;

  int get totalCost => records.fold(0, (a, r) => a + r.cost);

  int costThisYear() {
    final y = DateTime.now().year;
    return records.where((r) => r.date.year == y).fold(0, (a, r) => a + r.cost);
  }

  // ------------ Vehicles ------------
  Future<void> saveVehicle(Vehicle v) async {
    if (v.id.isEmpty) {
      await _col('vehicles').add(v.toMap());
    } else {
      await _col('vehicles').doc(v.id).set(v.toMap());
    }
  }

  Future<String> addVehicle(Vehicle v) async {
    final ref = await _col('vehicles').add(v.toMap());
    return ref.id;
  }

  Future<void> updateOdometer(Vehicle v, int km) async {
    await _col(
      'vehicles',
    ).doc(v.id).update({'currentKm': km, 'kmUpdatedAt': Timestamp.now()});
  }

  Future<void> deleteVehicle(String id) async {
    final batch = _db.batch();
    for (final r in reminders.where((r) => r.vehicleId == id)) {
      batch.delete(_col('reminders').doc(r.id));
    }
    for (final r in records.where((r) => r.vehicleId == id)) {
      batch.delete(_col('records').doc(r.id));
    }
    batch.delete(_col('vehicles').doc(id));
    await batch.commit();
  }

  // ------------ Reminders ------------
  Future<void> saveReminder(ServiceReminder r) async {
    if (r.id.isEmpty) {
      await _col('reminders').add(r.toMap());
    } else {
      await _col('reminders').doc(r.id).set(r.toMap());
    }
  }

  Future<void> toggleReminder(ServiceReminder r, bool active) =>
      _col('reminders').doc(r.id).update({'active': active});

  Future<void> deleteReminder(String id) => _col('reminders').doc(id).delete();

  /// Logs a completed service: creates a record, resets the reminder's
  /// baseline, and bumps the odometer if the new KM is higher.
  Future<void> completeService({
    required Vehicle vehicle,
    ServiceReminder? reminder,
    required String title,
    required String category,
    required DateTime date,
    required int km,
    required int cost,
    required String workshop,
    required String notes,
  }) async {
    final batch = _db.batch();
    batch.set(
      _col('records').doc(),
      ServiceRecord(
        id: '',
        vehicleId: vehicle.id,
        reminderId: reminder?.id,
        title: title,
        category: category,
        date: date,
        km: km,
        cost: cost,
        workshop: workshop,
        notes: notes,
      ).toMap(),
    );
    if (reminder != null) {
      batch.update(_col('reminders').doc(reminder.id), {
        'lastServiceDate': Timestamp.fromDate(date),
        'lastServiceKm': km,
      });
    }
    if (km > vehicle.currentKm) {
      batch.update(_col('vehicles').doc(vehicle.id), {
        'currentKm': km,
        'kmUpdatedAt': Timestamp.now(),
      });
    }
    await batch.commit();
  }

  Future<void> deleteRecord(String id) => _col('records').doc(id).delete();

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _debounce?.cancel();
    super.dispose();
  }
}
