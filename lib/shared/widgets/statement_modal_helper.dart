import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/localization/app_locale.dart';
import '../../shared/utils/communication_helper.dart';
import 'common_print_header.dart';

class StatementModalHelper {
  static void show({
    required BuildContext context,
    required String title,
    String? subtitle,
    DateTime? date,
    String? documentNumber,
    required Widget content,
    required String textStatement,
    String? customerPhone,
    String? whatsAppMessage,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        AppLocaleManager? locale;
        try {
          locale = Provider.of<AppLocaleManager>(ctx, listen: false);
        } catch (_) {}
        final isBangla = locale?.isBangla ?? false;

        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (_, scrollController) => Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header title bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.receipt_long_rounded,
                          color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              // Scrollable statement body
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CommonPrintHeader(
                        title: title,
                        subtitle: subtitle,
                        date: date,
                        documentNumber: documentNumber,
                      ),
                      content,
                    ],
                  ),
                ),
              ),
              // Action Buttons Bar
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      // Copy Statement Button
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(
                                color: AppColors.primary, width: 1.5),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.copy_rounded,
                              color: AppColors.primary, size: 18),
                          label: Text(
                            isBangla ? 'কপি করুন' : 'Copy Text',
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary),
                          ),
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: textStatement));
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(
                                        Icons.assignment_turned_in_rounded,
                                        color: Colors.white,
                                        size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '$title copied to clipboard!',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: AppColors.primaryDark,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),

                      // WhatsApp / Share Button (if customer phone is available)
                      if (customerPhone != null &&
                          customerPhone.trim().isNotEmpty) ...[
                        SizedBox(
                          height: 48,
                          width: 48,
                          child: Tooltip(
                            message: isBangla
                                ? 'হোয়াটসঅ্যাপে পাঠান'
                                : 'Send via WhatsApp',
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.zero,
                                backgroundColor: const Color(0xFF16A34A),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                final msg = whatsAppMessage ?? textStatement;
                                CommunicationHelper.sendWhatsAppMessage(
                                  context,
                                  rawPhone: customerPhone,
                                  message: msg,
                                );
                              },
                              child: const Icon(Icons.chat_rounded, size: 20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],

                      // Print / Share Button
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.print_rounded, size: 18),
                          label: Text(
                            isBangla ? 'প্রিন্ট / শেয়ার' : 'Print / Share',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: textStatement));
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(Icons.print_rounded,
                                        color: Colors.white, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '$title prepared for printing! (Copied to clipboard)',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: AppColors.primaryDark,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
