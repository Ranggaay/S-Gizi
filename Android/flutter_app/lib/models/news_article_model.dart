class NewsArticleModel {
  const NewsArticleModel({
    required this.id,
    required this.title,
    required this.description,
    required this.content,
    required this.category,
    required this.createdAt,
    this.sourceName,
    this.image,
    this.url,
  });

  final int id;
  final String title;
  final String description;
  final String content;
  final String category;
  final String createdAt;
  final String? sourceName;
  final String? image;
  final String? url;

  factory NewsArticleModel.fromJson(Map<String, dynamic> json) {
    return NewsArticleModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '-',
      description:
          (json['description'] as String? ?? json['excerpt'] as String? ?? '-')
              .trim(),
      content: (json['content'] as String? ?? '').trim(),
      category: (json['category'] as String? ?? 'Nutrisi Anak').trim(),
      createdAt:
          (json['created_at'] as String? ?? json['published_at'] as String? ?? '')
              .trim(),
      sourceName: (json['source_name'] as String? ?? '').trim().isEmpty
          ? null
          : json['source_name'] as String?,
      image: (json['image'] as String? ?? json['image_url'] as String? ?? '')
          .trim()
          .isEmpty
      ? null
      : (json['image'] as String? ?? json['image_url'] as String?),
      url: (json['url'] as String? ?? '').trim().isEmpty
          ? null
          : json['url'] as String?,
    );
  }
}
