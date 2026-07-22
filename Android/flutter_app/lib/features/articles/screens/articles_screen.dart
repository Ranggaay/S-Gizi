import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:s_gizi/app_design.dart';
import 'package:s_gizi/models/news_article_model.dart';
import 'package:s_gizi/services/article_service.dart';
import 'package:s_gizi/features/articles/screens/article_detail_screen.dart';

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
  final ArticleService _articleService = ArticleService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Set<int> _bookmarked = {};
  final List<NewsArticleModel> _articles = [];
  final List<NewsArticleModel> _recentlyViewed = [];

  Timer? _debounce;
  String _activeCategory = 'Semua';
  int _page = 1;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _activeCategory = widget.initialCategory;
    _scrollController.addListener(_handleScroll);
    _loadInitial();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients || _loadingMore || !_hasMore) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 420) {
      _loadMore();
    }
  }

  Future<void> _loadInitial({bool forceRefresh = false}) async {
    setState(() {
      _loading = true;
      _error = null;
      _page = 1;
      _hasMore = true;
    });

    try {
      final items = await _articleService.fetchArticles(
        query: _searchController.text,
        category: _activeCategory,
        page: 1,
        pageSize: 12,
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() {
        _articles
          ..clear()
          ..addAll(items.isNotEmpty ? items : widget.articles);
        _loading = false;
        _hasMore = items.length >= 12;
      });
    } catch (e) {
      if (!mounted) return;
      final fallback = _articleService.filterByCategory(
        widget.articles,
        _activeCategory,
      );
      setState(() {
        _articles
          ..clear()
          ..addAll(fallback);
        _loading = false;
        _error = fallback.isEmpty ? e.toString() : null;
        _hasMore = false;
      });
    }
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    try {
      final nextPage = _page + 1;
      final items = await _articleService.fetchArticles(
        query: _searchController.text,
        category: _activeCategory,
        page: nextPage,
        pageSize: 12,
      );
      if (!mounted) return;
      final existing = _articles
          .map((item) => (item.url ?? item.title).toLowerCase())
          .toSet();
      final fresh = items
          .where(
            (item) =>
                !existing.contains((item.url ?? item.title).toLowerCase()),
          )
          .toList();
      setState(() {
        _page = nextPage;
        _articles.addAll(fresh);
        _loadingMore = false;
        _hasMore = fresh.isNotEmpty && items.length >= 12;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingMore = false;
        _hasMore = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      _loadInitial(forceRefresh: value.trim().isNotEmpty);
    });
  }

  void _changeCategory(String category) {
    if (_activeCategory == category) return;
    setState(() => _activeCategory = category);
    _loadInitial(forceRefresh: true);
  }

  void _openArticle(NewsArticleModel article) {
    setState(() {
      _recentlyViewed.removeWhere((item) => item.id == article.id);
      _recentlyViewed.insert(0, article);
      if (_recentlyViewed.length > 5) _recentlyViewed.removeLast();
    });
    Navigator.of(context).push(
      fadeRoute(ArticleDetailScreen(article: article, related: _articles)),
    );
  }

  Future<void> _shareArticle(NewsArticleModel article) async {
    await Clipboard.setData(ClipboardData(text: article.url ?? article.title));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link artikel disalin untuk dibagikan.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SgColors.background,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Artikel Edukasi',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.white,
        foregroundColor: SgColors.textPrimary,
        elevation: 0.4,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => _loadInitial(forceRefresh: true),
            icon: const Icon(LucideIcons.refreshCcw, size: 20),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: SgColors.primary,
          onRefresh: () => _loadInitial(forceRefresh: true),
          child: ListView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
            children: [
              _SearchField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                onClear: () {
                  _searchController.clear();
                  _loadInitial(forceRefresh: true);
                },
              ),
              const SizedBox(height: 12),
              _CategoryChips(
                selected: _activeCategory,
                onSelected: _changeCategory,
              ),
              const SizedBox(height: 16),
              if (_recentlyViewed.isNotEmpty && !_loading) ...[
                _MiniSectionTitle(
                  title: 'Terakhir Dibaca',
                  count: _recentlyViewed.length,
                ),
                const SizedBox(height: 10),
                _RecentlyViewedList(
                  items: _recentlyViewed,
                  onTap: _openArticle,
                ),
                const SizedBox(height: 18),
              ],
              if (_loading)
                const _ArticleLoadingList()
              else if (_error != null)
                EmptyState(
                  title: 'Artikel gagal dimuat',
                  message:
                      'Periksa koneksi internet lalu coba muat ulang artikel online.',
                  actionLabel: 'Coba Lagi',
                  onAction: () => _loadInitial(forceRefresh: true),
                  icon: LucideIcons.fileWarning,
                )
              else if (_articles.isEmpty)
                EmptyState(
                  title: 'Artikel belum tersedia',
                  message: 'Coba refresh atau gunakan kata kunci lain.',
                  actionLabel: 'Refresh',
                  onAction: () => _loadInitial(forceRefresh: true),
                  icon: LucideIcons.newspaper,
                )
              else ...[
                _MiniSectionTitle(
                  title: 'Artikel Populer',
                  count: _articles.length,
                ),
                const SizedBox(height: 10),
                ..._articles.map(
                  (article) => _ArticleListCard(
                    article: article,
                    bookmarked: _bookmarked.contains(article.id),
                    onBookmark: () {
                      setState(() {
                        if (!_bookmarked.add(article.id)) {
                          _bookmarked.remove(article.id);
                        }
                      });
                    },
                    onShare: () => _shareArticle(article),
                    onTap: () => _openArticle(article),
                  ),
                ),
                if (_loadingMore)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2.2),
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

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: SgColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, child) {
          return TextField(
            controller: controller,
            onChanged: onChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Cari artikel edukasi...',
              hintStyle: AppTypography.body.copyWith(fontSize: 13),
              prefixIcon: const Icon(LucideIcons.search, size: 20),
              suffixIcon: value.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Hapus pencarian',
                      onPressed: onClear,
                      icon: const Icon(LucideIcons.x, size: 18),
                    ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 13,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: ArticleService.categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = ArticleService.categories[index];
          final active = category == selected;
          return ChoiceChip(
            selected: active,
            showCheckmark: false,
            label: Text(category),
            onSelected: (_) => onSelected(category),
            selectedColor: SgColors.primary,
            backgroundColor: Colors.white,
            side: BorderSide(
              color: active ? SgColors.primary : SgColors.border,
            ),
            labelStyle: AppTypography.caption.copyWith(
              color: active ? Colors.white : SgColors.textSecondary,
              fontWeight: FontWeight.w800,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          );
        },
      ),
    );
  }
}

class _MiniSectionTitle extends StatelessWidget {
  const _MiniSectionTitle({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: AppTypography.h3)),
        Text('$count artikel', style: AppTypography.caption),
      ],
    );
  }
}

class _RecentlyViewedList extends StatelessWidget {
  const _RecentlyViewedList({required this.items, required this.onTap});

  final List<NewsArticleModel> items;
  final ValueChanged<NewsArticleModel> onTap;

  @override
  Widget build(BuildContext context) {
    final cardWidth = math.min(
      220.0,
      math.max(176.0, MediaQuery.sizeOf(context).width * 0.62),
    );
    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => onTap(item),
            child: Container(
              width: cardWidth,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: SgColors.border),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 58,
                      height: 58,
                      child: _ArticleThumb(article: item),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        color: SgColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ArticleListCard extends StatelessWidget {
  const _ArticleListCard({
    required this.article,
    required this.bookmarked,
    required this.onBookmark,
    required this.onShare,
    required this.onTap,
  });

  final NewsArticleModel article;
  final bool bookmarked;
  final VoidCallback onBookmark;
  final VoidCallback onShare;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HealthCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: _ArticleThumb(article: article),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Flexible(
                child: StatusBadge(
                  text: article.category,
                  color: SgColors.primary,
                  compact: true,
                ),
              ),
              const SizedBox(width: 8),
              const Spacer(),
              _IconAction(
                icon: bookmarked
                    ? LucideIcons.bookmarkMinus
                    : LucideIcons.bookmark,
                onTap: onBookmark,
              ),
              const SizedBox(width: 6),
              _IconAction(icon: LucideIcons.share2, onTap: onShare),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            article.title,
            style: AppTypography.h3.copyWith(
              color: SgColors.textPrimary,
              fontSize: 16,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            article.description,
            style: AppTypography.body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                LucideIcons.newspaper,
                size: 14,
                color: SgColors.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  [
                    if ((article.sourceName ?? '').trim().isNotEmpty)
                      article.sourceName!,
                    if (article.createdAt.isNotEmpty) article.createdAt,
                  ].join(' • '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: const Color(0xFFEAF4F3),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Icon(icon, size: 17, color: SgColors.primary),
      ),
    );
  }
}

class _ArticleThumb extends StatelessWidget {
  const _ArticleThumb({required this.article});

  final NewsArticleModel article;

  @override
  Widget build(BuildContext context) {
    final image = article.image;
    final fallback = _articleAssetByIndex(article.id);
    if (image == null || image.trim().isEmpty) {
      return Image.asset(fallback, fit: BoxFit.cover);
    }
    return CachedNetworkImage(
      imageUrl: image,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(color: const Color(0xFFEAF1EF)),
      errorWidget: (context, url, error) =>
          Image.asset(fallback, fit: BoxFit.cover),
    );
  }
}

class _ArticleLoadingList extends StatelessWidget {
  const _ArticleLoadingList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (index) => HealthCard(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF1EF),
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 14,
                width: 96,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF1EF),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 12),
              Container(height: 16, color: const Color(0xFFEAF1EF)),
              const SizedBox(height: 8),
              Container(
                height: 16,
                width: double.infinity,
                color: const Color(0xFFEAF1EF),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _articleAssetByIndex(int index) {
  const assets = [
    'assets/image/onboarding_food.png',
    'assets/image/onboarding_monitoring.png',
    'assets/image/onboarding_consultation.png',
  ];
  return assets[index % assets.length];
}
