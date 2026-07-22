class MobileChildModel {
  const MobileChildModel({
    required this.id,
    required this.nama,
    required this.tanggalLahir,
    required this.jenisKelamin,
    this.latestStatus,
    this.latestMeasurementAt,
  });

  final int id;
  final String nama;
  final String tanggalLahir;
  final String jenisKelamin;
  final String? latestStatus;
  final String? latestMeasurementAt;

  factory MobileChildModel.fromJson(Map<String, dynamic> json) {
    return MobileChildModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      nama: json['nama'] as String? ?? '-',
      tanggalLahir: json['tanggal_lahir'] as String? ?? '-',
      jenisKelamin: json['jenis_kelamin'] as String? ?? '-',
      latestStatus: json['latest_status'] as String?,
      latestMeasurementAt: json['latest_measurement_at'] as String?,
    );
  }

  MobileChildModel copyWith({
    int? id,
    String? nama,
    String? tanggalLahir,
    String? jenisKelamin,
    String? latestStatus,
    String? latestMeasurementAt,
  }) {
    return MobileChildModel(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      tanggalLahir: tanggalLahir ?? this.tanggalLahir,
      jenisKelamin: jenisKelamin ?? this.jenisKelamin,
      latestStatus: latestStatus ?? this.latestStatus,
      latestMeasurementAt: latestMeasurementAt ?? this.latestMeasurementAt,
    );
  }
}
