import 'package:flutter/material.dart';
import '../constants/colors.dart';
import 'custom_button.dart';

class CustomErrorWidget extends StatelessWidget {
  final String? title;
  final String message;
  final IconData? icon;
  final String? buttonText;
  final VoidCallback? onRetry;
  final bool showRetryButton;

  const CustomErrorWidget({
    super.key,
    this.title,
    required this.message,
    this.icon,
    this.buttonText,
    this.onRetry,
    this.showRetryButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon ?? Icons.error_outline,
              size: 64,
              color: AppColors.errorColor,
            ),
            const SizedBox(height: 16),
            if (title != null) ...[
              Text(
                title!,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: isDarkMode ? AppColors.darkTextPrimaryColor : AppColors.textPrimaryColor,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
            ],
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: isDarkMode ? AppColors.darkTextSecondaryColor : AppColors.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            if (showRetryButton && onRetry != null) ...[
              const SizedBox(height: 24),
              PrimaryButton(
                text: buttonText ?? 'Try Again',
                onPressed: onRetry,
                icon: Icons.refresh,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class NetworkErrorWidget extends StatelessWidget {
  final VoidCallback? onRetry;

  const NetworkErrorWidget({
    super.key,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return CustomErrorWidget(
      title: 'No Internet Connection',
      message: 'Please check your internet connection and try again.',
      icon: Icons.wifi_off,
      onRetry: onRetry,
    );
  }
}

class ServerErrorWidget extends StatelessWidget {
  final VoidCallback? onRetry;

  const ServerErrorWidget({
    super.key,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return CustomErrorWidget(
      title: 'Server Error',
      message: 'Something went wrong on our end. Please try again later.',
      icon: Icons.cloud_off,
      onRetry: onRetry,
    );
  }
}

class NotFoundWidget extends StatelessWidget {
  final String? title;
  final String? message;
  final VoidCallback? onBack;

  const NotFoundWidget({
    super.key,
    this.title,
    this.message,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return CustomErrorWidget(
      title: title ?? 'Not Found',
      message: message ?? 'The content you are looking for could not be found.',
      icon: Icons.search_off,
      buttonText: 'Go Back',
      onRetry: onBack ?? () => Navigator.of(context).pop(),
    );
  }
}

class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final IconData? icon;
  final String? buttonText;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.message,
    this.icon,
    this.buttonText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon ?? Icons.inbox_outlined,
              size: 64,
              color: isDarkMode ? AppColors.darkTextSecondaryColor : AppColors.textSecondaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: isDarkMode ? AppColors.darkTextPrimaryColor : AppColors.textPrimaryColor,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: isDarkMode ? AppColors.darkTextSecondaryColor : AppColors.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            if (buttonText != null && onAction != null) ...[
              const SizedBox(height: 24),
              PrimaryButton(
                text: buttonText!,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}