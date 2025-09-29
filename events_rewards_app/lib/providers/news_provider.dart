// news_provider.dart - Enhanced version for Create/Manage functionality

import 'package:flutter/foundation.dart';
import '../core/services/api_service.dart';
import '../core/models/news_model.dart';

class NewsProvider with ChangeNotifier {
  final ApiService _apiService = ApiService.instance;

  // State variables
  List<NewsModel> _allNews = [];
  List<NewsModel> _filteredNews = [];
  List<NewsModel> _myNews = []; 
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  String _selectedCategory = 'all';
  String _searchQuery = '';
  int _currentPage = 1;
  List<String> _categories = ['Business', 'Sports', 'Technology', 'Health', 'Entertainment', 'Politics', 'Education', 'Science', 'Other'];
  NewsModel? _selectedNews;
  bool _hasMoreData = true;

  // Getters
  List<NewsModel> get allNews => _allNews;
  List<NewsModel> get filteredNews => _filteredNews;
  List<NewsModel> get myNews => _myNews; 
  List<String> get categories => _categories;
  NewsModel? get selectedNews => _selectedNews;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  bool get hasMoreData => _hasMoreData;

  // Load all published news
  Future<void> loadAllNews({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMoreData = true;
      _allNews.clear();
      _filteredNews.clear();
    }

    if (_isLoading || _isLoadingMore || !_hasMoreData) return;

    try {
      if (_currentPage == 1) {
        _setLoading(true);
      } else {
        _setLoadingMore(true);
      }

      _clearError();

      final response = await _apiService.getNews(
        page: _currentPage,
        category: _selectedCategory == 'all' ? null : _selectedCategory,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      );

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;
        final newsData = data['news'] as List? ?? [];
        final pagination = data['pagination'] as Map? ?? {};

        final newArticles = newsData
            .map((json) => NewsModel.fromJson(json as Map<String, dynamic>))
            .toList();

        if (_currentPage == 1) {
          _allNews = newArticles;
        } else {
          _allNews.addAll(newArticles);
        }

        // Apply current filters to the new data
        _applyFilters();
        _hasMoreData = pagination['has_next'] as bool? ?? false;
        _currentPage++;
        notifyListeners();
      } else {
        _setError(response['message'] as String? ?? 'Failed to load news');
      }
    } catch (e) {
      _setError('Failed to load news: $e');
    } finally {
      _setLoading(false);
      _setLoadingMore(false);
    }
  }

  // Load user's created news 
  Future<void> loadMyNews({bool refresh = false}) async {
    if (refresh) {
      _myNews.clear();
    }

    try {
      _setLoading(true);
      _clearError();
      
      final response = await _apiService.getMyNews();
      
      if (response['success'] == true) {
        
        // Check if response has data
        
        if (response['data'] != null) {
          // Try to cast to Map first
          final data = response['data'] as Map<String, dynamic>;
          if (data.containsKey('news')) {
            final newsData = data['news'] as List? ?? [];
            // Try to map to NewsModel
            try {
              _myNews = newsData
                  .map((json) {
                    return NewsModel.fromJson(json as Map<String, dynamic>);
                  })
                  .toList();
              for (var news in _myNews) {
                print('DEBUG: News item - ID: ${news.id}, Title: ${news.title}, Published: ${news.isPublished}');
              }
            } catch (e) {
              _setError('Error parsing news data: $e');
              return;
            }
          } else {
            final newsData = response['data'] as List? ?? [];
            _myNews = newsData
                .map((json) => NewsModel.fromJson(json as Map<String, dynamic>))
                .toList();
          }
        } else {
          _myNews = [];
        }
        notifyListeners();
        
      } else {
        _setError(response['message'] ?? 'Failed to load your news');
      }
    } finally {
      _setLoading(false);
    }
  }

  // Load news categories (ADDED)
  Future<void> loadCategories() async {
    try {
      final response = await _apiService.dio.get('/news/categories');
      if (response.data['success'] == true) {
        final List<dynamic> categoryData = response.data['data'] ?? [];
        _categories = categoryData.map((item) => item.toString()).toList();
        notifyListeners();
      }
    } catch (e) {
      // Use default categories if API fails
      _categories = ['Business', 'Sports', 'Technology', 'Health', 'Entertainment', 'Politics', 'Education', 'Science', 'Other'];
    }
  }

  // Create news (ADDED)
  Future<bool> createNews({
    required String title,
    required String content,
    String? summary,
    String? imageUrl,
    String? category,
    bool isPublished = false,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _apiService.dio.post('/news', data: {
        'title': title,
        'content': content,
        'summary': summary,
        'image_url': imageUrl,
        'category': category,
        'is_published': isPublished,
      });

      if (response.data['success'] == true) {
        final newNews = NewsModel.fromJson(response.data['data'] as Map<String, dynamic>);
        _myNews.insert(0, newNews);
        
        // Also add to allNews if published
        if (isPublished) {
          _allNews.insert(0, newNews);
          _applyFilters();
        }
        
        notifyListeners();
        return true;
      } else {
        _setError(response.data['message'] ?? 'Failed to create news');
        return false;
      }
    } catch (e) {
      _setError('Failed to create news: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update news (ADDED)
  Future<bool> updateNews({
    required String newsId,
    required String title,
    required String content,
    String? summary,
    String? imageUrl,
    String? category,
    bool isPublished = false,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _apiService.dio.put('/news/$newsId', data: {
        'title': title,
        'content': content,
        'summary': summary,
        'image_url': imageUrl,
        'category': category,
        'is_published': isPublished,
      });

      if (response.data['success'] == true) {
        final updatedNews = NewsModel.fromJson(response.data['data'] as Map<String, dynamic>);
        
        // Update in myNews
        final myNewsIndex = _myNews.indexWhere((news) => news.id == newsId);
        if (myNewsIndex != -1) {
          _myNews[myNewsIndex] = updatedNews;
        }
        
        // Update in allNews
        final allNewsIndex = _allNews.indexWhere((news) => news.id == newsId);
        if (allNewsIndex != -1) {
          _allNews[allNewsIndex] = updatedNews;
        }
        
        _applyFilters();
        notifyListeners();
        return true;
      } else {
        _setError(response.data['message'] ?? 'Failed to update news');
        return false;
      }
    } catch (e) {
      _setError('Failed to update news: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Load more news for pagination
  Future<void> loadMoreNews() async {
    if (_isLoadingMore || !_hasMoreData) return;

    try {
      _isLoadingMore = true;
      notifyListeners();

      final response = await _apiService.dio.get('/news', queryParameters: {
        'page': (_allNews.length ~/ 10) + 1,
        'limit': 10,
      });

      final List<dynamic> newsData = response.data['data'] ?? [];
      final newNews = newsData.map((json) => NewsModel.fromJson(json as Map<String, dynamic>)).toList();
      
      if (newNews.isEmpty) {
        _hasMoreData = false;
      } else {
        _allNews.addAll(newNews);
        _applyFilters();
      }
    } catch (e) {
      _setError('Failed to load more news: ${e.toString()}');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // Load specific news details
  Future<void> loadNewsDetails(String newsId) async {
    try {
      _setLoading(true);
      _clearError();
      
      final response = await _apiService.dio.get('/news/$newsId');
      
      if (response.data['success'] == true) {
        _selectedNews = NewsModel.fromJson(response.data['data'] as Map<String, dynamic>);
      } else {
        _setError(response.data['message'] ?? 'Failed to load news details');
      }
    } catch (e) {
      _setError('Failed to load news details: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Delete news
  Future<bool> deleteNews(String newsId) async {
    try {
      final response = await _apiService.dio.delete('/news/$newsId');
      
      if (response.data['success'] == true) {
        _myNews.removeWhere((news) => news.id == newsId);
        _allNews.removeWhere((news) => news.id == newsId);
        _applyFilters();
        notifyListeners();
        return true;
      } else {
        _setError(response.data['message'] ?? 'Failed to delete news');
        return false;
      }
    } catch (e) {
      _setError('Failed to delete news: ${e.toString()}');
      return false;
    }
  }

  // Toggle publish status
  Future<bool> togglePublishStatus(String newsId) async {
    try {
      final response = await _apiService.dio.patch('/news/$newsId/toggle-publish');
      
      if (response.data['success'] == true) {
        final updatedNews = NewsModel.fromJson(response.data['data'] as Map<String, dynamic>);
        
        // Update in myNews
        final myNewsIndex = _myNews.indexWhere((news) => news.id == newsId);
        if (myNewsIndex != -1) {
          _myNews[myNewsIndex] = updatedNews;
        }
        
        // Update in allNews - handle publish/unpublish logic
        final allNewsIndex = _allNews.indexWhere((news) => news.id == newsId);
        if (allNewsIndex != -1) {
          if (updatedNews.isPublished) {
            _allNews[allNewsIndex] = updatedNews;
          } else {
            // Remove from allNews if unpublished (since allNews only shows published)
            _allNews.removeAt(allNewsIndex);
          }
        } else if (updatedNews.isPublished) {
          // Add to allNews if newly published
          _allNews.insert(0, updatedNews);
        }
        
        _applyFilters();
        notifyListeners();
        return true;
      } else {
        _setError(response.data['message'] ?? 'Failed to update publish status');
        return false;
      }
    } catch (e) {
      _setError('Failed to update publish status: ${e.toString()}');
      return false;
    }
  }



  // Bookmark news
  Future<bool> bookmarkNews(String newsId) async {
    try {
      final response = await _apiService.dio.post('/news/$newsId/bookmark');
      
      if (response.data['success'] == true) {
        return true;
      } else {
        _setError(response.data['message'] ?? 'Failed to bookmark news');
        return false;
      }
    } catch (e) {
      _setError('Failed to bookmark news: ${e.toString()}');
      return false;
    }
  }

  // Set category filter
  void setCategory(String category) {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      _allNews.clear();
      _currentPage = 1;
      _hasMoreData = true;
      notifyListeners();
      loadAllNews();
    }
  }

  // Set search query
  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      _applyFilters();
      notifyListeners();
    }
  }

  // Apply search filter to current data
  void _applyFilters() {
    if (_searchQuery.isEmpty) {
      _filteredNews = List<NewsModel>.from(_allNews);
    } else {
      _filteredNews = _allNews.where((article) =>
          article.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (article.summary?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          article.content.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (article.category?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
      ).toList();
    }
  }

  // Clear search
  void clearSearch() {
    setSearchQuery('');
  }

  // Clear selected news
  void clearSelectedNews() {
    _selectedNews = null;
    notifyListeners();
  }

  // Refresh news
  Future<void> refresh() async {
    await loadAllNews(refresh: true);
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setLoadingMore(bool loading) {
    _isLoadingMore = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }
}
