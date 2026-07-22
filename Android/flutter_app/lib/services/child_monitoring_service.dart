import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:s_gizi/app_state.dart';
import 'package:s_gizi/models/child_detail_model.dart';
import 'package:s_gizi/models/child_monitoring_model.dart';
import 'package:s_gizi/services/api_service.dart';

class ChildMonitoringResponse {
  const ChildMonitoringResponse({
    required this.summary,
    required this.children,
  });

  final ChildMonitoringSummary summary;
  final List<ChildMonitoringModel> children;
}

class ChildMonitoringService {
  ChildMonitoringService({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? ApiService().baseUrl;

  final http.Client _client;
  final String _baseUrl;

  Future<ChildMonitoringResponse> getChildren({
    String search = '',
    String filter = 'all',
  }) async {
    final token = SgiziAppState.instance.authToken;
    if (token == null || token.isEmpty) {
      throw Exception('Token kosong. Silakan login ulang.');
    }

    final uri = Uri.parse('$_baseUrl/nutritionist/children').replace(
      queryParameters: {
        if (search.trim().isNotEmpty) 'search': search.trim(),
        if (filter != 'all') 'filter': filter,
      },
    );
    final response = await _client
        .get(uri, headers: _headers(token))
        .timeout(const Duration(seconds: 12));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _messageFromBody(response.body, 'Gagal memuat data anak.'),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Response data anak tidak valid.');
    }
    final data = decoded['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Data anak kosong atau tidak valid.');
    }

    final summary = data['summary'] is Map<String, dynamic>
        ? ChildMonitoringSummary.fromJson(
            data['summary'] as Map<String, dynamic>,
          )
        : ChildMonitoringSummary.empty;
    final children = (data['children'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(ChildMonitoringModel.fromJson)
        .toList();
    return ChildMonitoringResponse(summary: summary, children: children);
  }

  Future<ChildDetailModel> getChildDetail(int childId) async {
    final token = SgiziAppState.instance.authToken;
    if (token == null || token.isEmpty) {
      throw Exception('Token kosong. Silakan login ulang.');
    }

    final uri = Uri.parse('$_baseUrl/nutritionist/children/$childId');
    final response = await _client
        .get(uri, headers: _headers(token))
        .timeout(const Duration(seconds: 12));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _messageFromBody(response.body, 'Gagal memuat detail anak.'),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> ||
        decoded['data'] is! Map<String, dynamic>) {
      throw Exception('Response detail anak tidak valid.');
    }
    return ChildDetailModel.fromJson(decoded['data'] as Map<String, dynamic>);
  }

  Map<String, String> _headers(String token) => {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  String _messageFromBody(String body, String fallback) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'];
        if (message is String && message.trim().isNotEmpty) return message;
      }
    } catch (_) {}
    return fallback;
  }
}
