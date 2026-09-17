import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/currency/currency_manager.dart';
import '../../../core/localization/app_locale.dart';
import '../../../data/models/bay_job.dart';
import '../../../data/repositories/garage_repository.dart';
import '../../../shared/utils/communication_helper.dart';
import '../../../shared/widgets/statement_modal_helper.dart';
import 'edit_job_modal.dart';
import 'settle_job_modal.dart';

class JobCard extends StatelessWidget {
  final BayJob job;

  const JobCard({
    super.key,
    required this.job,
  });

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<CurrencyManager>();
    final locale = context.watch<AppLocale>();
    final repo = context.read<GarageRepository>();

    final isWaiting = job.isWaiting;
    final isReady = job.isReadyForPickup;
    final isCompleted = job.isCompleted;

    // Status colors and labels
    Color statusBg;
    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    if (isWaiting) {
      statusBg = const Color(0xFFFEF3C7);
      statusColor = AppColors.warning;
      statusIcon = Icons.hourglass_top_rounded;
      statusLabel = locale.isBangla ? 'অপেক্ষমান' : 'Waiting';
    } else if (isReady) {
      statusBg = const Color(0xFFE0F2FE);
      statusColor = AppColors.primary;
      statusIcon = Icons.check_circle_rounded;
      statusLabel = locale.isBangla ? 'গাড়ি প্রস্তুত' : 'Ready for Pickup';
    } else {
      statusBg = const Color(0xFFD1FAE5);
      statusColor = AppColors.success;
      statusIcon = Icons.done_all_rounded;
      statusLabel = locale.isBangla ? 'সম্পন্ন' : 'Completed';
    }

    final dateFormat = DateFormat('dd MMM, hh:mm a');
    final formattedTime = dateFormat.format(job.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Bay Pill & Status Pill with Print Receipt action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.build_circle_outlined, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        job.bayNumber,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 14, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            statusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.receipt_long_rounded, size: 20, color: AppColors.textSecondary),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      tooltip: locale.isBangla ? 'রসিদ / স্লিপ প্রিন্ট' : 'Print Job Receipt',
                      onPressed: () => _showJobReceiptModal(context, repo, currency, locale),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Row 2: Customer Name, Phone, Vehicle info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.customerName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (job.vehicleModel.isNotEmpty) ...[
                            Icon(Icons.directions_car_rounded, size: 14, color: AppColors.textSecondary.withValues(alpha: 0.8)),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                job.vehicleModel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                          if (job.plateNumber.isNotEmpty) ...[
                            Text(
                              job.vehicleModel.isNotEmpty ? ' • ' : '',
                              style: const TextStyle(color: AppColors.textSecondary),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Text(
                                job.plateNumber,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Quoted / Total Cost badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currency.format(isCompleted ? (job.settledAmount ?? job.estimatedCost) : job.estimatedCost),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      isCompleted ? (locale.isBangla ? 'পরিশোধিত' : 'Final Bill') : (locale.isBangla ? 'ধার্যকৃত মূল্য' : 'Quoted Bill'),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Row 3: Task Description Container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.taskDescription,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  if (job.technicianName.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.person_outline_rounded, size: 13, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${locale.isBangla ? 'কারিগর' : 'Tech'}: ${job.technicianName}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Metadata: Time recorded & Customer Phone Action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formattedTime,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (job.customerPhone.isNotEmpty)
                  InkWell(
                    onTap: () => CommunicationHelper.makePhoneCall(context, job.customerPhone),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.phone_rounded, size: 13, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            job.customerPhone,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // Completed Settlement breakdown if completed
            if (isCompleted) ...[
              const SizedBox(height: 8),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, size: 14, color: AppColors.success),
                      const SizedBox(width: 4),
                      Text(
                        '${locale.isBangla ? 'জমা' : 'Paid'}: ${currency.format(job.settledAmount ?? 0)}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  if ((job.dueAmount ?? 0) > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${locale.isBangla ? 'বাকি' : 'Due'}: ${currency.format(job.dueAmount ?? 0)}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.danger),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        locale.isBangla ? 'সম্পূর্ণ পরিশোধিত' : 'Fully Paid',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.success),
                      ),
                    ),
                ],
              ),
            ],

            // Action Buttons based on status
            if (isWaiting) ...[
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        minimumSize: const Size(0, 44),
                      ),
                      icon: const Icon(Icons.edit_note_rounded, size: 18),
                      label: Text(
                        locale.isBangla ? 'এডিট / দরদাম' : 'Edit / Bargain',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      onPressed: () => EditJobModal.show(context, job),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        minimumSize: const Size(0, 44),
                      ),
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                      label: Text(
                        locale.isBangla ? 'গাড়ি প্রস্তুত' : 'Mark Ready',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                      onPressed: () async {
                        await repo.updateBayJobStatus(job.id, 'ready_for_pickup');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Job #${job.bayNumber} is marked Ready for Pickup!'),
                              backgroundColor: AppColors.primary,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              showCloseIcon: true,
                              closeIconColor: Colors.white,
                              duration: const Duration(seconds: 8),
                              action: SnackBarAction(
                                label: 'Send WhatsApp',
                                textColor: Colors.white,
                                onPressed: () {
                                  _sendWhatsAppPickupAlert(context, repo, currency);
                                },
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],

            if (isReady) ...[
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 12),
              // 1-Tap WhatsApp Alert Button
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.chat_rounded, size: 18),
                  label: Text(
                    locale.isBangla ? 'হোয়াটসঅ্যাপ মেসেজ দিন (Send Alert)' : 'Send Ready Alert (WhatsApp)',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                  onPressed: () {
                    _sendWhatsAppPickupAlert(context, repo, currency);
                  },
                ),
              ),
              const SizedBox(height: 8),
              // Action Buttons Row: Edit Details & Complete & Settle
              Row(
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      minimumSize: const Size(44, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    icon: const Icon(Icons.edit_note_rounded, size: 18),
                    label: Text(locale.isBangla ? 'এডিট' : 'Edit'),
                    onPressed: () => EditJobModal.show(context, job),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        minimumSize: const Size(0, 48),
                      ),
                      icon: const Icon(Icons.payments_rounded, size: 20),
                      label: Text(
                        locale.isBangla ? 'বিল পরিশোধ ও খালাস (Settle)' : 'Complete & Settle',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                      ),
                      onPressed: () => SettleJobModal.show(context, job),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _sendWhatsAppPickupAlert(BuildContext context, GarageRepository repo, CurrencyManager currency) {
    final workshopName = repo.getWorkshopName();
    final vehicle = job.vehicleModel.isNotEmpty ? job.vehicleModel : 'Vehicle';
    final plate = job.plateNumber.isNotEmpty ? ' (Plate: ${job.plateNumber})' : '';
    final amount = currency.format(job.estimatedCost);

    final msg =
        'Assalamu Alaikum ${job.customerName},\n\nYour vehicle $vehicle$plate is ready for pickup at $workshopName! \n\nEstimated Bill: $amount\nThank you for choosing our workshop!';

    CommunicationHelper.sendWhatsAppMessage(
      context,
      rawPhone: job.customerPhone,
      message: msg,
    );
  }

  void _showJobReceiptModal(
    BuildContext context,
    GarageRepository repo,
    CurrencyManager currency,
    AppLocale locale,
  ) {
    final profile = repo.workshopProfile;
    final workshopName = repo.getWorkshopName();
    final address = profile['address'] ?? '';
    final phone = profile['phone'] ?? '';
    final isCompleted = job.isCompleted;
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(job.createdAt);

    final sb = StringBuffer();
    sb.writeln('========================================');
    sb.writeln(workshopName.toUpperCase());
    if (address.isNotEmpty) sb.writeln(address);
    if (phone.isNotEmpty) sb.writeln('Phone: $phone');
    sb.writeln('========================================');
    sb.writeln('JOB CARD / SERVICE RECEIPT');
    sb.writeln('Date: $dateStr');
    sb.writeln('Bay: ${job.bayNumber} | Status: ${job.status.toUpperCase()}');
    sb.writeln('----------------------------------------');
    sb.writeln('CUSTOMER & VEHICLE:');
    sb.writeln('Name: ${job.customerName}');
    if (job.customerPhone.isNotEmpty) sb.writeln('Phone: ${job.customerPhone}');
    if (job.vehicleModel.isNotEmpty) sb.writeln('Vehicle: ${job.vehicleModel}');
    if (job.plateNumber.isNotEmpty) sb.writeln('Plate: ${job.plateNumber}');
    sb.writeln('----------------------------------------');
    sb.writeln('SERVICE / TASK:');
    sb.writeln(job.taskDescription);
    if (job.technicianName.isNotEmpty) {
      sb.writeln('Assigned Technician: ${job.technicianName}');
    }
    sb.writeln('----------------------------------------');
    if (isCompleted) {
      sb.writeln('Total Bill:      ${currency.format(job.settledAmount ?? job.estimatedCost)}');
      sb.writeln('Paid Amount:     ${currency.format(job.settledAmount ?? 0)}');
      if ((job.dueAmount ?? 0) > 0) {
        sb.writeln('Due Balance:     ${currency.format(job.dueAmount ?? 0)}');
      } else {
        sb.writeln('Payment Status:  FULLY SETTLED');
      }
    } else {
      sb.writeln('Quoted Estimate: ${currency.format(job.estimatedCost)}');
      sb.writeln('Status:          IN PROGRESS');
    }
    sb.writeln('========================================');
    sb.writeln('Thank you for choosing $workshopName!');

    final plainText = sb.toString();

    StatementModalHelper.show(
      context: context,
      title: locale.isBangla ? 'জব কার্ড / সার্ভিস রসিদ' : 'Job Card / Service Receipt',
      subtitle: '${job.bayNumber} • ${job.customerName}',
      textStatement: plainText,
      customerPhone: job.customerPhone.isNotEmpty ? job.customerPhone : null,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.build_circle_outlined, size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      job.bayNumber,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.primary),
                    ),
                  ],
                ),
                Text(
                  dateStr,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      job.customerName,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary),
                    ),
                    if (job.customerPhone.isNotEmpty)
                      Text(
                        job.customerPhone,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.primary),
                      ),
                  ],
                ),
                if (job.vehicleModel.isNotEmpty || job.plateNumber.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.directions_car_rounded, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        [if (job.vehicleModel.isNotEmpty) job.vehicleModel, if (job.plateNumber.isNotEmpty) '(${job.plateNumber})'].join(' '),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  locale.isBangla ? 'কাজের বিবরণ:' : 'Work / Service Description:',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  job.taskDescription,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary),
                ),
                if (job.technicianName.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.person_outline_rounded, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${locale.isBangla ? 'কারিগর' : 'Technician'}: ${job.technicianName}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isCompleted
                          ? (locale.isBangla ? 'মোট বিল' : 'Total Bill')
                          : (locale.isBangla ? 'ধার্যকৃত মূল্য' : 'Quoted Estimate'),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
                    ),
                    Text(
                      currency.format(isCompleted ? (job.settledAmount ?? job.estimatedCost) : job.estimatedCost),
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.primary),
                    ),
                  ],
                ),
                if (isCompleted) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        locale.isBangla ? 'পরিশোধিত জমা' : 'Paid Amount',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.success),
                      ),
                      Text(
                        currency.format(job.settledAmount ?? 0),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.success),
                      ),
                    ],
                  ),
                  if ((job.dueAmount ?? 0) > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          locale.isBangla ? 'বাকি' : 'Due Balance',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.danger),
                        ),
                        Text(
                          currency.format(job.dueAmount ?? 0),
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.danger),
                        ),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
