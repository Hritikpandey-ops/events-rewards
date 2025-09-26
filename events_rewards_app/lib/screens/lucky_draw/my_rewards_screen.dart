// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    await rewardsProvider.loadUserRewards();
  }

  Future<void> _refreshRewards() async {
    final rewardsProvider = Provider.of<RewardsProvider>(context, listen: false);
    await rewardsProvider.refreshRewards();
  }

  Future<void> _redeemReward(UserRewardModel userReward) async {
    final rewardsProvider = Provider.of<RewardsProvider>(context, listen: false);
    final success = await rewardsProvider.redeemReward(userReward.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success 
                ? 'Reward redeemed successfully!' 
                : rewardsProvider.error ?? 'Failed to redeem reward'
          ),
          backgroundColor: success ? AppColors.successColor : AppColors.errorColor,
        ),
      );
    }
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
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _refreshRewards,
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              labelColor: AppColors.primaryColor,
              unselectedLabelColor: AppColors.textSecondaryColor,
              indicatorColor: AppColors.primaryColor,
              tabs: [
                Tab(
                  text: 'Earned (${rewardsProvider.earnedRewards.length})',
                ),
                Tab(
                  text: 'Redeemed (${rewardsProvider.redeemedRewards.length})',
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
                  _buildRewardsList(rewardsProvider.earnedRewards, 'earned', rewardsProvider),
                  _buildRewardsList(rewardsProvider.redeemedRewards, 'redeemed', rewardsProvider),
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
        );
      },
    );
  }

  Widget _buildRewardsList(List<UserRewardModel> rewards, String status, RewardsProvider rewardsProvider) {
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

  Widget _buildRewardCard(UserRewardModel userReward, String status) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final reward = userReward.reward;

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
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getRewardTypeColor(reward.type).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getRewardTypeIcon(reward.type),
                    color: _getRewardTypeColor(reward.type),
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
                      Text(
                        reward.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondaryColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
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

            // Details
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    context,
                    label: 'Earned',
                    value: userReward.formattedEarnedDate,
                  ),
                ),
                if (status == 'redeemed' && userReward.redeemedAt != null)
                  Expanded(
                    child: _buildDetailItem(
                      context,
                      label: 'Redeemed',
                      value: userReward.formattedRedeemedDate,
                    ),
                  ),
                if (status == 'earned' && userReward.expiresAt != null)
                  Expanded(
                    child: _buildDetailItem(
                      context,
                      label: 'Expires',
                      value: userReward.formattedExpiryDate,
                    ),
                  ),
              ],
            ),

            // Value display
            if (reward.value != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.monetization_on,
                      size: 16,
                      color: AppColors.primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Value: ${reward.formattedValue}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Action button for earned rewards
            if (status == 'earned') ...[
              const SizedBox(height: 16),
              CustomButton(
                text: userReward.canRedeem ? 'Redeem Now' : 'Expired',
                onPressed: userReward.canRedeem ? () => _redeemReward(userReward) : null,
                width: double.infinity,
                backgroundColor: userReward.canRedeem 
                    ? _getRewardTypeColor(reward.type)
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
      case 'earned':
        return Icons.card_giftcard;
      case 'redeemed':
        return Icons.check_circle;
      case 'expired':
        return Icons.access_time;
      default:
        return Icons.card_giftcard;
    }
  }

  String _getEmptyMessage(String status) {
    switch (status) {
      case 'earned':
        return 'No earned rewards yet.\nParticipate in events and spin the lucky draw to earn rewards!';
      case 'redeemed':
        return 'No redeemed rewards yet.\nRedeem your earned rewards to see them here!';
      case 'expired':
        return 'No expired rewards.\nKeep earning and redeeming on time!';
      default:
        return 'No rewards available.';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'earned':
        return AppColors.successColor;
      case 'redeemed':
        return AppColors.primaryColor;
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
      default:
        return AppColors.primaryColor;
    }
  }
}
