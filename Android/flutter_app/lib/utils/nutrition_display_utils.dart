import 'package:flutter/material.dart';

import '../app_design.dart';

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

  bool get hasStunting => categories.contains('Stunting');
  bool get hasUnderweight => categories.contains('Underweight');
  bool get hasWasting => categories.contains('Wasting');
  bool get hasObesitas => categories.contains('Obesitas');
  bool get isNormal => categories.length == 1 && categories.first == 'Normal';

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
  final originalStatus = status.trim().isEmpty ? 'Normal' : status.trim();
  final value = originalStatus.toLowerCase();
  final categories = <String>[];

  if (value.contains('stunting') || value.contains('stunted')) {
    categories.add('Stunting');
  }
  if (value.contains('wasting')) {
    categories.add('Wasting');
  }
  if (value.contains('underweight') || value.contains('gizi kurang')) {
    categories.add('Underweight');
  }
  if (value.contains('obesitas') ||
      value.contains('overweight') ||
      value.contains('gizi lebih')) {
    categories.add('Obesitas');
  }

  if (categories.isEmpty) {
    categories.add('Normal');
  }

  return NormalizedStatus(
    originalStatus: originalStatus,
    primaryCategory: categories.first,
    categories: categories.toSet().toList(),
  );
}

NutritionStatusVisual nutritionStatusVisual(String status) {
  final normalized = normalizeStatus(status);
  final value = normalized.originalStatus.toLowerCase();

  if (value.contains('stunting')) {
    return const NutritionStatusVisual(
      color: SgColors.warning,
      icon: Icons.height_rounded,
      badgeLabel: 'Perlu Perhatian',
      summary: 'Pertumbuhan tinggi badan perlu perhatian dan pemantauan rutin.',
    );
  }
  if (value.contains('buruk')) {
    return const NutritionStatusVisual(
      color: SgColors.danger,
      icon: Icons.warning_amber_rounded,
      badgeLabel: 'Perlu Tindak Lanjut',
      summary: 'Status gizi perlu tindak lanjut cepat bersama tenaga kesehatan.',
    );
  }
  if (value.contains('kurang') || value.contains('underweight')) {
    return const NutritionStatusVisual(
      color: SgColors.warning,
      icon: Icons.monitor_weight_outlined,
      badgeLabel: 'Perlu Perhatian',
      summary: 'Asupan energi dan protein perlu diperkuat secara konsisten.',
    );
  }
  if (value.contains('obesitas') || value.contains('lebih')) {
    return const NutritionStatusVisual(
      color: Color(0xFFF97316),
      icon: Icons.balance_rounded,
      badgeLabel: 'Perlu Pemantauan',
      summary: 'Porsi dan kualitas makan perlu dijaga agar pertumbuhan tetap seimbang.',
    );
  }

  return const NutritionStatusVisual(
    color: SgColors.success,
    icon: Icons.favorite_rounded,
    badgeLabel: 'Pertumbuhan Baik',
    summary: 'Pertumbuhan sesuai jalur dan tetap perlu dipantau secara berkala.',
  );
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

String formatAgeFromBirthDate(String rawBirthDate, {String? onDate}) {
  final birthDate = DateTime.tryParse(rawBirthDate);
  final referenceDate = DateTime.tryParse(onDate ?? '') ?? DateTime.now();
  if (birthDate == null) return '-';

  int months =
      (referenceDate.year - birthDate.year) * 12 +
      (referenceDate.month - birthDate.month);

  if (referenceDate.day < birthDate.day) {
    months -= 1;
  }

  return formatAgeFromMonths(months.toDouble());
}

String formatAgeFromMonths(double months) {
  if (months.isNaN || months.isInfinite || months < 0) return '-';

  final totalMonths = months.round();
  final years = totalMonths ~/ 12;
  final remainingMonths = totalMonths % 12;

  if (years <= 0) {
    return '$remainingMonths Bulan';
  }
  if (remainingMonths == 0) {
    return '$years Tahun';
  }
  return '$years Tahun $remainingMonths Bulan';
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
  if (fallback != null && fallback.trim().isNotEmpty) return fallback;
  if (score == null || score.isNaN || score.isInfinite) return '-';
  if (score < -3) return 'Sangat Kurang';
  if (score < -2) return 'Kurang';
  if (score <= 1) return 'Normal';
  return 'Risiko Lebih';
}

String tbuCategoryFromScore(double? score, {String? fallback}) {
  if (fallback != null && fallback.trim().isNotEmpty) return fallback;
  if (score == null || score.isNaN || score.isInfinite) return '-';
  if (score < -3) return 'Sangat Pendek';
  if (score < -2) return 'Pendek';
  if (score <= 3) return 'Normal';
  return 'Tinggi';
}

String bbtbCategoryFromScore(double? score, {String? fallback}) {
  if (fallback != null && fallback.trim().isNotEmpty) return fallback;
  if (score == null || score.isNaN || score.isInfinite) return '-';
  if (score < -3) return 'Gizi Buruk';
  if (score < -2) return 'Kurang';
  if (score <= 1) return 'Normal';
  if (score <= 2) return 'Risiko Gizi Lebih';
  if (score <= 3) return 'Gizi Lebih';
  return 'Obesitas';
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

String recommendationStatusExplanation(String status) {
  final normalized = normalizeStatus(status);

  if (normalized.isNormal) {
    return 'Status gizi terbaru berada pada kategori normal. Menu diarahkan untuk menjaga pola makan yang seimbang.';
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

  return '${normalized.originalStatus}: ${parts.join(', ')}.';
}
