import 'package:flutter/material.dart';

import 'package:s_gizi/app_design.dart';
import 'package:s_gizi/utils/nutrition_display_utils.dart';

/// Indikator trend ringkas (↑ Naik baik / ↓ Menurun / → Stabil).
class GrowthTrendIndicator extends StatelessWidget {
  const GrowthTrendIndicator({
    super.key,
    required this.trend,
    this.dense = false,
  });

  final GrowthTrendVisual trend;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: trend.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: trend.color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(trend.icon, size: dense ? 13 : 14, color: trend.color),
          SizedBox(width: dense ? 4 : 5),
          Text(
            trend.label,
            style: AppTypography.caption.copyWith(
              color: trend.color,
              fontWeight: FontWeight.w700,
              fontSize: dense ? 11 : 12,
            ),
          ),
        ],
      ),
    );
  }
}
