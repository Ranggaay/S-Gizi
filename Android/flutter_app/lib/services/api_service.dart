import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;

import 'package:s_gizi/app_state.dart';
import 'package:s_gizi/models/api_result_model.dart';
import 'package:s_gizi/models/mobile_child_model.dart';
import 'package:s_gizi/models/news_article_model.dart';
import 'package:s_gizi/models/recommendation_response_model.dart';
import 'package:s_gizi/models/riwayat_response_model.dart';

class ApiService {
  ApiService({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      baseUrl = baseUrl ?? _resolveDefaultBaseUrl();

  final http.Client _client;
  final String baseUrl;

  static String _resolveDefaultBaseUrl() {
    const configured = String.fromEnvironment('SGIZI_API_BASE_URL');
    if (configured.isNotEmpty) return configured;

    // Override for physical devices:
    // flutter run --dart-define=SGIZI_API_BASE_URL=http://<LAN-IP>:8000/api
    if (kIsWeb) {
      return 'http://192.168.1.69:8000/api';
    }
    return 'http://192.168.1.69:8000/api';
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

  Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'phone': phone, 'password': password}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_messageFromBody(response.body, 'Login gagal.'));
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Format response login tidak valid.');
    }

    final token = decoded['token'] as String? ?? '';
    if (token.isEmpty) throw Exception('Token login kosong.');

    final userJson = decoded['user'];
    if (userJson is Map<String, dynamic>) {
      await SgiziAppState.instance.saveSession(
        token: token,
        role: (userJson['role'] as String? ?? 'orang_tua').trim().toLowerCase(),
        user: Map<String, dynamic>.from(userJson),
      );
    }

    return decoded;
  }

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

  Future<void> registerSendOtp({
    required String name,
    required String phone,
    required String parentGender,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/auth/register/send-otp'),
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'phone': phone,
        'parent_gender': parentGender,
        'password': password,
        'password_confirmation': passwordConfirmation,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_messageFromBody(response.body, 'Gagal mengirim OTP.'));
    }
  }

  Future<Map<String, dynamic>> registerVerifyOtp({
    required String phone,
    required String otp,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/auth/register/verify'),
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'phone': phone, 'otp': otp}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_messageFromBody(response.body, 'OTP tidak valid.'));
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Format response verifikasi tidak valid.');
    }

    final token = decoded['token'] as String? ?? '';
    if (token.isEmpty) throw Exception('Token registrasi kosong.');

    final userJson = decoded['user'];
    if (userJson is Map<String, dynamic>) {
      await SgiziAppState.instance.saveSession(
        token: token,
        role: (userJson['role'] as String? ?? 'orang_tua').trim().toLowerCase(),
        user: Map<String, dynamic>.from(userJson),
      );
    }

    return decoded;
  }

  Future<void> forgotPassword({required String phone}) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/auth/forgot-password'),
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'phone': phone}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_messageFromBody(response.body, 'Gagal mengirim OTP.'));
    }
  }

  Future<Map<String, dynamic>> resetPassword({
    required String phone,
    required String otp,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/auth/reset-password'),
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'phone': phone,
        'otp': otp,
        'password': password,
        'password_confirmation': passwordConfirmation,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_messageFromBody(response.body, 'Gagal reset password.'));
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Format response reset password tidak valid.');
    }

    final token = decoded['token'] as String? ?? '';
    if (token.isNotEmpty) {
      final userJson = decoded['user'];
      if (userJson is Map<String, dynamic>) {
        await SgiziAppState.instance.saveSession(
          token: token,
          role: (userJson['role'] as String? ?? 'orang_tua')
              .trim()
              .toLowerCase(),
          user: Map<String, dynamic>.from(userJson),
        );
      }
    }

    return decoded;
  }

  Future<Map<String, dynamic>> verifyForgotPasswordOtp({
    required String phone,
    required String otp,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/auth/forgot-password/verify'),
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'phone': phone, 'otp': otp}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_messageFromBody(response.body, 'Gagal verifikasi OTP.'));
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Format response verifikasi OTP tidak valid.');
    }
    return decoded;
  }

  Future<List<MobileChildModel>> getChildren() async {
    final response = await _client
        .get(Uri.parse('$baseUrl/children'), headers: _headers())
        .timeout(const Duration(seconds: 12));

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
        if (data['tanggal_lahir'] != null)
          'tanggal_lahir': data['tanggal_lahir'],
        if (data['jenis_kelamin'] != null)
          'jenis_kelamin': data['jenis_kelamin'],
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Gagal memperbarui data anak: ${response.body}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> ||
        decoded['data'] is! Map<String, dynamic>) {
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
    final response = await _client
        .get(Uri.parse('$baseUrl/riwayat/$childId'), headers: _headers())
        .timeout(const Duration(seconds: 12));

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
    final encodedStatus = Uri.encodeComponent(
      status.isEmpty ? 'latest' : status,
    );
    final uri = Uri.parse('$baseUrl/rekomendasi/$encodedStatus').replace(
      queryParameters: {
        if (childId != null) 'child_id': '$childId',
        if (riwayatId != null) 'riwayat_id': '$riwayatId',
      },
    );
    final response = await _client.get(uri, headers: _headers());

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
    final uri = Uri.parse(
      '$baseUrl/news',
    ).replace(queryParameters: {'q': query});
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
    final response = await _client
        .get(Uri.parse('$baseUrl/profile'), headers: _headers())
        .timeout(const Duration(seconds: 12));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Gagal mengambil profil: ${response.body}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> ||
        decoded['data'] is! Map<String, dynamic>) {
      throw Exception('Format profil tidak valid.');
    }
    return decoded['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String phone,
    String? email,
    String? gender,
    String? birthDate,
    String? specialization,
    String? experience,
    String? strSip,
  }) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/profile'),
      headers: _headers(),
      body: jsonEncode({
        'name': name,
        'phone': phone,
        'email': (email ?? '').trim().isEmpty ? null : email?.trim(),
        if ((gender ?? '').trim().isNotEmpty) 'parent_gender': gender!.trim(),
        if ((birthDate ?? '').trim().isNotEmpty)
          'tanggal_lahir': birthDate!.trim(),
        if ((specialization ?? '').trim().isNotEmpty)
          'specialization': specialization!.trim(),
        if ((experience ?? '').trim().isNotEmpty)
          'experience': experience!.trim(),
        if ((strSip ?? '').trim().isNotEmpty) 'str_sip': strSip!.trim(),
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Gagal memperbarui profil: ${response.body}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> ||
        decoded['data'] is! Map<String, dynamic>) {
      throw Exception('Format update profil tidak valid.');
    }
    return decoded['data'] as Map<String, dynamic>;
  }

  Future<void> updatePassword({
    required String oldPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/profile/password'),
      headers: _headers(),
      body: jsonEncode({
        'old_password': oldPassword,
        'password': newPassword,
        'password_confirmation': newPasswordConfirmation,
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _messageFromBody(response.body, 'Password lama tidak sesuai.'),
      );
    }
  }

  Future<void> logoutAllDevices() async {
    final response = await _client.post(
      Uri.parse('$baseUrl/profile/logout-all'),
      headers: _headers(),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _messageFromBody(response.body, 'Gagal logout semua perangkat.'),
      );
    }
  }

  Future<void> deleteAccount() async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/profile'),
      headers: _headers(),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_messageFromBody(response.body, 'Gagal menghapus akun.'));
    }
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

  Future<List<Map<String, dynamic>>> getConsultationRooms({
    required int childId,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/consultation/rooms',
    ).replace(queryParameters: {'child_id': '$childId'});
    final response = await _client.get(uri, headers: _headers());
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Gagal mengambil room konsultasi: ${response.body}');
    }
    final decoded = jsonDecode(response.body);
    final data = decoded is Map<String, dynamic> ? decoded['data'] : null;
    if (data is! List) return const [];
    return data.whereType<Map<String, dynamic>>().toList();
  }

  Future<List<Map<String, dynamic>>> getNutritionists() async {
    final response = await _client
        .get(Uri.parse('$baseUrl/nutritionists'), headers: _headers())
        .timeout(const Duration(seconds: 12));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _messageFromBody(response.body, 'Gagal memuat ahli gizi.'),
      );
    }
    final decoded = jsonDecode(response.body);
    final data = decoded is Map<String, dynamic> ? decoded['data'] : null;
    if (data is! List) return const [];
    return data.whereType<Map<String, dynamic>>().toList();
  }

  Future<Map<String, dynamic>> openConsultationRoom({
    required int childId,
    required String expertId,
    required String expertName,
    required String specialization,
    required String assetImage,
    required bool online,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/consultation/rooms'),
      headers: _headers(),
      body: jsonEncode({
        'child_id': childId,
        'expert_id': expertId,
        'expert_name': expertName,
        'specialization': specialization,
        'asset_image': assetImage,
        'online': online,
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Gagal membuka room konsultasi: ${response.body}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> ||
        decoded['data'] is! Map<String, dynamic>) {
      throw Exception('Format room konsultasi tidak valid.');
    }
    return decoded['data'] as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getConsultationMessages({
    required int roomId,
  }) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/consultation/rooms/$roomId/messages'),
      headers: _headers(),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Gagal mengambil messages konsultasi: ${response.body}');
    }
    final decoded = jsonDecode(response.body);
    final data = decoded is Map<String, dynamic> ? decoded['data'] : null;
    if (data is! List) return const [];
    return data.whereType<Map<String, dynamic>>().toList();
  }

  Future<Map<String, dynamic>> sendConsultationMessage({
    required int roomId,
    required String message,
    int? measurementId,
  }) async {
    final body = <String, dynamic>{'message': message};
    if (measurementId != null) {
      body['measurement_id'] = measurementId;
    }
    final response = await _client.post(
      Uri.parse('$baseUrl/consultation/rooms/$roomId/messages'),
      headers: _headers(),
      body: jsonEncode(body),
    );
    debugPrint(
      '[sendConsultationMessage] status=${response.statusCode} body=${response.body}',
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Gagal kirim pesan konsultasi: ${response.body}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Format response kirim pesan tidak valid.');
    }
    final data = decoded['data'];
    if (data is Map<String, dynamic>) return data;

    final status = decoded['status'] == true || decoded['success'] == true;
    if (status || decoded.containsKey('message')) return decoded;

    throw Exception('Format response kirim pesan tidak valid.');
  }

  Future<Map<String, dynamic>> sendConsultationExpertReply({
    required int roomId,
    required String message,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/consultation/rooms/$roomId/expert-reply'),
      headers: _headers(),
      body: jsonEncode({'message': message}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Gagal kirim balasan ahli: ${response.body}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> ||
        decoded['data'] is! Map<String, dynamic>) {
      throw Exception('Format response balasan ahli tidak valid.');
    }
    return decoded['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getNutritionistDashboard() async {
    final response = await _client
        .get(Uri.parse('$baseUrl/nutritionist/dashboard'), headers: _headers())
        .timeout(const Duration(seconds: 12));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _messageFromBody(response.body, 'Gagal memuat dashboard ahli gizi.'),
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Format dashboard ahli gizi tidak valid.');
    }
    return decoded;
  }

  Future<Map<String, dynamic>> getNutritionistRoomMessages({
    required int roomId,
  }) async {
    final response = await _client
        .get(
          Uri.parse('$baseUrl/nutritionist/rooms/$roomId/messages'),
          headers: _headers(),
        )
        .timeout(const Duration(seconds: 12));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _messageFromBody(response.body, 'Gagal memuat chat konsultasi.'),
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Format chat konsultasi tidak valid.');
    }
    return decoded;
  }

  Future<Map<String, dynamic>> sendNutritionistMessage({
    required int roomId,
    required String message,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/nutritionist/rooms/$roomId/messages'),
      headers: _headers(),
      body: jsonEncode({'message': message}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_messageFromBody(response.body, 'Gagal mengirim pesan.'));
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Format kirim pesan tidak valid.');
    }
    return decoded;
  }

  Future<void> closeNutritionistConsultation({required int roomId}) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/nutritionist/consultations/$roomId/close'),
      headers: _headers(),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _messageFromBody(response.body, 'Gagal menandai konsultasi selesai.'),
      );
    }
  }

  Future<void> updateConsultationRoomStatus({
    required int roomId,
    required String status,
  }) async {
    final response = await _client.patch(
      Uri.parse('$baseUrl/consultation/rooms/$roomId/status'),
      headers: _headers(),
      body: jsonEncode({'status': status}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Gagal update status konsultasi: ${response.body}');
    }
  }

  Future<void> markConsultationMeasurementShared({
    required int roomId,
    required int measurementId,
  }) async {
    final response = await _client.patch(
      Uri.parse('$baseUrl/consultation/rooms/$roomId/shared-measurement'),
      headers: _headers(),
      body: jsonEncode({'measurement_id': measurementId}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Gagal menandai update perkembangan: ${response.body}');
    }
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
