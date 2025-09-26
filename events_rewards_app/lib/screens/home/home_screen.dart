// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math' as math;
import '../../providers/auth_provider.dart';
import '../../providers/home_provider.dart';
import '../../providers/events_provider.dart';
import '../../providers/news_provider.dart';
import '../../core/constants/colors.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/error_widget.dart';
import '../../core/models/event_model.dart';
import '../../core/models/news_model.dart';
import '../events/events_list_screen.dart';
import '../profile/profile_screen.dart';
import '../lucky_draw/lucky_draw_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  final List<Widget> _screens = [
    const HomeTab(),
    const EventsListScreen(),
    const LuckyDrawScreen(),
    const NewsTab(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _loadInitialData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final homeProvider = Provider.of<HomeProvider>(context, listen: false);
      final eventsProvider = Provider.of<EventsProvider>(context, listen: false);
      final newsProvider = Provider.of<NewsProvider>(context, listen: false);

      homeProvider.loadUIConfig();
      eventsProvider.loadEvents();
      newsProvider.loadNews();
    });
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        selectedItemColor: AppColors.primaryColor,
        unselectedItemColor:
            isDarkMode ? Colors.grey[400] : AppColors.textSecondaryColor,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.casino),
            label: 'Lucky Draw',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.article),
            label: 'News',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        title: const Text('Events & Rewards'),
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
        actions: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  // Handle notifications
                },
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer3<HomeProvider, EventsProvider, NewsProvider>(
          builder: (context, homeProvider, eventsProvider, newsProvider, child) {
            if (homeProvider.isLoading) {
              return const Center(child: LoadingWidget());
            }

            if (homeProvider.error != null) {
              return CustomErrorWidget(
                message: homeProvider.error!,
                onRetry: () => homeProvider.loadUIConfig(),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeSection(context),
                  const SizedBox(height: 24),
                  _buildQuickActions(context),
                  const SizedBox(height: 24),
                  _buildFeaturedEvents(context, eventsProvider),
                  const SizedBox(height: 24),
                  _buildLatestNews(context, newsProvider),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryColor,
                AppColors.primaryColor.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome${user?.firstName != null ? ', ${user!.firstName}' : ''}!',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Discover amazing events and win exciting rewards',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                icon: Icons.event,
                title: 'Events',
                subtitle: 'Browse events',
                onTap: () {
                  Navigator.of(context).pushNamed('/events');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                context,
                icon: Icons.casino,
                title: 'Lucky Draw',
                subtitle: 'Try your luck',
                onTap: () {
                  Navigator.of(context).pushNamed('/lucky-draw');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                context,
                icon: Icons.card_giftcard,
                title: 'Rewards',
                subtitle: 'View rewards',
                onTap: () {
                  Navigator.of(context).pushNamed('/my-rewards');
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 32,
              color: AppColors.primaryColor,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedEvents(BuildContext context, EventsProvider eventsProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Featured Events',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/events');
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (eventsProvider.isLoading)
          const SizedBox(height: 200, child: Center(child: LoadingWidget()))
        else if (eventsProvider.events.isEmpty)
          const SizedBox(
            height: 100,
            child: Center(child: Text('No events available')),
          )
        else
          SizedBox(
            height: 220, // Increased height to accommodate content
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: math.min(eventsProvider.events.length, 5),
              itemBuilder: (context, index) {
                final event = eventsProvider.events[index];
                return _buildEventCard(context, event);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildEventCard(BuildContext context, EventModel event) {
    final theme = Theme.of(context);
    // ignore: unused_local_variable
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      width: 280, // Slightly reduced width
      margin: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).pushNamed('/event-detail', arguments: event.id);
        },
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Event banner
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  color: AppColors.primaryColor.withOpacity(0.1),
                ),
                child: event.bannerImage != null
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: CachedNetworkImage(
                          imageUrl: event.bannerImage!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          errorWidget: (context, url, error) => const Center(
                            child: Icon(
                              Icons.event,
                              size: 48,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ),
                      )
                    : const Center(
                        child: Icon(
                          Icons.event,
                          size: 48,
                          color: AppColors.primaryColor,
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      event.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.location,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${event.startDate.day}/${event.startDate.month}/${event.startDate.year}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLatestNews(BuildContext context, NewsProvider newsProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Latest News',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to news tab
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (newsProvider.isLoading)
          const Center(child: LoadingWidget())
        else if (newsProvider.news.isEmpty)
          const Center(
            child: Text('No news available'),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: math.min(newsProvider.news.length, 3),
            itemBuilder: (context, index) {
              final news = newsProvider.news[index];
              return _buildNewsCard(context, news);
            },
          ),
      ],
    );
  }

  Widget _buildNewsCard(BuildContext context, NewsModel news) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed('/news-detail', arguments: news.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: AppColors.primaryColor.withOpacity(0.1),
              ),
              child: news.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: news.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.article,
                        color: AppColors.primaryColor,
                      ),
                    )
                  : const Icon(
                      Icons.article,
                      color: AppColors.primaryColor,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    news.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (news.summary != null)
                    Text(
                      news.summary!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondaryColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 6),
                  Text(
                    '${news.createdAt.day}/${news.createdAt.month}/${news.createdAt.year}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NewsTab extends StatelessWidget {
  const NewsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('News'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Consumer<NewsProvider>(
          builder: (context, newsProvider, child) {
            if (newsProvider.isLoading) {
              return const Center(child: LoadingWidget());
            }

            if (newsProvider.error != null) {
              return CustomErrorWidget(
                message: newsProvider.error!,
                onRetry: () => newsProvider.loadNews(),
              );
            }

            if (newsProvider.news.isEmpty) {
              return const Center(
                child: Text('No news available'),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: newsProvider.news.length,
              itemBuilder: (context, index) {
                final news = newsProvider.news[index];
                return _buildNewsItem(context, news);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildNewsItem(BuildContext context, NewsModel news) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed('/news-detail', arguments: news.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (news.imageUrl != null)
              Container(
                height: 200,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: CachedNetworkImage(
                  imageUrl: news.imageUrl!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    child: const Center(
                      child: Icon(
                        Icons.article,
                        size: 48,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    news.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (news.summary != null)
                    Text(
                      news.summary!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondaryColor,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (news.category != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            news.category!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ),
                        const Spacer(),
                      ],
                      Text(
                        '${news.createdAt.day}/${news.createdAt.month}/${news.createdAt.year}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}