import 'package:flutter/material.dart';

import 'package:s_gizi/app_design.dart';
import 'package:s_gizi/models/riwayat_response_model.dart';
import 'package:s_gizi/utils/nutrition_display_utils.dart';
import 'package:s_gizi/features/consultation/screens/consultation_chat_screen.dart';
import 'package:s_gizi/features/nutrition/screens/recommendation_screen.dart';

class RiwayatDetailScreen extends StatelessWidget {
  const RiwayatDetailScreen({
    super.key,
    required this.child,
    required this.item,
  });

  final ChildInfoModel child;
  final RiwayatItemModel item;

  @override
  Widget build(BuildContext context) {
    final visual = nutritionStatusVisual(item.statusGabungan);
    final bbuCategory = bbuCategoryFromScore(
      item.zBbu,
      fallback: item.kategori.bbu,
    );
    final tbuCategory = tbuCategoryFromScore(
      item.zTbu,
      fallback: item.kategori.tbu,
    );
    final bbtbCategory = bbtbCategoryFromScore(
      item.zBbtb,
      fallback: item.kategori.bbtb,
    );

    return Scaffold(
      backgroundColor: SgColors.background,
      appBar: AppBar(title: const Text('Detail Analisis')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 160),
        children: [
          HealthCard(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'STATUS UTAMA',
                  style: AppTypography.caption.copyWith(
                    color: SgColors.primary,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: visual.color.withValues(alpha: 0.14),
                      child: Icon(visual.icon, color: visual.color, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status Gizi: ${localizeNutritionStatus(item.statusGabungan)}',
                            style: AppTypography.h2,
                          ),
                          const SizedBox(height: 10),
                          StatusBadge(
                            text: visual.badgeLabel,
                            color: visual.color,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Divider(height: 1, color: SgColors.border),
                const SizedBox(height: 18),
                Row(
                  children: [
                    ChildAvatar(
                      name: child.nama,
                      gender: child.jenisKelamin,
                      radius: 28,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            child.nama,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.h3,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatAgeAtMeasurement(
                              birthDate: child.tanggalLahir,
                              measurementDate: item.tanggalUkur,
                              source: 'riwayat_detail_header',
                            ),
                            style: AppTypography.caption,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            formatMeasurementDate(item.tanggalUkur),
                            style: AppTypography.caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Data Pengukuran',
            child: Column(
              children: [
                _InfoRow(
                  label: 'Berat',
                  value: '${item.berat.toStringAsFixed(1)} kg',
                ),
                _InfoRow(
                  label: 'Tinggi',
                  value: '${item.tinggi.toStringAsFixed(1)} cm',
                ),
                _InfoRow(
                  label: 'Cara',
                  value: measurementMethodLabel(item.caraUkur, item.umurBulan),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Detail Z-Score',
            child: Column(
              children: [
                _ScoreRow(
                  label: 'BB/U',
                  score: formatScore(item.zBbu),
                  category: bbuCategory,
                ),
                _ScoreRow(
                  label: 'TB/U',
                  score: formatScore(item.zTbu),
                  category: tbuCategory,
                ),
                _ScoreRow(
                  label: 'BB/TB',
                  score: formatScore(item.zBbtb),
                  category: bbtbCategory,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Interpretasi',
            child: Text(
              buildInterpretation(
                status: item.statusGabungan,
                bbuCategory: bbuCategory,
                tbuCategory: tbuCategory,
                bbtbCategory: bbtbCategory,
              ),
              style: AppTypography.body.copyWith(color: SgColors.textPrimary),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.96),
          border: const Border(top: BorderSide(color: SgColors.border)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PrimaryButton(
                label: 'Lihat Rekomendasi',
                icon: Icons.restaurant_menu_rounded,
                onPressed: () {
                  Navigator.of(context).push(
                    fadeRoute(
                      RecommendationScreen(
                        status: item.statusGabungan,
                        childId: child.id,
                        riwayatId: item.id,
                        childName: child.nama,
                        measuredAt: item.tanggalUkur,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Konsultasi',
                icon: Icons.chat_bubble_outline_rounded,
                isOutlined: true,
                onPressed: () {
                  Navigator.of(
                    context,
                  ).push(fadeRoute(const ConsultationChatScreen()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return HealthCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: AppTypography.h3),
          const SizedBox(height: 16),
          child,
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(width: 72, child: Text(label, style: AppTypography.body)),
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.h3,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({
    required this.label,
    required this.score,
    required this.category,
  });

  final String label;
  final String score;
  final String category;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          SizedBox(width: 64, child: Text(label, style: AppTypography.body)),
          Expanded(
            child: Text(
              '$score → ${localizeNutritionStatus(category)}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.h3,
            ),
          ),
        ],
      ),
    );
  }
}
