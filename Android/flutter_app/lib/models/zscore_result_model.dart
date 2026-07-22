class ZScoreResultModel {
  const ZScoreResultModel({
    required this.bbuScore,
    required this.bbuStatus,
    required this.tbuScore,
    required this.tbuStatus,
    required this.bbtbScore,
    required this.bbtbStatus,
  });

  final double bbuScore;
  final String bbuStatus;
  final double tbuScore;
  final String tbuStatus;
  final double bbtbScore;
  final String bbtbStatus;

  factory ZScoreResultModel.fromJson(Map<String, dynamic> json) {
    return ZScoreResultModel(
      bbuScore: _double(json['bbu_score']),
      bbuStatus: _string(json['bbu_status'], fallback: '-'),
      tbuScore: _double(json['tbu_score']),
      tbuStatus: _string(json['tbu_status'], fallback: '-'),
      bbtbScore: _double(json['bbtb_score']),
      bbtbStatus: _string(json['bbtb_status'], fallback: '-'),
    );
  }

  Map<String, dynamic> toJson() => {
    'bbu_score': bbuScore,
    'bbu_status': bbuStatus,
    'tbu_score': tbuScore,
    'tbu_status': tbuStatus,
    'bbtb_score': bbtbScore,
    'bbtb_status': bbtbStatus,
  };
}

String _string(dynamic value, {String fallback = ''}) {
  if (value is String && value.trim().isNotEmpty) return value.trim();
  return fallback;
}

double _double(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}
