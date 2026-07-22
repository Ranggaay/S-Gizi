import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:s_gizi/app_design.dart';
import 'package:s_gizi/models/news_article_model.dart';

class ArticleDetailScreen extends StatelessWidget {
  const ArticleDetailScreen({
    super.key,
    required this.article,
    required this.related,
  });

  final NewsArticleModel article;
  final List<NewsArticleModel> related;

  Future<void> _share(BuildContext context) async {
    final text = [
      article.title,
      if ((article.url ?? '').trim().isNotEmpty) article.url!,
    ].join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link artikel disalin untuk dibagikan.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = article.content.trim().isEmpty
        ? article.description
        : article.content;
    final relatedItems = related
        .where((item) => item.id != article.id)
        .take(8)
        .toList();

    return Scaffold(
      backgroundColor: SgColors.background,
      appBar: AppBar(
        title: const Text('Detail Artikel'),
        actions: [
          IconButton(
            tooltip: 'Bagikan artikel',
            onPressed: () => _share(context),
            icon: const Icon(LucideIcons.share2),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: 'article-${article.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: _ArticleImage(
                      imageUrl: article.image,
                      fallbackIndex: article.id,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  StatusBadge(text: article.category, color: SgColors.primary),
                  StatusBadge(
                    text: '${_readingMinutes(body)} menit baca',
                    color: const Color(0xFF5B8DEF),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                article.title,
                style: AppTypography.h1.copyWith(fontSize: 24),
              ),
              const SizedBox(height: 10),
              _ArticleMeta(article: article),
              const SizedBox(height: 16),
              if (article.description.trim().isNotEmpty)
                HealthCard(
                  dense: true,
                  color: const Color(0xFFF8FCFB),
                  child: Text(
                    article.description,
                    style: AppTypography.body.copyWith(
                      color: SgColors.textPrimary,
                      height: 1.55,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              HealthCard(dense: true, child: _HtmlArticleBody(html: body)),
              if (article.url != null && article.url!.isNotEmpty) ...[
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Baca Sumber Artikel',
                  icon: Icons.open_in_new_rounded,
                  onPressed: () async {
                    final uri = Uri.tryParse(article.url!);
                    if (uri == null) return;
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                ),
              ],
              if (relatedItems.isNotEmpty) ...[
                const SizedBox(height: 22),
                Text('Artikel Terkait', style: AppTypography.h2),
                const SizedBox(height: 10),
                SizedBox(
                  height: 136,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: relatedItems.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final item = relatedItems[index];
                      return _RelatedArticleCard(
                        article: item,
                        related: related,
                        index: index,
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ArticleMeta extends StatelessWidget {
  const _ArticleMeta({required this.article});

  final NewsArticleModel article;

  @override
  Widget build(BuildContext context) {
    final source = (article.sourceName ?? 'S-Gizi').trim();
    final author = _shortAuthor(article.author);
    final date = _formatArticleDate(article.createdAt);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$source • $author',
          style: AppTypography.caption.copyWith(fontWeight: FontWeight.w800),
        ),
        if (date.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(date, style: AppTypography.caption),
        ],
      ],
    );
  }
}

class _HtmlArticleBody extends StatelessWidget {
  const _HtmlArticleBody({required this.html});

  final String html;

  @override
  Widget build(BuildContext context) {
    final blocks = _parseHtmlBlocks(html);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks
          .map((block) => _ArticleBlockView(block: block))
          .toList(growable: false),
    );
  }
}

class _ArticleBlockView extends StatelessWidget {
  const _ArticleBlockView({required this.block});

  final _ArticleBlock block;

  @override
  Widget build(BuildContext context) {
    final style = switch (block.type) {
      _ArticleBlockType.heading => AppTypography.h2.copyWith(height: 1.35),
      _ArticleBlockType.list => AppTypography.body.copyWith(
        height: 1.6,
        color: SgColors.textPrimary,
      ),
      _ArticleBlockType.paragraph => AppTypography.body.copyWith(
        height: 1.65,
        color: SgColors.textPrimary,
      ),
    };

    if (block.type == _ArticleBlockType.list) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Icon(Icons.circle, size: 6, color: SgColors.primary),
            ),
            const SizedBox(width: 10),
            Expanded(child: SelectableText(block.text, style: style)),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: block.type == _ArticleBlockType.heading ? 10 : 12,
        top: block.type == _ArticleBlockType.heading ? 6 : 0,
      ),
      child: SelectableText(block.text, style: style),
    );
  }
}

class _RelatedArticleCard extends StatelessWidget {
  const _RelatedArticleCard({
    required this.article,
    required this.related,
    required this.index,
  });

  final NewsArticleModel article;
  final List<NewsArticleModel> related;
  final int index;

  @override
  Widget build(BuildContext context) {
    final width = math.min(260.0, MediaQuery.sizeOf(context).width * 0.72);
    return SizedBox(
      width: width,
      child: HealthCard(
        dense: true,
        padding: const EdgeInsets.all(8),
        onTap: () => Navigator.of(context).push(
          fadeRoute(ArticleDetailScreen(article: article, related: related)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 72,
                height: 92,
                child: _ArticleImage(
                  imageUrl: article.image,
                  fallbackIndex: article.id + index,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  StatusBadge(
                    text: article.category,
                    color: SgColors.primary,
                    compact: true,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.h3,
                  ),
                ],
              ),
            ),
          ],
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
      return _ImagePlaceholder(asset: fallback);
    }
    return CachedNetworkImage(
      imageUrl: imageUrl!,
      fit: BoxFit.cover,
      memCacheWidth: 900,
      maxWidthDiskCache: 900,
      placeholder: (context, url) => const _ImageSkeleton(),
      errorWidget: (context, url, error) => _ImagePlaceholder(asset: fallback),
    );
  }
}

class _ImageSkeleton extends StatelessWidget {
  const _ImageSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE6EEEC),
      highlightColor: const Color(0xFFF8FAF9),
      child: Container(color: Colors.white),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(asset, fit: BoxFit.cover),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.04),
          ),
        ),
      ],
    );
  }
}

enum _ArticleBlockType { heading, paragraph, list }

class _ArticleBlock {
  const _ArticleBlock(this.type, this.text);

  final _ArticleBlockType type;
  final String text;
}

List<_ArticleBlock> _parseHtmlBlocks(String raw) {
  var html = raw.trim();
  if (html.isEmpty) return const [];
  html = html
      .replaceAll(RegExp(r'<\s*br\s*/?\s*>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</\s*p\s*>', caseSensitive: false), '\n\n')
      .replaceAll(RegExp(r'</\s*h[1-6]\s*>', caseSensitive: false), '\n\n')
      .replaceAll(RegExp(r'</\s*li\s*>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<\s*li[^>]*>', caseSensitive: false), '\n- ')
      .replaceAll(RegExp(r'</?\s*(ul|ol)[^>]*>', caseSensitive: false), '\n');

  final blocks = <_ArticleBlock>[];
  final headingMatches = RegExp(
    r'<\s*h[1-6][^>]*>(.*?)</\s*h[1-6]\s*>',
    caseSensitive: false,
    dotAll: true,
  ).allMatches(raw);
  final headings = {
    for (final match in headingMatches) _cleanHtmlText(match.group(1) ?? ''),
  };

  for (final chunk in html.split(RegExp(r'\n{2,}'))) {
    final lines = chunk
        .split('\n')
        .map(_cleanHtmlText)
        .where((line) => line.isNotEmpty)
        .toList();
    if (lines.isEmpty) continue;
    for (final line in lines) {
      if (line.startsWith('- ')) {
        blocks.add(_ArticleBlock(_ArticleBlockType.list, line.substring(2)));
      } else if (headings.contains(line)) {
        blocks.add(_ArticleBlock(_ArticleBlockType.heading, line));
      } else {
        blocks.add(_ArticleBlock(_ArticleBlockType.paragraph, line));
      }
    }
  }
  if (blocks.isEmpty) {
    final text = _cleanHtmlText(raw);
    if (text.isNotEmpty) {
      blocks.add(_ArticleBlock(_ArticleBlockType.paragraph, text));
    }
  }
  return blocks;
}

String _cleanHtmlText(String value) {
  final noTags = value
      .replaceAll(
        RegExp(r'<\s*/?\s*(strong|b|em|i|span|a)[^>]*>', caseSensitive: false),
        '',
      )
      .replaceAll(RegExp(r'<[^>]+>'), ' ');
  return _decodeText(noTags);
}

String _decodeText(String value) {
  return value
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

int _readingMinutes(String html) {
  final words = _decodeText(
    html.replaceAll(RegExp(r'<[^>]+>'), ' '),
  ).split(RegExp(r'\s+')).where((word) => word.trim().isNotEmpty).length;
  return math.max(1, (words / 180).ceil());
}

String _formatArticleDate(String raw) {
  final date = DateTime.tryParse(raw)?.toLocal();
  if (date == null) return raw.trim();
  const months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

String _shortAuthor(String? raw) {
  final value = (raw ?? 'Admin').trim();
  if (value.toLowerCase() == 'admin s-gizi') return 'Admin';
  return value.isEmpty ? 'Admin' : value;
}

String _assetByIndex(int index) {
  const images = [
    'assets/image/onboarding_food.png',
    'assets/image/onboarding_monitoring.png',
    'assets/image/onboarding_consultation.png',
  ];
  return images[index.abs() % images.length];
}
