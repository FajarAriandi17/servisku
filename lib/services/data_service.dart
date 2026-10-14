import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';
import 'notification_service.dart';

/// Data for the signed-in user stored in Supabase Postgres.
/// Tables: vehicles, reminders, records (Row Level Security per user).
class DataService extends ChangeNotifier {
  SupabaseClient get _db => Supabase.instance.client;
  String? _uid;

  List<Vehicle> vehicles = [];
  List<ServiceReminder> reminders = [];
  List<ServiceRecord> records = [];
  bool loading = false;
  String? error;

  void bindUser(String? uid) {
    if (uid == _uid) return;
    _uid = uid;
    vehicles = [];
    reminders = [];
    records = [];
    error = null;
    if (uid == null) {
      loading = false;
      NotificationService.instance.cancelAll();
      notifyListeners();
      return;
    }
    loading = true;
    notifyListeners();
    refresh();
  }

  Future<void> refresh() async {
    if (_uid == null) return;
    try {
      final results = await Future.wait([
        _db.from('vehicles').select().eq('user_id', _uid!),
        _db.from('reminders').select().eq('user_id', _uid!),
        _db.from('records').select().eq('user_id', _uid!),
      ]);
      vehicles =
          results[0].map((d) => Vehicle.fromMap(d['id'] as String, d)).toList()
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      reminders = results[1]
          .map((d) => ServiceReminder.fromMap(d['id'] as String, d))
          .toList();
      records =
          results[2]
              .map((d) => ServiceRecord.fromMap(d['id'] as String, d))
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date));
      error = null;
    } on PostgrestException catch (e) {
      error = (e.code == 'PGRST205' || e.code == '42P01')
          ? 'Tabel database belum dibuat. Jalankan file supabase/schema.sql di Supabase SQL Editor.'
          : 'Gagal memuat data: ${e.message}';
    } catch (e) {
      error = 'Gagal memuat data. Periksa koneksi internet.';
      debugPrint('refresh error: $e');
    }
    loading = false;
    notifyListeners();
    NotificationService.instance.scheduleAll(this);
  }

  Map<String, dynamic> _withUser(Map<String, dynamic> m) => {
    ...m,
    'user_id': _uid,
  };

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
      await _db.from('vehicles').insert(_withUser(v.toMap()));
    } else {
      await _db.from('vehicles').update(v.toMap()).eq('id', v.id);
    }
    await refresh();
  }

  Future<String> addVehicle(Vehicle v) async {
    final row = await _db
        .from('vehicles')
        .insert(_withUser(v.toMap()))
        .select('id')
        .single();
    await refresh();
    return row['id'] as String;
  }

  Future<void> updateOdometer(Vehicle v, int km) async {
    await _db
        .from('vehicles')
        .update({
          'current_km': km,
          'km_updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', v.id);
    await refresh();
  }

  Future<void> deleteVehicle(String id) async {
    // reminders & records cascade-delete via foreign keys
    await _db.from('vehicles').delete().eq('id', id);
    await refresh();
  }

  // ------------ Reminders ------------
  Future<void> saveReminder(ServiceReminder r) async {
    if (r.id.isEmpty) {
      await _db.from('reminders').insert(_withUser(r.toMap()));
    } else {
      await _db.from('reminders').update(r.toMap()).eq('id', r.id);
    }
    await refresh();
  }

  Future<void> addReminders(List<ServiceReminder> list) async {
    if (list.isEmpty) return;
    await _db
        .from('reminders')
        .insert(list.map((r) => _withUser(r.toMap())).toList());
    await refresh();
  }

  Future<void> toggleReminder(ServiceReminder r, bool active) async {
    await _db.from('reminders').update({'active': active}).eq('id', r.id);
    await refresh();
  }

  Future<void> deleteReminder(String id) async {
    await _db.from('reminders').delete().eq('id', id);
    await refresh();
  }

  /// Logs a completed service, resets the reminder baseline and bumps
  /// the odometer if needed.
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
    await _db
        .from('records')
        .insert(
          _withUser(
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
          ),
        );
    if (reminder != null) {
      await _db
          .from('reminders')
          .update({
            'last_service_date': date.toUtc().toIso8601String(),
            'last_service_km': km,
          })
          .eq('id', reminder.id);
    }
    if (km > vehicle.currentKm) {
      await _db
          .from('vehicles')
          .update({
            'current_km': km,
            'km_updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', vehicle.id);
    }
    await refresh();
  }

  Future<void> deleteRecord(String id) async {
    await _db.from('records').delete().eq('id', id);
    await refresh();
  }
}
