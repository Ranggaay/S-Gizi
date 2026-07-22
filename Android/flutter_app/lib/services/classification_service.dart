import 'package:s_gizi/core/helpers/nutrition_status_helper.dart';

class ClassificationService {
  // =========================
  // KLASIFIKASI UMUM (Z-SCORE)
  // =========================
  String classify(double zScore) {
    return NutritionStatusHelper.bbtbFromZ(zScore);
  }

  // =========================
  // BB/U (BERAT BADAN MENURUT UMUR)
  // =========================
  String interpretWeightForAge(double zScore) {
    if (zScore < -3) {
      return 'Berat Badan Sangat Kurang';
    }
    if (zScore < -2) {
      return 'Berat Badan Kurang';
    }
    if (zScore > 1) {
      return 'Risiko Berat Badan Lebih';
    }
    return 'Berat Badan Normal';
  }

  // =========================
  // TB/U (TINGGI BADAN MENURUT UMUR)
  // =========================
  String interpretHeightForAge(double zScore) {
    if (zScore < -3) {
      return 'Sangat Pendek';
    }
    if (zScore < -2) {
      return 'Pendek';
    }
    if (zScore < -1) {
      return 'Tinggi badan sedikit di bawah standar';
    }
    return 'Tinggi badan sesuai dengan standar usia';
  }

  // =========================
  // BB/TB (BERAT BADAN MENURUT TINGGI)
  // =========================
  String interpretWeightForHeight(double zScore) {
    if (zScore < -3) {
      return 'Gizi Buruk';
    }
    if (zScore < -2) {
      return 'Gizi Kurang';
    }
    if (zScore <= 1) {
      return 'Gizi Baik';
    }
    if (zScore <= 2) {
      return 'Risiko Berat Badan Lebih';
    }
    if (zScore <= 3) return 'Gizi Lebih';
    return NutritionStatusHelper.obesitas;
  }

  // =========================
  // KESIMPULAN AKHIR (SMART ANALYSIS)
  // =========================
  String buildConclusion({
    required double bbU,
    required double tbU,
    required double bbTb,
  }) {
    final masalah = <String>[];

    if (bbU < -2) masalah.add('Berat Badan Kurang');
    if (tbU < -2) masalah.add('Pendek');
    if (bbTb < -2) masalah.add('Gizi Kurang');
    if (bbTb > 2) masalah.add('gizi lebih');

    if (masalah.isEmpty) {
      return 'Status gizi anak baik berdasarkan indikator WHO.';
    }

    return 'Anak mengalami ${masalah.join(', ')}.';
  }
}
