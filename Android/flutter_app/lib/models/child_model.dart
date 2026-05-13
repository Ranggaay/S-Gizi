class ChildModel {
  const ChildModel({
    required this.ageInMonths,
    required this.weightKg,
    required this.heightCm,
    required this.gender,
    required this.measurementPosition,
  });

  final double ageInMonths;
  final double weightKg;
  final double heightCm;
  final String gender;
  final String measurementPosition;

  // =============================
  // NORMALIZATION
  // =============================
  String get normalizedGender {
    final g = gender.toLowerCase().trim();

    if (g == 'l' || g == 'laki' || g == 'laki-laki' || g == 'male') {
      return 'male';
    }

    if (g == 'p' || g == 'perempuan' || g == 'female') {
      return 'female';
    }

    throw Exception('Gender tidak dikenali: $gender');
  }

  String get normalizedPosition {
    final p = measurementPosition.toLowerCase().trim();

    if (p.contains('berdiri') || p.contains('standing')) {
      return 'standing';
    }

    if (p.contains('terlentang') ||
        p.contains('lying') ||
        p.contains('recumbent')) {
      return 'lying';
    }

    throw Exception('Posisi tidak dikenali: $measurementPosition');
  }

  // =============================
  // WHO RULE
  // =============================
  bool get usesLengthReference => ageInMonths < 24;

  bool get needsStandingToRecumbentAdjustment =>
      usesLengthReference && normalizedPosition == 'standing';

  double get adjustedHeightCm {
    if (needsStandingToRecumbentAdjustment) {
      return heightCm + 0.7;
    }
    return heightCm;
  }

  // =============================
  // INDICATORS
  // =============================
  String get weightForAgeIndicator => 'wfa';

  String get heightForAgeIndicator => 'hfa';

  String get weightForHeightIndicator => usesLengthReference ? 'wfl' : 'wfh';
}
