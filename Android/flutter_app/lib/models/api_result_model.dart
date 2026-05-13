class ApiResultModel {
  const ApiResultModel({
    required this.identitas,
    required this.zScore,
    required this.kategori,
    required this.statusGabungan,
    required this.rekomendasi,
    this.measurement,
  });

  final IdentitasModel identitas;
  final ZScoreModel zScore;
  final KategoriModel kategori;
  final String statusGabungan;
  final List<RekomendasiModel> rekomendasi;
  final AnalysisMeasurementModel? measurement;

  factory ApiResultModel.fromJson(Map<String, dynamic> json) {
    return ApiResultModel(
      identitas: IdentitasModel.fromJson(
        json['identitas'] as Map<String, dynamic>? ?? const {},
      ),
      zScore: ZScoreModel.fromJson(
        json['zscore'] as Map<String, dynamic>? ?? const {},
      ),
      kategori: KategoriModel.fromJson(
        json['kategori'] as Map<String, dynamic>? ?? const {},
      ),
      statusGabungan: json['status_gabungan'] as String? ?? '-',
      rekomendasi: (json['rekomendasi'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(RekomendasiModel.fromJson)
          .toList(),
      measurement: json['measurement'] is Map<String, dynamic>
          ? AnalysisMeasurementModel.fromJson(
              json['measurement'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class AnalysisMeasurementModel {
  const AnalysisMeasurementModel({
    required this.id,
    required this.childId,
    required this.childName,
    required this.tanggalUkur,
    required this.caraUkur,
  });

  final int id;
  final int childId;
  final String childName;
  final String tanggalUkur;
  final String? caraUkur;

  factory AnalysisMeasurementModel.fromJson(Map<String, dynamic> json) {
    return AnalysisMeasurementModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      childId: (json['child_id'] as num?)?.toInt() ?? 0,
      childName: json['child_name'] as String? ?? '-',
      tanggalUkur: json['tanggal_ukur'] as String? ?? '-',
      caraUkur: json['cara_ukur'] as String?,
    );
  }
}

class IdentitasModel {
  const IdentitasModel({required this.umurBulan, required this.jenisKelamin});

  final double umurBulan;
  final String jenisKelamin;

  factory IdentitasModel.fromJson(Map<String, dynamic> json) {
    double parseNum(dynamic v) {
      if (v is num) return v.toDouble();
      return double.nan;
    }

    return IdentitasModel(
      umurBulan: parseNum(json['umur_bulan']),
      jenisKelamin: json['jenis_kelamin'] as String? ?? '-',
    );
  }
}

class ZScoreModel {
  const ZScoreModel({required this.bbu, required this.tbu, required this.bbtb});

  final double bbu;
  final double tbu;
  final double bbtb;

  factory ZScoreModel.fromJson(Map<String, dynamic> json) {
    double parseNum(dynamic v) {
      if (v is num) return v.toDouble();
      return double.nan;
    }

    return ZScoreModel(
      bbu: parseNum(json['bbu']),
      tbu: parseNum(json['tbu']),
      bbtb: parseNum(json['bbtb']),
    );
  }
}

class KategoriModel {
  const KategoriModel({
    required this.bbu,
    required this.tbu,
    required this.bbtb,
  });

  final String bbu;
  final String tbu;
  final String bbtb;

  factory KategoriModel.fromJson(Map<String, dynamic> json) {
    return KategoriModel(
      bbu: json['bbu'] as String? ?? '-',
      tbu: json['tbu'] as String? ?? '-',
      bbtb: json['bbtb'] as String? ?? '-',
    );
  }
}

class RekomendasiModel {
  const RekomendasiModel({
    required this.menu,
    required this.kalori,
    required this.protein,
    required this.lemak,
    required this.karbohidrat,
    required this.alasan,
  });

  final String menu;
  final int kalori;
  final int protein;
  final int lemak;
  final int karbohidrat;
  final String alasan;

  factory RekomendasiModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return 0;
    }

    return RekomendasiModel(
      menu: json['menu'] as String? ?? '-',
      kalori: parseInt(json['kalori']),
      protein: parseInt(json['protein']),
      lemak: parseInt(json['lemak']),
      karbohidrat: parseInt(json['karbohidrat']),
      alasan: json['alasan'] as String? ?? '-',
    );
  }
}
