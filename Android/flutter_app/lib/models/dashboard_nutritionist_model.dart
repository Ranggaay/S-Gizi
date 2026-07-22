import 'consultation_model.dart';
import 'notification_model.dart';
import 'nutritionist_profile_model.dart';

class DashboardSummaryModel {
  const DashboardSummaryModel({
    required this.activeConsultations,
    required this.unrepliedMessages,
    required this.highRiskConsultations,
    required this.needReviewData,
  });

  final int activeConsultations;
  final int unrepliedMessages;
  final int highRiskConsultations;
  final int needReviewData;

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    return DashboardSummaryModel(
      activeConsultations: _int(json['active_consultations']),
      unrepliedMessages: _int(json['unreplied_messages'] ?? json['unanswered']),
      highRiskConsultations: _int(
        json['high_risk_consultations'] ?? json['risk_children'],
      ),
      needReviewData: _int(json['need_review_data'] ?? json['anomaly_data']),
    );
  }

  Map<String, dynamic> toJson() => {
    'active_consultations': activeConsultations,
    'unreplied_messages': unrepliedMessages,
    'high_risk_consultations': highRiskConsultations,
    'need_review_data': needReviewData,
  };
}

class DashboardNutritionistModel {
  const DashboardNutritionistModel({
    required this.nutritionist,
    required this.summary,
    required this.latestConsultations,
    required this.latestNotifications,
  });

  final NutritionistProfileModel nutritionist;
  final DashboardSummaryModel summary;
  final List<ConsultationModel> latestConsultations;
  final List<NotificationModel> latestNotifications;

  factory DashboardNutritionistModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    return DashboardNutritionistModel(
      nutritionist: NutritionistProfileModel.fromJson(
        data['nutritionist'] is Map<String, dynamic>
            ? data['nutritionist'] as Map<String, dynamic>
            : data['profile'] is Map<String, dynamic>
            ? data['profile'] as Map<String, dynamic>
            : const {},
      ),
      summary: DashboardSummaryModel.fromJson(
        data['summary'] is Map<String, dynamic>
            ? data['summary'] as Map<String, dynamic>
            : data['stats'] is Map<String, dynamic>
            ? data['stats'] as Map<String, dynamic>
            : const {},
      ),
      latestConsultations:
          ((data['latest_consultations'] ?? data['rooms']) as List<dynamic>? ??
                  const [])
              .whereType<Map<String, dynamic>>()
              .map(ConsultationModel.fromJson)
              .toList(),
      latestNotifications:
          ((data['latest_notifications'] ?? data['activities'])
                      as List<dynamic>? ??
                  const [])
              .whereType<Map<String, dynamic>>()
              .map(NotificationModel.fromJson)
              .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'nutritionist': nutritionist.toJson(),
    'summary': summary.toJson(),
    'latest_consultations': latestConsultations.map((e) => e.toJson()).toList(),
    'latest_notifications': latestNotifications.map((e) => e.toJson()).toList(),
  };
}

int _int(dynamic value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
