import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:s_gizi/app_state.dart';
import 'package:s_gizi/models/dashboard_nutritionist_model.dart';
import 'package:s_gizi/services/api_service.dart';

class NutritionistDashboardService {
  NutritionistDashboardService({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? ApiService().baseUrl;

  final http.Client _client;
  final String _baseUrl;

  Future<DashboardNutritionistModel> getDashboard() async {
    final token = _token();
    final response = await _client
        .get(
          Uri.parse('$_baseUrl/nutritionist/dashboard'),
          headers: _headers(token),
        )
        .timeout(const Duration(seconds: 12));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_message(response.body, 'Gagal memuat dashboard.'));
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Response dashboard tidak valid.');
    }
    return DashboardNutritionistModel.fromJson(decoded);
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
