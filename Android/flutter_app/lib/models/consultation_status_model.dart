class ConsultationStatusModel {
  const ConsultationStatusModel({
    required this.hasConsultation,
    this.consultationId,
    this.status = '',
  });

  final bool hasConsultation;
  final int? consultationId;
  final String status;

  factory ConsultationStatusModel.fromJson(Map<String, dynamic> json) {
    return ConsultationStatusModel(
      hasConsultation: json['has_consultation'] == true,
      consultationId: json['consultation_id'] is num
          ? (json['consultation_id'] as num).toInt()
          : null,
      status: json['status'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'has_consultation': hasConsultation,
    'consultation_id': consultationId,
    'status': status,
  };
}
