import 'package:flutter/material.dart';

import '../app_design.dart';
import '../models/news_article_model.dart';
import 'article_detail_screen.dart';

class ArticlesScreen extends StatefulWidget {
  const ArticlesScreen({
    super.key,
    required this.title,
    required this.articles,
    this.initialCategory = 'Semua',
  });

  final String title;
  final List<NewsArticleModel> articles;
  final String initialCategory;

  @override
  State<ArticlesScreen> createState() => _ArticlesScreenState();
}

class _ArticlesScreenState extends State<ArticlesScreen> {
  late String _activeCategory = widget.initialCategory;

  @override
  Widget build(BuildContext context) {
    final filtered = widget.articles
        .where(
          (a) =>
              _activeCategory == 'Semua' ||
              a.category.toLowerCase().contains(_activeCategory.toLowerCase()),
        )
        .toList();

    return Scaffold(
      backgroundColor: SgColors.background,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: SgColors.background,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (_, index) {
                    final label = _nutritionCategories[index];
                    final isActive = label == _activeCategory;
                    return InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () => setState(() => _activeCategory = label),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isActive ? const Color(0xFF0B7A86) : Colors.white,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color:
                                isActive ? const Color(0xFF0B7A86) : SgColors.border,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            label,
                            style: AppTypography.caption.copyWith(
                              color: isActive ? Colors.white : SgColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemCount: _nutritionCategories.length,
                ),
              ),
              const SizedBox(height: 16),
              if (filtered.isEmpty)
                const EmptyState(
                  title: 'Belum Ada Artikel',
                  message: 'Tidak ada artikel untuk kategori ini.',
                )
              else
                ...filtered.map(
                  (article) => HealthCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: EdgeInsets.zero,
                    onTap: () {
                      Navigator.of(context).push(
                        fadeRoute(
                          ArticleDetailScreen(
                            article: article,
                            related: widget.articles,
                          ),
                        ),
                      );
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Hero(
                          tag: 'article-${article.id}',
                          child: ClipRRect(
                            borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(20),
                            ),
                            child: SizedBox(
                              width: 104,
                              height: 96,
                              child: Image.asset(
                                _articleAssetByIndex(article.id),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 4,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF7FD6C2)
                                        .withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    article.category,
                                    style: AppTypography.caption.copyWith(
                                      color: const Color(0xFF085B63),
                                      fontWeight: FontWeight.w700,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  article.title,
                                  style: AppTypography.h3.copyWith(
                                    color: SgColors.textPrimary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  article.description,
                                  style: AppTypography.body,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
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

const List<String> _nutritionCategories = [
  'Semua',
  'Stunting',
  'MPASI',
  'Protein',
  'Vitamin',
  'Gizi Seimbang',
];

String _articleAssetByIndex(int index) {
  const assets = [
    'assets/image/onboarding_food.png',
    'assets/image/onboarding_monitoring.png',
    'assets/image/onboarding_consultation.png',
  ];
  return assets[index % assets.length];
}

