// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/news_provider.dart';
import '../../core/models/news_model.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/error_widget.dart';
import 'create_news_screen.dart';
import 'manage_news_screen.dart';
import 'news_detail_screen.dart';

class NewsListScreen extends StatefulWidget {
  const NewsListScreen({super.key});

  @override
  State<NewsListScreen> createState() => _NewsListScreenState();
}

class _NewsListScreenState extends State<NewsListScreen>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'all';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController.addListener(_onScroll);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNews();
    });
  }


  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged); 
    _tabController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }


  void _onTabChanged() {
    if (_tabController.index == 2) { 
      final newsProvider = Provider.of<NewsProvider>(context, listen: false);
      if (newsProvider.myNews.isEmpty) {
        newsProvider.loadMyNews(refresh: true);
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      final newsProvider = Provider.of<NewsProvider>(context, listen: false);
      if (!newsProvider.isLoadingMore && newsProvider.hasMoreData) {
        newsProvider.loadMoreNews();
      }
    }
  }

  Future<void> _loadNews() async {
    final newsProvider = Provider.of<NewsProvider>(context, listen: false);
    await Future.wait([
      newsProvider.loadAllNews(refresh: true),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              title: const Text('News'),
              floating: true,
              pinned: true,
              snap: true,
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _showSearchDialog,
                ),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: _showFilterBottomSheet,
                ),
                _buildNewsMenu(theme),
              ],
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: theme.colorScheme.onPrimary,
                labelColor: theme.colorScheme.onPrimary,
                unselectedLabelColor: theme.colorScheme.onPrimary.withOpacity(0.7),
                tabs: const [
                  Tab(text: 'All News'),
                  Tab(text: 'Published'),
                  Tab(text: 'My News'),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildAllNewsTab(),
            _buildPublishedNewsTab(),
            _buildMyNewsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsMenu(ThemeData theme) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      color: theme.colorScheme.surface,
      elevation: 4,
      onSelected: (value) {
        _handleMenuSelection(value);
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'create',
          child: ListTile(
            leading: Icon(Icons.add, color: Colors.blue),
            title: Text('Create News'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem<String>(
          value: 'manage',
          child: ListTile(
            leading: Icon(Icons.manage_accounts, color: Colors.green),
            title: Text('Manage My News'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'refresh',
          child: Consumer<NewsProvider>(
            builder: (context, newsProvider, child) {
              return ListTile(
                leading: const Icon(Icons.refresh, color: Colors.orange),
                title: const Text('Refresh News'),
                trailing: newsProvider.isLoading 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
                contentPadding: EdgeInsets.zero,
              );
            },
          ),
        ),
      ],
    );
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'create':
        _navigateToCreateNews();
        break;
      case 'manage':
        _navigateToManageNews();
        break;
      case 'refresh':
        _loadNews();
        break;
    }
  }

  void _navigateToCreateNews() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateNewsScreen()),
    );
    if (result == true) {
      _loadNews();
    }
  }

  void _navigateToManageNews() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ManageNewsScreen()),
    );
    if (result == true) {
      _loadNews();
    }
  }

  Widget _buildAllNewsTab() {
    return Consumer<NewsProvider>(
      builder: (context, newsProvider, child) {
        if (newsProvider.isLoading && newsProvider.allNews.isEmpty) {
          return const LoadingWidget(message: 'Loading news...');
        }

        if (newsProvider.error != null && newsProvider.allNews.isEmpty) {
          return CustomErrorWidget(
            message: newsProvider.error!,
            onRetry: _loadNews,
          );
        }

        List<NewsModel> filteredNews = _getFilteredNews(newsProvider.allNews);

        if (filteredNews.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.article, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No News Found',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'There are no news articles available at the moment. Check back later!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadNews,
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: filteredNews.length + (newsProvider.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == filteredNews.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              return NewsCard(
                news: filteredNews[index],
                onTap: () => _navigateToNewsDetail(filteredNews[index]),
                onBookmark: () => _handleNewsBookmark(filteredNews[index]),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPublishedNewsTab() {
    return Consumer<NewsProvider>(
      builder: (context, newsProvider, child) {
        final publishedNews = newsProvider.allNews.where((news) => news.isPublished).toList();
        final filteredNews = _getFilteredNews(publishedNews);
        
        if (newsProvider.isLoading) {
          return const LoadingWidget(message: 'Loading published news...');
        }

        if (filteredNews.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.publish, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No Published News',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'No news articles have been published yet. Stay tuned!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadNews,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredNews.length,
            itemBuilder: (context, index) {
              return NewsCard(
                news: filteredNews[index],
                onTap: () => _navigateToNewsDetail(filteredNews[index]),
                onBookmark: () => _handleNewsBookmark(filteredNews[index]),
                showPublishedDate: true,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMyNewsTab() {
    return Consumer<NewsProvider>(
      builder: (context, newsProvider, child) {
        final myNews = newsProvider.myNews;
        final filteredNews = _getFilteredNews(myNews);
        
        // Remove the problematic conditional loading
        // The loading is now handled by the tab listener
        
        if (newsProvider.isLoading && myNews.isEmpty) {
          return const LoadingWidget(message: 'Loading your news...');
        }
        
        if (newsProvider.error != null && myNews.isEmpty) {
          return CustomErrorWidget(
            message: newsProvider.error!,
            onRetry: () => newsProvider.loadMyNews(refresh: true),
          );
        }
        
        if (filteredNews.isEmpty && myNews.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.article, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'No News Created',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'You haven\'t created any news yet. Start writing and share your stories!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _navigateToCreateNews,
                  child: const Text('Create First Article'),
                ),
              ],
            ),
          );
        }

        if (filteredNews.isEmpty && myNews.isNotEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No Articles Match Filter',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Try adjusting your search or filter criteria.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => newsProvider.loadMyNews(refresh: true),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredNews.length,
            itemBuilder: (context, index) {
              return NewsCard(
                news: filteredNews[index],
                onTap: () => _navigateToNewsDetail(filteredNews[index]),
                onBookmark: () => _handleNewsBookmark(filteredNews[index]),
                showAuthorStatus: true,
              );
            },
          ),
        );
      },
    );
  }


  List<NewsModel> _getFilteredNews(List<NewsModel> news) {
    List<NewsModel> filtered = news;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((article) =>
          article.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (article.content.toLowerCase().contains(_searchQuery.toLowerCase())) ||
          (article.summary?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
      ).toList();
    }

    // Apply category filter
    if (_selectedCategory != 'all') {
      filtered = filtered.where((article) =>
          article.category?.toLowerCase() == _selectedCategory.toLowerCase()
      ).toList();
    }

    return filtered;
  }

  void _navigateToNewsDetail(NewsModel news) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewsDetailScreen(newsId: news.id),
      ),
    );
  }

  Future<void> _handleNewsBookmark(NewsModel news) async {
    final newsProvider = Provider.of<NewsProvider>(context, listen: false);
    final success = await newsProvider.bookmarkNews(news.id);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Bookmarked: ${news.title}' : 'Failed to bookmark article'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search News'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Enter news title or keyword...',
            prefixIcon: Icon(Icons.search),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _searchQuery = _searchController.text;
              });
              Navigator.of(context).pop();
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Consumer<NewsProvider>(
        builder: (context, newsProvider, child) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Filter News',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.all_inclusive),
                  title: const Text('All Categories'),
                  trailing: _selectedCategory == 'all' ? const Icon(Icons.check, color: Colors.green) : null,
                  onTap: () {
                    setState(() {
                      _selectedCategory = 'all';
                    });
                    Navigator.pop(context);
                  },
                ),
                ...newsProvider.categories.map((category) => ListTile(
                  leading: _getCategoryIcon(category),
                  title: Text(category),
                  trailing: _selectedCategory.toLowerCase() == category.toLowerCase() 
                      ? const Icon(Icons.check, color: Colors.green) : null,
                  onTap: () {
                    setState(() {
                      _selectedCategory = category;
                    });
                    Navigator.pop(context);
                  },
                )),
              ],
            ),
          );
        },
      ),
    );
  }

  Icon _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'business':
        return const Icon(Icons.business);
      case 'sports':
        return const Icon(Icons.sports);
      case 'technology':
        return const Icon(Icons.computer);
      case 'health':
        return const Icon(Icons.health_and_safety);
      case 'entertainment':
        return const Icon(Icons.movie);
      default:
        return const Icon(Icons.article);
    }
  }
}

class NewsCard extends StatelessWidget {
  final NewsModel news;
  final VoidCallback onTap;
  final VoidCallback? onBookmark;
  final bool showPublishedDate;
  final bool showAuthorStatus;

  const NewsCard({
    super.key,
    required this.news,
    required this.onTap,
    this.onBookmark,
    this.showPublishedDate = false,
    this.showAuthorStatus = false,
  });

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  String _formatTime(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // News Image
            if (news.imageUrl != null && news.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: CachedNetworkImage(
                    imageUrl: news.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.primary.withOpacity(0.8),
                          ],
                        ),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.primary.withOpacity(0.8),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.article,
                          color: theme.colorScheme.onPrimary,
                          size: 48,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // News title and category
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          news.title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (news.category != null && news.category!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            news.category!,
                            style: TextStyle(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // News summary or content preview
                  Text(
                    news.summary?.isNotEmpty == true ? news.summary! : news.contentPreview,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  
                  // News details
                  _buildNewsDetailRow(
                    icon: Icons.access_time,
                    text: showPublishedDate && news.publishedAt != null
                        ? 'Published ${_formatDate(news.publishedAt!)} at ${_formatTime(news.publishedAt!)}'
                        : 'Created ${_formatDate(news.createdAt)} at ${_formatTime(news.createdAt)}',
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 4),
                  
                  _buildNewsDetailRow(
                    icon: Icons.schedule_outlined,
                    text: '${news.readingTime} min read',
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  
                  // Show publication status for author
                  if (showAuthorStatus) ...[
                    const SizedBox(height: 4),
                    _buildNewsDetailRow(
                      icon: news.isPublished ? Icons.publish : Icons.drafts,
                      text: news.isPublished ? 'Published' : 'Draft',
                      color: news.isPublished ? Colors.green : Colors.orange,
                    ),
                  ],
                  
                  const SizedBox(height: 12),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          news.formattedDate,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ),
                      if (onBookmark != null)
                        IconButton(
                          onPressed: onBookmark,
                          icon: const Icon(Icons.bookmark_border),
                          iconSize: 20,
                        ),
                      IconButton(
                        onPressed: () {
                          // Share functionality - implement as needed
                        },
                        icon: const Icon(Icons.share),
                        iconSize: 20,
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

  Widget _buildNewsDetailRow({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}