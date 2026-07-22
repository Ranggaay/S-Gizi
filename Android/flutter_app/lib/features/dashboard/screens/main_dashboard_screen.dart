import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:s_gizi/app_design.dart';
import 'package:s_gizi/app_state.dart';
import 'package:s_gizi/core/helpers/nutrition_status_helper.dart';
import 'package:s_gizi/models/mobile_child_model.dart';
import 'package:s_gizi/models/news_article_model.dart';
import 'package:s_gizi/models/riwayat_response_model.dart';
import 'package:s_gizi/services/api_service.dart';
import 'package:s_gizi/services/article_service.dart';
import 'package:s_gizi/utils/dashboard_error_utils.dart';
import 'package:s_gizi/utils/nutrition_display_utils.dart';
import 'package:s_gizi/utils/parent_greeting_utils.dart';
import 'package:s_gizi/widgets/article_search_bar.dart';
import 'package:s_gizi/widgets/growth_chart_card.dart';
import 'package:s_gizi/features/articles/screens/article_detail_screen.dart';
import 'package:s_gizi/features/articles/screens/articles_screen.dart';
import 'package:s_gizi/features/children/screens/children_screen.dart';
import 'package:s_gizi/features/consultation/screens/consultation_chat_screen.dart';
import 'package:s_gizi/features/children/screens/input_screen.dart';
import 'package:s_gizi/features/nutrition/screens/recommendation_screen.dart';
import 'package:s_gizi/features/history/screens/riwayat_screen.dart';

class MainDashboardScreen extends StatefulWidget {
  const MainDashboardScreen({
    super.key,
    required this.onChangeTab,
    this.onShowFamilyOverview,
  });

  final ValueChanged<int> onChangeTab;
  final VoidCallback? onShowFamilyOverview;

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  final ApiService _apiService = ApiService();
  final ArticleService _articleService = ArticleService();
  final SgiziAppState _appState = SgiziAppState.instance;
  late Future<_HomeDashboardData> _future;
  late Future<List<NewsArticleModel>> _articlesFuture;
  String _articleQuery = '';
  String _articleCategory = 'Semua';
  final Set<int> _readDashboardNotificationRooms = {};

  @override
  void initState() {
    super.initState();
    _appState.addListener(_handleState);
    _future = _load();
    _articlesFuture = _loadArticles();
  }

  @override
  void dispose() {
    _appState.removeListener(_handleState);
    super.dispose();
  }

  void _handleState() => setState(() {
    _future = _load();
    _articlesFuture = _loadArticles();
  });
  void _retry() => setState(() {
    _future = _load();
    _articlesFuture = _loadArticles();
  });

  Future<_HomeDashboardData> _load() async {
    final child = _appState.activeChild;
    if (child == null) {
      return const _HomeDashboardData(child: null, history: null);
    }
    final results = await Future.wait([
      _apiService.getRiwayat(childId: child.id),
      _apiService.getConsultationRooms(childId: child.id),
    ]);
    return _HomeDashboardData(
      child: child,
      history: results[0] as RiwayatResponseModel,
      consultationRooms: (results[1] as List<Map<String, dynamic>>),
    );
  }

  Future<List<NewsArticleModel>> _loadArticles() async {
    return _articleService.fetchArticles(
      query: _articleQuery,
      category: _articleCategory,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      body: SafeArea(
        child: FutureBuilder<_HomeDashboardData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _HomeSkeleton();
            }
            if (snapshot.hasError) {
              return _HomeError(error: snapshot.error, onRetry: _retry);
            }
            final data = snapshot.data!;
            final child = data.child;
            final latest = data.latestMeasurement;
            return RefreshIndicator(
              color: SgColors.primary,
              onRefresh: () async {
                _retry();
                await _future;
                await _articlesFuture;
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  SgSpacing.pageH,
                  SgSpacing.pageV,
                  SgSpacing.pageH,
                  20,
                ),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TopBar(
                      notifications: data.notifications
                          .where(
                            (item) => !_readDashboardNotificationRooms.contains(
                              item.roomId,
                            ),
                          )
                          .toList(),
                      onOpenNotifications: (items) {
                        setState(() {
                          _readDashboardNotificationRooms.addAll(
                            items
                                .where((item) => item.roomId != null)
                                .map((item) => item.roomId!),
                          );
                        });
                        _showParentNotificationSheet(context, items);
                      },
                      onOpenProfile: () => widget.onChangeTab(3),
                    ),
                    const SizedBox(height: 12),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFE2E8E6),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      parentGreetingFromProfile(
                        _appState.profileData ?? _appState.userData,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.h1.copyWith(fontSize: 30),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Ayo pantau tumbuh kembang si kecil hari ini.',
                      style: AppTypography.body,
                    ),
                    const SizedBox(height: 16),
                    _ActiveChildCard(
                      child: child,
                      onTap: () {
                        if (child == null) {
                          Navigator.of(
                            context,
                          ).push(fadeRoute(const ChildrenScreen()));
                          return;
                        }
                        _appState.showFamilyOverview();
                        widget.onShowFamilyOverview?.call();
                      },
                    ),
                    const SizedBox(height: 16),
                    if (child == null)
                      EmptyState(
                        title: 'Belum Ada Data Anak',
                        message: 'Tambahkan data anak agar dashboard aktif.',
                        actionLabel: 'Tambah Data Anak',
                        onAction: () => Navigator.of(
                          context,
                        ).push(fadeRoute(const ChildrenScreen())),
                      )
                    else
                      _ModernStatusCard(
                        child: child,
                        latest: latest,
                        onOpen: () => Navigator.of(
                          context,
                        ).push(fadeRoute(RiwayatScreen(childId: child.id))),
                      ),
                    if (child != null) ...[
                      const SizedBox(height: 16),
                      GrowthChartCard(
                        history: data.recentMeasurements,
                        onViewDetail: () => Navigator.of(context).push(
                          fadeRoute(
                            RiwayatScreen(childId: child.id, initialTab: 1),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _GrowthInsightCard(latest: latest),
                    ],
                    const SizedBox(height: 18),
                    Text(
                      'Menu Utama',
                      style: GoogleFonts.montserrat(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: SgColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _MainMenuRow(
                      onTapInput: () => Navigator.of(
                        context,
                      ).push(fadeRoute(const InputScreen())),
                      onTapRecommendation: latest == null
                          ? null
                          : () => Navigator.of(context).push(
                              fadeRoute(
                                RecommendationScreen(
                                  childId: child!.id,
                                  riwayatId: latest.id,
                                  childName: child.nama,
                                  status: latest.statusGabungan,
                                  measuredAt: latest.tanggalUkur,
                                ),
                              ),
                            ),
                      onTapConsultation: () => Navigator.of(
                        context,
                      ).push(fadeRoute(const ConsultationChatScreen())),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Edukasi Si Kecil',
                            style: GoogleFonts.montserrat(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: SgColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).push(
                            fadeRoute(
                              const ArticlesScreen(
                                title: 'Artikel Edukasi',
                                articles: [],
                              ),
                            ),
                          ),
                          child: const Text('Lihat Semua'),
                        ),
                      ],
                    ),
                    ArticleSearchBar(
                      query: _articleQuery,
                      selectedCategory: _articleCategory,
                      categories: ArticleService.categories,
                      onChanged: (v) => setState(() {
                        _articleQuery = v;
                        _articlesFuture = _loadArticles();
                      }),
                      onCategoryChanged: (v) => setState(() {
                        _articleCategory = v;
                        _articlesFuture = _loadArticles();
                      }),
                    ),
                    const SizedBox(height: 10),
                    FutureBuilder<List<NewsArticleModel>>(
                      future: _articlesFuture,
                      builder: (context, articleSnapshot) {
                        if (articleSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const _ArticleSkeletonList();
                        }
                        if (articleSnapshot.hasError) {
                          return _ArticleError(onRetry: _retry);
                        }
                        final allArticles = articleSnapshot.data ?? const [];
                        final articles = allArticles.where((a) {
                          final q = _articleQuery.trim().toLowerCase();
                          final cat = _articleCategory;
                          final matchQuery =
                              q.isEmpty ||
                              a.title.toLowerCase().contains(q) ||
                              a.category.toLowerCase().contains(q);
                          final matchCat =
                              cat == 'Semua' ||
                              a.category.toLowerCase().contains(
                                cat.toLowerCase(),
                              );
                          return matchQuery && matchCat;
                        }).toList();
                        if (articles.isEmpty) {
                          return _ArticleEmpty(onRetry: _retry);
                        }
                        final textScale = MediaQuery.textScalerOf(
                          context,
                        ).scale(1);
                        final screenHeight = MediaQuery.sizeOf(context).height;
                        final articleHeight =
                            math.max(
                              272.0,
                              math.min(318.0, screenHeight * 0.34),
                            ) +
                            ((textScale - 1).clamp(0.0, 1.0) * 72);
                        return SizedBox(
                          height: articleHeight,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: articles.length > 5
                                ? 5
                                : articles.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              return _ArticleCard(
                                article: articles[index],
                                related: articles,
                                index: index,
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HomeDashboardData {
  const _HomeDashboardData({
    required this.child,
    required this.history,
    this.consultationRooms = const [],
  });

  final MobileChildModel? child;
  final RiwayatResponseModel? history;
  final List<Map<String, dynamic>> consultationRooms;

  RiwayatItemModel? get latestMeasurement {
    final records = history?.riwayat;
    if (records == null || records.isEmpty) return null;
    final sorted = [...records]
      ..sort((a, b) {
        final ad = DateTime.tryParse(a.tanggalUkur) ?? DateTime(1900);
        final bd = DateTime.tryParse(b.tanggalUkur) ?? DateTime(1900);
        final dateCompare = ad.compareTo(bd);
        if (dateCompare != 0) return dateCompare;
        return a.id.compareTo(b.id);
      });
    return sorted.last;
  }

  List<RiwayatItemModel> get recentMeasurements {
    final records = history?.riwayat;
    if (records == null || records.isEmpty) return const [];
    final sorted = [...records]
      ..sort((a, b) {
        final bd = DateTime.tryParse(b.tanggalUkur) ?? DateTime(2000);
        final ad = DateTime.tryParse(a.tanggalUkur) ?? DateTime(2000);
        return bd.compareTo(ad);
      });
    return sorted.take(6).toList().reversed.toList();
  }

  List<_ParentNotification> get notifications {
    final chatNotifications = consultationRooms
        .where((room) => ((room['unread_count'] as num?)?.toInt() ?? 0) > 0)
        .map(
          (room) => _ParentNotification(
            title: 'Ahli Gizi membalas konsultasi',
            description:
                '${room['expert_name'] ?? 'Ahli Gizi'} - ${room['last_message'] ?? 'Pesan baru'}',
            time: _shortNotificationTime(room['last_message_at'] as String?),
            count: (room['unread_count'] as num?)?.toInt() ?? 0,
            roomId: (room['id'] as num?)?.toInt(),
          ),
        )
        .toList();

    final latest = latestMeasurement;
    if (latest == null) return chatNotifications;
    final latestDate = DateTime.tryParse(latest.tanggalUkur);
    final now = DateTime.now();
    final needsReminder =
        latestDate == null || now.difference(latestDate).inDays >= 30;
    if (needsReminder) {
      chatNotifications.add(
        const _ParentNotification(
          title: 'Pengingat pengukuran bulanan',
          description: 'Saatnya memperbarui BB dan TB anak.',
          time: 'Hari ini',
          count: 1,
        ),
      );
    }
    return chatNotifications;
  }
}

class _ParentNotification {
  const _ParentNotification({
    required this.title,
    required this.description,
    required this.time,
    required this.count,
    this.roomId,
  });

  final String title;
  final String description;
  final String time;
  final int count;
  final int? roomId;
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.notifications,
    required this.onOpenNotifications,
    required this.onOpenProfile,
  });

  final List<_ParentNotification> notifications;
  final ValueChanged<List<_ParentNotification>> onOpenNotifications;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final profile =
        SgiziAppState.instance.profileData ?? SgiziAppState.instance.userData;
    final name = (profile?['name'] as String?)?.trim() ?? 'Pengguna';
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.asset(
            'assets/image/logo_sgizi.png',
            width: 66,
            height: 66,
            fit: BoxFit.cover,
          ),
        ),
        const Spacer(),
        _DashboardNotificationButton(
          count: notifications
              .where((item) => item.roomId != null)
              .fold<int>(0, (sum, item) => sum + item.count),
          onTap: () => onOpenNotifications(notifications),
        ),
        const SizedBox(width: 10),
        InkWell(
          onTap: onOpenProfile,
          borderRadius: BorderRadius.circular(999),
          child:
              Stack(
                    children: [
                      SgAvatar(name: name, radius: 22, icon: Icons.person),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 11,
                          height: 11,
                          decoration: BoxDecoration(
                            color: const Color(0xFF34C759),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .moveY(begin: 0, end: -2, duration: 1800.ms),
        ),
      ],
    );
  }
}

class _DashboardNotificationButton extends StatelessWidget {
  const _DashboardNotificationButton({
    required this.count,
    required this.onTap,
  });

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF8F7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFCFEAE7)),
            ),
            child: const Icon(LucideIcons.bell, color: SgColors.primary),
          ),
          if (count > 0)
            Positioned(
              right: -3,
              top: -5,
              child: Container(
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                padding: const EdgeInsets.symmetric(horizontal: 5),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: SgColors.danger,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

void _showParentNotificationSheet(
  BuildContext context,
  List<_ParentNotification> notifications,
) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (context) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.70,
        ),
        child: notifications.isEmpty
            ? const Padding(
                padding: EdgeInsets.fromLTRB(18, 8, 18, 24),
                child: EmptyState(
                  title: 'Tidak Ada Notifikasi',
                  message:
                      'Notifikasi konsultasi dan pengukuran akan tampil di sini.',
                  icon: LucideIcons.bell,
                ),
              )
            : ListView.separated(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                itemBuilder: (context, index) {
                  final item = notifications[index];
                  return HealthCard(
                    dense: true,
                    onTap: item.roomId == null
                        ? null
                        : () {
                            Navigator.of(context).pop();
                            Navigator.of(context).push(
                              fadeRoute(
                                ConsultationChatScreen(roomId: item.roomId),
                              ),
                            );
                          },
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xFFEAF8F7),
                          child: Icon(
                            item.roomId == null
                                ? LucideIcons.calendarClock
                                : LucideIcons.messageCircle,
                            color: SgColors.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.title, style: AppTypography.h3),
                              const SizedBox(height: 2),
                              Text(
                                item.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.caption,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(item.time, style: AppTypography.caption),
                      ],
                    ),
                  );
                },
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemCount: notifications.length,
              ),
      ),
    ),
  );
}

String _shortNotificationTime(String? raw) {
  if (raw == null || raw.trim().isEmpty) return 'Baru';
  final date = DateTime.tryParse(raw)?.toLocal();
  if (date == null) return 'Baru';
  final now = DateTime.now();
  final diff = now.difference(date);
  if (diff.inMinutes < 1) return 'Baru';
  if (diff.inMinutes < 60) return '${diff.inMinutes} menit';
  if (diff.inHours < 24) return '${diff.inHours} jam';
  return '${diff.inDays} hari';
}

class _ActiveChildCard extends StatelessWidget {
  const _ActiveChildCard({required this.child, required this.onTap});
  final MobileChildModel? child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HealthCard(
      dense: true,
      onTap: onTap,
      child: Row(
        children: [
          ChildAvatar(
            name: child?.nama ?? 'Anak',
            gender: child?.jenisKelamin ?? 'L',
            radius: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  child?.nama ?? 'Belum ada anak aktif',
                  style: AppTypography.h2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  child == null
                      ? '-'
                      : formatAgeFromBirthDate(
                          child!.tanggalLahir,
                          source: 'main_dashboard_active_child_header',
                        ),
                  style: AppTypography.body,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4F3),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text('Ganti'),
          ),
        ],
      ),
    );
  }
}

class _ModernStatusCard extends StatelessWidget {
  const _ModernStatusCard({
    required this.child,
    required this.latest,
    required this.onOpen,
  });

  final MobileChildModel child;
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
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF8F7),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                PhosphorIconsRegular.chartLineUp,
                color: SgColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Belum ada pengukuran tersimpan',
              style: AppTypography.h2.copyWith(fontSize: 17),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Yuk mulai pantau pertumbuhan anak dengan pengukuran pertama.',
              style: AppTypography.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Tambah Pengukuran Pertama',
              icon: PhosphorIconsBold.calculator,
              onPressed: () =>
                  Navigator.of(context).push(fadeRoute(const InputScreen())),
            ),
          ],
        ),
      );
    }

    return HealthCard(
      color: const Color(0xFFE3F6F8),
      borderColor: const Color(0xFFC8ECF0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'UPDATE: ${formatMeasurementDate(latest!.tanggalUkur).toUpperCase()}',
            style: AppTypography.caption.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Status Gizi: ${_shortStatus(latest!.statusGabungan)}',
                  style: AppTypography.h2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _statusDescription(latest!.statusGabungan),
            style: AppTypography.body.copyWith(color: const Color(0xFF2E5258)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _SmallMetric(
                  label: 'Berat',
                  value: '${latest!.berat.toStringAsFixed(1)} kg',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SmallMetric(
                  label: 'Tinggi',
                  value: '${latest!.tinggi.toStringAsFixed(1)} cm',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SmallMetric(
                  label: 'Usia',
                  value: formatAgeAtMeasurement(
                    birthDate: child.tanggalLahir,
                    measurementDate: latest!.tanggalUkur,
                    source: 'main_dashboard_status_card',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: 'Lihat Detail Analisis',
            icon: LucideIcons.arrowRight,
            onPressed: onOpen,
            isOutlined: true,
          ),
        ],
      ),
    );
  }
}

class _SmallMetric extends StatelessWidget {
  const _SmallMetric({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.caption),
          Text(value, style: AppTypography.h3, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _GrowthInsightCard extends StatelessWidget {
  const _GrowthInsightCard({required this.latest});

  final RiwayatItemModel? latest;

  @override
  Widget build(BuildContext context) {
    final message = latest == null
        ? 'Belum ada pengukuran tersimpan. Yuk mulai pantau pertumbuhan anak.'
        : friendlyDashboardSummary(latest!.statusGabungan);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6FBFA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDEDEA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFFE4F7F6),
            child: Icon(
              LucideIcons.sparkles,
              size: 16,
              color: SgColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body.copyWith(height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _MainMenuRow extends StatelessWidget {
  const _MainMenuRow({
    required this.onTapInput,
    required this.onTapRecommendation,
    required this.onTapConsultation,
  });
  final VoidCallback onTapInput;
  final VoidCallback? onTapRecommendation;
  final VoidCallback onTapConsultation;

  @override
  Widget build(BuildContext context) {
    final showRecommendation = onTapRecommendation != null;
    return Row(
      children: [
        Expanded(
          child: _MenuItem(
            icon: PhosphorIconsBold.calculator,
            label: 'Hitung Gizi',
            color: const Color(0xFF77D9E3),
            onTap: onTapInput,
          ),
        ),
        const SizedBox(width: 10),
        if (showRecommendation) ...[
          Expanded(
            child: _MenuItem(
              icon: LucideIcons.apple,
              label: 'Rekomendasi',
              color: const Color(0xFF63D39D),
              onTap: onTapRecommendation!,
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: _MenuItem(
            icon: LucideIcons.messageCircle,
            label: 'Konsultasi',
            color: const Color(0xFFF5A56E),
            onTap: onTapConsultation,
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 13,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTypography.caption,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  const _ArticleCard({
    required this.article,
    required this.related,
    required this.index,
  });
  final NewsArticleModel article;
  final List<NewsArticleModel> related;
  final int index;
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final cardWidth = math.min(220.0, math.max(176.0, screenWidth * 0.66));
    final imageHeight = screenWidth < 380 ? 90.0 : 102.0;
    final cardHeight =
        math.max(266.0, math.min(306.0, screenHeight * 0.325)) +
        ((textScale - 1).clamp(0.0, 1.0) * 72);
    return SizedBox(
      width: cardWidth,
      height: cardHeight,
      child: HealthCard(
        padding: EdgeInsets.zero,
        dense: true,
        onTap: () => Navigator.of(context).push(
          fadeRoute(ArticleDetailScreen(article: article, related: related)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: Hero(
                tag: 'article-${article.id}',
                child: _CardImage(
                  imageUrl: article.image,
                  fallbackIndex: index,
                  height: imageHeight,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StatusBadge(
                      text: article.category,
                      color: const Color(0xFF0B7A86),
                      compact: true,
                    ),
                    SizedBox(height: textScale > 1.15 ? 4 : 6),
                    Text(
                      article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.h3.copyWith(fontSize: 13),
                    ),
                    SizedBox(height: textScale > 1.15 ? 3 : 4),
                    Text(
                      article.description,
                      maxLines: textScale > 1.2 ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body.copyWith(fontSize: 12),
                    ),
                    if (textScale <= 1.05 &&
                        screenHeight >= 760 &&
                        article.sourceName != null &&
                        article.sourceName!.trim().isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        'Sumber: ${article.sourceName!}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          color: const Color(0xFF0B7A86),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Baca Selengkapnya',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption.copyWith(
                              color: const Color(0xFF0B7A86),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          LucideIcons.arrowRight,
                          size: 14,
                          color: Color(0xFF0B7A86),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardImage extends StatelessWidget {
  const _CardImage({
    required this.imageUrl,
    required this.fallbackIndex,
    required this.height,
  });
  final String? imageUrl;
  final int fallbackIndex;
  final double height;

  @override
  Widget build(BuildContext context) {
    final fallback = _imageByIndex(fallbackIndex);
    if (imageUrl == null || imageUrl!.isEmpty) {
      return SizedBox(
        height: height,
        width: double.infinity,
        child: Image.asset(fallback, fit: BoxFit.cover),
      );
    }
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CachedNetworkImage(
        imageUrl: imageUrl!,
        width: double.infinity,
        height: height,
        fit: BoxFit.cover,
        placeholder: (_, _) => Container(color: const Color(0xFFEAF1EF)),
        errorWidget: (_, _, _) => Image.asset(fallback, fit: BoxFit.cover),
      ),
    );
  }
}

class _ArticleSkeletonList extends StatelessWidget {
  const _ArticleSkeletonList();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height:
          math.max(
            272.0,
            math.min(318.0, MediaQuery.sizeOf(context).height * 0.34),
          ) +
          ((MediaQuery.textScalerOf(context).scale(1) - 1).clamp(0.0, 1.0) *
              72),
      child: Shimmer.fromColors(
        baseColor: const Color(0xFFE8EEEC),
        highlightColor: const Color(0xFFF7FAF9),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          separatorBuilder: (context, index) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final screenWidth = MediaQuery.sizeOf(context).width;
            return Container(
              width: math.min(220.0, math.max(176.0, screenWidth * 0.66)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ArticleError extends StatelessWidget {
  const _ArticleError({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    return HealthCard(
      child: Column(
        children: [
          const Icon(
            PhosphorIconsRegular.warningCircle,
            size: 32,
            color: SgColors.warning,
          ),
          const SizedBox(height: 8),
          const Text('Gagal memuat artikel edukasi.'),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('Coba Lagi')),
        ],
      ),
    );
  }
}

class _ArticleEmpty extends StatelessWidget {
  const _ArticleEmpty({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    return HealthCard(
      child: Column(
        children: [
          Image.asset(
            'assets/image/onboarding_monitoring.png',
            height: 72,
            fit: BoxFit.cover,
          ),
          const SizedBox(height: 8),
          const Text('Belum ada artikel edukasi tersedia.'),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('Refresh')),
        ],
      ),
    );
  }
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Shimmer.fromColors(
        baseColor: const Color(0xFFE8EEEC),
        highlightColor: const Color(0xFFF7FAF9),
        child: Column(
          children: [
            Container(height: 44, color: Colors.white),
            const SizedBox(height: 12),
            Container(height: 90, color: Colors.white),
            const SizedBox(height: 12),
            Container(height: 180, color: Colors.white),
            const SizedBox(height: 12),
            Container(height: 80, color: Colors.white),
            const SizedBox(height: 12),
            Container(height: 220, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _HomeError extends StatelessWidget {
  const _HomeError({required this.error, required this.onRetry});
  final Object? error;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    final info = dashboardErrorInfo(error);
    return ErrorState(
      title: info.title,
      message: info.message,
      icon: info.icon,
      color: info.color,
      onRetry: onRetry,
    );
  }
}

String _shortStatus(String value) {
  return NutritionStatusHelper.getStatus(
    status: value,
    source: 'main_dashboard_short_status',
  ).label;
}

String _statusDescription(String status) {
  return NutritionStatusHelper.getStatus(
    status: status,
    source: 'main_dashboard_status_description',
  ).recommendation;
}

String _imageByIndex(int index) {
  const images = [
    'assets/image/onboarding_food.png',
    'assets/image/onboarding_monitoring.png',
    'assets/image/onboarding_consultation.png',
  ];
  return images[index % images.length];
}
