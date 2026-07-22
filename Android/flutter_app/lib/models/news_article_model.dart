import 'article_model.dart';

class NewsArticleModel extends ArticleModel {
  const NewsArticleModel({
    required super.id,
    required super.title,
    required super.description,
    required super.content,
    required super.category,
    required String createdAt,
    String? sourceName,
    String? image,
    String? url,
    super.author,
  }) : super(
         publishedAt: createdAt,
         source: sourceName,
         imageUrl: image,
         articleUrl: url,
       );

  String get createdAt => publishedAt;
  String? get sourceName => source;
  String? get image => imageUrl;
  String? get url => articleUrl;

  factory NewsArticleModel.fromJson(Map<String, dynamic> json) {
    final article = ArticleModel.fromJson(json);
    return NewsArticleModel.fromArticle(article);
  }

  factory NewsArticleModel.fromArticle(ArticleModel article) {
    return NewsArticleModel(
      id: article.id,
      title: article.title,
      description: article.description,
      content: article.content,
      category: article.category,
      createdAt: article.publishedAt,
      sourceName: article.source,
      image: article.imageUrl,
      url: article.articleUrl,
      author: article.author,
    );
  }
}
