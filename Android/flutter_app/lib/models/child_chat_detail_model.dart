import 'child_detail_model.dart';
import 'measurement_history_model.dart';
import 'nutritionist_note_model.dart';
import 'zscore_result_model.dart';

class ChildChatDetailModel {
  const ChildChatDetailModel({
    required this.id,
    required this.name,
    required this.ageText,
    required this.gender,
    required this.parentName,
    required this.parentPhone,
    required this.riskStatus,
    required this.latestMeasurement,
    required this.zscoreResult,
    required this.interpretation,
    required this.shortHistories,
    required this.notes,
  });

  final int id;
  final String name;
  final String ageText;
  final String gender;
  final String parentName;
  final String parentPhone;
  final String riskStatus;
  final LatestMeasurementModel latestMeasurement;
  final ZScoreResultModel zscoreResult;
  final String interpretation;
  final List<MeasurementHistoryModel> shortHistories;
  final List<NutritionistNoteModel> notes;

  factory ChildChatDetailModel.fromJson(Map<String, dynamic> json) {
    final latest = json['latest_measurement'] is Map<String, dynamic>
        ? json['latest_measurement'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final zscore = json['zscore_result'] is Map<String, dynamic>
        ? json['zscore_result'] as Map<String, dynamic>
        : const <String, dynamic>{};
    return ChildChatDetailModel(
      id: _int(json['id']),
      name: _string(json['name'], fallback: 'Anak'),
      ageText: _string(json['age_text'], fallback: '-'),
      gender: _string(json['gender'], fallback: '-'),
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
      notes: (json['notes'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(NutritionistNoteModel.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'age_text': ageText,
    'gender': gender,
    'parent_name': parentName,
    'parent_phone': parentPhone,
    'risk_status': riskStatus,
    'latest_measurement': latestMeasurement.toJson(),
    'zscore_result': zscoreResult.toJson(),
    'interpretation': interpretation,
    'short_histories': shortHistories.map((e) => e.toJson()).toList(),
    'notes': notes.map((e) => e.toJson()).toList(),
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
