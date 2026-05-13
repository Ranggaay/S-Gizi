import 'dart:convert';
import 'package:flutter/services.dart';

class LmsRecord {
  const LmsRecord({required this.l, required this.m, required this.s});

  final double l;
  final double m;
  final double s;

  factory LmsRecord.fromJson(Map<String, dynamic> json) {
    return LmsRecord(
      l: (json['L'] as num).toDouble(),
      m: (json['M'] as num).toDouble(),
      s: (json['S'] as num).toDouble(),
    );
  }
}

class DataService {
  DataService._();
  static final DataService instance = DataService._();

  Map<String, dynamic>? _cache;
  Future<Map<String, dynamic>>? _loadingFuture;

  Future<void> loadData() async {
    if (_cache != null) return;

    _loadingFuture ??= _readJson();
    _cache = await _loadingFuture;
  }

  Future<Map<String, dynamic>> _readJson() async {
    final raw = await rootBundle.loadString('assets/data/lms_who_final.json');
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  // =========================
  // ✅ AGE BASED (FIX TOTAL)
  // =========================
  Future<LmsRecord> getAgeBasedLms({
    required String gender,
    required String indicator,
    required double ageInMonths,
  }) async {
    await loadData();
    final indicatorMap = _getIndicatorMap(gender, indicator);

    // 🔥 FIX: pakai double bukan int
    final monthKeys = indicatorMap.keys.map(double.parse).toList()..sort();

    final clampedAge = ageInMonths.clamp(monthKeys.first, monthKeys.last);

    double lower = monthKeys.first;
    double upper = monthKeys.last;

    for (int i = 0; i < monthKeys.length - 1; i++) {
      if (clampedAge >= monthKeys[i] && clampedAge <= monthKeys[i + 1]) {
        lower = monthKeys[i];
        upper = monthKeys[i + 1];
        break;
      }
    }

    final lowerRecord = _parseRecord(
      _getSafe(indicatorMap, lower),
      '$indicator age $lower',
    );

    if ((upper - lower).abs() < 1e-6) return lowerRecord;

    final upperRecord = _parseRecord(
      _getSafe(indicatorMap, upper),
      '$indicator age $upper',
    );

    final factor = (clampedAge - lower) / (upper - lower);

    return LmsRecord(
      l: _lerp(lowerRecord.l, upperRecord.l, factor),
      m: _lerp(lowerRecord.m, upperRecord.m, factor),
      s: _lerp(lowerRecord.s, upperRecord.s, factor),
    );
  }

  // =========================
  // HEIGHT BASED (SUDAH BENAR)
  // =========================
  Future<LmsRecord> getHeightBasedLms({
    required String gender,
    required String indicator,
    required double heightCm,
  }) async {
    await loadData();
    final indicatorMap = _getIndicatorMap(gender, indicator);

    final heights = indicatorMap.keys.map(double.parse).toList()..sort();

    final clampedHeight = heightCm.clamp(heights.first, heights.last);

    double lower = heights.first;
    double upper = heights.last;

    for (int i = 0; i < heights.length - 1; i++) {
      if (clampedHeight >= heights[i] && clampedHeight <= heights[i + 1]) {
        lower = heights[i];
        upper = heights[i + 1];
        break;
      }
    }

    final lowerRecord = _parseRecord(
      _getSafe(indicatorMap, lower),
      '$indicator height $lower',
    );

    if ((upper - lower).abs() < 1e-6) return lowerRecord;

    final upperRecord = _parseRecord(
      _getSafe(indicatorMap, upper),
      '$indicator height $upper',
    );

    final factor = (clampedHeight - lower) / (upper - lower);

    return LmsRecord(
      l: _lerp(lowerRecord.l, upperRecord.l, factor),
      m: _lerp(lowerRecord.m, upperRecord.m, factor),
      s: _lerp(lowerRecord.s, upperRecord.s, factor),
    );
  }

  // =========================
  // HELPERS
  // =========================

  Map<String, dynamic> _getIndicatorMap(String gender, String indicator) {
    final data = _cache;
    if (data == null) {
      throw Exception('Data LMS belum dimuat.');
    }

    final genderMap = data[gender];
    if (genderMap is! Map<String, dynamic>) {
      throw Exception('Gender $gender tidak ditemukan.');
    }

    final indicatorMap = genderMap[indicator];
    if (indicatorMap is! Map<String, dynamic>) {
      throw Exception('Indikator $indicator tidak ditemukan.');
    }

    return indicatorMap;
  }

  LmsRecord _parseRecord(dynamic value, String label) {
    if (value is! Map<String, dynamic>) {
      throw Exception('Record LMS untuk $label tidak ditemukan.');
    }
    return LmsRecord.fromJson(value);
  }

  double _lerp(double start, double end, double factor) {
    return start + ((end - start) * factor);
  }

  // 🔥 FIX FLEXIBLE KEY
  dynamic _getSafe(Map<String, dynamic> map, double key) {
    final k1 = key.toStringAsFixed(1); // 31.0
    final k2 = key.toStringAsFixed(0); // 31

    if (map.containsKey(k1)) return map[k1];
    if (map.containsKey(k2)) return map[k2];

    throw Exception('Key tidak ditemukan: $key');
  }
}
