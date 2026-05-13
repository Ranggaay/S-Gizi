import 'package:flutter/material.dart';

import '../app_design.dart';
import '../models/api_result_model.dart';
import '../models/recommendation_response_model.dart';
import '../services/api_service.dart';
import '../utils/nutrition_display_utils.dart';

class RecommendationScreen extends StatefulWidget {
  const RecommendationScreen({
    super.key,
    this.status,
    this.childId,
    this.riwayatId,
    this.childName,
    this.measuredAt,
  });

  final String? status;
  final int? childId;
  final int? riwayatId;
  final String? childName;
  final String? measuredAt;

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  final ApiService _apiService = ApiService();
  late Future<_RecommendationViewData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_RecommendationViewData> _load() async {
    final requestedStatus = widget.status?.trim() ?? '';
    if (requestedStatus.isEmpty &&
        widget.childId == null &&
        widget.riwayatId == null) {
      return _RecommendationViewData.empty(
        childName: widget.childName,
        measuredAt: widget.measuredAt,
      );
    }

    final response = await _apiService.getRecommendations(
      status: requestedStatus,
      childId: widget.childId,
      riwayatId: widget.riwayatId,
    );

    return _RecommendationViewData.fromResponse(
      response,
      fallbackChildName: widget.childName,
      fallbackMeasuredAt: widget.measuredAt,
    );
  }

  void _retry() {
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SgColors.background,
      appBar: AppBar(
        title: const Row(
          children: [
            AppLogo(size: 38),
            SizedBox(width: 12),
            Expanded(child: Text('Rekomendasi Makanan')),
          ],
        ),
      ),
      body: FutureBuilder<_RecommendationViewData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _RecommendationSkeleton();
          }

          if (snapshot.hasError) {
            return ErrorState(
              message:
                  'Rekomendasi makanan belum dapat dimuat. Coba lagi dalam beberapa saat.',
              onRetry: _retry,
            );
          }

          final data = snapshot.data!;
          final normalized = normalizeStatus(data.status ?? 'Normal');
          final visual = nutritionStatusVisual(data.status ?? 'Normal');

          if ((data.status == null || data.status!.isEmpty) &&
              data.items.isEmpty) {
            return EmptyState(
              title: 'Belum Ada Pengukuran',
              message:
                  'Tambahkan pengukuran terbaru agar rekomendasi makanan bisa disesuaikan dengan status gizi terakhir.',
              actionLabel: 'Muat Ulang',
              onAction: _retry,
            );
          }

          if (data.items.isEmpty) {
            return EmptyState(
              title: 'Rekomendasi Belum Tersedia',
              message:
                  'Belum ada menu yang terhubung ke status ${data.status}. Tambahkan data makanan di server lalu coba lagi.',
              actionLabel: 'Muat Ulang',
              onAction: _retry,
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
            children: [
              HealthCard(
                color: const Color(0xFFEAF7F7),
                borderColor: const Color(0xFFCBEAEA),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STATUS TERAKHIR',
                      style: AppTypography.caption.copyWith(
                        color: SgColors.primary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      data.status ?? '-',
                      style: AppTypography.h2,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        StatusBadge(
                          text: normalized.primaryCategory,
                          color: visual.color,
                        ),
                        ...normalized.categories
                            .where((category) => category != normalized.primaryCategory)
                            .map(
                              (category) => StatusBadge(
                                text: category,
                                color: SgColors.primaryDark,
                              ),
                            ),
                      ],
                    ),
                    if (data.measuredAt != null && data.measuredAt!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Tanggal Pengukuran: ${formatMeasurementDate(data.measuredAt!)}',
                        style: AppTypography.body.copyWith(
                          color: SgColors.textPrimary,
                        ),
                      ),
                    ],
                    if (data.childName != null && data.childName!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Nama Anak: ${data.childName!}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body.copyWith(
                          color: SgColors.textPrimary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      recommendationStatusExplanation(data.status ?? 'Normal'),
                      style: AppTypography.body,
                    ),
                    const SizedBox(height: 8),
                    Text(normalized.focusSummary, style: AppTypography.body),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'MENAMPILKAN ${data.items.length} MENU',
                style: AppTypography.caption.copyWith(
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 20),
              ...data.items.asMap().entries.map(
                (entry) => _FoodCard(
                  item: entry.value,
                  imageUrl: _imageForStatus(data.status ?? 'Normal', entry.key),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RecommendationViewData {
  const _RecommendationViewData({
    required this.items,
    required this.status,
    required this.childName,
    required this.measuredAt,
  });

  factory _RecommendationViewData.fromResponse(
    RecommendationResponseModel response, {
    String? fallbackChildName,
    String? fallbackMeasuredAt,
  }) {
    return _RecommendationViewData(
      items: response.items,
      status: response.resolvedStatus,
      childName:
          (response.measurement?.childName.trim().isNotEmpty ?? false)
          ? response.measurement?.childName
          : fallbackChildName,
      measuredAt: response.measurement?.tanggalUkur ?? fallbackMeasuredAt,
    );
  }

  factory _RecommendationViewData.empty({
    String? childName,
    String? measuredAt,
  }) {
    return _RecommendationViewData(
      items: const [],
      status: null,
      childName: childName,
      measuredAt: measuredAt,
    );
  }

  final List<RekomendasiModel> items;
  final String? status;
  final String? childName;
  final String? measuredAt;
}

class _FoodCard extends StatelessWidget {
  const _FoodCard({required this.item, required this.imageUrl});

  final RekomendasiModel item;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return HealthCard(
      margin: const EdgeInsets.only(bottom: 20),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: AspectRatio(
              aspectRatio: 16 / 8,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFFDDEFE8),
                      child: const Icon(
                        Icons.restaurant_rounded,
                        size: 44,
                        color: SgColors.primary,
                      ),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.05),
                          Colors.black.withValues(alpha: 0.46),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    top: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.42),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${item.kalori} KKAL',
                        style: AppTypography.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Text(
                      item.menu,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.h2.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    _NutrientChip(
                      icon: Icons.local_fire_department_outlined,
                      label: '${item.kalori} kkal',
                    ),
                    _NutrientChip(
                      icon: Icons.egg_alt_outlined,
                      label: '${item.protein} g protein',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF9F8),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFD8F0ED)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(top: 5),
                        decoration: const BoxDecoration(
                          color: SgColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MENGAPA COCOK?',
                              style: AppTypography.caption.copyWith(
                                color: SgColors.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(item.alasan, style: AppTypography.body),
                          ],
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
    );
  }
}

class _NutrientChip extends StatelessWidget {
  const _NutrientChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAF9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SgColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: SgColors.primaryDark),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                color: SgColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationSkeleton extends StatelessWidget {
  const _RecommendationSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        HealthCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 180, height: 12, color: const Color(0xFFE9EEEC)),
              const SizedBox(height: 12),
              Container(width: 140, height: 28, color: const Color(0xFFE9EEEC)),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                height: 12,
                color: const Color(0xFFE9EEEC),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        for (var i = 0; i < 2; i++) ...[
          HealthCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                Container(height: 140, color: const Color(0xFFE9EEEC)),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        height: 12,
                        color: const Color(0xFFE9EEEC),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: 180,
                        height: 12,
                        color: const Color(0xFFE9EEEC),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

String _imageForStatus(String status, int index) {
  final normalized = normalizeStatus(status);
  if (normalized.hasStunting) {
    return _stuntingImages[index % _stuntingImages.length];
  }
  if (normalized.hasUnderweight || normalized.hasWasting) {
    return _underweightImages[index % _underweightImages.length];
  }
  if (normalized.hasObesitas) {
    return _balancedImages[index % _balancedImages.length];
  }
  return _normalImages[index % _normalImages.length];
}

const _stuntingImages = [
  'https://images.unsplash.com/photo-1515003197210-e0cd71810b5f?auto=format&fit=crop&w=900&q=80',
  'https://images.unsplash.com/photo-1490645935967-10de6ba17061?auto=format&fit=crop&w=900&q=80',
  'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&w=900&q=80',
];

const _underweightImages = [
  'https://images.unsplash.com/photo-1511690743698-d9d85f2fbf38?auto=format&fit=crop&w=900&q=80',
  'https://images.unsplash.com/photo-1467003909585-2f8a72700288?auto=format&fit=crop&w=900&q=80',
  'https://images.unsplash.com/photo-1482049016688-2d3e1b311543?auto=format&fit=crop&w=900&q=80',
];

const _balancedImages = [
  'https://images.unsplash.com/photo-1498837167922-ddd27525d352?auto=format&fit=crop&w=900&q=80',
  'https://images.unsplash.com/photo-1547592180-85f173990554?auto=format&fit=crop&w=900&q=80',
  'https://images.unsplash.com/photo-1490645935967-10de6ba17061?auto=format&fit=crop&w=900&q=80',
];

const _normalImages = [
  'https://images.unsplash.com/photo-1547592166-23ac45744acd?auto=format&fit=crop&w=900&q=80',
  'https://images.unsplash.com/photo-1505253716362-afaea1d3d1af?auto=format&fit=crop&w=900&q=80',
  'https://images.unsplash.com/photo-1512058564366-18510be2db19?auto=format&fit=crop&w=900&q=80',
];
