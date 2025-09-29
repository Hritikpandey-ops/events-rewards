// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/news_provider.dart';
import '../../core/models/news_model.dart';
import 'create_news_screen.dart';

class ManageNewsScreen extends StatefulWidget {
  const ManageNewsScreen({super.key});

  @override
  State<ManageNewsScreen> createState() => _ManageNewsScreenState();
}

class _ManageNewsScreenState extends State<ManageNewsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMyNews();
    });
  }

  Future<void> _loadMyNews() async {
    final newsProvider = Provider.of<NewsProvider>(context, listen: false);
    await newsProvider.loadMyNews(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('My Created News'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateNewsScreen()),
              );
              if (result == true) {
                _loadMyNews();
              }
            },
          ),
        ],
      ),
      body: Consumer<NewsProvider>(
        builder: (context, newsProvider, child) {
          // Use the separate my created news list
          final myCreatedNews = newsProvider.myNews;
          
          if (newsProvider.isLoading && myCreatedNews.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading your news...'),
                ],
              ),
            );
          }

          if (newsProvider.error != null && myCreatedNews.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    newsProvider.error!,
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadMyNews,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (myCreatedNews.isEmpty) {
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
                    'You haven\'t created any news yet.\nStart by creating your first article!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateNewsScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create Your First Article'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadMyNews,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: myCreatedNews.length + (newsProvider.isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == myCreatedNews.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final news = myCreatedNews[index];
                return ManageNewsCard(
                  news: news,
                  onEdit: () => _editNews(news),
                  onDelete: () => _deleteNews(news),
                  onTogglePublish: () => _togglePublishStatus(news),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _editNews(NewsModel news) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateNewsScreen(newsToEdit: news),
      ),
    );
    if (result == true) {
      _loadMyNews();
    }
  }

  Future<void> _deleteNews(NewsModel news) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete News'),
        content: Text('Are you sure you want to delete "${news.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (result == true) {
      final newsProvider = Provider.of<NewsProvider>(context, listen: false);
      final success = await newsProvider.deleteNews(news.id);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${news.title}" has been deleted'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete "${news.title}"'),
            backgroundColor: Colors.red,
          ),
        );
      }
      
      if (result == true) {
        _loadMyNews();
      }
    }
  }

  Future<void> _togglePublishStatus(NewsModel news) async {
    final newsProvider = Provider.of<NewsProvider>(context, listen: false);
    final success = await newsProvider.togglePublishStatus(news.id);
    
    if (success && mounted) {
      final action = news.isPublished ? 'unpublished' : 'published';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${news.title}" has been $action'),
          backgroundColor: Colors.green,
        ),
      );
      _loadMyNews();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update publication status'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class ManageNewsCard extends StatelessWidget {
  final NewsModel news;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTogglePublish;

  const ManageNewsCard({
    super.key,
    required this.news,
    required this.onEdit,
    required this.onDelete,
    required this.onTogglePublish,
  });

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  String _formatTime(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }

  String _getStatus(NewsModel news) {
    if (news.isPublished && news.publishedAt != null) return 'Published';
    if (!news.isPublished) return 'Draft';
    return 'Publish';
  }

  Color _getStatusColor(NewsModel news, ThemeData theme) {
    if (news.isPublished) return Colors.green;
    if (!news.isPublished) return Colors.orange;
    return theme.colorScheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _getStatusColor(news, theme).withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(news, theme),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatus(news),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${news.readingTime} min read',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and category
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
                      Flexible(
                        child: Container(
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
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Summary or content preview
                Text(
                  news.summary?.isNotEmpty ?? false ? news.summary! : news.contentPreview,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                
                // News details
                _buildDetailRow(
                  icon: Icons.access_time,
                  text: 'Created: ${_formatDate(news.createdAt)} at ${_formatTime(news.createdAt)}',
                ),
                
                if (news.publishedAt != null)
                  _buildDetailRow(
                    icon: Icons.publish,
                    text: 'Published: ${_formatDate(news.publishedAt!)} at ${_formatTime(news.publishedAt!)}',
                  ),
                
                const SizedBox(height: 16),
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onTogglePublish,
                        icon: Icon(
                          news.isPublished ? Icons.visibility_off : Icons.publish,
                          size: 16,
                        ),
                        label: Text(news.isPublished ? 'Unpublish' : 'Publish'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: news.isPublished ? Colors.orange : Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete, size: 16),
                        label: const Text('Delete'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
