import 'package:flutter/foundation.dart';
import '../core/services/api_service.dart';
import '../core/models/reward_model.dart';

class RewardsProvider with ChangeNotifier {
  final ApiService _apiService = ApiService.instance;

  // State variables
  List<UserRewardModel> _userRewards = [];
  bool _isLoading = false;
  bool _isRedeeming = false;
  String? _error;

  // Getters
  List<UserRewardModel> get userRewards => _userRewards;
  bool get isLoading => _isLoading;
  bool get isRedeeming => _isRedeeming;
  String? get error => _error;

  // Filter getters
  List<UserRewardModel> get earnedRewards => 
      _userRewards.where((r) => r.status == 'earned').toList();
  
  List<UserRewardModel> get redeemedRewards => 
      _userRewards.where((r) => r.status == 'redeemed').toList();
  
  List<UserRewardModel> get expiredRewards => 
      _userRewards.where((r) => r.status == 'expired').toList();

  // Load user rewards from API
  Future<void> loadUserRewards() async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _apiService.getUserRewards();
      
      if (response['success'] == true) {
        final rewardsData = response['data'] as List;
        _userRewards = rewardsData
            .map((json) => UserRewardModel.fromJson(json as Map<String, dynamic>))
            .toList();
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

  // Redeem/claim a reward
  Future<bool> redeemReward(String rewardId) async {
    try {
      _setRedeeming(true);
      _clearError();

      final response = await _apiService.claimReward(rewardId);
      
      if (response['success'] == true) {
        // Update the local reward status
        final index = _userRewards.indexWhere((r) => r.id == rewardId);
        if (index != -1) {
          final updatedReward = _userRewards[index].copyWith(
            status: 'redeemed',
            redeemedAt: DateTime.now(),
          );
          _userRewards[index] = updatedReward;
          notifyListeners();
        }
        
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

  // Refresh rewards data
  Future<void> refreshRewards() async {
    await loadUserRewards();
  }

  // Get specific reward by ID
  UserRewardModel? getRewardById(String id) {
    try {
      return _userRewards.firstWhere((reward) => reward.id == id);
    } catch (e) {
      return null;
    }
  }

  // Check if user can redeem more rewards
  bool canRedeemMoreRewards() {
    final availableRewards = earnedRewards.where((r) => r.canRedeem).length;
    return availableRewards > 0;
  }

  // Get rewards count by status
  int getRewardsCountByStatus(String status) {
    return _userRewards.where((r) => r.status == status).length;
  }

  // Private helper methods
  void _setLoading(bool value) {
    _isLoading = value;
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
    _isLoading = false;
    _isRedeeming = false;
    _error = null;
    notifyListeners();
  }
}
