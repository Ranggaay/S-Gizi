import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:s_gizi/app_design.dart';
import 'package:s_gizi/models/child_monitoring_model.dart';
import 'package:s_gizi/widgets/risk_badge.dart';

class ChildMonitoringCard extends StatelessWidget {
  const ChildMonitoringCard({
    super.key,
    required this.child,
    required this.onTap,
  });

  final ChildMonitoringModel child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HealthCard(
      dense: true,
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SgAvatar(name: child.name, radius: 24, icon: LucideIcons.baby),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      child.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.h3,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${child.ageText} • ${child.gender}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption,
                    ),
                    Text(
                      'Orang tua: ${child.parentName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(child: RiskBadge(status: child.riskStatus)),
              const Icon(LucideIcons.chevronRight, size: 18),
            ],
          ),
          const SizedBox(height: 12),
          _StatusLine(label: 'TB/U', value: child.tbuStatus),
          _StatusLine(label: 'BB/U', value: child.bbuStatus),
          _StatusLine(label: 'BB/TB', value: child.bbtbStatus),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  'BB ${child.weightKg.toStringAsFixed(1)} kg • TB ${child.heightCm.toStringAsFixed(0)} cm',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: SgColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                child.lastMeasurementDate,
                style: AppTypography.caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          if (child.zscoreTbu != 0) ...[
            const SizedBox(height: 6),
            Text(
              'Z-score TB/U: ${child.zscoreTbu.toStringAsFixed(1)}',
              style: AppTypography.caption,
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          SizedBox(
            width: 46,
            child: Text(
              label,
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption,
            ),
          ),
        ],
      ),
    );
  }
}
