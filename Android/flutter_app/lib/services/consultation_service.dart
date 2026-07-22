import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:s_gizi/app_state.dart';
import 'package:s_gizi/models/chat_message_model.dart';
import 'package:s_gizi/models/child_chat_detail_model.dart';
import 'package:s_gizi/models/consultation_model.dart';
import 'package:s_gizi/services/api_service.dart';

class ConsultationService {
  ConsultationService({ApiService? api, http.Client? client, String? baseUrl})
    : _api = api ?? ApiService(),
      _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? ApiService().baseUrl;

  final ApiService _api;
  final http.Client _client;
  final String _baseUrl;

  Future<List<ConsultationModel>> getConsultations({
    String search = '',
    String filter = 'all',
  }) async {
    final token = _token();
    final uri = Uri.parse('$_baseUrl/nutritionist/consultations').replace(
      queryParameters: {
        if (search.trim().isNotEmpty) 'search': search.trim(),
        if (filter != 'all') 'filter': filter,
      },
    );
    final response = await _client
        .get(uri, headers: _headers(token))
        .timeout(const Duration(seconds: 12));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_message(response.body, 'Gagal memuat konsultasi.'));
    }
    final decoded = jsonDecode(response.body);
    final raw = decoded is Map<String, dynamic> ? decoded['data'] : decoded;
    if (raw is! List) throw Exception('Response konsultasi tidak valid.');
    return raw
        .whereType<Map<String, dynamic>>()
        .map(ConsultationModel.fromJson)
        .toList();
  }

  Future<Map<String, dynamic>> getMessages(int consultationId) {
    return _api.getNutritionistRoomMessages(roomId: consultationId);
  }

  Future<List<ChatMessageModel>> getChatMessages(int consultationId) async {
    final json = await getMessages(consultationId);
    final list = json['data'] as List<dynamic>? ?? const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(ChatMessageModel.fromJson)
        .toList();
  }

  Future<Map<String, dynamic>> sendMessage({
    required int consultationId,
    required String message,
  }) {
    return _api.sendNutritionistMessage(
      roomId: consultationId,
      message: message,
    );
  }

  Future<void> closeConsultation(int consultationId) async {
    final token = _token();
    final response = await _client
        .post(
          Uri.parse(
            '$_baseUrl/nutritionist/consultations/$consultationId/close',
          ),
          headers: _headers(token),
        )
        .timeout(const Duration(seconds: 12));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _message(response.body, 'Gagal menandai konsultasi selesai.'),
      );
    }
  }

  Future<ChildChatDetailModel> getChildDetailFromChat(
    int consultationId,
  ) async {
    final token = _token();
    final response = await _client
        .get(
          Uri.parse(
            '$_baseUrl/nutritionist/consultations/$consultationId/child-detail',
          ),
          headers: _headers(token),
        )
        .timeout(const Duration(seconds: 12));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_message(response.body, 'Gagal memuat detail anak.'));
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Response detail anak tidak valid.');
    }
    final data = decoded['data'] is Map<String, dynamic>
        ? decoded['data'] as Map<String, dynamic>
        : decoded;
    return ChildChatDetailModel.fromJson(data);
  }

  Future<void> saveNote({
    required int consultationId,
    required String category,
    required String note,
  }) async {
    final token = _token();
    final response = await _client
        .post(
          Uri.parse(
            '$_baseUrl/nutritionist/consultations/$consultationId/notes',
          ),
          headers: _headers(token),
          body: jsonEncode({'category': category, 'note': note}),
        )
        .timeout(const Duration(seconds: 12));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_message(response.body, 'Gagal menyimpan catatan.'));
    }
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
