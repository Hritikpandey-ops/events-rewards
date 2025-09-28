import 'package:flutter/foundation.dart';
import '../core/services/api_service.dart';
import '../core/models/reward_model.dart';

class RewardsProvider with ChangeNotifier {
  final ApiService _apiService = ApiService.instance;

  // State variables
  List<UserReward> _userRewards = [];
  UserRewardStats? _userStats;
  bool _isLoading = false;
  bool _isSpinning = false;
  bool _isRedeeming = false;
  String? _error;
  
  // Spin tracking from backend
  int _spinsLeft = 3;
  int _spinsUsed = 0;
  DateTime? _lastSpin;

  // Getters
  List<UserReward> get userRewards => _userRewards;
  UserRewardStats? get userStats => _userStats;
  bool get isLoading => _isLoading;
  bool get isSpinning => _isSpinning;
  bool get isRedeeming => _isRedeeming;
  String? get error => _error;
  
  // Spin tracking getters
  int get spinsLeft => _spinsLeft;
  int get spinsUsed => _spinsUsed;
  DateTime? get lastSpin => _lastSpin;
  bool get canSpinToday => _spinsLeft > 0;

  // Filter getters
  List<UserReward> get pendingRewards => _userRewards.where((r) => r.isPending).toList();
  List<UserReward> get claimedRewards => _userRewards.where((r) => r.isClaimed).toList();
  List<UserReward> get expiredRewards => _userRewards.where((r) => r.isExpired).toList();

  // Load remaining spins from backend
  Future<void> loadRemainingSpins() async {
    try {
      final response = await _apiService.getRemainingSpins();
      if (response['success'] == true) {
        final data = response['data'];
        _spinsLeft = data['remaining_spins'] ?? 3;
        _spinsUsed = data['spins_used_today'] ?? 0;
        if (data['last_spin'] != null) {
          _lastSpin = DateTime.parse(data['last_spin']);
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading remaining spins: $e');
      // Keep current values as fallback
    }
  }

  // Load user rewards from API
  Future<void> loadUserRewards() async {
    try {
      _setLoading(true);
      _clearError();
      
      final response = await _apiService.getUserRewards();
      if (response['success'] == true) {
        final rewardsData = response['data'] as List;
        _userRewards = rewardsData
            .map((json) => UserReward.fromJson(json as Map<String, dynamic>))
            .toList();
        notifyListeners();
      } else {
        throw Exception(response['message'] ?? 'Failed to load rewards');
      }
    } catch (e) {
      _setError(e.toString());
      debugPrint('Error loading user rewards: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load user stats from API
  Future<void> loadUserStats() async {
    try {
      final response = await _apiService.getUserStats();
      if (response['success'] == true) {
        _userStats = UserRewardStats.fromJson(response['data'] as Map<String, dynamic>);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading user stats: $e');
      // Keep existing stats or create default
    }
  }

  // Perform spin
  Future<SpinResponse?> spinWheel() async {
    try {
      _setSpinning(true);
      _clearError();
      
      final response = await _apiService.spinLuckyDraw();
      if (response['success'] == true) {
        final spinResponse = SpinResponse.fromJson(response['data'] as Map<String, dynamic>);
        
        // Refresh data after spin
        await Future.wait([
          loadUserRewards(),
          loadRemainingSpins(),
          loadUserStats(),
        ]);
        
        notifyListeners();
        return spinResponse;
      } else {
        _setError(response['message'] ?? 'Failed to spin wheel');
        return null;
      }
    } catch (e) {
      _setError(e.toString());
      debugPrint('Error spinning wheel: $e');
      return null;
    } finally {
      _setSpinning(false);
    }
  }

  // Redeem/claim a reward using claim code
  Future<bool> redeemReward(String claimCode) async {
    try {
      _setRedeeming(true);
      _clearError();
      
      final response = await _apiService.claimReward(claimCode);
      if (response['success'] == true) {
        // Refresh user rewards and stats after claiming
        await Future.wait([
          loadUserRewards(),
          loadUserStats(),
        ]);
        notifyListeners();
        return true;
      } else {
        _setError(response['message'] ?? 'Failed to redeem reward');
        return false;
      }
    } catch (e) {
      _setError(e.toString());
      debugPrint('Error redeeming reward: $e');
      return false;
    } finally {
      _setRedeeming(false);
    }
  }

  // Refresh all data
  Future<void> refreshAllData() async {
    await Future.wait([
      loadUserRewards(),
      loadRemainingSpins(),
      loadUserStats(),
    ]);
  }

  // Private helper methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setSpinning(bool value) {
    _isSpinning = value;
    notifyListeners();
  }

  void _setRedeeming(bool value) {
    _isRedeeming = value;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  // Clear all data
  void clear() {
    _userRewards.clear();
    _userStats = null;
    _isLoading = false;
    _isSpinning = false;
    _isRedeeming = false;
    _error = null;
    _spinsLeft = 3;
    _spinsUsed = 0;
    _lastSpin = null;
    notifyListeners();
  }
}
