class ConsultationModel {
  const ConsultationModel({
    required this.id,
    required this.parentName,
    required this.childName,
    required this.childAge,
    required this.riskStatus,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.status,
  });

  final int id;
  final String parentName;
  final String childName;
  final String childAge;
  final String riskStatus;
  final String lastMessage;
  final String lastMessageTime;
  final int unreadCount;
  final String status;

  bool get isClosed {
    final value = status.toLowerCase();
    return value == 'closed' || value == 'selesai' || value == 'resolved';
  }

  factory ConsultationModel.fromJson(Map<String, dynamic> json) {
    return ConsultationModel(
      id: _int(json['id']),
      parentName: _string(json['parent_name'], fallback: 'Orang Tua'),
      childName: _string(json['child_name'], fallback: 'Anak'),
      childAge: _string(json['child_age'], fallback: '-'),
      riskStatus: _riskLabel(json['risk_status'] ?? json['risk']),
      lastMessage: _string(json['last_message'], fallback: 'Belum ada pesan.'),
      lastMessageTime: _string(
        json['last_message_time'] ??
            json['last_message_at'] ??
            json['updated_at'],
        fallback: '-',
      ),
      unreadCount: _int(json['unread_count']),
      status: _string(
        json['status'] ?? json['room_status'],
        fallback: 'active',
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'parent_name': parentName,
    'child_name': childName,
    'child_age': childAge,
    'risk_status': riskStatus,
    'last_message': lastMessage,
    'last_message_time': lastMessageTime,
    'unread_count': unreadCount,
    'status': status,
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

String _riskLabel(dynamic value) {
  final raw = _string(value, fallback: 'Normal');
  switch (raw.toLowerCase()) {
    case 'high':
      return 'Risiko Tinggi';
    case 'warning':
      return 'Perlu Dipantau';
    default:
      return raw;
  }
}
