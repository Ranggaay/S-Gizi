import 'package:flutter/material.dart';

import 'package:s_gizi/app_design.dart';
import 'package:s_gizi/utils/nutrition_display_utils.dart';

/// Badge status gizi ringkas (utama + tambahan terpisah).
class NutritionStatusBadges extends StatelessWidget {
  const NutritionStatusBadges({
    super.key,
    required this.status,
    this.compact = true,
    this.spacing = 6,
    this.runSpacing = 6,
  });

  final String status;
  final bool compact;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    final badges = statusCompactBadges(status);
    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      children: badges
          .map(
            (b) => StatusBadge(text: b.label, color: b.color, compact: compact),
          )
          .toList(),
    );
  }
}
