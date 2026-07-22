import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:s_gizi/app_design.dart';
import 'package:s_gizi/models/riwayat_response_model.dart';

class GrowthChartCard extends StatelessWidget {
  const GrowthChartCard({super.key, required this.history, this.onViewDetail});

  final List<RiwayatItemModel> history;
  final VoidCallback? onViewDetail;

  @override
  Widget build(BuildContext context) {
    final safeHistory = _sanitizeGrowthItems(history);
    final points = safeHistory.length > 6
        ? safeHistory.skip(safeHistory.length - 6).toList()
        : safeHistory;

    if (points.isEmpty) {
      return const HealthCard(
        child: Text(
          'Belum ada data pengukuran untuk menampilkan grafik pertumbuhan.',
          style: AppTypography.body,
        ),
      );
    }

    final labels = points
        .map((e) => _shortDate(DateTime.tryParse(e.tanggalUkur)))
        .toList();
    final weights = points.map((e) => e.berat).toList();
    final heights = points.map((e) => e.tinggi).toList();
    final weightTrend = _latestTrendText(weights, 'Berat');
    final heightTrend = _latestTrendText(heights, 'Tinggi');

    return HealthCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Grafik Pertumbuhan Anak', style: AppTypography.h3),
                    const SizedBox(height: 4),
                    Text(
                      'Monitoring singkat berat dan tinggi badan',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              if (onViewDetail != null)
                IconButton(
                  onPressed: onViewDetail,
                  icon: const Icon(Icons.chevron_right_rounded),
                  color: const Color(0xFF8B959C),
                ),
            ],
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              _LegendDot(color: Color(0xFF0B7A86), label: 'Berat Badan'),
              SizedBox(width: 14),
              _LegendDot(color: Color(0xFF4F7EE8), label: 'Tinggi Badan'),
            ],
          ),
          const SizedBox(height: 12),
          _CombinedGrowthLineChart(
            weights: weights,
            heights: heights,
            labels: labels,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TrendSummaryChip(text: weightTrend),
              _TrendSummaryChip(text: heightTrend),
            ],
          ),
        ],
      ),
    );
  }

  String _shortDate(DateTime? date) {
    if (date == null) return '-';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  String _latestTrendText(List<double> values, String label) {
    if (values.length < 2) return '$label stabil';
    final delta = values.last - values[values.length - 2];
    final threshold = label.toLowerCase().contains('berat') ? 0.1 : 0.2;
    if (delta > threshold) return '↑ $label naik';
    if (delta < -threshold) return '↓ $label menurun';
    return '→ $label stabil';
  }

  // ignore: unused_element
  String _trendText(List<double> values, String label) {
    if (values.length < 2) return '$label stabil';
    final delta = values.last - values.first;
    if (delta > 0.2) return '↑ $label naik stabil';
    if (delta < -0.2) return '↓ $label menurun';
    return '→ $label stabil';
  }
}

class _CombinedGrowthLineChart extends StatelessWidget {
  const _CombinedGrowthLineChart({
    required this.weights,
    required this.heights,
    required this.labels,
  });

  final List<double> weights;
  final List<double> heights;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final weightSpots = _normalizedSpots(weights);
    final heightSpots = _normalizedSpots(heights);
    return SizedBox(
      height: 170,
      child: Stack(
        children: [
          Positioned.fill(
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: math.max(1, labels.length - 1).toDouble(),
                minY: -0.08,
                maxY: 1.08,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: Color(0xFFE8EEEC), strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= labels.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            labels[idx],
                            style: AppTypography.caption.copyWith(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => Colors.white,
                    tooltipRoundedRadius: 14,
                    getTooltipItems: (spots) => spots.map((spot) {
                      final idx = spot.x.toInt().clamp(0, labels.length - 1);
                      return LineTooltipItem(
                        '${labels[idx]}\nBB ${weights[idx].toStringAsFixed(1)} kg\nTB ${heights[idx].toStringAsFixed(1)} cm',
                        AppTypography.caption.copyWith(
                          color: SgColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                lineBarsData: [
                  _line(weightSpots, const Color(0xFF0B7A86), true),
                  _line(heightSpots, const Color(0xFF4F7EE8), false),
                ],
              ),
              duration: const Duration(milliseconds: 520),
              curve: Curves.easeOutCubic,
            ),
          ),
          _LastValueLabel(
            value: weights.last.toStringAsFixed(1),
            color: const Color(0xFF0B7A86),
            topFactor: 1 - weightSpots.last.y,
          ),
          _LastValueLabel(
            value: heights.last.toStringAsFixed(0),
            color: const Color(0xFF4F7EE8),
            topFactor: 1 - heightSpots.last.y,
            offsetY: 20,
          ),
        ],
      ),
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

  LineChartBarData _line(List<FlSpot> spots, Color color, bool showArea) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.35,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
          radius: index == spots.length - 1 ? 4.2 : 2.6,
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

class _TrendSummaryChip extends StatelessWidget {
  const _TrendSummaryChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final lower = text.toLowerCase();
    final isDown = text.startsWith('↓') || lower.contains('menurun');
    final isStable = text.startsWith('→') || lower.contains('stabil');
    final color = isDown
        ? const Color(0xFFE57373)
        : isStable
        ? const Color(0xFF7E8B87)
        : const Color(0xFF0B7A86);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        text,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _LastValueLabel extends StatelessWidget {
  const _LastValueLabel({
    required this.value,
    required this.color,
    required this.topFactor,
    this.offsetY = 0,
  });

  final String value;
  final Color color;
  final double topFactor;
  final double offsetY;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Positioned(
                right: 0,
                top:
                    (topFactor.clamp(0.04, 0.78) *
                        (constraints.maxHeight - 44)) +
                    offsetY,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: color.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    value,
                    style: AppTypography.caption.copyWith(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
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

  return sorted.where(_hasValidMeasurement).toList();
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

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTypography.caption),
      ],
    );
  }
}
