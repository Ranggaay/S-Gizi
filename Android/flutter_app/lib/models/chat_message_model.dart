class ChatMessageModel {
  const ChatMessageModel({
    required this.id,
    required this.consultationId,
    required this.senderId,
    required this.senderRole,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  final int id;
  final int consultationId;
  final int senderId;
  final String senderRole;
  final String message;
  final bool isRead;
  final String createdAt;

  bool get fromNutritionist {
    final role = senderRole.toLowerCase();
    return role == 'nutritionist' || role == 'expert' || role == 'ahli_gizi';
  }

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: _int(json['id']),
      consultationId: _int(json['consultation_id'] ?? json['room_id']),
      senderId: _int(json['sender_id']),
      senderRole: _string(
        json['sender_role'] ?? json['sender_type'],
        fallback: 'parent',
      ),
      message: _string(json['message']),
      isRead: json['is_read'] == true,
      createdAt: _string(json['created_at'], fallback: '-'),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'consultation_id': consultationId,
    'sender_id': senderId,
    'sender_role': senderRole,
    'message': message,
    'is_read': isRead,
    'created_at': createdAt,
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
