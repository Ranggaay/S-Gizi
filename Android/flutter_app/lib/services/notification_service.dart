import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:s_gizi/app_state.dart';
import 'package:s_gizi/models/notification_model.dart';
import 'package:s_gizi/services/api_service.dart';

class NotificationService {
  NotificationService({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? ApiService().baseUrl;

  final http.Client _client;
  final String _baseUrl;

  Future<List<NotificationModel>> getNotifications({
    String filter = 'all',
  }) async {
    final token = _token();
    final uri = Uri.parse(
      '$_baseUrl/nutritionist/notifications',
    ).replace(queryParameters: {if (filter != 'all') 'filter': filter});
    final response = await _client
        .get(uri, headers: _headers(token))
        .timeout(const Duration(seconds: 12));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_message(response.body, 'Gagal memuat notifikasi.'));
    }
    final decoded = jsonDecode(response.body);
    final raw = decoded is Map<String, dynamic> ? decoded['data'] : decoded;
    if (raw is! List) throw Exception('Response notifikasi tidak valid.');
    return raw
        .whereType<Map<String, dynamic>>()
        .map(NotificationModel.fromJson)
        .toList();
  }

  Future<void> markRead(int id) async {
    final token = _token();
    await _client.post(
      Uri.parse('$_baseUrl/nutritionist/notifications/$id/read'),
      headers: _headers(token),
    );
  }

  Future<void> readAll() async {
    final token = _token();
    await _client.post(
      Uri.parse('$_baseUrl/nutritionist/notifications/read-all'),
      headers: _headers(token),
    );
  }

  String _token() {
    final token = SgiziAppState.instance.authToken;
    if (token == null || token.isEmpty) {
      throw Exception('Token kosong. Silakan login ulang.');
    }
    return token;
  }

  Map<String, String> _headers(String token) => {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  String _message(String body, String fallback) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic> && decoded['message'] is String) {
        return decoded['message'] as String;
      }
    } catch (_) {}
    return fallback;
  }
}
