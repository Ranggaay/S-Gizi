class ArticleModel {
  const ArticleModel({
    required this.id,
    required this.title,
    required this.description,
    required this.content,
    required this.category,
    required this.publishedAt,
    this.source,
    this.author,
    this.imageUrl,
    this.articleUrl,
  });

  final int id;
  final String title;
  final String description;
  final String content;
  final String category;
  final String publishedAt;
  final String? source;
  final String? author;
  final String? imageUrl;
  final String? articleUrl;

  factory ArticleModel.fromJson(Map<String, dynamic> json) {
    final source = json['source'];
    final sourceName = source is Map<String, dynamic>
        ? source['name'] as String?
        : json['source_name'] as String?;

    return ArticleModel(
      id: _stableId(
        json['id']?.toString() ??
            json['url'] as String? ??
            json['articleUrl'] as String? ??
            json['title'] as String? ??
            '',
      ),
      title: (json['title'] as String? ?? '-').trim(),
      description:
          (json['description'] as String? ?? json['excerpt'] as String? ?? '-')
              .trim(),
      content: (json['content'] as String? ?? '').trim(),
      category: _categoryFromJson(json),
      publishedAt:
          (json['publishedAt'] as String? ??
                  json['published_at'] as String? ??
                  json['created_at'] as String? ??
                  '')
              .trim(),
      source: sourceName?.trim().isEmpty == true ? null : sourceName?.trim(),
      author: (json['author'] as String?)?.trim(),
      imageUrl:
          (json['image'] as String? ??
                  json['image_url'] as String? ??
                  json['urlToImage'] as String?)
              ?.trim(),
      articleUrl: (json['url'] as String? ?? json['articleUrl'] as String?)
          ?.trim(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'content': content,
      'category': category,
      'published_at': publishedAt,
      'source_name': source,
      'author': author,
      'image_url': imageUrl,
      'url': articleUrl,
    };
  }
}

String _categoryFromJson(Map<String, dynamic> json) {
  final raw = (json['category'] as String? ?? '').trim();
  if (raw.isNotEmpty) return raw;

  final text = '${json['title'] ?? ''} ${json['description'] ?? ''}'
      .toLowerCase();
  if (text.contains('stunting')) return 'Stunting';
  if (text.contains('mpasi')) return 'MPASI';
  if (text.contains('imunisasi') || text.contains('vaksin')) {
    return 'Imunisasi';
  }
  if (text.contains('kesehatan anak') || text.contains('balita')) {
    return 'Kesehatan Anak';
  }
  if (text.contains('protein')) return 'Protein';
  if (text.contains('vitamin')) return 'Vitamin';
  if (text.contains('tumbuh') || text.contains('kembang')) {
    return 'Tumbuh Kembang';
  }
  return 'Gizi';
}

int _stableId(String value) {
  var hash = 0;
  for (final codeUnit in value.codeUnits) {
    hash = (hash * 31 + codeUnit) & 0x7fffffff;
  }
  return hash;
}
