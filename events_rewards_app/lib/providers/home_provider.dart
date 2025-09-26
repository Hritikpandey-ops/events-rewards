import 'package:flutter/foundation.dart';
import '../core/services/api_service.dart';
import '../core/models/ui_config_model.dart';

class HomeProvider with ChangeNotifier {
  final ApiService _apiService = ApiService.instance;

  // State variables
  UIConfigModel? _uiConfig;
  bool _isLoading = false;
  String? _error;
  DateTime? _lastUpdated;

  // Getters
  UIConfigModel? get uiConfig => _uiConfig;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get lastUpdated => _lastUpdated;

  // Check if UI config is loaded
  bool get isConfigLoaded => _uiConfig != null;

  // Get modules that should be visible
  List<UIModule> get visibleModules {
    if (_uiConfig == null) return [];
    return _uiConfig!.modules.where((module) => module.isVisible).toList();
  }

  // Load UI configuration
  Future<void> loadUIConfig({bool refresh = false}) async {
    // Don't reload if we have recent data and not forcing refresh
    if (!refresh && _uiConfig != null && _lastUpdated != null) {
      final hoursSinceUpdate = DateTime.now().difference(_lastUpdated!).inHours;
      if (hoursSinceUpdate < 1) {
        return; // Use cached data if less than 1 hour old
      }
    }

    try {
      _setLoading(true);
      _clearError();

      final response = await _apiService.getUIConfig();

      if (response['success'] == true && response['data'] != null) {
        _uiConfig = UIConfigModel.fromJson(response['data'] as Map<String, dynamic>);
        _lastUpdated = DateTime.now();
        notifyListeners();
      } else {
        _setError(response['message'] as String? ?? 'Failed to load UI configuration');
      }
    } catch (e) {
      _setError('Failed to load UI configuration: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Get specific module by type
  UIModule? getModule(String moduleType) {
    if (_uiConfig == null) return null;

    try {
      return _uiConfig!.modules.firstWhere(
        (module) => module.type == moduleType && module.isVisible,
      );
    } catch (e) {
      return null;
    }
  }

  // Check if module is enabled
  bool isModuleEnabled(String moduleType) {
    final module = getModule(moduleType);
    return module?.isVisible ?? false;
  }

  // Get module configuration
  Map<String, dynamic>? getModuleConfig(String moduleType) {
    final module = getModule(moduleType);
    return module?.config;
  }

  // Refresh UI config
  Future<void> refresh() async {
    await loadUIConfig(refresh: true);
  }

  // Check if specific features are enabled
  bool get isEventsEnabled => isModuleEnabled('events');
  bool get isNewsEnabled => isModuleEnabled('news');
  bool get isLuckyDrawEnabled => isModuleEnabled('lucky_draw');
  bool get isRewardsEnabled => isModuleEnabled('rewards');
  bool get isProfileEnabled => isModuleEnabled('profile');

  // Get module order for display
  List<UIModule> get orderedModules {
    if (_uiConfig == null) return [];

    final modules = visibleModules;
    modules.sort((a, b) => (a.order ?? 999).compareTo(b.order ?? 999));
    return modules;
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
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