import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:s_gizi/app_design.dart';
import 'package:s_gizi/providers/child_monitoring_provider.dart';
import 'package:s_gizi/screens/nutritionist/child_detail_screen.dart';
import 'package:s_gizi/widgets/child_monitoring_card.dart';
import 'package:s_gizi/widgets/filter_chip_status.dart';
import 'package:s_gizi/widgets/loading_skeleton.dart';
import 'package:s_gizi/widgets/nutritionist_bottom_nav_bar.dart';
import 'package:s_gizi/widgets/search_bar_widget.dart';
import 'package:s_gizi/widgets/summary_count_card.dart';

class ChildMonitoringScreen extends StatefulWidget {
  const ChildMonitoringScreen({
    super.key,
    this.showAppBar = true,
    this.showBottomNav = true,
  });

  final bool showAppBar;
  final bool showBottomNav;

  @override
  State<ChildMonitoringScreen> createState() => _ChildMonitoringScreenState();
}

class _ChildMonitoringScreenState extends State<ChildMonitoringScreen> {
  late final ChildMonitoringProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = ChildMonitoringProvider()..fetchChildren();
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFA),
      appBar: widget.showAppBar ? AppBar(title: const Text('Data Anak')) : null,
      bottomNavigationBar: widget.showBottomNav
          ? NutritionistBottomNavBar(
              currentIndex: 1,
              onTap: (index) {
                if (index == 1) return;
                Navigator.of(context).maybePop();
              },
            )
          : null,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _provider,
          builder: (context, _) {
            if (_provider.isLoading) return const LoadingSkeleton();
            if (_provider.errorMessage != null) {
              return ErrorState(
                message: _provider.errorMessage!,
                onRetry: _provider.fetchChildren,
              );
            }
            return RefreshIndicator(
              color: SgColors.primary,
              onRefresh: _provider.refreshChildren,
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  widget.showAppBar ? 14 : 4,
                  20,
                  widget.showBottomNav ? 120 : 28,
                ),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SearchBarWidget(
                    hintText: 'Cari nama anak atau orang tua',
                    onChanged: _provider.setSearchQuery,
                  ),
                  const SizedBox(height: 12),
                  _FilterRow(provider: _provider),
                  const SizedBox(height: 12),
                  _SummaryRow(provider: _provider),
                  const SizedBox(height: 16),
                  if (_provider.children.isEmpty)
                    const EmptyState(
                      title: 'Belum ada data anak',
                      message:
                          'Data akan muncul setelah orang tua menambahkan data anak dan melakukan pengukuran.',
                      icon: LucideIcons.baby,
                    )
                  else
                    ..._provider.children.map(
                      (child) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ChildMonitoringCard(
                          child: child,
                          onTap: () => Navigator.of(context).push(
                            fadeRoute(ChildDetailScreen(childId: child.id)),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.provider});

  final ChildMonitoringProvider provider;

  @override
  Widget build(BuildContext context) {
    const filters = [
      ('Semua', 'all'),
      ('Risiko Tinggi', 'high_risk'),
      ('Perlu Dipantau', 'watch'),
      ('Perlu Ukur Ulang', 'anomaly'),
      ('Normal', 'normal'),
    ];
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = filters[index];
          return FilterChipStatus(
            label: item.$1,
            value: item.$2,
            selectedValue: provider.selectedFilter,
            onSelected: provider.setFilter,
          );
        },
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.provider});

  final ChildMonitoringProvider provider;

  @override
  Widget build(BuildContext context) {
    final summary = provider.summary;
    final items = [
      ('Total', summary.total, LucideIcons.users, SgColors.primary),
      (
        'Risiko',
        summary.highRisk,
        Icons.warning_amber_rounded,
        const Color(0xFFC62828),
      ),
      (
        'Ukur Ulang',
        summary.anomaly,
        LucideIcons.activity,
        const Color(0xFFEF6C00),
      ),
      (
        'Normal',
        summary.normal,
        LucideIcons.checkCircle,
        const Color(0xFF2E7D32),
      ),
    ];
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          return SummaryCountCard(
            label: item.$1,
            value: item.$2,
            icon: item.$3,
            color: item.$4,
          );
        },
      ),
    );
  }
}
