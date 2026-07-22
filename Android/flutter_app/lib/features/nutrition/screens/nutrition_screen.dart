import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shimmer/shimmer.dart';

import 'package:s_gizi/app_design.dart';
import 'package:s_gizi/app_state.dart';
import 'package:s_gizi/models/api_result_model.dart';
import 'package:s_gizi/models/mobile_child_model.dart';
import 'package:s_gizi/models/news_article_model.dart';
import 'package:s_gizi/models/riwayat_response_model.dart';
import 'package:s_gizi/services/api_service.dart';
import 'package:s_gizi/services/article_service.dart';
import 'package:s_gizi/utils/nutrition_display_utils.dart';
import 'package:s_gizi/features/articles/screens/article_detail_screen.dart';
import 'package:s_gizi/features/articles/screens/articles_screen.dart';
import 'package:s_gizi/features/nutrition/screens/recommendation_screen.dart';
import 'package:s_gizi/features/history/screens/riwayat_screen.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  final ApiService _apiService = ApiService();
  final ArticleService _articleService = ArticleService();
  final SgiziAppState _appState = SgiziAppState.instance;
  late Future<_NutritionViewData> _future;
  String _activeCategory = 'Semua';
  int _activeAgeIndex = 0;
  int _activeFoodIndex = 0;

  @override
  void initState() {
    super.initState();
    _appState.addListener(_handleStateChanged);
    _future = _load();
  }

  @override
  void dispose() {
    _appState.removeListener(_handleStateChanged);
    super.dispose();
  }

  void _handleStateChanged() {
    setState(() => _future = _load());
  }

  Future<_NutritionViewData> _load() async {
    final child = _appState.activeChild;
    if (child == null) {
      return const _NutritionViewData.noActiveChild();
    }

    final results = await Future.wait([
      _apiService.getRiwayat(childId: child.id),
      _articleService.fetchArticles(forceRefresh: true),
    ]);
    final history = results[0] as RiwayatResponseModel;
    final articles = results[1] as List<NewsArticleModel>;
    final sorted = [...history.riwayat]
      ..sort((a, b) {
        final bDate = DateTime.tryParse(b.tanggalUkur);
        final aDate = DateTime.tryParse(a.tanggalUkur);
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });
    final latest = sorted.isNotEmpty ? sorted.first : null;

    if (latest == null) {
      return _NutritionViewData(
        child: child,
        latestMeasurement: null,
        recommendations: const [],
        articles: articles,
      );
    }

    final recommendationResponse = await _apiService.getRecommendations(
      status: '',
      childId: child.id,
      riwayatId: latest.id,
    );

    return _NutritionViewData(
      child: child,
      latestMeasurement: latest,
      // Preview rekomendasi berdasarkan riwayat TERAKHIR anak aktif.
      recommendations: recommendationResponse.items,
      articles: articles,
    );
  }

  void _retry() {
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _NutriColors.background,
      body: SafeArea(
        child: FutureBuilder<_NutritionViewData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _NutritionSkeleton();
            }

            if (snapshot.hasError) {
              return ErrorState(
                message:
                    'Halaman nutrisi belum bisa dimuat. Periksa koneksi lalu coba lagi.',
                onRetry: _retry,
              );
            }

            final data = snapshot.data!;
            if (data.child == null) {
              return EmptyState(
                title: 'Belum Ada Anak Aktif',
                message:
                    'Pilih anak aktif terlebih dahulu untuk melihat insight nutrisi terbaru.',
                actionLabel: 'Muat Ulang',
                onAction: _retry,
              );
            }

            return RefreshIndicator(
              color: SgColors.primary,
              onRefresh: () async {
                _retry();
                await _future;
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _NutritionHeader(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        SgSpacing.pageH,
                        SgSpacing.section,
                        SgSpacing.pageH,
                        20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _AgeGuideSection(
                            activeIndex: _activeAgeIndex,
                            onPageChanged: (index) =>
                                setState(() => _activeAgeIndex = index),
                          ),
                          const SizedBox(height: 24),
                          _CategoryChipsRow(
                            activeCategory: _activeCategory,
                            onCategorySelected: (label) =>
                                setState(() => _activeCategory = label),
                          ),
                          const SizedBox(height: 16),
                          _ArticleSection(
                            data: data,
                            activeCategory: _activeCategory,
                            onRetry: _retry,
                          ),
                          const SizedBox(height: 24),
                          _LatestStatusSection(data: data),
                          const SizedBox(height: 24),
                          _FoodRecommendationSection(
                            data: data,
                            activeIndex: _activeFoodIndex,
                            onPageChanged: (index) =>
                                setState(() => _activeFoodIndex = index),
                          ),
                        ],
                      ),
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

class _NutritionViewData {
  const _NutritionViewData({
    required this.child,
    required this.latestMeasurement,
    required this.recommendations,
    required this.articles,
  });

  const _NutritionViewData.noActiveChild()
    : child = null,
      latestMeasurement = null,
      recommendations = const [],
      articles = const [];

  final MobileChildModel? child;
  final RiwayatItemModel? latestMeasurement;
  final List<RekomendasiModel> recommendations;
  final List<NewsArticleModel> articles;
}

class _NutritionHeader extends StatelessWidget {
  const _NutritionHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_NutriColors.primaryDark, _NutriColors.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -40,
                top: -20,
                child: _FloatingCircle(
                  size: 160,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              Positioned(
                left: -24,
                bottom: -40,
                child: _FloatingCircle(
                  size: 140,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
              Positioned(
                right: 24,
                top: 26,
                child: Icon(
                  LucideIcons.activity,
                  color: Colors.white.withValues(alpha: 0.5),
                  size: 40,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          Text(
                            'Nutrisi',
                            style: AppTypography.h1.copyWith(
                              color: Colors.white,
                              fontSize: 26,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Panduan nutrisi dan edukasi tumbuh kembang si kecil secara optimal.',
                            style: AppTypography.body.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 500.ms, curve: Curves.easeOut)
        .slideY(begin: -0.1, end: 0, duration: 500.ms, curve: Curves.easeOut);
  }
}

class _FloatingCircle extends StatelessWidget {
  const _FloatingCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _AgeGuideSection extends StatelessWidget {
  const _AgeGuideSection({
    required this.activeIndex,
    required this.onPageChanged,
  });

  final int activeIndex;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Panduan Usia',
                  style: AppTypography.h2.copyWith(color: SgColors.textPrimary),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _NutriColors.secondary.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        PhosphorIconsLight.baby,
                        size: 14,
                        color: _NutriColors.primary,
                      ),
                      SizedBox(width: 6),
                      Text('0–5 Tahun', style: AppTypography.caption),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            CarouselSlider.builder(
              itemCount: _ageGuides.length,
              options: CarouselOptions(
                height: 292,
                viewportFraction: 0.9,
                enlargeCenterPage: true,
                enlargeFactor: 0.16,
                autoPlay: true,
                autoPlayInterval: const Duration(seconds: 6),
                enableInfiniteScroll: true,
                onPageChanged: (index, _) => onPageChanged(index),
              ),
              itemBuilder: (context, index, realIndex) {
                final guide = _ageGuides[index];
                final isActive = index == activeIndex;
                return _AgeGuideCard(guide: guide, isActive: isActive);
              },
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_ageGuides.length, (index) {
                final isActive = index == activeIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  height: 7,
                  width: isActive ? 18 : 7,
                  decoration: BoxDecoration(
                    color: isActive
                        ? _NutriColors.primary
                        : _NutriColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(99),
                  ),
                );
              }),
            ),
          ],
        )
        .animate(delay: 80.ms)
        .fadeIn(duration: 420.ms, curve: Curves.easeOut)
        .slideY(begin: 0.03, end: 0, duration: 420.ms, curve: Curves.easeOut);
  }
}

class _CategoryChipsRow extends StatelessWidget {
  const _CategoryChipsRow({
    required this.activeCategory,
    required this.onCategorySelected,
  });

  final String activeCategory;
  final ValueChanged<String> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kategori Edukasi', style: _sectionLabelStyle()),
            const SizedBox(height: 10),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemBuilder: (_, index) {
                  final label = _nutritionCategories[index];
                  final isActive = label == activeCategory;
                  return _CategoryChip(
                    label: label,
                    isActive: isActive,
                    onTap: () => onCategorySelected(label),
                  );
                },
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemCount: _nutritionCategories.length,
              ),
            ),
          ],
        )
        .animate(delay: 140.ms)
        .fadeIn(duration: 380.ms, curve: Curves.easeOut)
        .slideY(begin: 0.03, end: 0, duration: 380.ms, curve: Curves.easeOut);
  }
}

class _ArticleSection extends StatelessWidget {
  const _ArticleSection({
    required this.data,
    required this.activeCategory,
    required this.onRetry,
  });

  final _NutritionViewData data;
  final String activeCategory;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final articles = data.articles
        .where(
          (a) =>
              activeCategory == 'Semua' ||
              a.category.toLowerCase().contains(activeCategory.toLowerCase()),
        )
        .toList();

    final visible = articles.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Artikel Edukasi', style: _sectionLabelStyle()),
            const SizedBox(width: 8),
            Icon(
              LucideIcons.bookOpenCheck,
              size: 16,
              color: _NutriColors.primary,
            ),
            const Spacer(),
            TextButton(
              onPressed: data.articles.isEmpty
                  ? null
                  : () {
                      Navigator.of(context).push(
                        fadeRoute(
                          ArticlesScreen(
                            title: 'Artikel Edukasi',
                            initialCategory: activeCategory,
                            articles: data.articles,
                          ),
                        ),
                      );
                    },
              child: const Text('Lihat Semua'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (data.articles.isEmpty)
          _SectionEmptyInfo(
            message:
                'Artikel edukasi belum tersedia. Sentuh untuk memuat ulang dari server.',
            actionLabel: 'Muat Ulang',
            onAction: onRetry,
          )
        else if (articles.isEmpty)
          const _SectionEmptyInfo(
            message:
                'Belum ada artikel untuk kategori ini. Coba pilih kategori lain.',
          )
        else
          Column(
            children: visible
                .map(
                  (article) => _ArticleCard(
                    article: article,
                    allArticles: data.articles,
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}

class _LatestStatusSection extends StatelessWidget {
  const _LatestStatusSection({required this.data});

  final _NutritionViewData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Status Gizi Anak', style: _sectionLabelStyle()),
        const SizedBox(height: 12),
        if (data.latestMeasurement == null)
          _SectionEmptyInfo(
            message:
                'Belum ada riwayat pengukuran untuk anak aktif. Tambahkan pengukuran untuk menampilkan status terbaru.',
            actionLabel: 'Buka Riwayat',
            onAction: () {
              Navigator.of(
                context,
              ).push(fadeRoute(RiwayatScreen(childId: data.child!.id)));
            },
          )
        else
          _LatestNutritionStatusCard(
            child: data.child!,
            latest: data.latestMeasurement!,
            onOpenHistory: () => Navigator.of(
              context,
            ).push(fadeRoute(RiwayatScreen(childId: data.child!.id))),
          ),
      ],
    );
  }
}

class _FoodRecommendationSection extends StatelessWidget {
  const _FoodRecommendationSection({
    required this.data,
    required this.activeIndex,
    required this.onPageChanged,
  });

  final _NutritionViewData data;
  final int activeIndex;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    // Preview max 3, berasal dari rekomendasi untuk riwayat TERAKHIR anak aktif.
    final items = data.recommendations.take(3).toList();

    return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Rekomendasi Untuk Anak',
                    style: AppTypography.h2.copyWith(
                      color: SgColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      fadeRoute(
                        RecommendationScreen(
                          childId: data.child!.id,
                          riwayatId: data.latestMeasurement?.id,
                          childName: data.child!.nama,
                          status: data.latestMeasurement?.statusGabungan,
                          measuredAt: data.latestMeasurement?.tanggalUkur,
                        ),
                      ),
                    );
                  },
                  child: const Text('Lihat Semua'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Menu sesuai status gizi terbaru anak.',
              style: AppTypography.body,
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              const _SectionEmptyInfo(
                message:
                    'Preview rekomendasi belum tersedia. Silakan lengkapi pengukuran terbaru.',
              )
            else
              Column(
                children: [
                  CarouselSlider.builder(
                    itemCount: items.length,
                    options: CarouselOptions(
                      height: 364,
                      viewportFraction: 0.9,
                      enlargeCenterPage: true,
                      enlargeFactor: 0.18,
                      autoPlay: true,
                      autoPlayInterval: const Duration(seconds: 7),
                      enableInfiniteScroll: items.length > 1,
                      onPageChanged: (index, _) => onPageChanged(index),
                    ),
                    itemBuilder: (context, index, realIndex) {
                      final item = items[index];
                      return _FoodPreviewCard(
                        item: item,
                        fallbackAssetImage: _foodAssetByIndex(index),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(items.length, (index) {
                      final isActive = index == activeIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        height: 7,
                        width: isActive ? 18 : 7,
                        decoration: BoxDecoration(
                          color: isActive
                              ? _NutriColors.primary
                              : _NutriColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      );
                    }),
                  ),
                ],
              ),
          ],
        )
        .animate(delay: 220.ms)
        .fadeIn(duration: 420.ms, curve: Curves.easeOut)
        .slideY(begin: 0.03, end: 0, duration: 420.ms, curve: Curves.easeOut);
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? _NutriColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isActive ? _NutriColors.primary : SgColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              color: isActive ? Colors.white : SgColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _AgeGuideCard extends StatelessWidget {
  const _AgeGuideCard({required this.guide, required this.isActive});

  final _AgeGuide guide;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SgColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isActive ? 0.10 : 0.05),
            blurRadius: isActive ? 30 : 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _NutriColors.secondary.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(guide.icon, color: _NutriColors.primary, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      guide.title,
                      style: AppTypography.h3.copyWith(
                        color: SgColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _InfoRow(label: 'Fokus', value: guide.focus),
          _InfoRow(label: 'Makanan dianjurkan', value: guide.foodSuggestion),
          _InfoRow(label: 'Tips singkat', value: guide.tip),
        ],
      ),
    );

    return card
        .animate(target: isActive ? 1 : 0)
        .scale(
          begin: const Offset(0.96, 0.96),
          end: const Offset(1, 1),
          duration: 260.ms,
          curve: Curves.easeOut,
        );
  }
}

const List<String> _nutritionCategories = [
  'Semua',
  'Gizi',
  'MPASI',
  'Stunting',
  'Tumbuh Kembang',
  'Protein',
  'Vitamin',
];

class _LatestNutritionStatusCard extends StatelessWidget {
  const _LatestNutritionStatusCard({
    required this.child,
    required this.latest,
    required this.onOpenHistory,
  });

  final MobileChildModel child;
  final RiwayatItemModel latest;
  final VoidCallback onOpenHistory;

  @override
  Widget build(BuildContext context) {
    final visual = nutritionStatusVisual(latest.statusGabungan);
    return HealthCard(
          color: const Color(0xFFEAF7F7),
          borderColor: const Color(0xFFCBEAEA),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                child.nama,
                style: AppTypography.h2,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      latest.statusGabungan,
                      style: AppTypography.h3,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: StatusBadge(
                      text: visual.badgeLabel,
                      color: visual.color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Pengukuran: ${formatMeasurementDate(latest.tanggalUkur)}',
                style: AppTypography.caption,
              ),
              const SizedBox(height: 12),
              Text(
                recommendationStatusExplanation(latest.statusGabungan),
                style: AppTypography.body.copyWith(color: SgColors.textPrimary),
              ),
              const SizedBox(height: 12),
              Text(
                'Saran: ${_suggestionForStatus(latest.statusGabungan)}',
                style: AppTypography.body,
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Lihat Riwayat Lengkap',
                icon: Icons.timeline_rounded,
                onPressed: onOpenHistory,
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 420.ms, curve: Curves.easeOut)
        .slideY(begin: 0.02, end: 0, duration: 420.ms, curve: Curves.easeOut);
  }
}

class _FoodPreviewCard extends StatelessWidget {
  const _FoodPreviewCard({
    required this.item,
    required this.fallbackAssetImage,
  });

  final RekomendasiModel item;
  final String fallbackAssetImage;

  @override
  Widget build(BuildContext context) {
    return HealthCard(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _FoodImage(
                    imageUrl: item.thumbnail,
                    fallbackAssetImage: fallbackAssetImage,
                  ),
                  Positioned(
                    left: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.42),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${item.kalori} kkal',
                        style: AppTypography.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.menu,
                  style: AppTypography.h3,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text('${item.protein}g protein', style: AppTypography.caption),
                const SizedBox(height: 10),
                Text(
                  'Mengapa cocok? ${item.alasan}',
                  style: AppTypography.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodImage extends StatelessWidget {
  const _FoodImage({required this.imageUrl, required this.fallbackAssetImage});

  final String? imageUrl;
  final String fallbackAssetImage;

  @override
  Widget build(BuildContext context) {
    final url = _resolveMediaUrl(imageUrl);
    if (url == null) {
      return Image.asset(fallbackAssetImage, fit: BoxFit.cover);
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) =>
          Image.asset(fallbackAssetImage, fit: BoxFit.cover),
    );
  }
}

class _SectionEmptyInfo extends StatelessWidget {
  const _SectionEmptyInfo({
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return HealthCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: AppTypography.body),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            PrimaryButton(
              label: actionLabel!,
              onPressed: onAction,
              isOutlined: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(label, style: AppTypography.caption),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: AppTypography.body.copyWith(color: SgColors.textPrimary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _NutritionSkeleton extends StatelessWidget {
  const _NutritionSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE3EBE8),
      highlightColor: const Color(0xFFF3F7F5),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          Container(
            width: double.infinity,
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          const SizedBox(height: 20),
          Container(width: 130, height: 18, color: Colors.white),
          const SizedBox(height: 12),
          SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) => Container(
                width: 260,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemCount: 3,
            ),
          ),
          const SizedBox(height: 24),
          for (var i = 0; i < 3; i++) ...[
            HealthCard(
              child: Container(
                height: 86,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  const _ArticleCard({required this.article, required this.allArticles});

  final NewsArticleModel article;
  final List<NewsArticleModel> allArticles;

  @override
  Widget build(BuildContext context) {
    return HealthCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      onTap: () {
        Navigator.of(context).push(
          fadeRoute(
            ArticleDetailScreen(article: article, related: allArticles),
          ),
        );
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Hero(
            tag: 'article-${article.id}',
            child: ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(20),
              ),
              child: SizedBox(
                width: 104,
                height: 96,
                child: _ArticleThumbImage(
                  imageUrl: article.image,
                  fallbackAsset: _articleAssetByIndex(article.id),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _NutriColors.secondary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          article.category,
                          style: AppTypography.caption.copyWith(
                            color: _NutriColors.primaryDark,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    article.title,
                    style: AppTypography.h3.copyWith(
                      color: SgColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    article.description,
                    style: AppTypography.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Baca Selengkapnya',
                    style: AppTypography.caption.copyWith(
                      color: _NutriColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArticleThumbImage extends StatelessWidget {
  const _ArticleThumbImage({
    required this.imageUrl,
    required this.fallbackAsset,
  });

  final String? imageUrl;
  final String fallbackAsset;

  @override
  Widget build(BuildContext context) {
    final resolved = _resolveMediaUrl(imageUrl);
    if (resolved == null) {
      return Image.asset(fallbackAsset, fit: BoxFit.cover);
    }
    return Image.network(
      resolved,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Image.asset(fallbackAsset, fit: BoxFit.cover),
    );
  }
}

class _AgeGuide {
  const _AgeGuide({
    required this.title,
    required this.focus,
    required this.foodSuggestion,
    required this.tip,
    required this.icon,
  });

  final String title;
  final String focus;
  final String foodSuggestion;
  final String tip;
  final IconData icon;
}

const List<_AgeGuide> _ageGuides = [
  _AgeGuide(
    title: 'Usia 0-6 Bulan',
    focus: 'ASI eksklusif sesuai kebutuhan bayi.',
    foodSuggestion: 'ASI sebagai sumber nutrisi utama.',
    tip: 'Susui lebih sering saat bayi menunjukkan tanda lapar.',
    icon: Icons.child_friendly_rounded,
  ),
  _AgeGuide(
    title: 'Usia 6-12 Bulan',
    focus: 'MPASI bertahap dengan tekstur meningkat.',
    foodSuggestion: 'Bubur tim, pure sayur, telur, ikan lembut.',
    tip: 'Kenalkan tekstur dari halus ke kasar secara bertahap.',
    icon: Icons.soup_kitchen_rounded,
  ),
  _AgeGuide(
    title: 'Usia 1-3 Tahun',
    focus: 'Variasi makanan dengan protein cukup.',
    foodSuggestion: 'Nasi, lauk hewani, sayur, buah, susu.',
    tip: 'Biasakan jam makan teratur dan camilan sehat.',
    icon: Icons.set_meal_rounded,
  ),
  _AgeGuide(
    title: 'Usia 3-5 Tahun',
    focus: 'Dukung pertumbuhan tinggi badan dan daya tahan tubuh.',
    foodSuggestion: 'Ikan, ayam, telur, tempe, sayur hijau, buah.',
    tip: 'Tambahkan protein hewani dan ajak anak aktif bergerak.',
    icon: Icons.directions_run_rounded,
  ),
];

String _suggestionForStatus(String status) {
  final value = status.toLowerCase();
  if (value.contains('stunting')) {
    return 'Tambahkan protein hewani dan pantau tinggi badan rutin.';
  }
  if (value.contains('kurang') || value.contains('underweight')) {
    return 'Tingkatkan porsi energi-protein, termasuk camilan bergizi.';
  }
  if (value.contains('obesitas') || value.contains('lebih')) {
    return 'Atur porsi seimbang, kurangi gula tambahan, dan tingkatkan aktivitas fisik.';
  }
  return 'Pertahankan pola makan gizi seimbang dan pemantauan berkala.';
}

TextStyle _sectionLabelStyle() {
  return AppTypography.caption.copyWith(
    letterSpacing: 1,
    fontWeight: FontWeight.w800,
    color: _NutriColors.primaryDark,
  );
}

class _NutriColors {
  const _NutriColors._();

  static const primary = Color(0xFF0B7A86);
  static const primaryDark = Color(0xFF085B63);
  static const secondary = Color(0xFF7FD6C2);
  static const background = Color(0xFFF5F7F6);
}

String _foodAssetByIndex(int index) {
  const assets = [
    'assets/image/onboarding_food.png',
    'assets/image/onboarding_monitoring.png',
    'assets/image/onboarding_consultation.png',
  ];
  return assets[index % assets.length];
}

String _articleAssetByIndex(int index) {
  const assets = [
    'assets/image/onboarding_food.png',
    'assets/image/onboarding_monitoring.png',
    'assets/image/onboarding_consultation.png',
  ];
  return assets[index % assets.length];
}

String? _resolveMediaUrl(String? raw) {
  final value = raw?.trim() ?? '';
  if (value.isEmpty) return null;
  if (value.startsWith('http://') || value.startsWith('https://')) {
    return value;
  }

  final baseUri = Uri.tryParse(ApiService().baseUrl);
  if (baseUri == null) return value;
  final root = baseUri.replace(path: '', query: '', fragment: '').toString();
  final normalizedRoot = root.endsWith('/') ? root : '$root/';
  final path = value.startsWith('/') ? value.substring(1) : value;
  return '$normalizedRoot$path';
}
