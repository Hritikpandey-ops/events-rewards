import 'package:flutter/material.dart';
import '../../core/models/ui_config_model.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/constants/colors.dart';

class DynamicWidget extends StatelessWidget {
  final UIModule module;

  const DynamicWidget({
    super.key,
    required this.module,
  });

  @override
  Widget build(BuildContext context) {
    if (!module.isVisible) {
      return const SizedBox.shrink();
    }

    switch (module.type.toLowerCase()) {
      case 'events':
        return _buildEventsWidget(context);
      case 'news':
        return _buildNewsWidget(context);
      case 'lucky_draw':
        return _buildLuckyDrawWidget(context);
      case 'rewards':
        return _buildRewardsWidget(context);
      case 'banner':
        return _buildBannerWidget(context);
      case 'featured':
        return _buildFeaturedWidget(context);
      default:
        return _buildDefaultWidget(context);
    }
  }

  Widget _buildEventsWidget(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: isDarkMode ? AppColors.darkCardColor : AppColors.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.event,
                  color: AppColors.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  module.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/events');
                  },
                  child: const Text('See All'),
                ),
              ],
            ),
            if (module.description != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  module.description!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondaryColor,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            // Mock events list
            _buildEventsList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsWidget(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: isDarkMode ? AppColors.darkCardColor : AppColors.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.article,
                  color: AppColors.secondaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  module.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/news');
                  },
                  child: const Text('See All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Mock news articles
            _buildNewsList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLuckyDrawWidget(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryColor,
              // ignore: deprecated_member_use
              AppColors.primaryColor.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(
                  Icons.casino,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        module.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (module.description != null)
                        Text(
                          module.description!,
                          style: TextStyle(
                            // ignore: deprecated_member_use
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Spin Now!',
              onPressed: () {
                Navigator.pushNamed(context, '/lucky-draw');
              },
              backgroundColor: Colors.white,
              textColor: AppColors.primaryColor,
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardsWidget(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: isDarkMode ? AppColors.darkCardColor : AppColors.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.card_giftcard,
                  color: AppColors.errorColor,
                ),
                const SizedBox(width: 8),
                Text(
                  module.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/my-rewards');
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Mock rewards summary
            Row(
              children: [
                Expanded(
                  child: _buildRewardStat('Total Rewards', '5', Icons.card_giftcard),
                ),
                Expanded(
                  child: _buildRewardStat('Available', '2', Icons.redeem),
                ),
                Expanded(
                  child: _buildRewardStat('Used', '3', Icons.check_circle),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerWidget(BuildContext context) {
    final imageUrl = module.config['image_url'] as String?;
    final backgroundColor = module.config['background_color'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: backgroundColor != null
              ? Color(int.parse(backgroundColor.replaceFirst('#', '0xFF')))
              // ignore: deprecated_member_use
              : AppColors.primaryColor.withOpacity(0.1),
          image: imageUrl != null
              ? DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                // ignore: deprecated_member_use
                Colors.black.withOpacity(0.6),
              ],
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                module.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (module.description != null)
                Text(
                  module.description!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedWidget(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: isDarkMode ? AppColors.darkCardColor : AppColors.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(
              Icons.stars,
              size: 48,
              color: AppColors.primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              module.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (module.description != null) ...[
              const SizedBox(height: 8),
              Text(
                module.description!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 16),
            CustomButton(
              text: 'Learn More',
              onPressed: () {
                //navigation logic here 
              },
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultWidget(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: isDarkMode ? AppColors.darkCardColor : AppColors.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              module.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (module.description != null) ...[
              const SizedBox(height: 8),
              Text(
                module.description!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondaryColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEventsList(BuildContext context) {
    return Column(
      children: [
        _buildEventItem('Flutter Conference 2025', 'Tech conference', Icons.computer),
        _buildEventItem('Music Festival', 'Live music event', Icons.music_note),
        _buildEventItem('Food Fair', 'Local food vendors', Icons.restaurant),
      ],
    );
  }

  Widget _buildEventItem(String title, String subtitle, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsList(BuildContext context) {
    return Column(
      children: [
        _buildNewsItem('New App Features Released', '2 hours ago'),
        _buildNewsItem('Upcoming Events This Weekend', '1 day ago'),
        _buildNewsItem('Winner Announcement', '3 days ago'),
      ],
    );
  }

  Widget _buildNewsItem(String title, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.article, size: 20, color: AppColors.secondaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Colors.orange),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondaryColor,
          ),
        ),
      ],
    );
  }
}
