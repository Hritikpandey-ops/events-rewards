import 'package:flutter/foundation.dart';
import '../core/services/api_service.dart';
import '../core/models/news_model.dart';

class NewsProvider with ChangeNotifier {
  final ApiService _apiService = ApiService.instance;

  // State variables
  List<NewsModel> _news = [];
  NewsModel? _selectedNews;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  String _selectedCategory = 'all';
  String _searchQuery = '';
  int _currentPage = 1;
  bool _hasMoreData = true;

  // Getters
  List<NewsModel> get news => _news;
  NewsModel? get selectedNews => _selectedNews;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  bool get hasMoreData => _hasMoreData;

  // Filtered news based on category
  List<NewsModel> get filteredNews {
    if (_selectedCategory == 'all') {
      return _news.where((article) => 
        article.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        article.content.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    return _news.where((article) => 
      article.category?.toLowerCase() == _selectedCategory.toLowerCase() &&
      (article.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
       article.content.toLowerCase().contains(_searchQuery.toLowerCase()))
    ).toList();
  }

  // Load news
  Future<void> loadNews({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMoreData = true;
      _news.clear();
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
        final newsData = data['news'] as List<dynamic>? ?? [];

        final newArticles = newsData
            .map((json) => NewsModel.fromJson(json as Map<String, dynamic>))
            .toList();

        if (_currentPage == 1) {
          _news = newArticles;
        } else {
          _news.addAll(newArticles);
        }

        _hasMoreData = newArticles.length >= 20; // Assuming page size is 20
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

  // Load more news (pagination)
  Future<void> loadMoreNews() async {
    if (!_hasMoreData || _isLoading || _isLoadingMore) return;
    await loadNews();
  }

  // Load news details
  Future<void> loadNewsDetails(String newsId) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _apiService.getNewsArticle(newsId);

      if (response['success'] == true && response['data'] != null) {
        _selectedNews = NewsModel.fromJson(response['data'] as Map<String, dynamic>);
        notifyListeners();
      } else {
        _setError(response['message'] as String? ?? 'Failed to load article');
      }
    } catch (e) {
      _setError('Failed to load article: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Set category filter
  void setCategory(String category) {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      _news.clear();
      _currentPage = 1;
      _hasMoreData = true;
      notifyListeners();
      loadNews();
    }
  }

  // Set search query
  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      _news.clear();
      _currentPage = 1;
      _hasMoreData = true;
      notifyListeners();
      loadNews();
    }
  }

  // Clear search
  void clearSearch() {
    setSearchQuery('');
  }

  // Refresh news
  Future<void> refresh() async {
    await loadNews(refresh: true);
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