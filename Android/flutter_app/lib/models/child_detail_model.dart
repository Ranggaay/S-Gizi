import 'measurement_history_model.dart';
import 'zscore_result_model.dart';

class LatestMeasurementModel {
  const LatestMeasurementModel({
    required this.measurementId,
    required this.measurementDate,
    required this.ageAtMeasurement,
    required this.weightKg,
    required this.heightCm,
    required this.position,
  });

  final int measurementId;
  final String measurementDate;
  final String ageAtMeasurement;
  final double weightKg;
  final double heightCm;
  final String position;

  factory LatestMeasurementModel.fromJson(Map<String, dynamic> json) {
    return LatestMeasurementModel(
      measurementId: _int(json['measurement_id']),
      measurementDate: _string(json['measurement_date'], fallback: '-'),
      ageAtMeasurement: _string(json['age_at_measurement'], fallback: '-'),
      weightKg: _double(json['weight_kg']),
      heightCm: _double(json['height_cm']),
      position: _string(json['position'], fallback: '-'),
    );
  }

  Map<String, dynamic> toJson() => {
    'measurement_id': measurementId,
    'measurement_date': measurementDate,
    'age_at_measurement': ageAtMeasurement,
    'weight_kg': weightKg,
    'height_cm': heightCm,
    'position': position,
  };
}

class ChildDetailModel {
  const ChildDetailModel({
    required this.id,
    required this.name,
    required this.ageText,
    required this.gender,
    required this.birthDate,
    required this.parentName,
    required this.parentPhone,
    required this.riskStatus,
    required this.latestMeasurement,
    required this.zscoreResult,
    required this.interpretation,
    required this.shortHistories,
    required this.hasConsultation,
    this.consultationId,
  });

  final int id;
  final String name;
  final String ageText;
  final String gender;
  final String birthDate;
  final String parentName;
  final String parentPhone;
  final String riskStatus;
  final LatestMeasurementModel latestMeasurement;
  final ZScoreResultModel zscoreResult;
  final String interpretation;
  final List<MeasurementHistoryModel> shortHistories;
  final bool hasConsultation;
  final int? consultationId;

  factory ChildDetailModel.fromJson(Map<String, dynamic> json) {
    final latest = json['latest_measurement'] is Map<String, dynamic>
        ? json['latest_measurement'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final zscore = json['zscore_result'] is Map<String, dynamic>
        ? json['zscore_result'] as Map<String, dynamic>
        : const <String, dynamic>{};
    return ChildDetailModel(
      id: _int(json['id']),
      name: _string(json['name'], fallback: 'Anak'),
      ageText: _string(json['age_text'], fallback: '-'),
      gender: _string(json['gender'], fallback: '-'),
      birthDate: _string(json['birth_date'], fallback: '-'),
      parentName: _string(json['parent_name'], fallback: '-'),
      parentPhone: _string(json['parent_phone'], fallback: '-'),
      riskStatus: _string(json['risk_status'], fallback: 'Normal'),
      latestMeasurement: LatestMeasurementModel.fromJson(latest),
      zscoreResult: ZScoreResultModel.fromJson(zscore),
      interpretation: _string(json['interpretation'], fallback: '-'),
      shortHistories: (json['short_histories'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(MeasurementHistoryModel.fromJson)
          .toList(),
      hasConsultation: json['has_consultation'] == true,
      consultationId: json['consultation_id'] is num
          ? (json['consultation_id'] as num).toInt()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'age_text': ageText,
    'gender': gender,
    'birth_date': birthDate,
    'parent_name': parentName,
    'parent_phone': parentPhone,
    'risk_status': riskStatus,
    'latest_measurement': latestMeasurement.toJson(),
    'zscore_result': zscoreResult.toJson(),
    'interpretation': interpretation,
    'short_histories': shortHistories.map((item) => item.toJson()).toList(),
    'has_consultation': hasConsultation,
    'consultation_id': consultationId,
  };
}

String _string(dynamic value, {String fallback = ''}) {
  if (value is String && value.trim().isNotEmpty) return value.trim();
  return fallback;
}

int _int(dynamic value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

double _double(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}
