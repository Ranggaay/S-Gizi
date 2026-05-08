import 'api_result_model.dart';

class RecommendationResponseModel {
  const RecommendationResponseModel({
    required this.requestedStatus,
    required this.resolvedStatus,
    required this.primaryCategory,
    required this.matchedCategories,
    required this.items,
    this.measurement,
  });

  final String requestedStatus;
  final String resolvedStatus;
  final String primaryCategory;
  final List<String> matchedCategories;
  final List<RekomendasiModel> items;
  final RecommendationMeasurementModel? measurement;

  factory RecommendationResponseModel.fromJson(Map<String, dynamic> json) {
    final normalized =
        json['normalized_status'] as Map<String, dynamic>? ?? const {};
    final rawCategories = normalized['matched_categories'];

    return RecommendationResponseModel(
      requestedStatus: json['requested_status'] as String? ?? '-',
      resolvedStatus:
          json['resolved_status'] as String? ??
          json['status'] as String? ??
          '-',
      primaryCategory: normalized['primary_category'] as String? ?? 'Normal',
      matchedCategories: rawCategories is List
          ? rawCategories.whereType<String>().toList()
          : const ['Normal'],
      items: (json['data'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(RekomendasiModel.fromJson)
          .toList(),
      measurement: json['measurement'] is Map<String, dynamic>
          ? RecommendationMeasurementModel.fromJson(
              json['measurement'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class RecommendationMeasurementModel {
  const RecommendationMeasurementModel({
    required this.id,
    required this.childId,
    required this.childName,
    required this.tanggalUkur,
    required this.umurBulan,
  });

  final int id;
  final int childId;
  final String childName;
  final String? tanggalUkur;
  final double? umurBulan;

  factory RecommendationMeasurementModel.fromJson(Map<String, dynamic> json) {
    return RecommendationMeasurementModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      childId: (json['child_id'] as num?)?.toInt() ?? 0,
      childName: json['child_name'] as String? ?? '-',
      tanggalUkur: json['tanggal_ukur'] as String?,
      umurBulan: (json['umur_bulan'] as num?)?.toDouble(),
    );
  }
}
