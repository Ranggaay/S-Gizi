import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../app_design.dart';
import '../app_state.dart';
import '../models/mobile_child_model.dart';
import '../models/news_article_model.dart';
import '../models/riwayat_response_model.dart';
import '../services/api_service.dart';
import '../utils/nutrition_display_utils.dart';
import 'article_detail_screen.dart';
import 'children_screen.dart';
import 'consultation_chat_screen.dart';
import 'input_screen.dart';
import 'recommendation_screen.dart';
import 'riwayat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onChangeTab});
  final ValueChanged<int> onChangeTab;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  final SgiziAppState _appState = SgiziAppState.instance;
  late Future<_HomeDashboardData> _future;
  late Future<List<NewsArticleModel>> _articlesFuture;

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
    final history = await _apiService.getRiwayat(childId: child.id);
    return _HomeDashboardData(child: child, history: history);
  }

  Future<List<NewsArticleModel>> _loadArticles() async {
    // Dashboard artikel: gabungan DB admin + online (Google News).
    final db = await _apiService.getArticlesDb().catchError((_) => <NewsArticleModel>[]);
    final news = await _apiService.getNewsArticles().catchError((_) => <NewsArticleModel>[]);

    final merged = <NewsArticleModel>[];
    final seen = <String>{};

    void addAll(List<NewsArticleModel> items) {
      for (final a in items) {
        final key = '${a.title}__${a.category}'.toLowerCase().trim();
        if (key.isEmpty || seen.contains(key)) continue;
        seen.add(key);
        merged.add(a);
      }
    }

    // Prioritaskan artikel dari DB admin, lalu tambah dari online.
    addAll(db);
    addAll(news);
    return merged;
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
              return _HomeError(onRetry: _retry);
            }
            final data = snapshot.data!;
            final child = data.child;
            final latest = data.latestMeasurement;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _TopBar(),
                  const SizedBox(height: 12),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFE2E8E6),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Halo, Bunda 👋',
                    style: AppTypography.h1.copyWith(fontSize: 34),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Ayo pantau tumbuh kembang si kecil hari ini.',
                    style: AppTypography.body,
                  ),
                  const SizedBox(height: 16),
                  _ActiveChildCard(
                    child: child,
                    onTap: () =>
                        Navigator.of(context).push(fadeRoute(const ChildrenScreen())),
                  ),
                  const SizedBox(height: 16),
                  if (child == null)
                    EmptyState(
                      title: 'Belum Ada Data Anak',
                      message: 'Tambahkan data anak agar dashboard aktif.',
                      actionLabel: 'Tambah Data Anak',
                      onAction: () =>
                          Navigator.of(context).push(fadeRoute(const ChildrenScreen())),
                    )
                  else
                    _ModernStatusCard(
                      latest: latest,
                      onOpen: () => Navigator.of(context).push(
                        fadeRoute(RiwayatScreen(childId: child.id)),
                      ),
                    ),
                  const SizedBox(height: 22),
                  Text(
                    'Menu Utama',
                    style: GoogleFonts.montserrat(
                      fontSize: 27,
                      fontWeight: FontWeight.w700,
                      color: SgColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _MainMenuRow(
                    onTapInput: () =>
                        Navigator.of(context).push(fadeRoute(const InputScreen())),
                    onTapRecommendation: latest == null
                        ? null
                        : () => Navigator.of(context).push(
                              fadeRoute(
                                RecommendationScreen(
                                  childId: child?.id,
                                  riwayatId: latest?.id,
                                  childName: child?.nama,
                                  status: latest?.statusGabungan,
                                  measuredAt: latest?.tanggalUkur,
                                ),
                              ),
                            ),
                    onTapConsultation: () => Navigator.of(context).push(
                      fadeRoute(const ConsultationChatScreen()),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Edukasi Si Kecil',
                          style: GoogleFonts.montserrat(
                            fontSize: 27,
                            fontWeight: FontWeight.w700,
                            color: SgColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(
                        onPressed: () => widget.onChangeTab(1),
                        child: const Text('Lihat Semua'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  FutureBuilder<List<NewsArticleModel>>(
                    future: _articlesFuture,
                    builder: (context, articleSnapshot) {
                      if (articleSnapshot.connectionState == ConnectionState.waiting) {
                        return const _ArticleSkeletonList();
                      }
                      if (articleSnapshot.hasError) {
                        return _ArticleError(onRetry: _retry);
                      }
                      final articles = articleSnapshot.data ?? const [];
                      if (articles.isEmpty) {
                        return _ArticleEmpty(onRetry: _retry);
                      }
                      return SizedBox(
                        height: 280,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: articles.length > 8 ? 8 : articles.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
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
  });

  final MobileChildModel? child;
  final RiwayatResponseModel? history;

  RiwayatItemModel? get latestMeasurement {
    final records = history?.riwayat;
    if (records == null || records.isEmpty) return null;
    return records.first;
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();
  @override
  Widget build(BuildContext context) {
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
        Stack(
          children: [
            const CircleAvatar(
              radius: 22,
              backgroundImage: AssetImage('assets/image/onboarding_consultation.png'),
            ),
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
        ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(
          begin: 0,
          end: -2,
          duration: 1800.ms,
        ),
      ],
    );
  }
}

class _ActiveChildCard extends StatelessWidget {
  const _ActiveChildCard({required this.child, required this.onTap});
  final MobileChildModel? child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HealthCard(
      onTap: onTap,
      child: Row(
        children: [
          ChildAvatar(
            name: child?.nama ?? 'Anak',
            gender: child?.jenisKelamin ?? 'L',
            photoUrl: child?.photoUrl,
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
                const SizedBox(height: 4),
                Text(
                  child == null ? '-' : formatAgeFromBirthDate(child!.tanggalLahir),
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
  const _ModernStatusCard({required this.latest, required this.onOpen});
  final RiwayatItemModel? latest;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    if (latest == null) {
      return HealthCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('STATUS GIZI TERAKHIR'),
            const SizedBox(height: 8),
            const Text('Belum ada pengukuran tersimpan untuk anak aktif.'),
            const SizedBox(height: 14),
            PrimaryButton(label: 'Lihat Detail Analisis', onPressed: onOpen),
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
              Expanded(child: _SmallMetric(label: 'Berat', value: '${latest!.berat.toStringAsFixed(1)} kg')),
              const SizedBox(width: 8),
              Expanded(child: _SmallMetric(label: 'Tinggi', value: '${latest!.tinggi.toStringAsFixed(1)} cm')),
              const SizedBox(width: 8),
              Expanded(child: _SmallMetric(label: 'Usia', value: formatAgeFromMonths(latest!.umurBulan))),
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
          Text(label, style: AppTypography.caption, overflow: TextOverflow.ellipsis),
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
    return SizedBox(
      width: 250,
      child: HealthCard(
        padding: EdgeInsets.zero,
        onTap: () => Navigator.of(context).push(
          fadeRoute(ArticleDetailScreen(article: article, related: related)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Hero(
                tag: 'article-${article.id}',
                child: _CardImage(
                  imageUrl: article.image,
                  fallbackIndex: index,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: StatusBadge(
                text: article.category,
                color: const Color(0xFF0B7A86),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.h3,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    article.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body,
                  ),
                  if (article.sourceName != null &&
                      article.sourceName!.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
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
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Baca Selengkapnya',
                        style: AppTypography.caption.copyWith(
                          color: const Color(0xFF0B7A86),
                          fontWeight: FontWeight.w700,
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
          ],
        ),
      ),
    );
  }
}

class _CardImage extends StatelessWidget {
  const _CardImage({required this.imageUrl, required this.fallbackIndex});
  final String? imageUrl;
  final int fallbackIndex;

  @override
  Widget build(BuildContext context) {
    final fallback = _imageByIndex(fallbackIndex);
    if (imageUrl == null || imageUrl!.isEmpty) {
      return Image.asset(
        fallback,
        width: double.infinity,
        height: 110,
        fit: BoxFit.cover,
      );
    }
    return CachedNetworkImage(
      imageUrl: imageUrl!,
      width: double.infinity,
      height: 110,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(color: const Color(0xFFEAF1EF)),
      errorWidget: (_, __, ___) => Image.asset(
        fallback,
        width: double.infinity,
        height: 110,
        fit: BoxFit.cover,
      ),
    );
  }
}

class _ArticleSkeletonList extends StatelessWidget {
  const _ArticleSkeletonList();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      child: Shimmer.fromColors(
        baseColor: const Color(0xFFE8EEEC),
        highlightColor: const Color(0xFFF7FAF9),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, __) => Container(
            width: 250,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
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
          Image.asset('assets/image/onboarding_monitoring.png', height: 72, fit: BoxFit.cover),
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
  const _HomeError({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    return ErrorState(
      message: 'Dashboard belum dapat dimuat.',
      onRetry: onRetry,
    );
  }
}

String _shortStatus(String value) {
  final lower = value.toLowerCase();
  if (lower.contains('normal')) return 'Baik';
  if (lower.contains('stunting') || lower.contains('kurang')) return 'Perlu Perhatian';
  return value;
}

String _statusDescription(String status) {
  final value = status.toLowerCase();
  if (value.contains('stunting')) {
    return 'Tinggi badan anak masih perlu perhatian. Fokus pada protein hewani, zat besi, dan pemantauan tinggi rutin.';
  }
  if (value.contains('kurang') || value.contains('underweight')) {
    return 'Berat badan anak perlu ditingkatkan. Tambahkan asupan energi dan protein secara bertahap.';
  }
  if (value.contains('obesitas') || value.contains('lebih')) {
    return 'Berat badan perlu dikontrol. Atur porsi seimbang dan perbanyak aktivitas fisik harian anak.';
  }
  return 'Berdasarkan pengukuran terakhir, tinggi dan berat badan anak sudah sesuai standar WHO.';
}

String _imageByIndex(int index) {
  const images = [
    'assets/image/onboarding_food.png',
    'assets/image/onboarding_monitoring.png',
    'assets/image/onboarding_consultation.png',
  ];
  return images[index % images.length];
}
