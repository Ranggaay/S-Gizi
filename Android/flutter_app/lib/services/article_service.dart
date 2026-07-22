import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:s_gizi/models/news_article_model.dart';
import 'api_service.dart';

class ArticleService {
  ArticleService({http.Client? client, ApiService? apiService})
    : _client = client ?? http.Client(),
      _apiService = apiService ?? ApiService();

  final http.Client _client;
  final ApiService _apiService;

  static const _gNewsKey = String.fromEnvironment('GNEWS_API_KEY');
  static const _newsApiKey = String.fromEnvironment('NEWS_API_KEY');
  static const _cacheTtl = Duration(minutes: 20);
  static final Map<String, _ArticleCacheEntry> _cache = {};

  static const categories = [
    'Semua',
    'Gizi',
    'MPASI',
    'Stunting',
    'Tumbuh Kembang',
    'Imunisasi',
    'Kesehatan Anak',
  ];

  Future<List<NewsArticleModel>> fetchArticles({
    String query = '',
    String category = 'Semua',
    int page = 1,
    int pageSize = 12,
    bool forceRefresh = false,
  }) async {
    final keyword = _buildQuery(query: query, category: category);
    final cacheKey = '$keyword|$page|$pageSize';
    final cached = _cache[cacheKey];
    if (!forceRefresh &&
        cached != null &&
        DateTime.now().difference(cached.storedAt) < _cacheTtl) {
      return cached.items;
    }

    final online = await _fetchOnline(
      keyword,
      page: page,
      pageSize: pageSize,
    ).catchError((_) => <NewsArticleModel>[]);
    final backend = await _apiService
        .getNewsArticles(query: keyword)
        .catchError((_) => <NewsArticleModel>[]);
    final db = await _apiService.getArticlesDb().catchError(
      (_) => <NewsArticleModel>[],
    );

    final merged = _dedupe([
      ...db,
      ...online,
      ...backend,
    ]).where((article) => _matchesCategory(article, category)).toList();

    if (merged.isEmpty && online.isEmpty && backend.isEmpty && db.isEmpty) {
      throw Exception('Artikel gagal dimuat');
    }

    _cache[cacheKey] = _ArticleCacheEntry(merged, DateTime.now());
    return merged;
  }

  Future<List<NewsArticleModel>> searchArticles(String keyword) {
    return fetchArticles(query: keyword, forceRefresh: true);
  }

  List<NewsArticleModel> filterByCategory(
    List<NewsArticleModel> articles,
    String category,
  ) {
    return articles.where((item) => _matchesCategory(item, category)).toList();
  }

  Future<List<NewsArticleModel>> _fetchOnline(
    String keyword, {
    required int page,
    required int pageSize,
  }) async {
    if (_gNewsKey.trim().isNotEmpty) {
      return _fetchGNews(keyword, pageSize: pageSize);
    }
    if (_newsApiKey.trim().isNotEmpty) {
      return _fetchNewsApi(keyword, page: page, pageSize: pageSize);
    }
    return const [];
  }

  Future<List<NewsArticleModel>> _fetchGNews(
    String keyword, {
    required int pageSize,
  }) async {
    final uri = Uri.https('gnews.io', '/api/v4/search', {
      'q': keyword,
      'lang': 'id',
      'country': 'id',
      'max': pageSize.toString(),
      'apikey': _gNewsKey,
    });
    final response = await _client.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('GNews gagal dimuat');
    }
    final decoded = jsonDecode(response.body);
    final data = decoded is Map<String, dynamic> ? decoded['articles'] : null;
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(NewsArticleModel.fromJson)
        .toList();
  }

  Future<List<NewsArticleModel>> _fetchNewsApi(
    String keyword, {
    required int page,
    required int pageSize,
  }) async {
    final uri = Uri.https('newsapi.org', '/v2/everything', {
      'q': keyword,
      'language': 'id',
      'sortBy': 'publishedAt',
      'page': page.toString(),
      'pageSize': pageSize.toString(),
      'apiKey': _newsApiKey,
    });
    final response = await _client.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('NewsAPI gagal dimuat');
    }
    final decoded = jsonDecode(response.body);
    final data = decoded is Map<String, dynamic> ? decoded['articles'] : null;
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(NewsArticleModel.fromJson)
        .toList();
  }

  String _buildQuery({required String query, required String category}) {
    final base = query.trim().isEmpty
        ? 'gizi anak OR stunting OR MPASI OR tumbuh kembang anak OR nutrisi balita OR kesehatan anak OR parenting kesehatan OR WHO nutrition OR child nutrition'
        : query.trim();
    if (category == 'Semua') return base;
    return '$base $category anak balita kesehatan';
  }

  bool _matchesCategory(NewsArticleModel article, String category) {
    if (category == 'Semua') return true;
    final c = category.toLowerCase();
    final text =
        '${article.category} ${article.title} ${article.description} ${article.content}'
            .toLowerCase();
    if (c == 'gizi') {
      return text.contains('gizi') ||
          text.contains('nutrisi') ||
          text.contains('nutrition');
    }
    if (c == 'imunisasi') {
      return text.contains('imunisasi') ||
          text.contains('vaksin') ||
          text.contains('vaccine');
    }
    if (c == 'kesehatan anak') {
      return text.contains('kesehatan anak') ||
          text.contains('balita') ||
          text.contains('anak');
    }
    return text.contains(c.toLowerCase());
  }

  List<NewsArticleModel> _dedupe(List<NewsArticleModel> articles) {
    final seen = <String>{};
    final out = <NewsArticleModel>[];
    for (final article in articles) {
      final key = (article.url ?? article.title).toLowerCase().trim();
      if (key.isEmpty || seen.contains(key)) continue;
      seen.add(key);
      out.add(article);
    }
    return out;
  }
}

class _ArticleCacheEntry {
  const _ArticleCacheEntry(this.items, this.storedAt);

  final List<NewsArticleModel> items;
  final DateTime storedAt;
}
