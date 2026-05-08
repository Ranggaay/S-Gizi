import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;

import '../app_state.dart';
import '../models/api_result_model.dart';
import '../models/mobile_child_model.dart';
import '../models/news_article_model.dart';
import '../models/recommendation_response_model.dart';
import '../models/riwayat_response_model.dart';

class ApiService {
  ApiService({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      baseUrl = baseUrl ?? _resolveDefaultBaseUrl();

  final http.Client _client;
  final String baseUrl;

  static String _resolveDefaultBaseUrl() {
    // Web -> localhost browser, Android emulator -> 10.0.2.2
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api';
    }
    return 'http://10.0.2.2:8000/api';
  }

  Future<Map<String, dynamic>> hitungGizi(Map<String, dynamic> data) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/gizi/hitung'),
      headers: _headers(),
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Format response API tidak valid.');
      }
      return decoded;
    }

    throw Exception('Gagal API (${response.statusCode}): ${response.body}');
  }

  Future<void> sendOtp(String phone) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/send-otp'),
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'phone': phone}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Gagal mengirim OTP: ${response.body}');
    }
  }

  Future<String> verifyOtp(String phone, String otp) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/verify-otp'),
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'phone': phone, 'otp': otp}),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Format response API tidak valid.');
      }
      final token = decoded['token'] as String? ?? '';
      if (token.isEmpty) throw Exception('Token login kosong.');
      return token;
    }

    throw Exception('OTP tidak valid: ${response.body}');
  }

  Future<List<MobileChildModel>> getChildren() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/children'),
      headers: _headers(),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Gagal mengambil data anak: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    final list = decoded is Map<String, dynamic> ? decoded['data'] : null;
    if (list is! List) return const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(MobileChildModel.fromJson)
        .toList();
  }

  Future<MobileChildModel> createChild(Map<String, dynamic> data) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/children'),
      headers: _headers(),
      body: jsonEncode({
        'nama_anak': data['nama_anak'] ?? data['nama'],
        'tanggal_lahir': data['tanggal_lahir'],
        'jenis_kelamin': data['jenis_kelamin'],
      }),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Gagal menyimpan data anak: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> ||
        decoded['data'] is! Map<String, dynamic>) {
      throw Exception('Format data anak tidak valid.');
    }

    return MobileChildModel.fromJson(decoded['data'] as Map<String, dynamic>);
  }

  Future<MobileChildModel> updateChild({
    required int childId,
    required Map<String, dynamic> data,
  }) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/children/$childId'),
      headers: _headers(),
      body: jsonEncode({
        if (data['nama'] != null) 'nama': data['nama'],
        if (data['nama_anak'] != null) 'nama_anak': data['nama_anak'],
        if (data['tanggal_lahir'] != null) 'tanggal_lahir': data['tanggal_lahir'],
        if (data['jenis_kelamin'] != null) 'jenis_kelamin': data['jenis_kelamin'],
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Gagal memperbarui data anak: ${response.body}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['data'] is! Map<String, dynamic>) {
      throw Exception('Format response update anak tidak valid.');
    }
    return MobileChildModel.fromJson(decoded['data'] as Map<String, dynamic>);
  }

  Future<void> deleteChild({required int childId}) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/children/$childId'),
      headers: _headers(),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Gagal menghapus data anak: ${response.body}');
    }
  }

  Future<ApiResultModel> postHasil(Map<String, dynamic> data) async {
    final json = await hitungGizi(data);
    return ApiResultModel.fromJson(json);
  }

  Future<RiwayatResponseModel> getRiwayat({required int childId}) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/riwayat/$childId'),
      headers: _headers(),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Gagal mengambil riwayat. Status code: ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Format response API tidak valid.');
    }

    return RiwayatResponseModel.fromJson(decoded);
  }

  Future<RecommendationResponseModel> getRecommendations({
    required String status,
    int? childId,
    int? riwayatId,
  }) async {
    final encodedStatus = Uri.encodeComponent(status.isEmpty ? 'latest' : status);
    final uri = Uri.parse('$baseUrl/rekomendasi/$encodedStatus').replace(
      queryParameters: {
        if (childId != null) 'child_id': '$childId',
        if (riwayatId != null) 'riwayat_id': '$riwayatId',
      },
    );
    final response = await _client.get(
      uri,
      headers: _headers(),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Gagal mengambil rekomendasi. Status code: ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Format response rekomendasi tidak valid.');
    }
    return RecommendationResponseModel.fromJson(decoded);
  }

  Future<List<NewsArticleModel>> getNewsArticles({
    String query =
        'kesehatan anak gizi balita stunting mpasi tumbuh kembang protein anak parenting kesehatan who nutrition imunisasi kesehatan ibu anak',
  }) async {
    // Online/Internet (Google News RSS) tetap lewat endpoint `/news`
    // agar tidak bentrok dengan `/articles` yang sekarang khusus DB admin.
    final uri = Uri.parse('$baseUrl/news').replace(queryParameters: {'q': query});
    final response = await _client.get(uri, headers: _headers());
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Gagal mengambil artikel berita. Status code: ${response.statusCode}',
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Format response artikel tidak valid.');
    }
    final data = decoded['data'];
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(NewsArticleModel.fromJson)
        .toList();
  }

  Future<Map<String, dynamic>> getProfile() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/profile'),
      headers: _headers(),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Gagal mengambil profil: ${response.body}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['data'] is! Map<String, dynamic>) {
      throw Exception('Format profil tidak valid.');
    }
    return decoded['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String phone,
    String? email,
  }) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/profile'),
      headers: _headers(),
      body: jsonEncode({
        'name': name,
        'phone': phone,
        'email': (email ?? '').trim().isEmpty ? null : email?.trim(),
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Gagal memperbarui profil: ${response.body}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['data'] is! Map<String, dynamic>) {
      throw Exception('Format update profil tidak valid.');
    }
    return decoded['data'] as Map<String, dynamic>;
  }

  /// Ambil artikel dari database `s_gizi` (tanpa query News API).
  Future<List<NewsArticleModel>> getArticlesDb() async {
    final uri = Uri.parse('$baseUrl/articles');
    final response = await _client.get(uri, headers: _headers());
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Gagal mengambil artikel. Status code: ${response.statusCode}',
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Format response artikel tidak valid.');
    }
    final data = decoded['data'];
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(NewsArticleModel.fromJson)
        .toList();
  }

  Map<String, String> _headers() {
    final token = SgiziAppState.instance.authToken;
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}
