import 'package:flutter/material.dart';

import 'package:s_gizi/app_design.dart';

class MeasurementInfoRow extends StatelessWidget {
  const MeasurementInfoRow({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: SgColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: AppTypography.caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.body.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}
