import 'package:flutter/material.dart';

import 'package:s_gizi/app_design.dart';

class ActionButtonCard extends StatelessWidget {
  const ActionButtonCard({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return HealthCard(
      dense: true,
      padding: const EdgeInsets.all(12),
      color: enabled ? Colors.white : const Color(0xFFF3F4F6),
      onTap: enabled ? onTap : null,
      child: Row(
        children: [
          Icon(
            icon,
            color: enabled ? SgColors.primary : SgColors.textSecondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: AppTypography.body.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
