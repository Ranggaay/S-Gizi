import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:s_gizi/app_design.dart';
import 'package:s_gizi/app_state.dart';
import 'package:s_gizi/models/mobile_child_model.dart';
import 'package:s_gizi/models/riwayat_response_model.dart';
import 'package:s_gizi/services/api_service.dart';
import 'package:s_gizi/utils/nutrition_display_utils.dart';
import 'package:s_gizi/utils/parent_greeting_utils.dart';
import 'package:s_gizi/widgets/dashboard_home_header.dart';
import 'package:s_gizi/widgets/growth_chart_card.dart';
import 'package:s_gizi/features/consultation/screens/consultation_chat_screen.dart';
import 'package:s_gizi/features/children/screens/input_screen.dart';
import 'package:s_gizi/features/nutrition/screens/recommendation_screen.dart';
import 'package:s_gizi/features/history/screens/riwayat_screen.dart';

/// Dashboard utama / detail untuk satu anak terpilih.
class ChildDashboardScreen extends StatefulWidget {
  const ChildDashboardScreen({
    super.key,
    this.childId,
    this.embedded = false,
    this.onChangeTab,
  });

  final int? childId;
  final bool embedded;
  final ValueChanged<int>? onChangeTab;

  @override
  State<ChildDashboardScreen> createState() => _ChildDashboardScreenState();
}

class _ChildDashboardScreenState extends State<ChildDashboardScreen> {
  final _api = ApiService();
  final _appState = SgiziAppState.instance;
  late Future<_ChildDashboardData> _future;

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

  @override
  void didUpdateWidget(covariant ChildDashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.childId != widget.childId) {
      setState(() => _future = _load());
    }
  }

  void _onState() => setState(() => _future = _load());

  Future<_ChildDashboardData> _load() async {
    final id = widget.childId ?? _appState.activeChildId;
    if (id == null) {
      return const _ChildDashboardData(child: null, history: null);
    }
    final child = _appState.children.where((c) => c.id == id).firstOrNull;
    if (child == null) {
      return const _ChildDashboardData(child: null, history: null);
    }
    final history = await _api.getRiwayat(childId: child.id);
    return _ChildDashboardData(child: child, history: history);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      body: SafeArea(
        child: FutureBuilder<_ChildDashboardData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: HealthCard(
                    dense: true,
                    child: Text('Memuat dashboard anak...'),
                  ),
                ),
              );
            }
            if (snapshot.hasError) {
              return ErrorState(
                message: 'Gagal memuat dashboard anak.',
                onRetry: () => setState(() => _future = _load()),
              );
            }
            final data = snapshot.data!;
            final child = data.child;
            final latest = data.latestMeasurement;
            if (child == null) {
              return const EmptyState(
                title: 'Anak Tidak Ditemukan',
                message: 'Pilih anak dari dashboard keluarga.',
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.embedded) ...[
                    const DashboardHomeHeader().animate().fadeIn(
                      duration: 240.ms,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      parentGreetingFromProfile(
                        _appState.profileData ?? _appState.userData,
                      ),
                      style: AppTypography.h1.copyWith(fontSize: 32),
                    ).animate().fadeIn(delay: 40.ms),
                    const SizedBox(height: 6),
                    Text(
                      'Pantau pertumbuhan si kecil hari ini.',
                      style: AppTypography.body,
                    ).animate().fadeIn(delay: 60.ms),
                    const SizedBox(height: 16),
                  ] else
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(LucideIcons.chevronLeft),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dashboard Anak',
                                style: AppTypography.caption,
                              ),
                              Text(
                                child.nama,
                                style: AppTypography.h1.copyWith(fontSize: 28),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ).animate().fadeIn(duration: 240.ms),
                  if (!widget.embedded) ...[
                    const SizedBox(height: 8),
                    Text(
                      formatAgeFromBirthDate(
                        child.tanggalLahir,
                        source: 'child_dashboard_header',
                      ),
                      style: AppTypography.body,
                    ),
                  ],
                  const SizedBox(height: 16),
                  _ChildHeroCard(child: child, latest: latest),
                  const SizedBox(height: 16),
                  if (data.history != null)
                    GrowthChartCard(
                      history: data.history!.riwayat,
                      onViewDetail: latest == null
                          ? null
                          : () => Navigator.of(context).push(
                              fadeRoute(
                                RiwayatScreen(childId: child.id, initialTab: 1),
                              ),
                            ),
                    ),
                  const SizedBox(height: 16),
                  _StatusDetailCard(
                    latest: latest,
                    onOpen: latest == null
                        ? () => Navigator.of(
                            context,
                          ).push(fadeRoute(const InputScreen()))
                        : () => Navigator.of(
                            context,
                          ).push(fadeRoute(RiwayatScreen(childId: child.id))),
                  ),
                  const SizedBox(height: 20),
                  Text('Aksi Cepat', style: AppTypography.h2),
                  const SizedBox(height: 12),
                  _ChildQuickActions(
                    hasMeasurement: latest != null,
                    onHitung: () => Navigator.of(
                      context,
                    ).push(fadeRoute(const InputScreen())),
                    onRekomendasi: latest == null
                        ? null
                        : () {
                            if (widget.onChangeTab != null) {
                              widget.onChangeTab!(1);
                              return;
                            }
                            Navigator.of(context).push(
                              fadeRoute(
                                RecommendationScreen(
                                  childId: child.id,
                                  riwayatId: latest.id,
                                  childName: child.nama,
                                  status: latest.statusGabungan,
                                  measuredAt: latest.tanggalUkur,
                                ),
                              ),
                            );
                          },
                    onRiwayat: () => Navigator.of(
                      context,
                    ).push(fadeRoute(RiwayatScreen(childId: child.id))),
                    onKonsultasi: () => Navigator.of(
                      context,
                    ).push(fadeRoute(const ConsultationChatScreen())),
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

class _ChildDashboardData {
  const _ChildDashboardData({required this.child, required this.history});

  final MobileChildModel? child;
  final RiwayatResponseModel? history;

  RiwayatItemModel? get latestMeasurement {
    final records = history?.riwayat;
    if (records == null || records.isEmpty) return null;
    final sorted = [...records]
      ..sort((a, b) {
        final ad = DateTime.tryParse(a.tanggalUkur) ?? DateTime(2000);
        final bd = DateTime.tryParse(b.tanggalUkur) ?? DateTime(2000);
        final dateCompare = ad.compareTo(bd);
        if (dateCompare != 0) return dateCompare;
        return a.id.compareTo(b.id);
      });
    return sorted.last;
  }
}

class _ChildHeroCard extends StatelessWidget {
  const _ChildHeroCard({required this.child, required this.latest});

  final MobileChildModel child;
  final RiwayatItemModel? latest;

  @override
  Widget build(BuildContext context) {
    final visual = nutritionStatusVisual(
      latest?.statusGabungan ?? child.latestStatus ?? 'Belum Diukur',
    );
    return HealthCard(
      child: Row(
        children: [
          ChildAvatar(name: child.nama, gender: child.jenisKelamin, radius: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(child.nama, style: AppTypography.h2),
                Text(
                  formatAgeFromBirthDate(
                    child.tanggalLahir,
                    source: 'child_dashboard_hero_card',
                  ),
                  style: AppTypography.body,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: visual.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    visual.badgeLabel,
                    style: AppTypography.caption.copyWith(
                      color: visual.color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusDetailCard extends StatelessWidget {
  const _StatusDetailCard({required this.latest, required this.onOpen});

  final RiwayatItemModel? latest;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    if (latest == null) {
      return HealthCard(
        dense: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 28,
              backgroundColor: Color(0xFFEAF8F7),
              child: Icon(LucideIcons.activity, color: SgColors.primary),
            ),
            const SizedBox(height: 12),
            Text(
              'Belum ada pengukuran tersimpan',
              style: AppTypography.h2.copyWith(fontSize: 17),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              'Yuk mulai pantau pertumbuhan anak dengan pengukuran pertama.',
              style: AppTypography.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Tambah Pengukuran Pertama',
              icon: PhosphorIconsBold.calculator,
              onPressed: onOpen,
            ),
          ],
        ),
      );
    }

    final normalized = normalizeStatus(latest!.statusGabungan);
    return HealthCard(
      color: const Color(0xFFE8F7F1),
      borderColor: const Color(0xFF0B7A86),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Status Gizi Terakhir', style: AppTypography.h3),
          const SizedBox(height: 8),
          Text(
            normalized.primaryCategory,
            style: AppTypography.h1.copyWith(
              fontSize: 26,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            normalized.focusSummary,
            style: AppTypography.body.copyWith(color: Colors.black87),
          ),
          const SizedBox(height: 10),
          Text(
            'Terakhir diperiksa: ${formatMeasurementDate(latest!.tanggalUkur)}',
            style: AppTypography.caption,
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: 'Lihat Detail Analisis',
            icon: LucideIcons.arrowRight,
            onPressed: onOpen,
          ),
        ],
      ),
    );
  }
}

class _ChildQuickActions extends StatelessWidget {
  const _ChildQuickActions({
    required this.hasMeasurement,
    required this.onHitung,
    required this.onRekomendasi,
    required this.onRiwayat,
    required this.onKonsultasi,
  });

  final bool hasMeasurement;
  final VoidCallback onHitung;
  final VoidCallback? onRekomendasi;
  final VoidCallback onRiwayat;
  final VoidCallback onKonsultasi;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionChip(
            icon: PhosphorIconsBold.calculator,
            label: 'Hitung Gizi',
            onTap: onHitung,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionChip(
            icon: LucideIcons.apple,
            label: 'Nutrisi',
            onTap: onRekomendasi ?? () {},
            enabled: onRekomendasi != null,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionChip(
            icon: LucideIcons.messageCircle,
            label: 'Konsultasi',
            onTap: onKonsultasi,
          ),
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE1E8E6)),
          ),
          child: Column(
            children: [
              Icon(icon, color: const Color(0xFF0B7A86), size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
