import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:s_gizi/app_design.dart';
import 'package:s_gizi/models/notification_model.dart';
import 'package:s_gizi/widgets/risk_badge.dart';

class NotificationCard extends StatelessWidget {
  const NotificationCard({super.key, required this.notification, this.onTap});

  final NotificationModel notification;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final high = notification.priority.toLowerCase().contains('tinggi');
    final color = high ? const Color(0xFFC62828) : const Color(0xFFEF6C00);
    return HealthCard(
      dense: true,
      padding: const EdgeInsets.all(14),
      color: notification.isRead ? Colors.white : color.withValues(alpha: 0.06),
      borderColor: color.withValues(alpha: 0.16),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.13),
            child: Icon(LucideIcons.bell, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.h3,
                      ),
                    ),
                    RiskBadge(status: notification.priority),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notification.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption,
                ),
                const SizedBox(height: 6),
                Text(notification.time, style: AppTypography.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
