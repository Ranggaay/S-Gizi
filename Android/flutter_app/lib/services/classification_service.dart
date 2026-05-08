class ClassificationService {
  // =========================
  // KLASIFIKASI UMUM (Z-SCORE)
  // =========================
  String classify(double zScore) {
    if (zScore < -3) return 'Severe';
    if (zScore < -2) return 'Moderate';
    if (zScore <= 2) return 'Normal';
    if (zScore <= 3) return 'Overweight';
    return 'Obese';
  }

  // =========================
  // BB/U (BERAT BADAN MENURUT UMUR)
  // =========================
  String interpretWeightForAge(double zScore) {
    if (zScore < -3) {
      return 'Gizi buruk (berat badan sangat kurang)';
    }
    if (zScore < -2) {
      return 'Gizi kurang (underweight)';
    }
    if (zScore > 2) {
      return 'Berat badan lebih dari standar usia';
    }
    return 'Berat badan sesuai dengan standar usia';
  }

  // =========================
  // TB/U (TINGGI BADAN MENURUT UMUR)
  // =========================
  String interpretHeightForAge(double zScore) {
    if (zScore < -3) {
      return 'Sangat pendek (stunting berat)';
    }
    if (zScore < -2) {
      return 'Pendek (stunting)';
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
      return 'Gizi buruk (wasting berat)';
    }
    if (zScore < -2) {
      return 'Gizi kurang (wasting)';
    }
    if (zScore <= 2) {
      return 'Status gizi normal';
    }
    if (zScore <= 3) {
      return 'Berisiko gizi lebih';
    }
    return 'Obesitas';
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

    if (bbU < -2) masalah.add('berat badan kurang');
    if (tbU < -2) masalah.add('stunting');
    if (bbTb < -2) masalah.add('wasting');
    if (bbTb > 2) masalah.add('gizi lebih');

    if (masalah.isEmpty) {
      return 'Status gizi anak normal berdasarkan indikator WHO.';
    }

    return 'Anak mengalami ${masalah.join(', ')}.';
  }
}
