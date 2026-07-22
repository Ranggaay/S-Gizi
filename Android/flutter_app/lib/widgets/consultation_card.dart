import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:s_gizi/app_design.dart';
import 'package:s_gizi/models/consultation_model.dart';
import 'package:s_gizi/widgets/risk_badge.dart';

class ConsultationCard extends StatelessWidget {
  const ConsultationCard({super.key, required this.consultation, this.onTap});

  final ConsultationModel consultation;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return HealthCard(
      dense: true,
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: [
          SgAvatar(name: consultation.parentName, radius: 25),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        consultation.parentName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.h3,
                      ),
                    ),
                    if (consultation.unreadCount > 0)
                      _UnreadBadge(count: consultation.unreadCount),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Anak: ${consultation.childName} • ${consultation.childAge}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption,
                ),
                const SizedBox(height: 7),
                RiskBadge(status: consultation.riskStatus),
                const SizedBox(height: 7),
                Text(
                  '"${consultation.lastMessage}"',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 5),
                Text(
                  '${consultation.lastMessageTime} • Status: ${consultation.status}',
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(LucideIcons.chevronRight, size: 18),
        ],
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: SgColors.primary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count pesan',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
