class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.childName,
    required this.priority,
    required this.time,
    required this.isRead,
  });

  final int id;
  final String type;
  final String title;
  final String description;
  final String childName;
  final String priority;
  final String time;
  final bool isRead;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: _int(json['id']),
      type: _string(json['type'], fallback: 'info'),
      title: _string(json['title'], fallback: 'Notifikasi'),
      description: _string(json['description'] ?? json['message']),
      childName: _string(json['child_name']),
      priority: _string(json['priority'], fallback: 'Sedang'),
      time: _string(json['time'], fallback: '-'),
      isRead: json['is_read'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'title': title,
    'description': description,
    'child_name': childName,
    'priority': priority,
    'time': time,
    'is_read': isRead,
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
