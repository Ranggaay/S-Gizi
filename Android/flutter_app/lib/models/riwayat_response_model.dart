class RiwayatResponseModel {
  const RiwayatResponseModel({required this.child, required this.riwayat});

  final ChildInfoModel child;
  final List<RiwayatItemModel> riwayat;

  factory RiwayatResponseModel.fromJson(Map<String, dynamic> json) {
    final rawList = json['riwayat'];
    final items = rawList is List
        ? rawList
              .whereType<Map<String, dynamic>>()
              .map(RiwayatItemModel.fromJson)
              .toList()
        : <RiwayatItemModel>[];
    items.sort((a, b) {
      final ad = DateTime.tryParse(a.tanggalUkur) ?? DateTime(1900);
      final bd = DateTime.tryParse(b.tanggalUkur) ?? DateTime(1900);
      final dateCompare = ad.compareTo(bd);
      if (dateCompare != 0) return dateCompare;
      return a.id.compareTo(b.id);
    });

    return RiwayatResponseModel(
      child: ChildInfoModel.fromJson(
        json['child'] as Map<String, dynamic>? ?? const {},
      ),
      riwayat: items,
    );
  }
}

class ChildInfoModel {
  const ChildInfoModel({
    required this.id,
    required this.nama,
    required this.tanggalLahir,
    required this.jenisKelamin,
  });

  final int id;
  final String nama;
  final String tanggalLahir;
  final String jenisKelamin;

  factory ChildInfoModel.fromJson(Map<String, dynamic> json) {
    return ChildInfoModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      nama: json['nama'] as String? ?? '-',
      tanggalLahir: json['tanggal_lahir'] as String? ?? '-',
      jenisKelamin: json['jenis_kelamin'] as String? ?? '-',
    );
  }
}

class RiwayatKategoriModel {
  const RiwayatKategoriModel({
    required this.bbu,
    required this.tbu,
    required this.bbtb,
  });

  final String? bbu;
  final String? tbu;
  final String? bbtb;

  factory RiwayatKategoriModel.fromJson(Map<String, dynamic> json) {
    return RiwayatKategoriModel(
      bbu: json['bbu'] as String?,
      tbu: json['tbu'] as String?,
      bbtb: json['bbtb'] as String?,
    );
  }
}

class RiwayatItemModel {
  const RiwayatItemModel({
    required this.id,
    required this.berat,
    required this.tinggi,
    required this.tanggalUkur,
    required this.caraUkur,
    required this.umurBulan,
    required this.statusGabungan,
    required this.kategori,
    required this.zBbu,
    required this.zTbu,
    required this.zBbtb,
    this.isAnomaly = false,
    this.dataStatus = 'normal',
  });

  final int id;
  final double berat;
  final double tinggi;
  final String tanggalUkur;
  final String? caraUkur;
  final double umurBulan;
  final String statusGabungan;
  final RiwayatKategoriModel kategori;
  final double? zBbu;
  final double? zTbu;
  final double? zBbtb;
  final bool isAnomaly;
  final String dataStatus;

  factory RiwayatItemModel.fromJson(Map<String, dynamic> json) {
    final z = json['z_score'] as Map<String, dynamic>? ?? const {};
    final kategori = json['kategori'] as Map<String, dynamic>? ?? const {};
    double? parseNullableNum(dynamic v) => v is num ? v.toDouble() : null;

    return RiwayatItemModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      berat: (json['berat'] as num?)?.toDouble() ?? double.nan,
      tinggi: (json['tinggi'] as num?)?.toDouble() ?? double.nan,
      tanggalUkur: json['tanggal_ukur'] as String? ?? '-',
      caraUkur: json['cara_ukur'] as String?,
      umurBulan: (json['umur_bulan'] as num?)?.toDouble() ?? double.nan,
      statusGabungan: json['status_gabungan'] as String? ?? '-',
      kategori: RiwayatKategoriModel.fromJson(kategori),
      zBbu: parseNullableNum(z['bbu']),
      zTbu: parseNullableNum(z['tbu']),
      zBbtb: parseNullableNum(z['bbtb']),
      isAnomaly: json['is_anomaly'] == true,
      dataStatus: json['data_status'] as String? ?? 'normal',
    );
  }
}
