import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';

class CommunicationHelper {
  /// Cleans phone string by removing non-digits (keeps digits only)
  static String cleanPhoneNumber(String raw) {
    String cleaned = raw.replaceAll(RegExp(r'[^0-9]'), '');
    // If it is a Bangladeshi local 11-digit mobile starting with 01, add 88 prefix for WhatsApp
    if (cleaned.startsWith('01') && cleaned.length == 11) {
      cleaned = '88$cleaned';
    }
    return cleaned;
  }

  /// Initiates a phone call via tel: URI
  static Future<void> makePhoneCall(BuildContext context, String rawPhone) async {
    final digits = rawPhone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No valid phone number provided.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final Uri callUri = Uri(scheme: 'tel', path: digits);
    try {
      final launched = await launchUrl(callUri);
      if (!launched && context.mounted) {
        _showCopyPhoneDialog(context, digits);
      }
    } catch (e) {
      if (context.mounted) {
        _showCopyPhoneDialog(context, digits);
      }
    }
  }

  /// Sends a pre-formatted message via WhatsApp (https://wa.me/ or whatsapp://send)
  static Future<void> sendWhatsAppMessage(
    BuildContext context, {
    required String rawPhone,
    required String message,
  }) async {
    final phone = cleanPhoneNumber(rawPhone);
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer does not have a valid phone number for WhatsApp.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final encodedMsg = Uri.encodeComponent(message);
    final webUri = Uri.parse('https://wa.me/$phone?text=$encodedMsg');
    final nativeUri = Uri.parse('whatsapp://send?phone=$phone&text=$encodedMsg');

    try {
      // First try opening native or external web WhatsApp
      bool launched = false;
      try {
        launched = await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } catch (_) {
        launched = false;
      }

      if (!launched) {
        try {
          launched = await launchUrl(nativeUri);
        } catch (_) {
          launched = false;
        }
      }

      if (!launched && context.mounted) {
        _showWhatsAppFallbackDialog(context, phone, message);
      }
    } catch (e) {
      if (context.mounted) {
        _showWhatsAppFallbackDialog(context, phone, message);
      }
    }
  }

  static void _showCopyPhoneDialog(BuildContext context, String phone) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.phone_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Call Customer', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Text('Phone number: $phone\n\nCould not launch device dialer automatically. Would you like to copy the number?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: phone));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Phone number $phone copied to clipboard!'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copy Phone'),
          ),
        ],
      ),
    );
  }

  static void _showWhatsAppFallbackDialog(BuildContext context, String phone, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.chat_rounded, color: Color(0xFF16A34A)),
            SizedBox(width: 8),
            Text('WhatsApp Due Reminder', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recipient: +$phone', style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                message,
                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: message));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reminder message copied to clipboard!'),
                  backgroundColor: Color(0xFF16A34A),
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copy Message'),
          ),
        ],
      ),
    );
  }
}
