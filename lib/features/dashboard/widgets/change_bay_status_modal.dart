import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/bay_job.dart';

class ChangeBayStatusModal extends StatelessWidget {
  final BayJob job;
  final ValueChanged<String> onStatusSelected;

  const ChangeBayStatusModal({
    super.key,
    required this.job,
    required this.onStatusSelected,
  });

  static void show(
    BuildContext context, {
    required BayJob job,
    required ValueChanged<String> onStatusSelected,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ChangeBayStatusModal(
        job: job,
        onStatusSelected: onStatusSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statuses = [
      {
        'key': 'ready_for_pickup',
        'title': 'Ready for Pickup',
        'subtitle': 'Work finished, car washed, awaiting customer',
        'icon': Icons.check_circle_outline_rounded,
        'color': AppColors.success,
        'bg': AppColors.successLight,
      },
      {
        'key': 'in_progress',
        'title': 'In Progress',
        'subtitle': 'Technician currently working on vehicle in bay',
        'icon': Icons.autorenew_rounded,
        'color': AppColors.primary,
        'bg': AppColors.primaryLight,
      },
      {
        'key': 'waiting_for_parts',
        'title': 'Waiting for Parts',
        'subtitle': 'On hold pending arrival of required spare parts',
        'icon': Icons.schedule_rounded,
        'color': AppColors.warning,
        'bg': AppColors.warningLight,
      },
      {
        'key': 'completed',
        'title': 'Completed & Settled',
        'subtitle': 'Customer paid and vehicle has left the bay',
        'icon': Icons.task_alt_rounded,
        'color': AppColors.textSecondary,
        'bg': const Color(0xFFF1F5F9),
      },
    ];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Update ${job.bayNumber} Status',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${job.vehicleModel} • ${job.customerName}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 12),
            ...statuses.map((s) {
              final isCurrent = job.status == s['key'];
              final color = s['color'] as Color;
              final bg = s['bg'] as Color;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: isCurrent ? bg : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).pop();
                      onStatusSelected(s['key'] as String);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isCurrent ? color : AppColors.border,
                          width: isCurrent ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isCurrent ? color : bg,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              s['icon'] as IconData,
                              size: 20,
                              color: isCurrent ? Colors.white : color,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s['title'] as String,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: isCurrent ? color : AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  s['subtitle'] as String,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isCurrent)
                            Icon(Icons.check_circle, color: color, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
