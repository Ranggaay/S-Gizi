import 'dart:developer' as developer;
import 'dart:math';

import 'package:s_gizi/models/child_model.dart';
import 'data_service.dart';

class CalculationResult {
  const CalculationResult({
    required this.bbU,
    required this.tbU,
    required this.bbTb,
    required this.adjustedHeightCm,
    required this.weightForHeightIndicator,
    required this.debugLog,
  });

  final double bbU;
  final double tbU;
  final double bbTb;
  final double adjustedHeightCm;
  final String weightForHeightIndicator;
  final String debugLog;
}

class CalculationService {
  CalculationService({DataService? dataService})
    : _dataService = dataService ?? DataService.instance;

  final DataService _dataService;

  // Kode ini digunakan untuk mengambil LMS dan menghitung tiga indikator Z-Score anak.
  Future<CalculationResult> calculate(ChildModel child) async {
    final gender = child.normalizedGender;
    final position = child.normalizedPosition;
    final adjustedHeight = child.adjustedHeightCm;
    final indicator = child.weightForHeightIndicator;

    final wfaLms = await _dataService.getAgeBasedLms(
      gender: gender,
      indicator: child.weightForAgeIndicator,
      ageInMonths: child.ageInMonths,
    );

    final hfaLms = await _dataService.getAgeBasedLms(
      gender: gender,
      indicator: child.heightForAgeIndicator,
      ageInMonths: child.ageInMonths,
    );

    final wfhLms = await _dataService.getHeightBasedLms(
      gender: gender,
      indicator: indicator,
      heightCm: adjustedHeight,
    );

    final bbU = _calculateZScore(
      l: wfaLms.l,
      m: wfaLms.m,
      s: wfaLms.s,
      x: child.weightKg,
    );
    final tbU = _calculateZScore(
      l: hfaLms.l,
      m: hfaLms.m,
      s: hfaLms.s,
      x: child.heightCm,
    );
    final bbTb = _calculateZScore(
      l: wfhLms.l,
      m: wfhLms.m,
      s: wfhLms.s,
      x: child.weightKg,
    );

    final debugLog = _buildDebugLog(
      child: child,
      gender: gender,
      position: position,
      indicator: indicator,
      adjustedHeight: adjustedHeight,
      wfaLms: wfaLms,
      hfaLms: hfaLms,
      wfhLms: wfhLms,
      bbU: bbU,
      tbU: tbU,
      bbTb: bbTb,
    );
    developer.log(debugLog, name: 'nutrition.zscore');

    return CalculationResult(
      bbU: bbU,
      tbU: tbU,
      bbTb: bbTb,
      adjustedHeightCm: adjustedHeight,
      weightForHeightIndicator: indicator,
      debugLog: debugLog,
    );
  }

  // Kode ini digunakan untuk menghitung nilai Z-Score menggunakan rumus WHO LMS.
  double _calculateZScore({
    required double l,
    required double m,
    required double s,
    required double x,
  }) {
    // PRESENTASI TA: Implementasi Z-Score lokal Flutter untuk perhitungan berbasis data LMS perangkat.
    if (x <= 0 || m <= 0 || s <= 0) {
      throw Exception('Nilai LMS atau data pengukuran tidak valid.');
    }

    final zScore = l.abs() < 1e-7
        ? log(x / m) / s
        : (pow(x / m, l) - 1) / (l * s);

    if (zScore.isNaN || zScore.isInfinite) {
      throw Exception('Z-score tidak valid.');
    }

    return zScore.toDouble();
  }

  // Kode ini digunakan untuk membuat catatan detail proses perhitungan Z-Score.
  String _buildDebugLog({
    required ChildModel child,
    required String gender,
    required String position,
    required String indicator,
    required double adjustedHeight,
    required LmsRecord wfaLms,
    required LmsRecord hfaLms,
    required LmsRecord wfhLms,
    required double bbU,
    required double tbU,
    required double bbTb,
  }) {
    // Kode ini digunakan untuk membentuk satu baris informasi nilai LMS.
    String lmsLine(String label, LmsRecord record) {
      return '$label LMS: L=${record.l}, M=${record.m}, S=${record.s}';
    }

    return [
      '=== WHO Z-SCORE DEBUG ===',
      'Umur (bulan): ${child.ageInMonths}',
      'Berat (kg): ${child.weightKg}',
      'Tinggi input (cm): ${child.heightCm}',
      'Tinggi adjusted (cm): $adjustedHeight',
      'Gender input: ${child.gender}',
      'Gender normalized: $gender',
      'Posisi input: ${child.measurementPosition}',
      'Posisi normalized: $position',
      'Indikator BB/TB: ${indicator.toUpperCase()}',
      lmsLine('WFA', wfaLms),
      lmsLine('HFA', hfaLms),
      lmsLine(indicator.toUpperCase(), wfhLms),
      'Z-score BB/U: $bbU',
      'Z-score TB/U: $tbU',
      'Z-score BB/TB: $bbTb',
      '==========================',
    ].join('\n');
  }
}
