class NutritionistProfileModel {
  const NutritionistProfileModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.profession,
    required this.workplace,
    this.photo,
    required this.isActive,
  });

  final int id;
  final String name;
  final String phone;
  final String email;
  final String profession;
  final String workplace;
  final String? photo;
  final bool isActive;

  factory NutritionistProfileModel.fromJson(Map<String, dynamic> json) {
    return NutritionistProfileModel(
      id: _int(json['id']),
      name: _string(json['name'], fallback: 'Ahli Gizi'),
      phone: _string(json['phone'], fallback: '-'),
      email: _string(json['email'], fallback: '-'),
      profession: _string(json['profession'], fallback: 'Ahli Gizi'),
      workplace: _string(json['workplace'], fallback: '-'),
      photo: json['photo'] as String?,
      isActive: json['is_active'] != false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'email': email,
    'profession': profession,
    'workplace': workplace,
    'photo': photo,
    'is_active': isActive,
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
