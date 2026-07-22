import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:s_gizi/app_design.dart';
import 'package:s_gizi/app_state.dart';
import 'package:s_gizi/models/mobile_child_model.dart';
import 'package:s_gizi/models/riwayat_response_model.dart';
import 'package:s_gizi/services/api_service.dart';
import 'package:s_gizi/utils/dashboard_error_utils.dart';
import 'package:s_gizi/utils/parent_greeting_utils.dart';
import 'package:s_gizi/widgets/dashboard_home_header.dart';
import 'package:s_gizi/widgets/family_child_overview_card.dart';
import 'package:s_gizi/widgets/family_dashboard_skeleton.dart';
import 'package:s_gizi/features/children/screens/add_child_screen.dart';
import 'package:s_gizi/features/dashboard/screens/main_dashboard_screen.dart';

/// Overview pertumbuhan seluruh anak (hanya jika > 1 anak).
class FamilyDashboardScreen extends StatefulWidget {
  const FamilyDashboardScreen({
    super.key,
    required this.onChangeTab,
    this.onOpenDashboard,
  });

  final ValueChanged<int> onChangeTab;
  final ValueChanged<MobileChildModel>? onOpenDashboard;

  @override
  State<FamilyDashboardScreen> createState() => _FamilyDashboardScreenState();
}

class _FamilyDashboardScreenState extends State<FamilyDashboardScreen> {
  final _api = ApiService();
  final _appState = SgiziAppState.instance;
  late Future<_FamilyDashboardData> _future;

  @override
  void initState() {
    super.initState();
    _appState.addListener(_onState);
    _future = _load();
  }

  @override
  void dispose() {
    _appState.removeListener(_onState);
    super.dispose();
  }

  void _onState() => setState(() => _future = _load());

  Future<_FamilyDashboardData> _load() async {
    final children = _appState.children;
    final histories = <int, RiwayatResponseModel>{};
    Object? firstError;
    var failedCount = 0;
    await Future.wait(
      children.map((child) async {
        try {
          histories[child.id] = await _api.getRiwayat(childId: child.id);
        } catch (error) {
          firstError ??= error;
          failedCount++;
        }
      }),
    );
    if (children.isNotEmpty && failedCount == children.length) {
      throw firstError ?? Exception('Gagal memuat dashboard keluarga.');
    }
    return _FamilyDashboardData(children: children, histories: histories);
  }

  void _openChildDashboard(MobileChildModel child) {
    _appState.setActiveChild(child.id);
    if (widget.onOpenDashboard != null) {
      widget.onOpenDashboard!(child);
      return;
    }
    Navigator.of(
      context,
    ).push(fadeRoute(MainDashboardScreen(onChangeTab: widget.onChangeTab)));
  }

  void _openAddChild() {
    Navigator.of(context).push(fadeRoute(const AddChildScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SgColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddChild,
        backgroundColor: SgColors.primaryTeal,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
        label: const Text(
          'Tambah Anak',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<_FamilyDashboardData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const FamilyDashboardSkeleton();
            }
            if (snapshot.hasError) {
              final info = dashboardErrorInfo(snapshot.error);
              return ErrorState(
                title: info.title,
                message: info.message,
                icon: info.icon,
                color: info.color,
                onRetry: () => setState(() => _future = _load()),
              );
            }

            final data = snapshot.data!;
            final children = data.children;

            return RefreshIndicator(
              color: SgColors.primary,
              onRefresh: () async {
                final refreshed = await _api.getChildren();
                _appState.setChildren(refreshed);
                setState(() => _future = _load());
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  SgSpacing.pageH,
                  SgSpacing.pageV,
                  SgSpacing.pageH,
                  88,
                ),
                children: [
                  const DashboardHomeHeader().animate().fadeIn(
                    duration: 240.ms,
                  ),
                  const SizedBox(height: SgSpacing.item),
                  Text(
                    parentGreetingFromProfile(
                      _appState.profileData ?? _appState.userData,
                    ),
                    style: AppTypography.h1.copyWith(fontSize: 26),
                  ).animate().fadeIn(delay: 30.ms),
                  const SizedBox(height: 4),
                  Text(
                    'Pantau pertumbuhan si kecil hari ini.',
                    style: AppTypography.body.copyWith(fontSize: 13),
                  ).animate().fadeIn(delay: 50.ms),
                  const SizedBox(height: SgSpacing.section),
                  Text('Anak Anda', style: AppTypography.h2),
                  const SizedBox(height: SgSpacing.item),
                  ...children.asMap().entries.map((entry) {
                    final index = entry.key;
                    final child = entry.value;
                    final history =
                        data.histories[child.id]?.riwayat ?? const [];
                    final latest = data.latestFor(child.id);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: FamilyChildOverviewCard(
                        child: child,
                        latest: latest,
                        history: history,
                        index: index,
                        onTap: () => _openChildDashboard(child),
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FamilyDashboardData {
  _FamilyDashboardData({required this.children, required this.histories});

  final List<MobileChildModel> children;
  final Map<int, RiwayatResponseModel> histories;

  RiwayatItemModel? latestFor(int childId) {
    final records = histories[childId]?.riwayat;
    if (records == null || records.isEmpty) return null;
    final sorted = [...records]
      ..sort((a, b) {
        final bd = DateTime.tryParse(b.tanggalUkur) ?? DateTime(2000);
        final ad = DateTime.tryParse(a.tanggalUkur) ?? DateTime(2000);
        return bd.compareTo(ad);
      });
    return sorted.first;
  }
}
