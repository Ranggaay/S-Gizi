import 'package:flutter/material.dart';

import 'package:s_gizi/app_design.dart';
import 'package:s_gizi/models/measurement_history_model.dart';
import 'package:s_gizi/widgets/risk_badge.dart';

class HistoryMeasurementCard extends StatelessWidget {
  const HistoryMeasurementCard({super.key, required this.history});

  final MeasurementHistoryModel history;

  @override
  Widget build(BuildContext context) {
    return HealthCard(
      dense: true,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${history.date} | BB ${history.weightKg.toStringAsFixed(1)} kg | TB ${history.heightCm.toStringAsFixed(0)} cm',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption,
            ),
          ),
          const SizedBox(width: 8),
          RiskBadge(status: history.riskStatus),
        ],
      ),
    );
  }
}
