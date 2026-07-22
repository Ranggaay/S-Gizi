String parentGreetingFromProfile(Map<String, dynamic>? profile) {
  final raw = _parentGenderValue(profile);
  if (_isFather(raw)) return 'Halo, Ayah';
  if (_isMother(raw)) return 'Halo, Bunda';
  return 'Halo, Ayah & Bunda';
}

String parentGenderLabel(String? raw) {
  final value = raw?.trim().toLowerCase() ?? '';
  if (_isFather(value)) return 'Ayah';
  if (_isMother(value)) return 'Bunda';
  return '';
}

String _parentGenderValue(Map<String, dynamic>? profile) {
  if (profile == null) return '';
  for (final key in const [
    'parent_gender',
    'parentGender',
    'gender',
    'jenis_kelamin',
  ]) {
    final value = profile[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim().toLowerCase();
    }
  }
  return '';
}

bool _isFather(String value) {
  return value == 'ayah' ||
      value == 'l' ||
      value == 'laki-laki' ||
      value == 'laki_laki' ||
      value == 'male' ||
      value == 'pria';
}

bool _isMother(String value) {
  return value == 'bunda' ||
      value == 'ibu' ||
      value == 'p' ||
      value == 'perempuan' ||
      value == 'female' ||
      value == 'wanita';
}
