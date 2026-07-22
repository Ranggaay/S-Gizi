class ChildMonitoringSummary {
  const ChildMonitoringSummary({
    required this.total,
    required this.highRisk,
    required this.anomaly,
    required this.normal,
  });

  final int total;
  final int highRisk;
  final int anomaly;
  final int normal;

  factory ChildMonitoringSummary.fromJson(Map<String, dynamic> json) {
    return ChildMonitoringSummary(
      total: _int(json['total']),
      highRisk: _int(json['high_risk']),
      anomaly: _int(json['anomaly']),
      normal: _int(json['normal']),
    );
  }

  Map<String, dynamic> toJson() => {
    'total': total,
    'high_risk': highRisk,
    'anomaly': anomaly,
    'normal': normal,
  };

  static const empty = ChildMonitoringSummary(
    total: 0,
    highRisk: 0,
    anomaly: 0,
    normal: 0,
  );
}

class ChildMonitoringModel {
  const ChildMonitoringModel({
    required this.id,
    required this.name,
    required this.ageText,
    required this.gender,
    required this.parentName,
    required this.parentPhone,
    required this.riskStatus,
    required this.bbuStatus,
    required this.tbuStatus,
    required this.bbtbStatus,
    required this.weightKg,
    required this.heightCm,
    required this.zscoreTbu,
    required this.lastMeasurementDate,
    required this.isAnomaly,
    required this.hasConsultation,
    this.consultationId,
  });

  final int id;
  final String name;
  final String ageText;
  final String gender;
  final String parentName;
  final String parentPhone;
  final String riskStatus;
  final String bbuStatus;
  final String tbuStatus;
  final String bbtbStatus;
  final double weightKg;
  final double heightCm;
  final double zscoreTbu;
  final String lastMeasurementDate;
  final bool isAnomaly;
  final bool hasConsultation;
  final int? consultationId;

  factory ChildMonitoringModel.fromJson(Map<String, dynamic> json) {
    return ChildMonitoringModel(
      id: _int(json['id']),
      name: _string(json['name'], fallback: 'Anak'),
      ageText: _string(json['age_text'], fallback: '-'),
      gender: _string(json['gender'], fallback: '-'),
      parentName: _string(json['parent_name'], fallback: '-'),
      parentPhone: _string(json['parent_phone'], fallback: '-'),
      riskStatus: _string(json['risk_status'], fallback: 'Normal'),
      bbuStatus: _string(json['bbu_status'], fallback: '-'),
      tbuStatus: _string(json['tbu_status'], fallback: '-'),
      bbtbStatus: _string(json['bbtb_status'], fallback: '-'),
      weightKg: _double(json['weight_kg']),
      heightCm: _double(json['height_cm']),
      zscoreTbu: _double(json['zscore_tbu']),
      lastMeasurementDate: _string(
        json['last_measurement_date'],
        fallback: '-',
      ),
      isAnomaly: json['is_anomaly'] == true,
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
    'parent_name': parentName,
    'parent_phone': parentPhone,
    'risk_status': riskStatus,
    'bbu_status': bbuStatus,
    'tbu_status': tbuStatus,
    'bbtb_status': bbtbStatus,
    'weight_kg': weightKg,
    'height_cm': heightCm,
    'zscore_tbu': zscoreTbu,
    'last_measurement_date': lastMeasurementDate,
    'is_anomaly': isAnomaly,
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
