class MeasurementHistoryModel {
  const MeasurementHistoryModel({
    required this.date,
    required this.weightKg,
    required this.heightCm,
    required this.riskStatus,
  });

  final String date;
  final double weightKg;
  final double heightCm;
  final String riskStatus;

  factory MeasurementHistoryModel.fromJson(Map<String, dynamic> json) {
    return MeasurementHistoryModel(
      date: _string(json['date']),
      weightKg: _double(json['weight_kg']),
      heightCm: _double(json['height_cm']),
      riskStatus: _string(json['risk_status'], fallback: 'Normal'),
    );
  }

  Map<String, dynamic> toJson() => {
    'date': date,
    'weight_kg': weightKg,
    'height_cm': heightCm,
    'risk_status': riskStatus,
  };
}

String _string(dynamic value, {String fallback = ''}) {
  if (value is String && value.trim().isNotEmpty) return value.trim();
  return fallback;
}

double _double(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}
