import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/data_service.dart';
import '../services/notification_service.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/three_d.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _notif = NotificationService.instance;

  Future<void> _editName(AuthService auth) async {
    final ctrl = TextEditingController(text: auth.user?.displayName ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ubah nama'),
        content: Input3D(
          controller: ctrl,
          hint: 'Nama',
          icon: Icons.person_rounded,
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
    if (ok == true && ctrl.text.trim().isNotEmpty) {
      await auth.updateName(ctrl.text);
    }
  }

  Future<void> _pickHour(DataService data) async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _notif.notifyHour, minute: 0),
    );
    if (t != null) {
      await _notif.setHour(t.hour, data);
      setState(() {});
    }
  }

  Future<void> _logout(AuthService auth) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar?'),
        content: const Text('Anda akan keluar dari akun ServisKu.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (ok == true) await auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final data = context.watch<DataService>();
    final u = auth.user;
    final needsVerify =
        u != null &&
        (u.email ?? '').isNotEmpty &&
        !u.emailVerified &&
        auth.providerLabel == 'Email';

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 130),
        children: [
          Card3D(
            gradient: AppColors.primaryGradient,
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.primaryDark,
                        offset: Offset(0, 4),
                      ),
                    ],
                    image: (u?.photoURL ?? '').isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(u!.photoURL!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: (u?.photoURL ?? '').isEmpty
                      ? Text(
                          auth.displayName.isEmpty
                              ? '?'
                              : auth.displayName[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        auth.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        u?.email?.isNotEmpty == true
                            ? u!.email!
                            : (u?.phoneNumber ?? ''),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Login via ${auth.providerLabel}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _editName(auth),
                  icon: const Icon(Icons.edit_rounded, color: Colors.white),
                ),
              ],
            ),
          ),
          if (needsVerify) ...[
            const SizedBox(height: 14),
            Card3D(
              color: const Color(0xFFFFF4DE),
              depthColor: const Color(0xFFF5D9A0),
              child: Row(
                children: [
                  const Icon(
                    Icons.mark_email_unread_rounded,
                    color: AppColors.accentDark,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Email belum diverifikasi.',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final m = ScaffoldMessenger.of(context);
                      await auth.resendVerification();
                      m.showSnackBar(
                        const SnackBar(
                          content: Text('Email verifikasi dikirim ulang.'),
                        ),
                      );
                    },
                    child: const Text('Kirim ulang'),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              _MiniStat(
                icon: Icons.garage_rounded,
                value: '${data.vehicles.length}',
                label: 'Kendaraan',
              ),
              const SizedBox(width: 12),
              _MiniStat(
                icon: Icons.alarm_rounded,
                value: '${data.upcoming.length}',
                label: 'Pengingat',
              ),
              const SizedBox(width: 12),
              _MiniStat(
                icon: Icons.build_rounded,
                value: '${data.records.length}',
                label: 'Servis',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Card3D(
            child: Row(
              children: [
                const IconTile3D(
                  icon: Icons.savings_rounded,
                  color: AppColors.success,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total biaya perawatan',
                        style: TextStyle(color: AppColors.muted),
                      ),
                      Text(
                        rupiah(data.totalCost),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SectionTitle('Notifikasi'),
          Card3D(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const IconTile3D(
                    icon: Icons.notifications_active_rounded,
                    color: AppColors.accent,
                    size: 40,
                  ),
                  title: const Text(
                    'Pengingat servis',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    kIsWeb
                        ? 'Notifikasi aktif di aplikasi Android'
                        : 'Notifikasi sebelum & saat jatuh tempo',
                  ),
                  value: _notif.enabled,
                  onChanged: (v) async {
                    await _notif.setEnabled(v, data);
                    setState(() {});
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const IconTile3D(
                    icon: Icons.access_time_filled_rounded,
                    size: 40,
                  ),
                  title: const Text(
                    'Jam notifikasi',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  trailing: Text(
                    '${_notif.notifyHour.toString().padLeft(2, '0')}:00',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                      fontSize: 16,
                    ),
                  ),
                  onTap: () => _pickHour(data),
                ),
                if (!kIsWeb) ...[
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: const IconTile3D(
                      icon: Icons.campaign_rounded,
                      color: AppColors.violet,
                      size: 40,
                    ),
                    title: const Text(
                      'Tes notifikasi',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    onTap: () async {
                      await _notif.requestPermission();
                      await _notif.showTest();
                    },
                  ),
                ],
              ],
            ),
          ),
          const SectionTitle('Lainnya'),
          Card3D(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: [
                ListTile(
                  leading: const IconTile3D(
                    icon: Icons.tips_and_updates_rounded,
                    color: Color(0xFF26C6DA),
                    size: 40,
                  ),
                  title: const Text(
                    'Tips perawatan',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showTips(context),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const IconTile3D(
                    icon: Icons.info_rounded,
                    color: AppColors.primary,
                    size: 40,
                  ),
                  title: const Text(
                    'Tentang ServisKu',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => showAboutDialog(
                    context: context,
                    applicationName: 'ServisKu',
                    applicationVersion: '1.0.0',
                    applicationIcon: Image.asset(
                      'assets/images/logo.png',
                      width: 56,
                    ),
                    children: const [
                      Text(
                        'Pengingat servis kendaraan per bulan atau per KM. Data tersimpan aman di cloud.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Button3D(
            label: 'Keluar',
            icon: Icons.logout_rounded,
            color: AppColors.danger,
            depthColor: AppColors.dangerDark,
            onPressed: () => _logout(auth),
          ),
        ],
      ),
    );
  }

  void _showTips(BuildContext context) {
    const tips = [
      (
        Icons.oil_barrel_rounded,
        'Ganti oli tepat waktu',
        'Motor: tiap 2.000–3.000 km. Mobil: tiap 5.000–10.000 km atau 6 bulan.',
      ),
      (
        Icons.tire_repair_rounded,
        'Cek tekanan ban',
        'Periksa minimal 2 minggu sekali. Tekanan ideal ada di stiker pintu/swing arm.',
      ),
      (
        Icons.battery_charging_full_rounded,
        'Rawat aki',
        'Cek kondisi aki tiap 6 bulan, terutama jika kendaraan jarang dipakai.',
      ),
      (
        Icons.album_rounded,
        'Kampas rem',
        'Ganti bila tebal < 2 mm atau rem terdengar berdecit.',
      ),
      (
        Icons.receipt_long_rounded,
        'Pajak & STNK',
        'Bayar pajak tahunan sebelum jatuh tempo untuk menghindari denda.',
      ),
    ];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (ctx, s) => ListView(
          controller: s,
          padding: const EdgeInsets.all(22),
          children: [
            const Text(
              'Tips Perawatan',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            for (final t in tips)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card3D(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconTile3D(icon: t.$1, size: 40),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.$2,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              t.$3,
                              style: const TextStyle(
                                color: AppColors.muted,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _MiniStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card3D(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
