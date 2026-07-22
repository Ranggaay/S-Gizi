class NutritionistNoteModel {
  const NutritionistNoteModel({
    required this.id,
    required this.childId,
    required this.note,
    required this.createdAt,
  });

  final int id;
  final int childId;
  final String note;
  final String createdAt;

  factory NutritionistNoteModel.fromJson(Map<String, dynamic> json) {
    return NutritionistNoteModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      childId: (json['child_id'] as num?)?.toInt() ?? 0,
      note: json['note'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'child_id': childId,
    'note': note,
    'created_at': createdAt,
  };
}
