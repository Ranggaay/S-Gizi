import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:s_gizi/app_design.dart';

enum NutritionIndicator { bbtb, tbu, bbu, combined }

enum NutritionRiskLevel { unknown, normal, attention, high }

class NutritionStatusResult {
  const NutritionStatusResult({
    required this.label,
    required this.color,
    required this.icon,
    required this.recommendation,
    required this.riskLevel,
    required this.badges,
  });

  final String label;
  final Color color;
  final IconData icon;
  final String recommendation;
  final NutritionRiskLevel riskLevel;
  final List<String> badges;

  bool get isNormal => riskLevel == NutritionRiskLevel.normal;
  bool get isHighRisk => riskLevel == NutritionRiskLevel.high;
  bool get needsAttention =>
      riskLevel == NutritionRiskLevel.attention ||
      riskLevel == NutritionRiskLevel.high;
}

class NutritionStatusHelper {
  const NutritionStatusHelper._();

  static const belumDiukur = 'Belum Diukur';
  static const giziBuruk = 'Gizi Buruk';
  static const giziKurang = 'Gizi Kurang';
  static const giziBaik = 'Gizi Baik';
  static const risikoBeratBadanLebih = 'Risiko Berat Badan Lebih';
  static const giziLebih = 'Gizi Lebih';
  static const obesitas = 'Obesitas';
  static const sangatPendek = 'Sangat Pendek';
  static const pendek = 'Pendek';
  static const normal = 'Normal';
  static const tinggi = 'Tinggi';
  static const beratBadanSangatKurang = 'Berat Badan Sangat Kurang';
  static const beratBadanKurang = 'Berat Badan Kurang';
  static const beratBadanNormal = 'Berat Badan Normal';

  static NutritionStatusResult getStatus({
    String? status,
    double? zBbu,
    double? zTbu,
    double? zBbtb,
    NutritionIndicator indicator = NutritionIndicator.combined,
    bool debug = false,
    String source = 'NutritionStatusHelper',
  }) {
    final label = _resolveLabel(
      status: status,
      zBbu: zBbu,
      zTbu: zTbu,
      zBbtb: zBbtb,
      indicator: indicator,
    );
    final badges = _badgesFor(label);
    final primary = badges.isEmpty ? label : badges.first;
    final result = NutritionStatusResult(
      label: primary,
      color: colorFor(primary),
      icon: iconFor(primary),
      recommendation: recommendationFor(primary),
      riskLevel: riskLevelFor(primary),
      badges: badges.isEmpty ? [primary] : badges,
    );

    if (debug || kDebugMode) {
      debugPrint(
        '[nutrition-status][$source] indicator=${indicator.name} '
        'z_bbu=${_debugNum(zBbu)} z_tbu=${_debugNum(zTbu)} '
        'z_bbtb=${_debugNum(zBbtb)} raw="${status ?? ''}" '
        'final="${result.label}" badges=${result.badges.join('|')}',
      );
    }
    return result;
  }

  static String bbtbFromZ(double? z) {
    if (!_valid(z)) return belumDiukur;
    if (z! < -3) return giziBuruk;
    if (z < -2) return giziKurang;
    if (z <= 1) return giziBaik;
    if (z <= 2) return risikoBeratBadanLebih;
    if (z <= 3) return giziLebih;
    return obesitas;
  }

  static String tbuFromZ(double? z) {
    if (!_valid(z)) return belumDiukur;
    if (z! < -3) return sangatPendek;
    if (z < -2) return pendek;
    if (z <= 3) return normal;
    return tinggi;
  }

  static String bbuFromZ(double? z) {
    if (!_valid(z)) return belumDiukur;
    if (z! < -3) return beratBadanSangatKurang;
    if (z < -2) return beratBadanKurang;
    if (z <= 1) return beratBadanNormal;
    return risikoBeratBadanLebih;
  }

  static String localize(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty || value == '-') return belumDiukur;
    final lower = value.toLowerCase();
    final replacements = <String, String>{
      'severely stunted': sangatPendek,
      'stunting berat': sangatPendek,
      'stunted': pendek,
      'stunting': pendek,
      'severe wasting': giziBuruk,
      'wasting': giziKurang,
      'severely wasted': giziBuruk,
      'severe underweight': beratBadanSangatKurang,
      'severely underweight': beratBadanSangatKurang,
      'underweight': beratBadanKurang,
      'risk of overweight': risikoBeratBadanLebih,
      'overweight': giziLebih,
      'obese': obesitas,
      'obesity': obesitas,
      'normal': giziBaik,
      'berat badan lebih': risikoBeratBadanLebih,
      'risiko lebih': risikoBeratBadanLebih,
      'risiko gizi lebih': risikoBeratBadanLebih,
      'risiko berat badan lebih': risikoBeratBadanLebih,
    };
    var output = value;
    for (final entry in replacements.entries) {
      output = output.replaceAll(
        RegExp(entry.key, caseSensitive: false),
        entry.value,
      );
    }
    if (lower == 'normal') return giziBaik;
    return output;
  }

  static Color colorFor(String status) {
    final label = localize(status).toLowerCase();
    if (label.contains('gizi buruk') ||
        label.contains('sangat pendek') ||
        label.contains('sangat kurang')) {
      return SgColors.danger;
    }
    if (label.contains('obesitas')) return const Color(0xFF991B1B);
    if (label.contains('gizi lebih')) return const Color(0xFFEA580C);
    if (label.contains('risiko berat badan lebih')) {
      return const Color(0xFFEAB308);
    }
    if (label.contains('gizi kurang') ||
        label.contains('pendek') ||
        label.contains('berat badan kurang')) {
      return SgColors.warning;
    }
    if (label.contains('belum')) return SgColors.textSecondary;
    return SgColors.success;
  }

  static IconData iconFor(String status) {
    final label = localize(status).toLowerCase();
    if (label.contains('buruk') ||
        label.contains('obesitas') ||
        label.contains('sangat')) {
      return Icons.warning_amber_rounded;
    }
    if (label.contains('kurang') || label.contains('pendek')) {
      return Icons.monitor_weight_outlined;
    }
    if (label.contains('lebih') || label.contains('risiko')) {
      return Icons.balance_rounded;
    }
    if (label.contains('belum')) return Icons.help_outline_rounded;
    return Icons.favorite_rounded;
  }

  static NutritionRiskLevel riskLevelFor(String status) {
    final label = localize(status).toLowerCase();
    if (label.contains('belum')) return NutritionRiskLevel.unknown;
    if (label.contains('buruk') ||
        label.contains('sangat') ||
        label.contains('obesitas')) {
      return NutritionRiskLevel.high;
    }
    if (label.contains('kurang') ||
        label.contains('pendek') ||
        label.contains('lebih') ||
        label.contains('risiko')) {
      return NutritionRiskLevel.attention;
    }
    return NutritionRiskLevel.normal;
  }

  static String recommendationFor(String status) {
    final label = localize(status).toLowerCase();
    if (label.contains('gizi buruk') || label.contains('sangat kurang')) {
      return 'Segera konsultasi dengan tenaga kesehatan dan pantau asupan energi-protein.';
    }
    if (label.contains('sangat pendek') || label.contains('pendek')) {
      return 'Fokus pada protein hewani, zat besi, zinc, dan pemantauan tinggi badan rutin.';
    }
    if (label.contains('gizi kurang') || label.contains('berat badan kurang')) {
      return 'Tingkatkan makanan padat energi dan protein secara bertahap.';
    }
    if (label.contains('obesitas') ||
        label.contains('gizi lebih') ||
        label.contains('risiko berat badan lebih')) {
      return 'Atur porsi, batasi gula/lemak berlebih, dan dorong aktivitas sesuai usia.';
    }
    if (label.contains('belum')) {
      return 'Lengkapi pengukuran berat, tinggi, usia, dan jenis kelamin anak.';
    }
    return 'Pertahankan pola makan seimbang dan lakukan pengukuran rutin.';
  }

  static String _resolveLabel({
    String? status,
    double? zBbu,
    double? zTbu,
    double? zBbtb,
    required NutritionIndicator indicator,
  }) {
    switch (indicator) {
      case NutritionIndicator.bbtb:
        return bbtbFromZ(zBbtb);
      case NutritionIndicator.tbu:
        return tbuFromZ(zTbu);
      case NutritionIndicator.bbu:
        return bbuFromZ(zBbu);
      case NutritionIndicator.combined:
        final direct = (status ?? '').trim();
        if (direct.isNotEmpty && direct != '-') return localize(direct);
        if (_valid(zBbtb)) return bbtbFromZ(zBbtb);
        if (_valid(zTbu)) return tbuFromZ(zTbu);
        if (_valid(zBbu)) return bbuFromZ(zBbu);
        return belumDiukur;
    }
  }

  static List<String> _badgesFor(String status) {
    final localized = localize(status);
    if (localized == belumDiukur) return [belumDiukur];
    final parts = localized
        .split(RegExp(r'\s*\+\s*'))
        .map((part) => localize(part).trim())
        .where((part) => part.isNotEmpty)
        .toSet()
        .toList();
    return parts.isEmpty ? [localized] : parts;
  }

  static bool _valid(double? value) =>
      value != null && !value.isNaN && !value.isInfinite;

  static String _debugNum(double? value) =>
      _valid(value) ? value!.toStringAsFixed(2) : '-';
}
