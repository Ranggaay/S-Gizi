import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:s_gizi/app_design.dart';
import 'package:s_gizi/models/mobile_child_model.dart';
import 'package:s_gizi/models/riwayat_response_model.dart';
import 'package:s_gizi/utils/nutrition_display_utils.dart';
import 'growth_trend_indicator.dart';
import 'mini_growth_preview.dart';
import 'nutrition_status_badges.dart';
import 'tap_scale_card.dart';

/// Card overview anak untuk dashboard keluarga (vertical list).
class FamilyChildOverviewCard extends StatelessWidget {
  const FamilyChildOverviewCard({
    super.key,
    required this.child,
    required this.latest,
    required this.history,
    required this.onTap,
    this.index = 0,
  });

  final MobileChildModel child;
  final RiwayatItemModel? latest;
  final List<RiwayatItemModel> history;
  final VoidCallback onTap;
  final int index;

  @override
  Widget build(BuildContext context) {
    final statusRaw =
        latest?.statusGabungan ?? child.latestStatus ?? 'Belum diukur';
    final measuredAt = latest?.tanggalUkur ?? child.latestMeasurementAt;
    final lastChecked = formatRelativeLastChecked(measuredAt);
    final measuredLabel = measuredAt != null && measuredAt.isNotEmpty
        ? formatMeasurementDate(measuredAt)
        : '-';
    final trend = growthTrendFromHistory(history);
    final insight = friendlyDashboardSummary(statusRaw);

    return TapScaleCard(
          onTap: onTap,
          borderRadius: 16,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE1E8E6)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                              style: AppTypography.h3,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              formatAgeFromBirthDate(
                                child.tanggalLahir,
                                source: 'family_overview_child_card',
                              ),
                              style: AppTypography.caption,
                            ),
                            const SizedBox(height: 6),
                            NutritionStatusBadges(status: statusRaw),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          GrowthTrendIndicator(trend: trend, dense: true),
                          const SizedBox(height: 4),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.grey.shade400,
                            size: 22,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  MiniGrowthPreview(
                    childName: '',
                    history: history,
                    compact: true,
                  ),
                  Text(
                    'Terakhir diperiksa: $measuredLabel',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      color: const Color(0xFF8B959C),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '$lastChecked • ${history.length} pengukuran',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      color: const Color(0xFF6D7A77),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6FBFA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFDDEDEA)),
                    ),
                    child: Text(
                      insight,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(delay: (50 * index).ms, duration: 280.ms)
        .slideY(begin: 0.03, end: 0, delay: (50 * index).ms);
  }
}
