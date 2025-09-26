import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/events_provider.dart';
import '../../core/models/event_model.dart';
import 'create_event_screen.dart';

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
                 IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateEventScreen(),
                      ),
                    );
                  },
                ),
              ],
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: theme.colorScheme.onPrimary,
                labelColor: theme.colorScheme.onPrimary,
                // ignore: deprecated_member_use
                unselectedLabelColor: theme.colorScheme.onPrimary.withOpacity(0.7),
                tabs: const [
                  Tab(text: 'All Events'),
                  Tab(text: 'Upcoming'),
                  Tab(text: 'My Events'),
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
          ? 'Successfully unregistered from \${event.title}'
          : 'Successfully registered for \${event.title}';

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
                      // ignore: deprecated_member_use
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
                                  // ignore: deprecated_member_use
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
                      if (event.category != null)
                        Container(
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
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Event description
                  Text(
                    event.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      // ignore: deprecated_member_use
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 12),

                  // Event details
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '\${event.formattedDate} at \${event.formattedTime}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        // ignore: deprecated_member_use
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.location,
                          style: theme.textTheme.bodySmall?.copyWith(
                            // ignore: deprecated_member_use
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  
                  // Participants and registration button
                  Row(
                    children: [
                      Text(
                        '\${event.currentParticipants} participants',
                        style: theme.textTheme.bodySmall?.copyWith(
                          // ignore: deprecated_member_use
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const Spacer(),
                      if (onRegister != null)
                        ElevatedButton(
                          onPressed: event.hasAvailableSlots ? onRegister : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: event.isRegistered
                                ? theme.colorScheme.surfaceContainerHighest
                                : theme.colorScheme.primary,
                            foregroundColor: event.isRegistered
                                ? theme.colorScheme.onSurfaceVariant
                                : theme.colorScheme.onPrimary,
                          ),
                          child: Text(
                            event.isRegistered ? 'Registered' : 'Register',
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