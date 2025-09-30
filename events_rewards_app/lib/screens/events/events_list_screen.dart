// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; 
import '../../providers/events_provider.dart';
import '../../core/models/event_model.dart';
import 'create_event_screen.dart';
import 'manage_events_screen.dart'; // Import the new screen

class EventsListScreen extends StatefulWidget {
  const EventsListScreen({super.key});

  @override
  State<EventsListScreen> createState() => _EventsListScreenState();
}

class _EventsListScreenState extends State<EventsListScreen>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEvents();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      final eventsProvider = Provider.of<EventsProvider>(context, listen: false);
      if (!eventsProvider.isLoadingMore && eventsProvider.hasMoreData) {
        eventsProvider.loadMoreEvents();
      }
    }
  }

  Future<void> _loadEvents() async {
    final eventsProvider = Provider.of<EventsProvider>(context, listen: false);
    await eventsProvider.loadEvents(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              title: const Text('Events'),
              floating: true,
              pinned: true,
              snap: true,
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _showSearchDialog,
                ),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: _showFilterBottomSheet,
                ),
                _buildEventsMenu(theme),
              ],
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: theme.colorScheme.onPrimary,
                labelColor: theme.colorScheme.onPrimary,
                unselectedLabelColor: theme.colorScheme.onPrimary.withOpacity(0.7),
                tabs: const [
                  Tab(text: 'All Events'),
                  Tab(text: 'Upcoming'),
                  Tab(text: 'Register Events'),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildAllEventsTab(),
            _buildUpcomingEventsTab(),
            _buildMyEventsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsMenu(ThemeData theme) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      color: theme.colorScheme.surface,
      elevation: 4,
      onSelected: (value) {
        _handleMenuSelection(value);
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'create',
          child: ListTile(
            leading: Icon(Icons.add, color: Colors.blue),
            title: Text('Create Event'),
          ),
        ),
        const PopupMenuItem<String>(
          value: 'manage',
          child: ListTile(
            leading: Icon(Icons.manage_accounts, color: Colors.green),
            title: Text('Manage My Events'),
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'refresh',
          child: ListTile(
            leading: const Icon(Icons.refresh, color: Colors.orange),
            title: const Text('Refresh Events'),
            trailing: Consumer<EventsProvider>(
              builder: (context, eventsProvider, child) {
                if (eventsProvider.isLoading) {
                  return const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ),
      ],
    );
  }

  // Handle menu selection
  void _handleMenuSelection(String value) {
    switch (value) {
      case 'create':
        _navigateToCreateEvent();
        break;
      case 'manage':
        final result = Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (context) => const ManageEventsScreen()),
        );
        // ignore: unrelated_type_equality_checks
        if (result == true) {
          _loadEvents();
        }
        break;
      case 'refresh':
        _loadEvents();
        break;
    }
  }

  void _navigateToCreateEvent() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const CreateEventScreen()),
    );
    
    if (result == true) {
      _loadEvents();
    }
  }

  // void _navigateToManageEvents() {
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => const ManageEventsScreen(),
  //     ),
  //   );
  // }


  Widget _buildAllEventsTab() {
    return Consumer<EventsProvider>(
      builder: (context, eventsProvider, child) {
        if (eventsProvider.isLoading && eventsProvider.events.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading events...'),
              ],
            ),
          );
        }

        if (eventsProvider.error != null && eventsProvider.events.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  eventsProvider.error!,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadEvents,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (eventsProvider.events.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No Events Found',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'There are no events available at the moment. Check back later!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadEvents,
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: eventsProvider.events.length + (eventsProvider.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == eventsProvider.events.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              return EventCard(
                event: eventsProvider.events[index],
                onTap: () => _navigateToEventDetail(eventsProvider.events[index]),
                onRegister: () => _handleEventRegistration(eventsProvider.events[index]),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildUpcomingEventsTab() {
    return Consumer<EventsProvider>(
      builder: (context, eventsProvider, child) {
        final upcomingEvents = eventsProvider.events.where((event) => event.isUpcoming).toList();

        if (eventsProvider.isLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading upcoming events...'),
              ],
            ),
          );
        }

        if (upcomingEvents.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_available, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No Upcoming Events',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'No events scheduled for the near future. Stay tuned!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadEvents,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: upcomingEvents.length,
            itemBuilder: (context, index) {
              return EventCard(
                event: upcomingEvents[index],
                onTap: () => _navigateToEventDetail(upcomingEvents[index]),
                onRegister: () => _handleEventRegistration(upcomingEvents[index]),
                showTimeUntil: true,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMyEventsTab() {
    return Consumer<EventsProvider>(
      builder: (context, eventsProvider, child) {
        final myEvents = eventsProvider.events.where((event) => event.isRegistered).toList();

        if (eventsProvider.isLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading your events...'),
              ],
            ),
          );
        }

        if (myEvents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.event_note, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'No Registered Events',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'You haven\'t registered for any events yet. Browse and join exciting events!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _tabController.animateTo(0),
                  child: const Text('Browse Events'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadEvents,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: myEvents.length,
            itemBuilder: (context, index) {
              return EventCard(
                event: myEvents[index],
                onTap: () => _navigateToEventDetail(myEvents[index]),
                onRegister: () => _handleEventRegistration(myEvents[index]),
                showRegistrationStatus: true,
              );
            },
          ),
        );
      },
    );
  }

  void _navigateToEventDetail(EventModel event) {
    Navigator.pushNamed(context, '/event-detail', arguments: event.id);
  }

  Future<void> _handleEventRegistration(EventModel event) async {
    final eventsProvider = Provider.of<EventsProvider>(context, listen: false);

    bool success;
    if (event.isRegistered) {
      success = await eventsProvider.unregisterFromEvent(event.id);
    } else {
      success = await eventsProvider.registerForEvent(event.id);
    }

    if (success && mounted) {
      final message = event.isRegistered 
          ? 'Successfully unregistered from ${event.title}'
          : 'Successfully registered for ${event.title}';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Events'),
        content: const TextField(
          decoration: InputDecoration(
            hintText: 'Enter event name or keyword...',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Filter Events',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.all_inclusive),
              title: const Text('All Categories'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.music_note),
              title: const Text('Music'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.sports),
              title: const Text('Sports'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.computer),
              title: const Text('Technology'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class EventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback onTap;
  final VoidCallback? onRegister;
  final bool showTimeUntil;
  final bool showRegistrationStatus;

  const EventCard({
    super.key,
    required this.event,
    required this.onTap,
    this.onRegister,
    this.showTimeUntil = false,
    this.showRegistrationStatus = false,
  });

  // Helper method to format date
  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  // Helper method to format time
  String _formatTime(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withOpacity(0.8),
                    ],
                  ),
                ),
                child: event.bannerImage != null
                    ? Image.network(
                        event.bannerImage!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  theme.colorScheme.primary,
                                  theme.colorScheme.primary.withOpacity(0.8),
                                ],
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.event,
                                color: theme.colorScheme.onPrimary,
                                size: 48,
                              ),
                            ),
                          );
                        },
                      )
                    : Center(
                        child: Icon(
                          Icons.event,
                          color: theme.colorScheme.onPrimary,
                          size: 48,
                        ),
                      ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event title and category
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (event.category != null)
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              event.category!,
                              style: TextStyle(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Event description
                  Text(
                    event.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 12),

                  // Event details
                  _buildEventDetailRow(
                    icon: Icons.access_time,
                    text: '${_formatDate(event.startDate)} at ${_formatTime(event.startDate)}',
                    color: theme.colorScheme.primary,
                  ),

                  const SizedBox(height: 4),

                  _buildEventDetailRow(
                    icon: Icons.location_on,
                    text: event.location,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),

                  // Show time until event if enabled
                  if (showTimeUntil && event.isUpcoming) ...[
                    const SizedBox(height: 4),
                    _buildEventDetailRow(
                      icon: Icons.schedule,
                      text: _getTimeUntilEvent(event.startDate),
                      color: Colors.orange,
                    ),
                  ],

                  // Show registration status if enabled
                  if (showRegistrationStatus) ...[
                    const SizedBox(height: 4),
                    _buildEventDetailRow(
                      icon: Icons.check_circle,
                      text: 'Registered',
                      color: Colors.green,
                    ),
                  ],

                  const SizedBox(height: 12),
                  
                  // Participants and registration button
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${event.currentParticipants} participants',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (onRegister != null)
                        Flexible(
                          child: ElevatedButton(
                            onPressed: event.hasAvailableSlots ? onRegister : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: event.isRegistered
                                  ? theme.colorScheme.surfaceContainerHighest
                                  : theme.colorScheme.primary,
                              foregroundColor: event.isRegistered
                                  ? theme.colorScheme.onSurfaceVariant
                                  : theme.colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              minimumSize: const Size(0, 36),
                            ),
                            child: Text(
                              event.isRegistered ? 'Registered' : 'Register',
                              style: const TextStyle(fontSize: 12),
                            ),
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

  Widget _buildEventDetailRow({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Helper method to get time until event
  String _getTimeUntilEvent(DateTime eventDate) {
    final now = DateTime.now();
    final difference = eventDate.difference(now);

    if (difference.inDays > 0) {
      return 'In ${difference.inDays} day${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'In ${difference.inHours} hour${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'In ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'Starting soon';
    }
  }
}