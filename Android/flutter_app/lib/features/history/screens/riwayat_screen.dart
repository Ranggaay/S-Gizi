import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:s_gizi/app_design.dart';
import 'package:s_gizi/models/riwayat_response_model.dart';
import 'package:s_gizi/services/api_service.dart';
import 'package:s_gizi/utils/nutrition_display_utils.dart';
import 'package:s_gizi/widgets/nutrition_status_badges.dart';
import 'package:s_gizi/features/history/screens/riwayat_detail_screen.dart';

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key, required this.childId, this.initialTab = 0});

  final int childId;
  final int initialTab;

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late final TabController _tabController;
  late Future<RiwayatResponseModel> _future;
  String _selectedMetric = 'BB (kg)';
  int _activeTab = 0;

  static const _filters = [
    'BB (kg)',
    'TB (cm)',
    'Z-Score TB/U',
    'Z-Score BB/TB',
    'Z-Score BB/U',
  ];

  @override
  void initState() {
    super.initState();
    final initialIndex = widget.initialTab.clamp(0, 1);
    _activeTab = initialIndex;
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: initialIndex,
    );
    _tabController.addListener(_handleTabChanged);
    _future = _apiService.getRiwayat(childId: widget.childId);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChanged() {
    if (_activeTab == _tabController.index) return;
    setState(() => _activeTab = _tabController.index);
  }

  void _retry() {
    setState(() {
      _future = _apiService.getRiwayat(childId: widget.childId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SgColors.background,
      appBar: AppBar(
        title: const Text('Riwayat Pertumbuhan'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _retry,
            icon: const Icon(LucideIcons.refreshCcw, size: 19),
          ),
        ],
      ),
      body: FutureBuilder<RiwayatResponseModel>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _HistorySkeleton();
          }
          if (snapshot.hasError) {
            return ErrorState(
              message:
                  'Riwayat belum dapat dimuat. Pastikan server API aktif dan koneksi tersedia.',
              onRetry: _retry,
            );
          }

          final data = snapshot.data!;
          if (data.riwayat.isEmpty) {
            return EmptyState(
              title: 'Belum Ada Riwayat',
              message:
                  'Input pengukuran pertama untuk mulai melihat timeline pertumbuhan anak.',
              actionLabel: 'Muat Ulang',
              onAction: _retry,
              icon: Icons.timeline_rounded,
              assetImage: 'assets/image/onboarding_monitoring.png',
            );
          }

          final newest = _newestFirst(data.riwayat);
          final chartItems = _chartItems(data.riwayat);

          return RefreshIndicator(
            color: SgColors.primary,
            onRefresh: () async {
              setState(() {
                _future = _apiService.getRiwayat(childId: widget.childId);
              });
              await _future;
            },
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      SgSpacing.pageH,
                      SgSpacing.pageV,
                      SgSpacing.pageH,
                      10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ChildSummaryCard(
                              child: data.child,
                              entryCount: data.riwayat.length,
                            )
                            .animate()
                            .fadeIn(duration: 260.ms)
                            .slideY(begin: 0.02, end: 0, duration: 260.ms),
                        const SizedBox(height: 14),
                        _SegmentedTabs(controller: _tabController),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ],
              body: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: _activeTab == 0
                    ? _TimelineTab(
                        key: const ValueKey('riwayat-pengukuran'),
                        child: data.child,
                        items: newest,
                      )
                    : _ChartTab(
                        key: const ValueKey('grafik-pertumbuhan'),
                        items: chartItems,
                        selectedMetric: _selectedMetric,
                        filters: _filters,
                        onMetricSelected: (value) =>
                            setState(() => _selectedMetric = value),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<RiwayatItemModel> _newestFirst(List<RiwayatItemModel> items) {
    return [...items]..sort((a, b) {
      final bd = DateTime.tryParse(b.tanggalUkur) ?? DateTime(2000);
      final ad = DateTime.tryParse(a.tanggalUkur) ?? DateTime(2000);
      return bd.compareTo(ad);
    });
  }

  List<RiwayatItemModel> _chartItems(List<RiwayatItemModel> items) {
    return _sanitizeGrowthItems(items);
  }
}

class _ChildSummaryCard extends StatelessWidget {
  const _ChildSummaryCard({required this.child, required this.entryCount});

  final ChildInfoModel child;
  final int entryCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE4F7F6), Color(0xFFF7FCFB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFCBEAEA)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B7A86).withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          ChildAvatar(name: child.nama, gender: child.jenisKelamin, radius: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  child.nama,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.h2,
                ),
                const SizedBox(height: 4),
                Text(
                  '${genderLabel(child.jenisKelamin)} • ${formatAgeFromBirthDate(child.tanggalLahir, source: 'riwayat_summary_child_card')}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: const Color(0xFF49605C),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFD8ECEA)),
            ),
            child: Text(
              '$entryCount Entri',
              style: AppTypography.caption.copyWith(
                color: SgColors.primaryDark,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SgColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TabBar(
        controller: controller,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: SgColors.primary,
          borderRadius: BorderRadius.circular(14),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: SgColors.textSecondary,
        labelStyle: AppTypography.caption.copyWith(fontWeight: FontWeight.w800),
        tabs: const [
          Tab(text: 'Riwayat Pengukuran'),
          Tab(text: 'Grafik'),
        ],
      ),
    );
  }
}

class _ChartTab extends StatelessWidget {
  const _ChartTab({
    super.key,
    required this.items,
    required this.selectedMetric,
    required this.filters,
    required this.onMetricSelected,
  });

  final List<RiwayatItemModel> items;
  final String selectedMetric;
  final List<String> filters;
  final ValueChanged<String> onMetricSelected;

  @override
  Widget build(BuildContext context) {
    final zTbuCard = _ChartCard(
      title: 'Grafik Z-Score TB/U',
      subtitle: 'TB/U = Tinggi badan menurut umur',
      compact: true,
      height: 150,
      child: _SingleMetricChart(
        items: items,
        color: const Color(0xFF45C43B),
        values: (item) => item.zTbu,
        fixedMinY: -3,
        fixedMaxY: 3,
      ),
    );
    final zBbtbCard = _ChartCard(
      title: 'Grafik Z-Score BB/TB',
      subtitle: 'BB/TB = Berat badan menurut tinggi badan',
      compact: true,
      height: 150,
      child: _SingleMetricChart(
        items: items,
        color: const Color(0xFF45C43B),
        values: (item) => item.zBbtb,
        fixedMinY: -3,
        fixedMaxY: 3,
      ),
    );

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        SgSpacing.pageH,
        0,
        SgSpacing.pageH,
        28,
      ),
      children: [
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: filters.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final filter = filters[index];
              final active = filter == selectedMetric;
              return ChoiceChip(
                selected: active,
                label: Text(filter),
                onSelected: (_) => onMetricSelected(filter),
                showCheckmark: false,
                selectedColor: SgColors.primary,
                backgroundColor: Colors.white,
                labelStyle: AppTypography.caption.copyWith(
                  color: active ? Colors.white : SgColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
                side: BorderSide(
                  color: active ? SgColors.primary : SgColors.border,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        _SelectedMetricCard(metric: selectedMetric, items: items),
        const SizedBox(height: 14),
        _ChartCard(
          title: 'Grafik Pertumbuhan Anak',
          subtitle: 'Perkembangan dari waktu ke waktu',
          height: 230,
          child: _CombinedGrowthChart(items: items),
        ).animate().fadeIn(duration: 260.ms),
        const SizedBox(height: 14),
        _ChartCard(
          title: 'Grafik Berat Badan menurut Umur',
          subtitle: 'BB/U = Berat badan menurut umur',
          height: 210,
          child: _SingleMetricChart(
            items: items,
            color: SgColors.primary,
            values: (item) => item.berat,
            suffix: 'kg',
          ),
        ),
        const SizedBox(height: 14),
        _ChartCard(
          title: 'Grafik Tinggi Badan menurut Umur',
          subtitle: 'TB/U = Tinggi badan menurut umur',
          height: 210,
          child: _SingleMetricChart(
            items: items,
            color: const Color(0xFF1D6AD8),
            values: (item) => item.tinggi,
            suffix: 'cm',
          ),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 390) {
              return Column(
                children: [zTbuCard, const SizedBox(height: 14), zBbtbCard],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: zTbuCard),
                const SizedBox(width: 10),
                Expanded(child: zBbtbCard),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        _ChartCard(
          title: 'Grafik Z-Score BB/U',
          subtitle: 'BB/U = Berat badan menurut umur',
          height: 170,
          child: _SingleMetricChart(
            items: items,
            color: const Color(0xFF45C43B),
            values: (item) => item.zBbu,
            fixedMinY: -3,
            fixedMaxY: 3,
          ),
        ),
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.child,
    required this.height,
    this.subtitle,
    this.compact = false,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final double height;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: SgColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: compact ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            style: (compact ? AppTypography.h3 : AppTypography.h2).copyWith(
              fontSize: compact ? 14 : null,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: AppTypography.caption),
          ],
          SizedBox(height: compact ? 10 : 14),
          SizedBox(height: height, child: child),
        ],
      ),
    );
  }
}

class _SelectedMetricCard extends StatelessWidget {
  const _SelectedMetricCard({required this.metric, required this.items});

  final String metric;
  final List<RiwayatItemModel> items;

  @override
  Widget build(BuildContext context) {
    return _ChartCard(
      title: metric,
      subtitle: 'Filter visual aktif',
      height: 170,
      child: _SingleMetricChart(
        items: items,
        color: _color,
        values: _values,
        suffix: _suffix,
        fixedMinY: _isZScore ? -3 : null,
        fixedMaxY: _isZScore ? 3 : null,
      ),
    );
  }

  bool get _isZScore => metric.startsWith('Z-Score');

  Color get _color {
    switch (metric) {
      case 'TB (cm)':
        return const Color(0xFF1D6AD8);
      case 'Z-Score TB/U':
        return const Color(0xFF45C43B);
      case 'Z-Score BB/TB':
        return const Color(0xFF45C43B);
      case 'Z-Score BB/U':
        return const Color(0xFF45C43B);
      default:
        return SgColors.primary;
    }
  }

  String get _suffix {
    switch (metric) {
      case 'BB (kg)':
        return 'kg';
      case 'TB (cm)':
        return 'cm';
      default:
        return '';
    }
  }

  double? _values(RiwayatItemModel item) {
    switch (metric) {
      case 'TB (cm)':
        return item.tinggi;
      case 'Z-Score TB/U':
        return item.zTbu;
      case 'Z-Score BB/TB':
        return item.zBbtb;
      case 'Z-Score BB/U':
        return item.zBbu;
      default:
        return item.berat;
    }
  }
}

class _CombinedGrowthChart extends StatelessWidget {
  const _CombinedGrowthChart({required this.items});

  final List<RiwayatItemModel> items;

  @override
  Widget build(BuildContext context) {
    final chartItems = _sanitizeGrowthItems(items);
    final weights = chartItems.map((e) => e.berat).toList();
    final heights = chartItems.map((e) => e.tinggi).toList();
    if (chartItems.isEmpty || weights.isEmpty || heights.isEmpty) {
      return const Center(child: Text('Belum ada data grafik.'));
    }
    final weightSpots = _normalizedSpots(weights);
    final heightSpots = _normalizedSpots(heights);

    return Column(
      children: [
        const Row(
          children: [
            _LegendDot(color: SgColors.primary, label: 'Berat Badan (kg)'),
            SizedBox(width: 18),
            _LegendDot(color: Color(0xFF1D6AD8), label: 'Tinggi Badan (cm)'),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: LineChart(
                  LineChartData(
                    minX: 0,
                    maxX: math.max(1, chartItems.length - 1).toDouble(),
                    minY: -0.08,
                    maxY: 1.08,
                    gridData: _grid(),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: AxisTitles(
                        axisNameWidget: Text(
                          'BB',
                          style: AppTypography.caption.copyWith(fontSize: 9),
                        ),
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: 0.5,
                          getTitlesWidget: (value, meta) =>
                              _axisText(_scaleLabel(value, weights)),
                        ),
                      ),
                      rightTitles: AxisTitles(
                        axisNameWidget: Text(
                          'TB',
                          style: AppTypography.caption.copyWith(fontSize: 9),
                        ),
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 34,
                          interval: 0.5,
                          getTitlesWidget: (value, meta) =>
                              _axisText(_scaleLabel(value, heights)),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 38,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= chartItems.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _chartDateLabel(
                                  chartItems[idx].tanggalUkur,
                                  idx,
                                ),
                                textAlign: TextAlign.center,
                                style: AppTypography.caption.copyWith(
                                  fontSize: 10,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    lineTouchData: _touchData(chartItems),
                    lineBarsData: [
                      _chartLine(
                        weightSpots,
                        SgColors.primary,
                        width: 3.6,
                        area: true,
                      ),
                      _chartLine(
                        heightSpots,
                        const Color(0xFF1D6AD8),
                        width: 3,
                      ),
                    ],
                  ),
                  duration: const Duration(milliseconds: 620),
                  curve: Curves.easeOutCubic,
                ),
              ),
              _LastPointLabel(
                value: '${weights.last.toStringAsFixed(1)} kg',
                color: SgColors.primary,
                topFactor: 1 - weightSpots.last.y,
              ),
              _LastPointLabel(
                value: '${heights.last.toStringAsFixed(0)} cm',
                color: const Color(0xFF1D6AD8),
                topFactor: 1 - heightSpots.last.y,
                offsetY: 22,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SingleMetricChart extends StatelessWidget {
  const _SingleMetricChart({
    required this.items,
    required this.values,
    required this.color,
    this.suffix = '',
    this.fixedMinY,
    this.fixedMaxY,
  });

  final List<RiwayatItemModel> items;
  final double? Function(RiwayatItemModel item) values;
  final Color color;
  final String suffix;
  final double? fixedMinY;
  final double? fixedMaxY;

  @override
  Widget build(BuildContext context) {
    final chartItems = _sanitizeGrowthItems(items);
    final chartValues = [
      for (final item in chartItems)
        _chartValue(values(item), fixedMinY, fixedMaxY),
    ].whereType<double>().where(_isValid).toList();
    if (chartItems.isEmpty || chartValues.isEmpty) {
      return const Center(child: Text('Belum ada data.'));
    }

    final min = fixedMinY ?? chartValues.reduce(math.min);
    final max = fixedMaxY ?? chartValues.reduce(math.max);
    final padding = fixedMinY == null ? math.max((max - min) * 0.18, 1) : 0.0;
    final spots = <FlSpot>[];
    for (var i = 0; i < chartItems.length; i++) {
      final value = _chartValue(values(chartItems[i]), fixedMinY, fixedMaxY);
      if (value != null && _isValid(value)) {
        spots.add(FlSpot(i.toDouble(), value));
      }
    }

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: math.max(1, chartItems.length - 1).toDouble(),
        minY: min - padding,
        maxY: max + padding,
        gridData: _grid(),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) =>
                  _axisText(value.toStringAsFixed(value.abs() >= 10 ? 0 : 1)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              interval: math.max(1, (chartItems.length / 4).floorToDouble()),
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= chartItems.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _shortMonth(chartItems[idx].tanggalUkur),
                    textAlign: TextAlign.center,
                    style: AppTypography.caption.copyWith(fontSize: 9),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => Colors.white,
            tooltipRoundedRadius: 14,
            tooltipPadding: const EdgeInsets.all(10),
            getTooltipItems: (spots) => spots.map((spot) {
              final idx = spot.x.toInt().clamp(0, chartItems.length - 1);
              final item = chartItems[idx];
              return LineTooltipItem(
                '${formatMeasurementDate(item.tanggalUkur)}\n'
                '${fixedMinY == null ? 'Nilai' : 'Z-Score'}: ${spot.y.toStringAsFixed(1)}$suffix\n'
                'BB ${item.berat.toStringAsFixed(1)} kg • TB ${item.tinggi.toStringAsFixed(1)} cm',
                AppTypography.caption.copyWith(
                  color: SgColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [_chartLine(spots, color, width: 3, area: true)],
      ),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
    );
  }
}

class _TimelineTab extends StatelessWidget {
  const _TimelineTab({super.key, required this.child, required this.items});

  final ChildInfoModel child;
  final List<RiwayatItemModel> items;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        SgSpacing.pageH,
        2,
        SgSpacing.pageH,
        28,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final previous = index + 1 < items.length ? items[index + 1] : null;
        return _TimelineItem(
              child: child,
              item: items[index],
              previous: previous,
              isLast: index == items.length - 1,
            )
            .animate()
            .fadeIn(delay: (40 * index).ms, duration: 240.ms)
            .slideY(
              begin: 0.015,
              end: 0,
              delay: (40 * index).ms,
              duration: 240.ms,
            );
      },
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.child,
    required this.item,
    required this.isLast,
    this.previous,
  });

  final ChildInfoModel child;
  final RiwayatItemModel item;
  final RiwayatItemModel? previous;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final visual = nutritionStatusVisual(item.statusGabungan);
    final changeText = formatMeasurementChange(
      current: item,
      previous: previous,
    );

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 26,
            child: Column(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: visual.color.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: visual.color.withValues(alpha: 0.38),
                      width: 2,
                    ),
                  ),
                  child: Icon(visual.icon, color: visual.color, size: 12),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDDE8E6),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _HistoryMeasurementCard(
                child: child,
                item: item,
                insight: changeText ?? visual.summary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryMeasurementCard extends StatelessWidget {
  const _HistoryMeasurementCard({
    required this.child,
    required this.item,
    required this.insight,
  });

  final ChildInfoModel child;
  final RiwayatItemModel item;
  final String insight;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          Navigator.of(
            context,
          ).push(fadeRoute(RiwayatDetailScreen(child: child, item: item)));
        },
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: SgColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      formatMeasurementDate(item.tanggalUkur),
                      style: AppTypography.caption.copyWith(
                        color: SgColors.primaryDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Icon(
                    LucideIcons.chevronRight,
                    size: 17,
                    color: SgColors.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ChildAvatar(
                    name: child.nama,
                    gender: child.jenisKelamin,
                    radius: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          child.nama,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.h3,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Usia ${formatAgeAtMeasurement(birthDate: child.tanggalLahir, measurementDate: item.tanggalUkur, source: 'riwayat_timeline_card')}',
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              NutritionStatusBadges(status: item.statusGabungan),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _MeasureBox(
                      icon: LucideIcons.scale,
                      label: 'Berat badan',
                      value: '${item.berat.toStringAsFixed(1)} kg',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MeasureBox(
                      icon: LucideIcons.ruler,
                      label: 'Tinggi badan',
                      value: '${item.tinggi.toStringAsFixed(1)} cm',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6FBFA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFDDEDEA)),
                ),
                child: Text(
                  _insightText(item.statusGabungan, insight),
                  style: AppTypography.caption.copyWith(
                    color: const Color(0xFF3F5D58),
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    LucideIcons.fileSearch,
                    size: 16,
                    color: SgColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ketuk untuk detail analisis',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _insightText(String status, String fallback) {
    final normalized = normalizeStatus(status);
    if (normalized.hasStunting) {
      return 'Pertumbuhan tinggi badan perlu perhatian dan pemantauan rutin.';
    }
    if (normalized.hasUnderweight || normalized.hasWasting) {
      return 'Asupan energi dan protein perlu diperkuat secara bertahap.';
    }
    if (normalized.hasObesitas) {
      return 'Pola makan dan aktivitas harian perlu dijaga tetap seimbang.';
    }
    if (normalized.isNormal) {
      return 'Pertumbuhan stabil dan baik. Pertahankan pola makan seimbang.';
    }
    return fallback;
  }
}

class _MeasureBox extends StatelessWidget {
  const _MeasureBox({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FCFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SgColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: const Color(0xFFEAF7F7),
            child: Icon(icon, size: 16, color: SgColors.primary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(fontSize: 10),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.h3.copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistorySkeleton extends StatelessWidget {
  const _HistorySkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        for (var i = 0; i < 4; i++) ...[
          Container(
            height: i == 0 ? 96 : 150,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: SgColors.border),
            ),
          ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}

FlGridData _grid() {
  return FlGridData(
    show: true,
    drawVerticalLine: true,
    verticalInterval: 1,
    getDrawingHorizontalLine: (_) =>
        const FlLine(color: Color(0xFFE9F0EE), strokeWidth: 1),
    getDrawingVerticalLine: (_) =>
        const FlLine(color: Color(0xFFF1F5F4), strokeWidth: 1),
  );
}

LineTouchData _touchData(List<RiwayatItemModel> items) {
  return LineTouchData(
    handleBuiltInTouches: true,
    touchTooltipData: LineTouchTooltipData(
      getTooltipColor: (_) => Colors.white,
      tooltipRoundedRadius: 16,
      tooltipPadding: const EdgeInsets.all(12),
      tooltipBorder: const BorderSide(color: Color(0xFFDDEDEA)),
      getTooltipItems: (spots) => spots.map((spot) {
        final idx = spot.x.toInt().clamp(0, items.length - 1);
        final item = items[idx];
        return LineTooltipItem(
          '${formatMeasurementDate(item.tanggalUkur)}\n'
          'BB ${item.berat.toStringAsFixed(1)} kg • TB ${item.tinggi.toStringAsFixed(1)} cm\n'
          'Z BB/U ${_zLabel(item.zBbu)} • Z TB/U ${_zLabel(item.zTbu)}\n'
          '${localizeNutritionStatus(item.statusGabungan)}',
          AppTypography.caption.copyWith(
            color: SgColors.textPrimary,
            fontWeight: FontWeight.w800,
            height: 1.35,
          ),
        );
      }).toList(),
    ),
  );
}

LineChartBarData _chartLine(
  List<FlSpot> spots,
  Color color, {
  double width = 3,
  bool area = false,
}) {
  return LineChartBarData(
    spots: spots,
    isCurved: true,
    curveSmoothness: 0.35,
    color: color,
    barWidth: width,
    isStrokeCapRound: true,
    dotData: FlDotData(
      show: true,
      getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
        radius: index == spots.length - 1 ? 4.2 : 3,
        color: Colors.white,
        strokeWidth: 2.2,
        strokeColor: color,
      ),
    ),
    belowBarData: BarAreaData(
      show: area,
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.02)],
      ),
    ),
  );
}

class _LastPointLabel extends StatelessWidget {
  const _LastPointLabel({
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
                right: 2,
                top:
                    (topFactor.clamp(0.06, 0.76) *
                        (constraints.maxHeight - 42)) +
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
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
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

List<FlSpot> _normalizedSpots(List<double> values) {
  final min = values.reduce(math.min);
  final max = values.reduce(math.max);
  final range = (max - min).abs() < 0.01 ? 1.0 : max - min;
  return [
    for (var i = 0; i < values.length; i++)
      FlSpot(i.toDouble(), (values[i] - min) / range),
  ];
}

double? _chartValue(double? value, double? minY, double? maxY) {
  if (value == null || !_isValid(value)) return null;
  if (minY != null && maxY != null) return value.clamp(minY, maxY).toDouble();
  return value;
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
    safe.add(item);
  }

  return safe;
}

bool _hasValidMeasurement(RiwayatItemModel item) {
  final date = DateTime.tryParse(item.tanggalUkur);
  if (date == null) return false;
  if (!_isValid(item.berat) || !_isValid(item.tinggi)) return false;
  if (item.berat <= 0 || item.tinggi <= 0) return false;
  if (item.berat < 1.5 || item.berat > 45) return false;
  if (item.tinggi < 45 || item.tinggi > 125) return false;
  if (item.berat > item.tinggi) return false;
  return true;
}

Widget _axisText(String text) {
  return Text(
    text,
    style: AppTypography.caption.copyWith(fontSize: 10),
    textAlign: TextAlign.center,
  );
}

String _scaleLabel(double normalizedValue, List<double> values) {
  final min = values.reduce(math.min);
  final max = values.reduce(math.max);
  final value = min + ((max - min) * normalizedValue.clamp(0, 1));
  return value.toStringAsFixed(value.abs() >= 10 ? 0 : 1);
}

String _chartDateLabel(String rawDate, int index) {
  final date = DateTime.tryParse(rawDate);
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
  final label = months[date.month - 1];
  if (index == 0 || date.month == 1) return '$label\n${date.year}';
  return label;
}

String _shortMonth(String rawDate) {
  final date = DateTime.tryParse(rawDate);
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
  return '${date.day}\n${months[date.month - 1]}';
}

String _zLabel(double? value) {
  if (value == null || !_isValid(value)) return '-';
  return value.clamp(-3.0, 3.0).toStringAsFixed(1);
}

bool _isValid(double value) => value.isFinite && !value.isNaN;

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
          width: 13,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              color: SgColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
