// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../../core/constants/colors.dart';
import '../../core/widgets/error_widget.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/models/reward_model.dart';
import '../../providers/rewards_provider.dart';

class MyRewardsScreen extends StatefulWidget {
  const MyRewardsScreen({super.key});

  @override
  State<MyRewardsScreen> createState() => _MyRewardsScreenState();
}

class _MyRewardsScreenState extends State<MyRewardsScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  bool _isRefreshing = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRewards();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRewards() async {
    final rewardsProvider = Provider.of<RewardsProvider>(context, listen: false);
    await rewardsProvider.refreshAllData();
  }

  Future<void> _refreshRewards() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
    });

    try {
      final rewardsProvider = Provider.of<RewardsProvider>(context, listen: false);
      await rewardsProvider.refreshAllData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rewards refreshed successfully'),
            backgroundColor: AppColors.successColor,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh: ${e.toString()}'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _redeemReward(UserReward userReward) async {
    if (!userReward.canClaim || userReward.claimCode == null) return;

    // Show confirmation dialog
    final confirmed = await _showClaimConfirmation(userReward);
    if (!confirmed) return;

    final rewardsProvider = Provider.of<RewardsProvider>(context, listen: false);
    final success = await rewardsProvider.redeemReward(userReward.claimCode!);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Reward claimed successfully!'
                : rewardsProvider.error ?? 'Failed to claim reward'
          ),
          backgroundColor: success ? AppColors.successColor : AppColors.errorColor,
          duration: Duration(seconds: success ? 3 : 5),
          action: success ? null : SnackBarAction(
            label: 'Retry',
            onPressed: () => _redeemReward(userReward),
          ),
        ),
      );
    }
  }

  Future<bool> _showClaimConfirmation(UserReward userReward) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Claim Reward'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to claim this reward?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userReward.reward?.name ?? 'Unknown Reward',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (userReward.reward?.description != null)
                    Text(userReward.reward!.description!),
                  if (userReward.reward?.value != null)
                    Text('Value: ${userReward.reward!.value}'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Claim'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _copyClaimCode(String claimCode) {
    Clipboard.setData(ClipboardData(text: claimCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Claim code copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<RewardsProvider>(
      builder: (context, rewardsProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('My Rewards'),
            automaticallyImplyLeading: false,
            actions: [
              if (_isRefreshing)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _refreshRewards,
                  tooltip: 'Refresh rewards',
                ),
            ],
            bottom: TabBar(
              controller: _tabController,
              labelColor: AppColors.primaryColor,
              unselectedLabelColor: AppColors.textSecondaryColor,
              indicatorColor: AppColors.primaryColor,
              tabs: [
                Tab(
                  text: 'Pending (${rewardsProvider.pendingRewards.length})',
                ),
                Tab(
                  text: 'Claimed (${rewardsProvider.claimedRewards.length})',
                ),
                Tab(
                  text: 'Expired (${rewardsProvider.expiredRewards.length})',
                ),
              ],
            ),
          ),
          body: Stack(
            children: [
              TabBarView(
                controller: _tabController,
                children: [
                  _buildRewardsList(rewardsProvider.pendingRewards, 'pending', rewardsProvider),
                  _buildRewardsList(rewardsProvider.claimedRewards, 'claimed', rewardsProvider),
                  _buildRewardsList(rewardsProvider.expiredRewards, 'expired', rewardsProvider),
                ],
              ),
              if (rewardsProvider.isRedeeming)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(child: LoadingWidget()),
                ),
            ],
          ),
          floatingActionButton: rewardsProvider.userStats != null
              ? FloatingActionButton.extended(
                  onPressed: () => _showStatsDialog(rewardsProvider.userStats!),
                  icon: const Icon(Icons.analytics),
                  label: const Text('Stats'),
                  backgroundColor: AppColors.primaryColor,
                )
              : null,
        );
      },
    );
  }

  void _showStatsDialog(UserRewardStats stats) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🏆 Your Reward Stats'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatItem('Total Spins', '${stats.totalSpins}', Icons.refresh),
            _buildStatItem('Total Wins', '${stats.totalWins}', Icons.emoji_events),
            _buildStatItem('Pending Rewards', '${stats.pendingRewards}', Icons.hourglass_empty),
            _buildStatItem('Claimed Rewards', '${stats.claimedRewards}', Icons.check_circle),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primaryColor),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardsList(List<UserReward> rewards, String status, RewardsProvider rewardsProvider) {
    if (rewardsProvider.isLoading && rewards.isEmpty) {
      return const Center(child: LoadingWidget());
    }

    if (rewardsProvider.error != null && rewards.isEmpty) {
      return CustomErrorWidget(
        message: rewardsProvider.error!,
        onRetry: _loadRewards,
      );
    }

    if (rewards.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshRewards,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getStatusIcon(status),
                    size: 64,
                    color: AppColors.textSecondaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _getEmptyMessage(status),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _refreshRewards,
                    child: const Text('Refresh'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshRewards,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: rewards.length,
        itemBuilder: (context, index) {
          final userReward = rewards[index];
          return _buildRewardCard(userReward, status);
        },
      ),
    );
  }

  Widget _buildRewardCard(UserReward userReward, String status) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final reward = userReward.reward;

    if (reward == null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('Invalid reward data'),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkCardColor : AppColors.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with reward details
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getRewardTypeColor(reward.rewardType ?? 'default').withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getRewardTypeIcon(reward.rewardType ?? 'default'),
                    color: _getRewardTypeColor(reward.rewardType ?? 'default'),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reward.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (reward.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          reward.description!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondaryColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _getStatusColor(status),
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Details row
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    context,
                    label: 'Earned',
                    value: userReward.formattedCreatedDate,
                  ),
                ),
                if (status == 'claimed')
                  Expanded(
                    child: _buildDetailItem(
                      context,
                      label: 'Claimed',
                      value: userReward.formattedClaimedDate,
                    ),
                  ),
                if (status == 'pending' && userReward.expiresAt != null)
                  Expanded(
                    child: _buildDetailItem(
                      context,
                      label: 'Expires',
                      value: userReward.formattedExpiryDate,
                    ),
                  ),
              ],
            ),

            if (userReward.claimCode != null && userReward.isPending) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primaryColor,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.confirmation_number,
                      size: 16,
                      color: AppColors.primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Code: ${userReward.claimCode}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 16),
                      onPressed: () => _copyClaimCode(userReward.claimCode!),
                      color: AppColors.primaryColor,
                      tooltip: 'Copy code',
                    ),
                  ],
                ),
              ),
            ],

            // Value display
            if (reward.value != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.monetization_on,
                      size: 16,
                      color: AppColors.successColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Value: ${reward.value}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.successColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Action button for pending rewards
            if (status == 'pending') ...[
              const SizedBox(height: 16),
              CustomButton(
                text: userReward.canClaim ? 'Claim Now' : 'Expired',
                onPressed: userReward.canClaim ? () => _redeemReward(userReward) : null,
                width: double.infinity,
                backgroundColor: userReward.canClaim
                    ? _getRewardTypeColor(reward.rewardType ?? 'default')
                    : Colors.grey,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(BuildContext context, {
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondaryColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.card_giftcard;
      case 'claimed':
        return Icons.check_circle;
      case 'expired':
        return Icons.access_time;
      default:
        return Icons.card_giftcard;
    }
  }

  String _getEmptyMessage(String status) {
    switch (status) {
      case 'pending':
        return 'No pending rewards yet.\nParticipate in events and spin the lucky draw to earn rewards!';
      case 'claimed':
        return 'No claimed rewards yet.\nClaim your earned rewards to see them here!';
      case 'expired':
        return 'No expired rewards.\nKeep earning and claiming on time!';
      default:
        return 'No rewards available.';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.warningColor;
      case 'claimed':
        return AppColors.successColor;
      case 'expired':
        return AppColors.errorColor;
      default:
        return AppColors.textSecondaryColor;
    }
  }

  IconData _getRewardTypeIcon(String type) {
    switch (type) {
      case 'points':
        return Icons.star;
      case 'voucher':
        return Icons.local_offer;
      case 'discount':
        return Icons.percent;
      case 'coupon':
        return Icons.confirmation_number;
      case 'coffee':
        return Icons.coffee;
      case 'gift':
        return Icons.card_giftcard;
      default:
        return Icons.card_giftcard;
    }
  }

  Color _getRewardTypeColor(String type) {
    switch (type) {
      case 'points':
        return Colors.amber;
      case 'voucher':
        return Colors.green;
      case 'discount':
        return Colors.blue;
      case 'coupon':
        return Colors.purple;
      case 'coffee':
        return Colors.brown;
      case 'gift':
        return AppColors.primaryColor;
      default:
        return AppColors.primaryColor;
    }
  }
}
