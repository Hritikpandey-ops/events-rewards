// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/colors.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/loading_widget.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/theme_provider.dart';
import '../auth/selfie_capture_screen.dart';
import '../auth/voice_recording_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> 
    with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });
  }

  Future<void> _loadProfile() async {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    await profileProvider.loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.darkBackgroundColor : AppColors.backgroundColor,
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: Consumer2<AuthProvider, ProfileProvider>(
          builder: (context, authProvider, profileProvider, child) {
           final user = profileProvider.user ?? authProvider.user;

            if (profileProvider.isLoading && user == null) {
              return const LoadingWidget(message: 'Loading profile...');
            }

            return CustomScrollView(
              slivers: [
                // App Bar
                SliverAppBar(
                  expandedHeight: 200,
                  floating: false,
                  pinned: true,
                  backgroundColor: AppColors.primaryColor,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: AppColors.primaryGradient,
                      ),
                      child: SafeArea(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Profile Avatar
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 50,
                                  backgroundColor: Colors.white,
                                  backgroundImage: user?.selfieUrl != null
                                      ? CachedNetworkImageProvider(user!.selfieUrl!)
                                      : null,
                                  child: user?.selfieUrl == null
                                      ? Text(
                                          user?.firstName?.substring(0, 1).toUpperCase() ?? 'U',
                                          style: const TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primaryColor,
                                          ),
                                        )
                                      : null,
                                ),
                                if (user?.isVerified == true)
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: AppColors.successColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                      child: const Icon(
                                        Icons.verified,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // User Name
                            Text(
                              user?.fullName ?? 'User',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),

                            // Email
                            Text(
                              user?.email ?? '',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Profile Content
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Verification Status
                      _buildVerificationStatus(user, profileProvider),
                      const SizedBox(height: 24),

                      // Profile Information
                      _buildProfileInfo(user),
                      const SizedBox(height: 24),

                      // Settings
                      _buildSettings(),
                      const SizedBox(height: 24),

                      // App Information
                      _buildAppInfo(),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

Widget _buildVerificationStatus(user, ProfileProvider profileProvider) {
  // Use the actual user data for verification status
  final isVerified = user?.isVerified == true || 
                    user?.verificationStatus == 'verified';
  final hasSelfie = user?.hasSelfie == true;
  final hasVoice = user?.hasVoice == true;

  double progress = 0.0;
  if (hasSelfie) progress += 0.33;
  if (hasVoice) progress += 0.33;
  if (isVerified) progress += 0.34;

  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isVerified ? Icons.verified_user : Icons.pending,
                color: isVerified ? AppColors.successColor : AppColors.warningColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Identity Verification',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      isVerified 
                          ? 'Verified • Full access enabled'
                          : 'Pending • Complete to unlock all features',
                      style: TextStyle(
                        color: isVerified ? AppColors.successColor : AppColors.warningColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (!isVerified) ...[
            const SizedBox(height: 16),

            // Progress Bar
            LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.dividerColor,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
            ),
            const SizedBox(height: 8),
            Text(
              '${(progress * 100).round()}% Complete',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 16),

            // Verification Steps - Use actual user data
            _buildVerificationStep(
              icon: Icons.camera_alt,
              title: 'Upload Selfie',
              completed: hasSelfie,
              onTap: hasSelfie ? null : () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SelfieCaptureScreen(),
                  ),
                ).then((_) async {
                  // Refresh profile after returning from selfie capture
                  await profileProvider.loadProfile();
                  // Also sync auth provider
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  await authProvider.syncUserData();
                });
              },
            ),
            const SizedBox(height: 12),
            _buildVerificationStep(
              icon: Icons.mic,
              title: 'Record Voice',
              completed: hasVoice,
              onTap: hasVoice ? null : () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const VoiceRecordingScreen(),
                  ),
                ).then((_) async {
                  // Refresh profile after returning from voice recording
                  await profileProvider.loadProfile();
                  // Also sync auth provider
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  await authProvider.syncUserData();
                });
              },
            ),
            const SizedBox(height: 12),
            _buildVerificationStep(
              icon: Icons.verified,
              title: 'Complete Verification',
              completed: isVerified,
              onTap: (hasSelfie && hasVoice && !isVerified) ? () async {
                final success = await profileProvider.verifyIdentity();
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Identity verified successfully!'),
                      backgroundColor: AppColors.successColor,
                    ),
                  );
                  // Refresh data
                  await profileProvider.loadProfile();
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  await authProvider.syncUserData();
                }
              } : null,
            ),
          ],
        ],
      ),
    ),
  );
}

  Widget _buildVerificationStep({
    required IconData icon,
    required String title,
    required bool completed,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: completed 
              ? AppColors.successColor.withOpacity(0.1)
              : AppColors.primaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: completed ? AppColors.successColor : AppColors.primaryColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                completed ? Icons.check : icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: completed ? AppColors.successColor : AppColors.textPrimaryColor,
                ),
              ),
            ),
            if (onTap != null)
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.textSecondaryColor,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfo(user) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profile Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            _buildInfoRow(Icons.person, 'Name', user?.fullName ?? 'Not provided'),
            _buildInfoRow(Icons.email, 'Email', user?.email ?? 'Not provided'),
            _buildInfoRow(Icons.phone, 'Phone', user?.phone ?? 'Not provided'),
            _buildInfoRow(
              Icons.calendar_today, 
              'Member Since', 
              user?.createdAt != null 
                  ? '${user!.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}'
                  : 'Unknown'
            ),

            const SizedBox(height: 16),
            SecondaryButton(
              text: 'Edit Profile',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const EditProfileScreen(),
                  ),
                ).then((_) {
                  // Refresh profile data when returning from edit screen
                  _loadProfile();
                });
              },
              icon: Icons.edit,
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.textSecondaryColor,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettings() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Settings',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Dark Mode Toggle
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return _buildSettingRow(
                  icon: Icons.dark_mode,
                  title: 'Dark Mode',
                  trailing: Switch(
                    value: themeProvider.isDarkMode,
                    onChanged: (value) => themeProvider.toggleDarkMode(),
                    activeColor: AppColors.primaryColor,
                  ),
                );
              },
            ),

            _buildSettingRow(
              icon: Icons.notifications,
              title: 'Notifications',
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Navigate to notification settings
              },
            ),

            _buildSettingRow(
              icon: Icons.security,
              title: 'Privacy & Security',
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Navigate to privacy settings
              },
            ),

            _buildSettingRow(
              icon: Icons.help,
              title: 'Help & Support',
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Navigate to help
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: AppColors.textSecondaryColor,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildAppInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'App Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            _buildSettingRow(
              icon: Icons.info,
              title: 'About',
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                _showAboutDialog();
              },
            ),

            _buildSettingRow(
              icon: Icons.star_rate,
              title: 'Rate App',
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Open app store for rating
              },
            ),

            const SizedBox(height: 16),

            // Logout Button
            DangerButton(
              text: 'Logout',
              onPressed: _showLogoutDialog,
              icon: Icons.logout,
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Events & Rewards'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: 1.0.0'),
            SizedBox(height: 8),
            Text('A platform to discover exciting events and win amazing rewards through identity-verified participation.'),
            SizedBox(height: 16),
            Text('© 2025 Events & Rewards. All rights reserved.'),
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

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.logout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}