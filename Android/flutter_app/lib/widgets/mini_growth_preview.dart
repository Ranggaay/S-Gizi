import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:s_gizi/app_design.dart';
import 'package:s_gizi/models/riwayat_response_model.dart';

/// Grafik ringkas gabungan berat dan tinggi untuk card overview.
class MiniGrowthPreview extends StatelessWidget {
  const MiniGrowthPreview({
    super.key,
    required this.childName,
    required this.history,
    this.compact = false,
  });

  final String childName;
  final List<RiwayatItemModel> history;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final safeHistory = _sanitizeGrowthItems(history);
    final points = safeHistory.length > 6
        ? safeHistory.skip(safeHistory.length - 6).toList()
        : safeHistory;

    final chartHeight = compact ? 72.0 : 64.0;

    if (points.isEmpty) {
      return Container(
        height: chartHeight,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE8EEEC)),
        ),
        child: Text(
          'Belum ada data grafik',
          style: AppTypography.caption.copyWith(fontSize: 11),
        ),
      );
    }

    final weights = points.map((e) => e.berat).toList();
    final heights = points.map((e) => e.tinggi).toList();
    final weightSpots = _normalizedSpots(weights);
    final heightSpots = _normalizedSpots(heights);
    const weightColor = Color(0xFF0B7A86);
    const heightColor = Color(0xFF4F7EE8);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!compact && childName.isNotEmpty) ...[
          Text(
            childName,
            style: AppTypography.h3,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
        ],
        if (compact) ...[
          Row(
            children: const [
              _MiniLegend(color: weightColor, label: 'BB'),
              SizedBox(width: 10),
              _MiniLegend(color: heightColor, label: 'TB'),
            ],
          ),
          const SizedBox(height: 4),
        ],
        SizedBox(
          height: chartHeight,
          width: double.infinity,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: math.max(1, points.length - 1).toDouble(),
              minY: -0.08,
              maxY: 1.08,
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineTouchData: const LineTouchData(enabled: false),
              lineBarsData: [
                _line(weightSpots, weightColor, showArea: true),
                _line(heightSpots, heightColor),
              ],
            ),
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutCubic,
          ),
        ),
      ],
    );
  }

  List<FlSpot> _normalizedSpots(List<double> values) {
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final range = (max - min).abs() < 0.01 ? 1.0 : max - min;
    return [
      for (var i = 0; i < values.length; i++)
        FlSpot(i.toDouble(), (values[i] - min) / range),
    ];
  }

  LineChartBarData _line(
    List<FlSpot> spots,
    Color color, {
    bool showArea = false,
  }) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.35,
      color: color,
      barWidth: 2.5,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
          radius: index == spots.length - 1 ? 3.8 : 2.2,
          color: Colors.white,
          strokeWidth: 2,
          strokeColor: color,
        ),
      ),
      belowBarData: BarAreaData(
        show: showArea,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.02),
          ],
        ),
      ),
    );
  }
}

class _MiniLegend extends StatelessWidget {
  const _MiniLegend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: const Color(0xFF5D6B68),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

List<RiwayatItemModel> _sanitizeGrowthItems(List<RiwayatItemModel> items) {
  final sorted = [...items]
    ..sort((a, b) {
      final ad = DateTime.tryParse(a.tanggalUkur) ?? DateTime(1900);
      final bd = DateTime.tryParse(b.tanggalUkur) ?? DateTime(1900);
      return ad.compareTo(bd);
    });

  final safe = <RiwayatItemModel>[];
  for (final item in sorted) {
    if (!_hasValidMeasurement(item)) continue;

    final previous = safe.isEmpty ? null : safe.last;
    if (previous != null) {
      final heightDelta = item.tinggi - previous.tinggi;
      final weightDelta = item.berat - previous.berat;
      final weightRatioTooSharp =
          previous.berat > 0 && (weightDelta.abs() / previous.berat) > 0.55;

      if (heightDelta < -3 ||
          heightDelta.abs() > 25 ||
          weightDelta.abs() > 10 ||
          weightRatioTooSharp) {
        continue;
      }
    }

    safe.add(item);
  }

  return safe;
}

bool _hasValidMeasurement(RiwayatItemModel item) {
  final date = DateTime.tryParse(item.tanggalUkur);
  if (date == null) return false;
  if (!item.berat.isFinite || !item.tinggi.isFinite) return false;
  if (item.berat < 1.5 || item.berat > 45) return false;
  if (item.tinggi < 45 || item.tinggi > 125) return false;
  if (item.berat > item.tinggi) return false;
  return true;
}
