import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_design.dart';
import '../models/news_article_model.dart';

class ArticleDetailScreen extends StatelessWidget {
  const ArticleDetailScreen({
    super.key,
    required this.article,
    required this.related,
  });

  final NewsArticleModel article;
  final List<NewsArticleModel> related;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SgColors.background,
      appBar: AppBar(title: const Text('Detail Artikel')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: 'article-${article.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: _ArticleImage(imageUrl: article.image, fallbackIndex: article.id),
                ),
              ),
              const SizedBox(height: 14),
              StatusBadge(text: article.category, color: SgColors.primary),
              const SizedBox(height: 10),
              Text(article.title, style: AppTypography.h2),
              const SizedBox(height: 6),
              Text(
                [
                  if (article.sourceName != null && article.sourceName!.isNotEmpty)
                    article.sourceName,
                  if (article.createdAt.isNotEmpty) article.createdAt,
                ].whereType<String>().join(' • '),
                style: AppTypography.caption,
              ),
              const SizedBox(height: 14),
              Text(article.description, style: AppTypography.body),
              const SizedBox(height: 12),
              Text(
                article.content.trim().isEmpty ? article.description : article.content,
                style: AppTypography.body.copyWith(color: SgColors.textPrimary),
              ),
              if (article.url != null && article.url!.isNotEmpty) ...[
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Buka Sumber (Selengkapnya)',
                  icon: Icons.open_in_new_rounded,
                  onPressed: () async {
                    final uri = Uri.tryParse(article.url!);
                    if (uri == null) return;
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                ),
              ],
              const SizedBox(height: 20),
              Text('Artikel Terkait', style: AppTypography.h3),
              const SizedBox(height: 10),
              ...related
                  .where((item) => item.id != article.id)
                  .take(3)
                  .map(
                    (item) => HealthCard(
                      margin: const EdgeInsets.only(bottom: 10),
                      onTap: () => Navigator.of(context).push(
                        fadeRoute(ArticleDetailScreen(article: item, related: related)),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 64,
                            height: 64,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: _ArticleImage(
                                imageUrl: item.image,
                                fallbackIndex: item.id,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArticleImage extends StatelessWidget {
  const _ArticleImage({required this.imageUrl, required this.fallbackIndex});

  final String? imageUrl;
  final int fallbackIndex;

  @override
  Widget build(BuildContext context) {
    final fallback = _assetByIndex(fallbackIndex);
    if (imageUrl == null || imageUrl!.isEmpty) {
      return Image.asset(fallback, fit: BoxFit.cover);
    }
    return CachedNetworkImage(
      imageUrl: imageUrl!,
      fit: BoxFit.cover,
      errorWidget: (_, __, ___) => Image.asset(fallback, fit: BoxFit.cover),
      placeholder: (_, __) => Container(color: const Color(0xFFEAF1EF)),
    );
  }
}

String _assetByIndex(int index) {
  const images = [
    'assets/image/onboarding_food.png',
    'assets/image/onboarding_monitoring.png',
    'assets/image/onboarding_consultation.png',
  ];
  return images[index % images.length];
}
