import 'package:flutter/material.dart';

import 'package:s_gizi/app_design.dart';

class RiskBadge extends StatelessWidget {
  const RiskBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final style = riskStyle(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: style.foreground.withValues(alpha: 0.18)),
      ),
      child: Text(
        status,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.caption.copyWith(
          color: style.foreground,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class RiskStyle {
  const RiskStyle(this.background, this.foreground);
  final Color background;
  final Color foreground;
}

RiskStyle riskStyle(String status) {
  final value = status.toLowerCase();
  if (value.contains('tinggi')) {
    return const RiskStyle(Color(0xFFFDECEC), Color(0xFFC62828));
  }
  if (value.contains('pantau')) {
    return const RiskStyle(Color(0xFFFFF3E0), Color(0xFFEF6C00));
  }
  if (value.contains('ukur ulang') || value.contains('anomali')) {
    return const RiskStyle(Color(0xFFF3F4F6), Color(0xFF374151));
  }
  return const RiskStyle(Color(0xFFE8F5E9), Color(0xFF2E7D32));
}
