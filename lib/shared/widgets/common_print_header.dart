import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/garage_repository.dart';

class CommonPrintHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final DateTime? date;
  final String? documentNumber;
  final bool showDivider;

  const CommonPrintHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.date,
    this.documentNumber,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<GarageRepository>(context);
    final profile = repo.workshopProfile;
    final logoBase64 = repo.workshopLogoBase64;
    final workshopName = profile['name']?.isNotEmpty == true
        ? profile['name']!
        : 'Apex Auto Workshop';
    final address = profile['address'] ?? '';
    final phone = profile['phone'] ?? '';
    final formattedDate =
        DateFormat('dd MMM yyyy, hh:mm a').format(date ?? DateTime.now());

    final contactInfo = [
      if (address.isNotEmpty) address,
      if (phone.isNotEmpty) 'Tel: $phone',
    ].join(' • ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Row(
            children: [
              // Workshop Logo
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                clipBehavior: Clip.antiAlias,
                child: (logoBase64 != null && logoBase64.isNotEmpty)
                    ? Image.memory(
                        base64Decode(logoBase64),
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => const Icon(
                          Icons.garage_rounded,
                          color: AppColors.primary,
                          size: 28,
                        ),
                      )
                    : const Icon(
                        Icons.garage_rounded,
                        color: AppColors.primary,
                        size: 28,
                      ),
              ),
              const SizedBox(width: 12),
              // Workshop Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workshopName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (contactInfo.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        contactInfo,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 11,
                          color: AppColors.textSecondary.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary.withValues(alpha: 0.9),
                          ),
                        ),
                        if (documentNumber != null &&
                            documentNumber!.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text('•',
                              style: TextStyle(
                                  color: AppColors.textSecondary
                                      .withValues(alpha: 0.6))),
                          const SizedBox(width: 6),
                          Text(
                            documentNumber!,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Title Ribbon
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 0.6,
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty)
                Flexible(
                  child: Text(
                    subtitle!,
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
        if (showDivider) ...[
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
