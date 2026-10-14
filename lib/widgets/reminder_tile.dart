import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme.dart';
import '../utils/format.dart';
import 'three_d.dart';

class ReminderTile extends StatelessWidget {
  final ServiceReminder reminder;
  final Vehicle vehicle;
  final bool showVehicle;
  final VoidCallback? onTap;
  final VoidCallback? onDone;

  const ReminderTile({
    super.key,
    required this.reminder,
    required this.vehicle,
    this.showVehicle = true,
    this.onTap,
    this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final r = reminder;
    final preset = presetFor(r.category);
    final status = r.active ? r.status(vehicle) : DueStatus.ok;
    final color = r.active ? status.color : AppColors.muted;
    final dl = r.daysLeft();
    final kl = r.kmLeft(vehicle);
    final pct = (r.progress(vehicle) * 100).clamp(0, 100).round();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Card3D(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: Opacity(
          opacity: r.active ? 1 : 0.55,
          child: Row(
            children: [
              GaugeRing(
                progress: r.progress(vehicle),
                color: color,
                size: 60,
                stroke: 6,
                center: Icon(preset.icon, color: preset.color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            r.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15.5,
                            ),
                          ),
                        ),
                        StatusChip(
                          label: r.active ? status.label : 'Nonaktif',
                          color: color,
                        ),
                      ],
                    ),
                    if (showVehicle) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${vehicle.name}${vehicle.plate.isEmpty ? '' : ' • ${vehicle.plate}'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (dl != null)
                          _Pill(
                            icon: Icons.event_rounded,
                            text: '${daysLabel(dl)} • ${dateShort(r.dueDate!)}',
                          ),
                        if (kl != null)
                          _Pill(
                            icon: Icons.speed_rounded,
                            text: '${kmLeftLabel(kl)} • ${numFmt(r.dueKm!)}',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onDone != null) ...[
                const SizedBox(width: 8),
                Column(
                  children: [
                    InkWell(
                      onTap: onDone,
                      borderRadius: BorderRadius.circular(14),
                      child: const IconTile3D(
                        icon: Icons.check_rounded,
                        color: AppColors.success,
                        size: 38,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$pct%',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Pill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
