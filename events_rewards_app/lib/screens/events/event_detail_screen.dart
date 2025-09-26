// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/colors.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/error_widget.dart';
import '../../providers/events_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/models/event_model.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;

  const EventDetailScreen({
    super.key,
    required this.eventId,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEventDetails();
    });
  }

  Future<void> _loadEventDetails() async {
    final eventsProvider = Provider.of<EventsProvider>(context, listen: false);
    await eventsProvider.loadEventDetails(widget.eventId);
  }

  Future<void> _registerForEvent() async {
    final eventsProvider = Provider.of<EventsProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Check if user is verified
    if (!authProvider.isIdentityVerified) {
      _showVerificationDialog();
      return;
    }

    final success = await eventsProvider.registerForEvent(widget.eventId);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully registered for event!'),
          backgroundColor: AppColors.successColor,
        ),
      );
    } else if (mounted && eventsProvider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(eventsProvider.error!),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  void _showVerificationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verification Required'),
        content: const Text(
          'Please complete your identity verification to register for events.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to profile for verification
              Navigator.of(context).pop(); // Go back to previous screen
              DefaultTabController.of(context).animateTo(4); // Go to profile tab
            },
            child: const Text('Verify Now'),
          ),
        ],
      ),
    );
  }

  void _shareEvent(EventModel event) {
    Share.share(
      'Check out this amazing event: ${event.title}\n'
      '${event.formattedDate}\n'
      '${event.location}\n'
      '\n${event.description}\n'
      '\nJoin me at Events & Rewards app!',
      subject: 'Join me at ${event.title}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.darkBackgroundColor : AppColors.backgroundColor,
      body: Consumer<EventsProvider>(
        builder: (context, eventsProvider, child) {
          if (eventsProvider.isLoading && eventsProvider.selectedEvent == null) {
            return const Scaffold(
              body: LoadingWidget(message: 'Loading event details...'),
            );
          }

          if (eventsProvider.error != null && eventsProvider.selectedEvent == null) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Event Details'),
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
              ),
              body: CustomErrorWidget(
                message: eventsProvider.error!,
                onRetry: _loadEventDetails,
              ),
            );
          }

          final event = eventsProvider.selectedEvent;
          if (event == null) {
            return const Scaffold(
              body: NotFoundWidget(
                title: 'Event Not Found',
                message: 'The event you are looking for could not be found.',
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              // App Bar with Image
              SliverAppBar(
                expandedHeight: size.height * 0.35,
                floating: false,
                pinned: true,
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Event Image
                      event.bannerImage != null
                          ? CachedNetworkImage(
                              imageUrl: event.bannerImage!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                decoration: const BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(color: Colors.white),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                decoration: const BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                ),
                                child: const Center(
                                  child: Icon(Icons.event, color: Colors.white, size: 64),
                                ),
                              ),
                            )
                          : Container(
                              decoration: const BoxDecoration(
                                gradient: AppColors.primaryGradient,
                              ),
                              child: const Center(
                                child: Icon(Icons.event, color: Colors.white, size: 64),
                              ),
                            ),

                      // Gradient Overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  IconButton(
                    onPressed: () => _shareEvent(event),
                    icon: const Icon(Icons.share),
                    tooltip: 'Share Event',
                  ),
                  IconButton(
                    onPressed: () {
                      // navigate logic to favorites
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Added to favorites!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.favorite_border),
                    tooltip: 'Add to Favorites',
                  ),
                ],
              ),

              // Event Content
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Event Title and Basic Info
                    _buildEventHeader(event, theme, isDarkMode),
                    const SizedBox(height: 24),

                    // Event Details
                    _buildEventDetails(event, theme, isDarkMode),
                    const SizedBox(height: 24),

                    // Event Description
                    _buildEventDescription(event, theme, isDarkMode),
                    const SizedBox(height: 24),

                    // Participants Info
                    _buildParticipantsInfo(event, theme, isDarkMode),
                    const SizedBox(height: 24),

                    // Location Map (Placeholder)
                    _buildLocationSection(event, theme, isDarkMode),
                    const SizedBox(height: 100), // Space for floating button
                  ]),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Consumer2<EventsProvider, AuthProvider>(
        builder: (context, eventsProvider, authProvider, child) {
          final event = eventsProvider.selectedEvent;
          if (event == null) return const SizedBox.shrink();

          if (event.isRegistered) {
            return const FloatingActionButton.extended(
              onPressed: null,
              backgroundColor: AppColors.successColor,
              icon: Icon(Icons.check_circle, color: Colors.white),
              label: Text(
                'Registered',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            );
          }

          if (!event.hasAvailableSlots) {
            return const FloatingActionButton.extended(
              onPressed: null,
              backgroundColor: AppColors.disabledColor,
              icon: Icon(Icons.event_busy, color: Colors.white),
              label: Text(
                'Full',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            );
          }

          if (event.isPast) {
            return const FloatingActionButton.extended(
              onPressed: null,
              backgroundColor: AppColors.textSecondaryColor,
              icon: Icon(Icons.schedule, color: Colors.white),
              label: Text(
                'Past Event',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            );
          }

          return FloatingActionButton.extended(
            onPressed: eventsProvider.isLoading ? null : _registerForEvent,
            backgroundColor: AppColors.primaryColor,
            icon: eventsProvider.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.how_to_reg, color: Colors.white),
            label: Text(
              eventsProvider.isLoading ? 'Registering...' : 'Register Now',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEventHeader(EventModel event, ThemeData theme, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Event Title
        Text(
          event.title,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDarkMode ? AppColors.darkTextPrimaryColor : AppColors.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 16),

        // Status and Category
        Row(
          children: [
            if (event.category != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  event.category!,
                  style: const TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: event.isUpcoming
                    ? AppColors.successColor.withOpacity(0.1)
                    : AppColors.textSecondaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                event.isUpcoming ? 'Upcoming' : event.isPast ? 'Past Event' : 'Today',
                style: TextStyle(
                  color: event.isUpcoming
                      ? AppColors.successColor
                      : AppColors.textSecondaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEventDetails(EventModel event, ThemeData theme, bool isDarkMode) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDarkMode ? AppColors.darkCardColor : AppColors.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Event Details',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Date and Time
            _buildDetailRow(
              Icons.calendar_today,
              'Date',
              event.formattedDate,
              theme,
              isDarkMode,
            ),
            const SizedBox(height: 16),

            // Location
            _buildDetailRow(
              Icons.location_on,
              'Location',
              event.location,
              theme,
              isDarkMode,
            ),
            const SizedBox(height: 16),

            // Duration (if available)
            _buildDetailRow(
              Icons.schedule,
              'Duration',
              '2 hours', // This would come from the event model
              theme,
              isDarkMode,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    ThemeData theme,
    bool isDarkMode,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: AppColors.primaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDarkMode ? AppColors.darkTextSecondaryColor : AppColors.textSecondaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEventDescription(EventModel event, ThemeData theme, bool isDarkMode) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDarkMode ? AppColors.darkCardColor : AppColors.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'About This Event',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              event.description,
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.6,
                color: isDarkMode ? AppColors.darkTextSecondaryColor : AppColors.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantsInfo(EventModel event, ThemeData theme, bool isDarkMode) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDarkMode ? AppColors.darkCardColor : AppColors.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Participants',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '${event.currentParticipants}',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      Text(
                        'Registered',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDarkMode ? AppColors.darkTextSecondaryColor : AppColors.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (event.maxParticipants != null) ...[
                  Container(
                    width: 1,
                    height: 40,
                    color: isDarkMode ? AppColors.darkTextSecondaryColor : AppColors.dividerColor,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '${event.maxParticipants! - event.currentParticipants}',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondaryColor,
                          ),
                        ),
                        Text(
                          'Available',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDarkMode ? AppColors.darkTextSecondaryColor : AppColors.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),

            if (event.maxParticipants != null) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: event.currentParticipants / event.maxParticipants!,
                backgroundColor: isDarkMode ? AppColors.darkTextSecondaryColor.withOpacity(0.3) : AppColors.dividerColor,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection(EventModel event, ThemeData theme, bool isDarkMode) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDarkMode ? AppColors.darkCardColor : AppColors.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Location',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    // Open maps with location
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Opening in maps...'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.directions),
                  label: const Text('Get Directions'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Location Address
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: AppColors.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    event.location,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Placeholder for map
            Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                color: isDarkMode ? AppColors.darkSurfaceColor : AppColors.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDarkMode ? AppColors.darkTextSecondaryColor : AppColors.dividerColor,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map,
                    size: 48,
                    color: isDarkMode ? AppColors.darkTextSecondaryColor : AppColors.textSecondaryColor,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Map View',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDarkMode ? AppColors.darkTextSecondaryColor : AppColors.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap "Get Directions" to open in maps',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDarkMode ? AppColors.darkTextSecondaryColor : AppColors.textSecondaryColor,
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