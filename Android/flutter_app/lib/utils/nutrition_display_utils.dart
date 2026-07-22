import 'package:flutter/material.dart';

import 'package:s_gizi/app_design.dart';
import 'package:s_gizi/core/helpers/nutrition_status_helper.dart';
import 'package:s_gizi/models/riwayat_response_model.dart';
import 'age_helper.dart';

class NutritionStatusVisual {
  const NutritionStatusVisual({
    required this.color,
    required this.icon,
    required this.badgeLabel,
    required this.summary,
  });

  final Color color;
  final IconData icon;
  final String badgeLabel;
  final String summary;
}

class NormalizedStatus {
  const NormalizedStatus({
    required this.originalStatus,
    required this.primaryCategory,
    required this.categories,
  });

  final String originalStatus;
  final String primaryCategory;
  final List<String> categories;

  bool get hasStunting =>
      categories.contains('Pendek') || categories.contains('Sangat Pendek');
  bool get hasUnderweight =>
      categories.contains('Berat Badan Kurang') ||
      categories.contains('Berat Badan Sangat Kurang');
  bool get hasWasting => categories.contains('Gizi Kurang');
  bool get hasObesitas =>
      categories.contains('Obesitas') ||
      categories.contains('Gizi Lebih') ||
      categories.contains('Risiko Berat Badan Lebih');
  bool get isNormal =>
      categories.length == 1 && categories.first == 'Gizi Baik';

  String get focusSummary {
    if (isNormal) {
      return 'Fokus menu gizi seimbang untuk mempertahankan pertumbuhan yang baik.';
    }

    final focuses = <String>[];
    if (hasStunting) {
      focuses.add('protein tinggi, zat besi, dan zinc');
    }
    if (hasUnderweight || hasWasting) {
      focuses.add('energi padat dan protein tinggi');
    }
    if (hasObesitas) {
      focuses.add('rendah gula, rendah lemak, dan tinggi serat');
    }

    if (focuses.isEmpty) {
      return 'Fokus menu disesuaikan dengan status gizi terakhir anak.';
    }

    return 'Fokus menu: ${focuses.join(', ')}.';
  }
}

NormalizedStatus normalizeStatus(String status) {
  final result = NutritionStatusHelper.getStatus(
    status: status,
    source: 'normalizeStatus',
  );
  final originalStatus = result.label;
  final categories = result.badges;

  return NormalizedStatus(
    originalStatus: originalStatus,
    primaryCategory: categories.first,
    categories: categories.toSet().toList(),
  );
}

NutritionStatusVisual nutritionStatusVisual(String status) {
  final result = NutritionStatusHelper.getStatus(
    status: status,
    source: 'nutritionStatusVisual',
  );
  return NutritionStatusVisual(
    color: result.color,
    icon: result.icon,
    badgeLabel: result.label,
    summary: result.recommendation,
  );
}

String localizeNutritionStatus(String status) {
  return NutritionStatusHelper.localize(status);
}

String formatRelativeLastChecked(String? rawDate) {
  if (rawDate == null || rawDate.trim().isEmpty) {
    return 'Belum pernah diperiksa';
  }
  final date = DateTime.tryParse(rawDate);
  if (date == null) return 'Belum pernah diperiksa';

  final days = wholeDaysBetween(date, DateTime.now());
  if (days <= 0) return 'Terakhir diperiksa hari ini';
  if (days == 1) return 'Terakhir diperiksa 1 hari lalu';
  return 'Terakhir diperiksa $days hari lalu';
}

String formatMeasurementDate(String rawDate) {
  final date = DateTime.tryParse(rawDate);
  if (date == null) return rawDate;

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

  return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
}

String formatAgeFromBirthDate(
  String rawBirthDate, {
  String? onDate,
  String source = 'formatAgeFromBirthDate',
}) {
  return formatAgeFromDateStrings(rawBirthDate, onDate: onDate, source: source);
}

String formatAgeAtMeasurement({
  required String birthDate,
  required String measurementDate,
  String source = 'formatAgeAtMeasurement',
}) {
  return formatAgeFromDateStrings(
    birthDate,
    onDate: measurementDate,
    source: source,
  );
}

String genderLabel(String gender) {
  if (gender.toLowerCase().startsWith('p')) return 'Perempuan';
  return 'Laki-laki';
}

String measurementMethodLabel(String? rawMethod, double ageMonths) {
  final value = (rawMethod ?? '').toLowerCase();
  if (value == 'lying') return 'Terlentang';
  if (value == 'standing') return 'Berdiri';
  if (ageMonths < 24) return 'Terlentang';
  return 'Berdiri';
}

String formatScore(double? value) {
  if (value == null || value.isNaN || value.isInfinite) return '-';
  return value.toStringAsFixed(2);
}

String bbuCategoryFromScore(double? score, {String? fallback}) {
  final normalizedFallback = _validIndicatorFallback(
    fallback,
    indicator: NutritionIndicator.bbu,
  );
  if (normalizedFallback != null) return normalizedFallback;
  if (score == null || score.isNaN || score.isInfinite) return '-';
  return NutritionStatusHelper.bbuFromZ(score);
}

String tbuCategoryFromScore(double? score, {String? fallback}) {
  final normalizedFallback = _validIndicatorFallback(
    fallback,
    indicator: NutritionIndicator.tbu,
  );
  if (normalizedFallback != null) return normalizedFallback;
  if (score == null || score.isNaN || score.isInfinite) return '-';
  return NutritionStatusHelper.tbuFromZ(score);
}

String bbtbCategoryFromScore(double? score, {String? fallback}) {
  final normalizedFallback = _validIndicatorFallback(
    fallback,
    indicator: NutritionIndicator.bbtb,
  );
  if (normalizedFallback != null) return normalizedFallback;
  if (score == null || score.isNaN || score.isInfinite) return '-';
  return NutritionStatusHelper.bbtbFromZ(score);
}

String? _validIndicatorFallback(
  String? fallback, {
  required NutritionIndicator indicator,
}) {
  final value = (fallback ?? '').trim();
  if (value.isEmpty || value == '-') return null;
  final localized = NutritionStatusHelper.localize(value);
  final lower = localized.toLowerCase();

  switch (indicator) {
    case NutritionIndicator.bbu:
      if (lower.contains('berat badan') && !lower.contains('gizi baik')) {
        return localized;
      }
      return null;
    case NutritionIndicator.tbu:
      if (lower == 'normal' ||
          lower == 'gizi baik' ||
          lower.contains('pendek') ||
          lower.contains('tinggi')) {
        return localized == 'Gizi Baik' ? 'Normal' : localized;
      }
      return null;
    case NutritionIndicator.bbtb:
      if (lower.contains('gizi') ||
          lower.contains('obesitas') ||
          lower.contains('risiko berat badan lebih')) {
        return localized;
      }
      return null;
    case NutritionIndicator.combined:
      return localized;
  }
}

String buildInterpretation({
  required String status,
  required String bbuCategory,
  required String tbuCategory,
  required String bbtbCategory,
}) {
  final value = status.toLowerCase();

  if (value.contains('stunting')) {
    return 'Anak mengalami stunting ($tbuCategory) dibandingkan usia. '
        'Status BB/TB saat ini $bbtbCategory dan BB/U $bbuCategory.';
  }
  if (value.contains('buruk') || value.contains('kurang')) {
    return 'Berat badan perlu perhatian. BB/U tercatat $bbuCategory dan proporsi BB/TB $bbtbCategory.';
  }
  if (value.contains('obesitas') || value.contains('lebih')) {
    return 'Proporsi berat terhadap tinggi menunjukkan $bbtbCategory. '
        'Pengaturan porsi dan kualitas asupan perlu dipantau.';
  }

  return 'Pertumbuhan saat ini berada pada jalur yang baik. '
      'BB/U $bbuCategory, TB/U $tbuCategory, dan BB/TB $bbtbCategory.';
}

class StatusBadgeSpec {
  const StatusBadgeSpec(this.label, this.color);

  final String label;
  final Color color;
}

enum GrowthTrendDirection { up, down, stable }

class GrowthTrendVisual {
  const GrowthTrendVisual({
    required this.direction,
    required this.label,
    required this.color,
    required this.icon,
  });

  final GrowthTrendDirection direction;
  final String label;
  final Color color;
  final IconData icon;
}

/// Badge utama + tambahan (mis. Stunting Berat + Underweight).
List<StatusBadgeSpec> statusCompactBadges(String status) {
  final raw = status.trim();
  if (raw.isEmpty) {
    return [const StatusBadgeSpec('Belum Diukur', SgColors.textSecondary)];
  }

  final lower = raw.toLowerCase();
  if (normalizeStatus(raw).isNormal) {
    return [const StatusBadgeSpec('Gizi Baik', SgColors.success)];
  }

  final badges = <StatusBadgeSpec>[];

  if (lower.contains('severely stunted') ||
      lower.contains('sangat pendek') ||
      lower.contains('stunting berat')) {
    badges.add(const StatusBadgeSpec('Sangat Pendek', SgColors.danger));
  } else if (lower.contains('stunting') ||
      lower.contains('stunted') ||
      lower.contains('pendek')) {
    badges.add(const StatusBadgeSpec('Pendek', SgColors.warning));
  }

  if (lower.contains('wasting') || lower.contains('gizi buruk')) {
    badges.add(const StatusBadgeSpec('Gizi Buruk', SgColors.danger));
  }

  if (lower.contains('gizi kurang')) {
    badges.add(const StatusBadgeSpec('Gizi Kurang', Color(0xFFF97316)));
  }

  if (lower.contains('underweight') ||
      lower.contains('berat badan kurang') ||
      lower.contains('berat badan sangat kurang')) {
    badges.add(const StatusBadgeSpec('Berat Badan Kurang', Color(0xFFF97316)));
  }

  if (lower.contains('obesitas') ||
      lower.contains('overweight') ||
      lower.contains('gizi lebih')) {
    badges.add(
      StatusBadgeSpec(localizeNutritionStatus(raw), Color(0xFFF97316)),
    );
  }

  if (badges.isEmpty) {
    badges.add(const StatusBadgeSpec('Perlu Perhatian', SgColors.warning));
  }

  return badges.take(3).toList();
}

/// Ringkasan ramah orang tua untuk dashboard (bukan istilah medis panjang).
String friendlyDashboardSummary(String status) {
  final normalized = normalizeStatus(status);
  if (normalized.isNormal) {
    return 'Pertumbuhan anak berjalan baik. Tetap pantau secara rutin ya, Bunda.';
  }
  if (normalized.hasStunting &&
      (normalized.hasUnderweight || normalized.hasWasting)) {
    return 'Tinggi dan berat badan perlu perhatian.';
  }
  if (normalized.hasStunting) {
    return 'Tinggi badan perlu dipantau dan ditingkatkan secara bertahap.';
  }
  if (normalized.hasUnderweight || normalized.hasWasting) {
    return 'Berat badan perlu ditingkatkan dengan asupan bergizi.';
  }
  if (normalized.hasObesitas) {
    return 'Berat badan perlu dijaga agar tetap seimbang.';
  }
  return 'Status gizi perlu pemantauan rutin bersama tenaga kesehatan.';
}

/// Interpretasi ringkas dashboard (maks. ~3 baris).
String compactDashboardInterpretation(String status) {
  return friendlyDashboardSummary(status);
}

GrowthTrendVisual growthTrendFromWeightHistory(List<double> weights) {
  if (weights.length < 2) {
    return const GrowthTrendVisual(
      direction: GrowthTrendDirection.stable,
      label: 'Stabil',
      color: SgColors.textSecondary,
      icon: Icons.trending_flat_rounded,
    );
  }

  final delta = weights.last - weights[weights.length - 2];
  if (delta.abs() < 0.08) {
    return const GrowthTrendVisual(
      direction: GrowthTrendDirection.stable,
      label: 'Stabil',
      color: SgColors.textSecondary,
      icon: Icons.trending_flat_rounded,
    );
  }
  if (delta > 0) {
    return const GrowthTrendVisual(
      direction: GrowthTrendDirection.up,
      label: 'Naik baik',
      color: SgColors.success,
      icon: Icons.trending_up_rounded,
    );
  }
  return const GrowthTrendVisual(
    direction: GrowthTrendDirection.down,
    label: 'Menurun',
    color: SgColors.warning,
    icon: Icons.trending_down_rounded,
  );
}

GrowthTrendVisual growthTrendFromHistory(List<RiwayatItemModel> history) {
  final sorted = [...history]
    ..sort((a, b) {
      final ad = DateTime.tryParse(a.tanggalUkur) ?? DateTime(2000);
      final bd = DateTime.tryParse(b.tanggalUkur) ?? DateTime(2000);
      return ad.compareTo(bd);
    });
  return growthTrendFromWeightHistory(sorted.map((e) => e.berat).toList());
}

/// Perubahan pengukuran vs entri sebelumnya (timeline).
String? formatMeasurementChange({
  required RiwayatItemModel current,
  RiwayatItemModel? previous,
}) {
  if (previous == null) return null;
  final parts = <String>[];
  final dWeight = current.berat - previous.berat;
  if (dWeight.abs() >= 0.05) {
    parts.add(
      '${dWeight > 0 ? '↑' : '↓'} Berat ${dWeight > 0 ? 'naik' : 'turun'} ${dWeight.abs().toStringAsFixed(1)} kg',
    );
  }
  final dHeight = current.tinggi - previous.tinggi;
  if (dHeight.abs() >= 0.2) {
    parts.add(
      '${dHeight > 0 ? '↑' : '↓'} Tinggi ${dHeight > 0 ? 'naik' : 'turun'} ${dHeight.abs().toStringAsFixed(0)} cm',
    );
  }
  if (parts.isEmpty) return null;
  return parts.join(' · ');
}

/// Pengingat pengukuran (null jika tidak perlu ditampilkan).
String? monitoringReminderMessage(String? rawDate, {int warnDays = 21}) {
  if (rawDate == null || rawDate.trim().isEmpty) {
    return 'Belum ada pengukuran. Mulai pemantauan dengan input pengukuran pertama.';
  }
  final date = DateTime.tryParse(rawDate);
  if (date == null) return null;

  final days = wholeDaysBetween(date, DateTime.now());
  if (days >= 30) {
    return 'Sudah $days hari belum ada pengukuran baru.';
  }
  if (days >= warnDays) {
    return 'Segera lakukan pengukuran ulang minggu ini.';
  }
  return null;
}

String recommendationStatusExplanation(String status) {
  final normalized = normalizeStatus(status);

  if (normalized.isNormal) {
    return 'Status gizi terbaru berada pada kategori gizi baik. Menu diarahkan untuk menjaga pola makan yang seimbang.';
  }

  final parts = <String>[];
  if (normalized.hasStunting) {
    parts.add('pertumbuhan tinggi badan perlu dukungan nutrisi');
  }
  if (normalized.hasUnderweight || normalized.hasWasting) {
    parts.add('asupan energi dan protein perlu diperkuat');
  }
  if (normalized.hasObesitas) {
    parts.add('berat badan perlu dijaga dengan menu lebih terkontrol');
  }

  return '${localizeNutritionStatus(normalized.originalStatus)}: ${parts.join(', ')}.';
}
