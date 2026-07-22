import 'package:flutter/material.dart';

import 'package:s_gizi/app_design.dart';
import 'package:s_gizi/widgets/risk_badge.dart';

class ZScoreCard extends StatelessWidget {
  const ZScoreCard({
    super.key,
    required this.title,
    required this.score,
    required this.status,
  });

  final String title;
  final double score;
  final String status;

  @override
  Widget build(BuildContext context) {
    final style = riskStyle(status);
    return HealthCard(
      dense: true,
      padding: const EdgeInsets.all(14),
      color: style.background.withValues(alpha: 0.65),
      borderColor: style.foreground.withValues(alpha: 0.16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.caption),
          const SizedBox(height: 8),
          Text(
            score.toStringAsFixed(1),
            style: AppTypography.h1.copyWith(
              fontSize: 28,
              color: style.foreground,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            status,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              color: style.foreground,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
