// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/colors.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/error_widget.dart';
import '../../providers/news_provider.dart';
import '../../core/models/news_model.dart';

class NewsDetailScreen extends StatefulWidget {
  final String newsId;

  const NewsDetailScreen({
    super.key,
    required this.newsId,
  });

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNewsDetails();
    });
  }

  Future<void> _loadNewsDetails() async {
    final newsProvider = Provider.of<NewsProvider>(context, listen: false);
    await newsProvider.loadNewsDetails(widget.newsId);
  }

  void _shareNews(NewsModel news) {
    Share.share(
      '📰 ${news.title}\n'
      '\n${news.summary ?? news.content.substring(0, news.content.length > 200 ? 200 : news.content.length)}...'
      '\n\nRead more on Events & Rewards app!',
      subject: news.title,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.darkBackgroundColor : AppColors.backgroundColor,
      body: Consumer<NewsProvider>(
        builder: (context, newsProvider, child) {
          if (newsProvider.isLoading && newsProvider.selectedNews == null) {
            return const Scaffold(
              body: LoadingWidget(message: 'Loading article...'),
            );
          }

          if (newsProvider.error != null && newsProvider.selectedNews == null) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('News Article'),
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
              ),
              body: CustomErrorWidget(
                message: newsProvider.error!,
                onRetry: _loadNewsDetails,
              ),
            );
          }

          final news = newsProvider.selectedNews;
          if (news == null) {
            return const Scaffold(
              body: NotFoundWidget(
                title: 'Article Not Found',
                message: 'The news article you are looking for could not be found.',
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              // App Bar with Image
              SliverAppBar(
                expandedHeight: news.imageUrl != null ? 250 : 120,
                floating: false,
                pinned: true,
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  background: news.imageUrl != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            // News Image
                            CachedNetworkImage(
                              imageUrl: news.imageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                decoration: const BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(color: Colors.white),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                decoration: const BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                ),
                                child: const Center(
                                  child: Icon(Icons.article, color: Colors.white, size: 64),
                                ),
                              ),
                            ),

                            // Gradient Overlay
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.7),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : Container(
                          decoration: const BoxDecoration(
                            gradient: AppColors.primaryGradient,
                          ),
                          child: const Center(
                            child: Icon(Icons.article, color: Colors.white, size: 48),
                          ),
                        ),
                ),
                actions: [
                  IconButton(
                    onPressed: () => _shareNews(news),
                    icon: const Icon(Icons.share),
                    tooltip: 'Share Article',
                  ),
                  IconButton(
                    onPressed: () {
                      // Bookmark article
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Article bookmarked!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.bookmark_border),
                    tooltip: 'Bookmark',
                  ),
                ],
              ),

              // Article Content
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Article Header
                    _buildArticleHeader(news, theme, isDarkMode),
                    const SizedBox(height: 24),

                    // Article Meta Information
                    _buildArticleMeta(news, theme, isDarkMode),
                    const SizedBox(height: 24),

                    // Article Content
                    _buildArticleContent(news, theme, isDarkMode),
                    const SizedBox(height: 32),

                    // Related Articles Section (Placeholder)
                    _buildRelatedArticles(theme, isDarkMode),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildArticleHeader(NewsModel news, ThemeData theme, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Badge
        if (news.category != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              news.category!.toUpperCase(),
              style: const TextStyle(
                color: AppColors.primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Article Title
        Text(
          news.title,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            height: 1.3,
            color: isDarkMode ? AppColors.darkTextPrimaryColor : AppColors.textPrimaryColor,
          ),
        ),

        // Article Summary (if available)
        if (news.summary != null) ...[
          const SizedBox(height: 16),
          Text(
            news.summary!,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.5,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? AppColors.darkTextSecondaryColor : AppColors.textSecondaryColor,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildArticleMeta(NewsModel news, ThemeData theme, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode 
            ? AppColors.darkCardColor.withOpacity(0.5)
            : AppColors.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? AppColors.darkTextSecondaryColor.withOpacity(0.2) : AppColors.dividerColor,
        ),
      ),
      child: Row(
        children: [
          // Publication Date
          Icon(
            Icons.schedule,
            size: 16,
            color: isDarkMode ? AppColors.darkTextSecondaryColor : AppColors.textSecondaryColor,
          ),
          const SizedBox(width: 8),
          Text(
            'Published ${news.formattedDate}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDarkMode ? AppColors.darkTextSecondaryColor : AppColors.textSecondaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),

          // Reading Time
          Icon(
            Icons.access_time,
            size: 16,
            color: isDarkMode ? AppColors.darkTextSecondaryColor : AppColors.textSecondaryColor,
          ),
          const SizedBox(width: 8),
          Text(
            news.readingTime,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDarkMode ? AppColors.darkTextSecondaryColor : AppColors.textSecondaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArticleContent(NewsModel news, ThemeData theme, bool isDarkMode) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDarkMode ? AppColors.darkCardColor : AppColors.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Content
            SelectableText(
              news.content,
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.7,
                fontSize: 16,
                color: isDarkMode ? AppColors.darkTextPrimaryColor : AppColors.textPrimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRelatedArticles(ThemeData theme, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Related Articles',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Placeholder for related articles
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: isDarkMode ? AppColors.darkSurfaceColor : AppColors.backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDarkMode ? AppColors.darkTextSecondaryColor.withOpacity(0.2) : AppColors.dividerColor,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.article_outlined,
                size: 48,
                color: isDarkMode ? AppColors.darkTextSecondaryColor : AppColors.textSecondaryColor,
              ),
              const SizedBox(height: 16),
              Text(
                'More Articles Coming Soon',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: isDarkMode ? AppColors.darkTextSecondaryColor : AppColors.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We are working on bringing you more related content',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDarkMode ? AppColors.darkTextSecondaryColor : AppColors.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// News List Screen (since it was referenced but not created)
class NewsListScreen extends StatefulWidget {
  const NewsListScreen({super.key});

  @override
  State<NewsListScreen> createState() => _NewsListScreenState();
}

class _NewsListScreenState extends State<NewsListScreen> 
    with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNews();
    });
  }

  Future<void> _loadNews() async {
    final newsProvider = Provider.of<NewsProvider>(context, listen: false);
    await newsProvider.loadNews(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.darkBackgroundColor : AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('News'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Implement search
            },
          ),
        ],
      ),
      body: Consumer<NewsProvider>(
        builder: (context, newsProvider, child) {
          if (newsProvider.isLoading && newsProvider.news.isEmpty) {
            return const LoadingWidget(message: 'Loading news...');
          }

          if (newsProvider.error != null && newsProvider.news.isEmpty) {
            return CustomErrorWidget(
              message: newsProvider.error!,
              onRetry: _loadNews,
            );
          }

          if (newsProvider.news.isEmpty) {
            return const EmptyStateWidget(
              title: 'No News Available',
              message: 'There are no news articles available at the moment. Check back later!',
              icon: Icons.article,
            );
          }

          return RefreshIndicator(
            onRefresh: _loadNews,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: newsProvider.news.length,
              itemBuilder: (context, index) {
                final article = newsProvider.news[index];
                return NewsCard(
                  news: article,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => NewsDetailScreen(newsId: article.id),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class NewsCard extends StatelessWidget {
  final NewsModel news;
  final VoidCallback onTap;

  const NewsCard({
    super.key,
    required this.news,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDarkMode ? AppColors.darkCardColor : AppColors.cardColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // News Image
            if (news.imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: CachedNetworkImage(
                  imageUrl: news.imageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 200,
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 200,
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                    ),
                    child: const Center(
                      child: Icon(Icons.article, color: Colors.white, size: 48),
                    ),
                  ),
                ),
              ),

            // News Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category
                  if (news.category != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        news.category!.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primaryColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Title
                  Text(
                    news.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Summary or Content Preview
                  Text(
                    news.summary ?? news.content,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDarkMode ? AppColors.darkTextSecondaryColor : AppColors.textSecondaryColor,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // Meta Information
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 14,
                        color: isDarkMode ? AppColors.darkTextSecondaryColor : AppColors.textSecondaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        news.formattedDate,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDarkMode ? AppColors.darkTextSecondaryColor : AppColors.textSecondaryColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: isDarkMode ? AppColors.darkTextSecondaryColor : AppColors.textSecondaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        news.readingTime,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDarkMode ? AppColors.darkTextSecondaryColor : AppColors.textSecondaryColor,
                        ),
                      ),
                    ],
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