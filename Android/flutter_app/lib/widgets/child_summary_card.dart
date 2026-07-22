import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:s_gizi/app_design.dart';
import 'package:s_gizi/models/child_chat_detail_model.dart';
import 'package:s_gizi/widgets/risk_badge.dart';

class ChildSummaryCard extends StatelessWidget {
  const ChildSummaryCard({super.key, required this.child, this.onDetail});

  final ChildChatDetailModel child;
  final VoidCallback? onDetail;

  @override
  Widget build(BuildContext context) {
    final m = child.latestMeasurement;
    return HealthCard(
      dense: true,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SgAvatar(name: child.name, radius: 24, icon: LucideIcons.baby),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(child.name, style: AppTypography.h3),
                    Text(
                      '${child.ageText} • ${child.gender}',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              RiskBadge(status: child.riskStatus),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'BB ${m.weightKg.toStringAsFixed(1)} kg • TB ${m.heightCm.toStringAsFixed(0)} cm',
            style: AppTypography.caption.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'BB/U: ${child.zscoreResult.bbuStatus}',
            style: AppTypography.caption,
          ),
          Text(
            'TB/U: ${child.zscoreResult.tbuStatus}',
            style: AppTypography.caption,
          ),
          Text(
            'BB/TB: ${child.zscoreResult.bbtbStatus}',
            style: AppTypography.caption,
          ),
          if (onDetail != null) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onDetail,
              icon: const Icon(LucideIcons.fileText, size: 18),
              label: const Text('Lihat Detail Anak'),
            ),
          ],
        ],
      ),
    );
  }
}
