import 'package:flutter/foundation.dart';
import '../core/services/api_service.dart';
import '../core/models/event_model.dart';
import 'dart:convert';

class EventsProvider with ChangeNotifier {
  final ApiService _apiService = ApiService.instance;

  // State variables
  List<EventModel> _events = [];
  EventModel? _selectedEvent;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  String _selectedCategory = 'all';
  String _searchQuery = '';
  int _currentPage = 1;
  bool _hasMoreData = true;

  // Getters
  List<EventModel> get events => _events;
  EventModel? get selectedEvent => _selectedEvent;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  bool get hasMoreData => _hasMoreData;

  // Filtered events based on category
  List<EventModel> get filteredEvents {
    if (_selectedCategory == 'all') {
      return _events.where((event) => 
        event.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        event.description.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    return _events.where((event) => 
      event.category?.toLowerCase() == _selectedCategory.toLowerCase() &&
      (event.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
       event.description.toLowerCase().contains(_searchQuery.toLowerCase()))
    ).toList();
  }

  // Add to EventsProvider
Future<bool> createEvent({
  required String title,
  required String description, 
  required DateTime eventDate,
  required String location,
  String? category,
  int? maxParticipants,
  String? bannerImage,
}) async {
  try {
    _setLoading(true);
    _clearError();

    final eventData = {
      'title': title,
      'description': description,
      'eventdate': eventDate.toUtc().toIso8601String(),
      'location': location,
      'category': category ?? 'general',
      'maxparticipants': maxParticipants,
      'bannerimage': bannerImage,
    };

    print("🔍 DEBUG: Sending event data: ${jsonEncode(eventData)}");

    final result = await _apiService.createEvent(eventData);
    
    print("🔍 DEBUG: API Response: $result");
    
    // Check if the response indicates success
    if (result['success'] == true || result.containsKey('id') || result.containsKey('event')) {
      await loadEvents();
      return true;
    } else {
      // Handle the error response
      final errorMessage = result['message'] ?? result['error'] ?? 'Failed to create event';
      _setError(errorMessage);
      return false;
    }
  } catch (e) {
    print("🔍 DEBUG: Exception: $e");
    _setError('Failed to create event: $e');
    return false;
  } finally {
    _setLoading(false);
  }
}



  // Load events
  Future<void> loadEvents({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMoreData = true;
      _events.clear();
    }

    if (_isLoading || _isLoadingMore || !_hasMoreData) return;

    try {
      if (_currentPage == 1) {
        _setLoading(true);
      } else {
        _setLoadingMore(true);
      }

      _clearError();

      final response = await _apiService.getEvents(
        page: _currentPage,
        category: _selectedCategory == 'all' ? null : _selectedCategory,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      );

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;
        final eventsData = data['events'] as List<dynamic>? ?? [];

        final newEvents = eventsData
            .map((json) => EventModel.fromJson(json as Map<String, dynamic>))
            .toList();

        if (_currentPage == 1) {
          _events = newEvents;
        } else {
          _events.addAll(newEvents);
        }

        _hasMoreData = newEvents.length >= 20; // Assuming page size is 20
        _currentPage++;

        notifyListeners();
      } else {
        _setError(response['message'] as String? ?? 'Failed to load events');
      }
    } catch (e) {
      _setError('Failed to load events: $e');
    } finally {
      _setLoading(false);
      _setLoadingMore(false);
    }
  }

  // Load more events (pagination)
  Future<void> loadMoreEvents() async {
    if (!_hasMoreData || _isLoading || _isLoadingMore) return;
    await loadEvents();
  }

  // Load event details
  Future<void> loadEventDetails(String eventId) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _apiService.getEvent(eventId);

      if (response['success'] == true && response['data'] != null) {
        _selectedEvent = EventModel.fromJson(response['data'] as Map<String, dynamic>);
        notifyListeners();
      } else {
        _setError(response['message'] as String? ?? 'Failed to load event details');
      }
    } catch (e) {
      _setError('Failed to load event details: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Register for event
  Future<bool> registerForEvent(String eventId) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _apiService.registerForEvent(eventId);

      if (response['success'] == true) {
        // Update local event data
        if (_selectedEvent?.id == eventId) {
          _selectedEvent = _selectedEvent!.copyWith(
            isRegistered: true,
            currentParticipants: _selectedEvent!.currentParticipants + 1,
          );
        }

        // Update in events list too
        final index = _events.indexWhere((e) => e.id == eventId);
        if (index != -1) {
          _events[index] = _events[index].copyWith(
            isRegistered: true,
            currentParticipants: _events[index].currentParticipants + 1,
          );
        }

        notifyListeners();
        return true;
      } else {
        _setError(response['message'] as String? ?? 'Registration failed');
        return false;
      }
    } catch (e) {
      _setError('Registration failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Unregister from event
  Future<bool> unregisterFromEvent(String eventId) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _apiService.unregisterFromEvent(eventId);

      if (response['success'] == true) {
        // Update local event data
        if (_selectedEvent?.id == eventId) {
          _selectedEvent = _selectedEvent!.copyWith(
            isRegistered: false,
            currentParticipants: _selectedEvent!.currentParticipants - 1,
          );
        }

        // Update in events list too
        final index = _events.indexWhere((e) => e.id == eventId);
        if (index != -1) {
          _events[index] = _events[index].copyWith(
            isRegistered: false,
            currentParticipants: _events[index].currentParticipants - 1,
          );
        }

        notifyListeners();
        return true;
      } else {
        _setError(response['message'] as String? ?? 'Unregistration failed');
        return false;
      }
    } catch (e) {
      _setError('Unregistration failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Set category filter
  void setCategory(String category) {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      _events.clear();
      _currentPage = 1;
      _hasMoreData = true;
      notifyListeners();
      loadEvents();
    }
  }

  // Set search query
  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      _events.clear();
      _currentPage = 1;
      _hasMoreData = true;
      notifyListeners();
      loadEvents();
    }
  }

  // Clear search
  void clearSearch() {
    setSearchQuery('');
  }

  // Refresh events
  Future<void> refresh() async {
    await loadEvents(refresh: true);
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