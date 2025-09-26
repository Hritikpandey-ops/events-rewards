import 'dart:io';
import 'package:dio/dio.dart'; 

import '../constants/api_constants.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  static AuthService? _instance;
  AuthService._();

  static AuthService get instance {
    _instance ??= AuthService._();
    return _instance!;
  }

  // Get API and Storage services
  ApiService get _apiService => ApiService.instance;
  StorageService get _storageService => StorageService.instance;

  /// Login with email and password
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiService.login(email, password);

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;
        final token = data['token'] as String?;
        final userData = data['user'] as Map<String, dynamic>?;

        if (token != null && userData != null) {
          // Save token (your backend only returns one token)
          await _storageService.saveAuthToken(token);
          
          // Save user data
          await _storageService.saveUserData(userData);

          return AuthResult.success(
            message: 'Login successful',
            userData: userData,
          );
        } else {
          return AuthResult.failure(
            message: 'Invalid response format',
          );
        }
      } else {
        return AuthResult.failure(
          message: response['message'] as String? ?? 'Login failed',
        );
      }
    } catch (e) {
      return AuthResult.failure(
        message: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }


  /// Register new user
  Future<AuthResult> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    try {
      final userData = {
        'email': email,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      };

      final response = await _apiService.register(userData);

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;

        // Check if user needs email verification
        if (data['requires_verification'] == true) {
          return AuthResult.success(
            message: 'Please check your email for verification link',
            userData: data['user'] as Map<String, dynamic>?,
            requiresVerification: true,
          );
        }

        // Auto login after registration if no verification required
        final accessToken = data['access_token'] as String?;
        final refreshToken = data['refresh_token'] as String?;
        final userInfo = data['user'] as Map<String, dynamic>?;

        if (accessToken != null && refreshToken != null && userInfo != null) {
          await _storageService.saveAuthToken(accessToken);
          await _storageService.saveRefreshToken(refreshToken);
          await _storageService.saveUserData(userInfo);

          return AuthResult.success(
            message: 'Registration successful',
            userData: userInfo,
          );
        } else {
          return AuthResult.success(
            message: 'Registration successful. Please login.',
            userData: userInfo,
            requiresLogin: true,
          );
        }
      } else {
        return AuthResult.failure(
          message: response['message'] as String? ?? 'Registration failed',
        );
      }
    } catch (e) {
      return AuthResult.failure(
        message: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Logout user
  Future<AuthResult> logout() async {
    try {
      // Call logout endpoint (ignore errors as we clear local data anyway)
      try {
        await _apiService.logout();
      } catch (e) {
        // Ignore API errors during logout
      }

      // Clear local storage
      await _storageService.clearAllUserData();

      return AuthResult.success(message: 'Logged out successfully');
    } catch (e) {
      return AuthResult.failure(
        message: 'Logout failed: ${e.toString()}',
      );
    }
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    try {
      final token = await _storageService.getAuthToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get current user data
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      return await _storageService.getUserData();
    } catch (e) {
      return null;
    }
  }

  /// Refresh authentication token
  Future<AuthResult> refreshToken() async {
    try {
      final response = await _apiService.refreshToken();

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;
        final accessToken = data['access_token'] as String?;
        final refreshTokenNew = data['refresh_token'] as String?;

        if (accessToken != null) {
          await _storageService.saveAuthToken(accessToken);
          if (refreshTokenNew != null) {
            await _storageService.saveRefreshToken(refreshTokenNew);
          }

          return AuthResult.success(message: 'Token refreshed');
        }
      }

      return AuthResult.failure(message: 'Token refresh failed');
    } catch (e) {
      return AuthResult.failure(
        message: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Upload user's selfie for identity verification (File)
  Future<AuthResult> uploadSelfie(File file) async {
    try {
      final response = await _apiService.uploadSelfie(file);

      if (response['success'] == true) {
        return AuthResult.success(
          message: 'Selfie uploaded successfully',
          data: response['data'] as Map<String, dynamic>?,
        );
      } else {
        return AuthResult.failure(
          message: response['message'] as String? ?? 'Selfie upload failed',
        );
      }
    } catch (e) {
      return AuthResult.failure(
        message: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Upload selfie using MultipartFile (for web compatibility)
  Future<AuthResult> uploadSelfieMultipart(MultipartFile file) async {
    try {
      final formData = FormData.fromMap({
        'selfie': file,
      });

      final response = await _apiService.dio.post(
        '/auth/upload-selfie',
        data: formData,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return AuthResult.success(
          message: 'Selfie uploaded successfully',
          userData: response.data['data']?['user'] as Map<String, dynamic>?,
          data: response.data['data'] as Map<String, dynamic>?,
        );
      } else {
        return AuthResult.failure(
          message: response.data['message'] as String? ?? 'Upload failed',
          data: response.data as Map<String, dynamic>?,
        );
      }
    } catch (e) {
      return AuthResult.failure(
        message: 'Network error occurred',
      );
    }
  }

  /// Upload user's voice recording for identity verification (File)
  Future<AuthResult> uploadVoice(File file) async {
    try {
      final response = await _apiService.uploadVoice(file);

      if (response['success'] == true) {
        return AuthResult.success(
          message: 'Voice recording uploaded successfully',
          data: response['data'] as Map<String, dynamic>?,
        );
      } else {
        return AuthResult.failure(
          message: response['message'] as String? ?? 'Voice upload failed',
        );
      }
    } catch (e) {
      return AuthResult.failure(
        message: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Upload voice using MultipartFile (for web compatibility)
  Future<AuthResult> uploadVoiceMultipart(MultipartFile file) async {
    try {
      final formData = FormData.fromMap({
        'voice': file,
      });

      final response = await _apiService.dio.post(
        '/auth/upload-voice',
        data: formData,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return AuthResult.success(
          message: 'Voice uploaded successfully',
          userData: response.data['data']?['user'] as Map<String, dynamic>?,
          data: response.data['data'] as Map<String, dynamic>?,
        );
      } else {
        return AuthResult.failure(
          message: response.data['message'] as String? ?? 'Upload failed',
          data: response.data as Map<String, dynamic>?,
        );
      }
    } catch (e) {
      return AuthResult.failure(
        message: 'Network error occurred',
      );
    }
  }

  /// Complete identity verification
  Future<AuthResult> verifyIdentity() async {
    try {
      final response = await _apiService.verifyIdentity();

      if (response['success'] == true) {
        // Update user data with verification status
        final userData = await getCurrentUser();
        if (userData != null) {
          userData['is_verified'] = true;
          userData['verification_status'] = 'verified';
          await _storageService.saveUserData(userData);
        }

        return AuthResult.success(
          message: 'Identity verified successfully',
          data: response['data'] as Map<String, dynamic>?,
        );
      } else {
        return AuthResult.failure(
          message: response['message'] as String? ?? 'Identity verification failed',
        );
      }
    } catch (e) {
      return AuthResult.failure(
        message: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Get user profile
  Future<AuthResult> getProfile() async {
    try {
      final response = await _apiService.getProfile();

      if (response['success'] == true && response['data'] != null) {
        final userData = response['data'] as Map<String, dynamic>;

        // Update local storage with latest user data
        await _storageService.saveUserData(userData);

        return AuthResult.success(
          message: 'Profile loaded successfully',
          userData: userData,
        );
      } else {
        return AuthResult.failure(
          message: response['message'] as String? ?? 'Failed to load profile',
        );
      }
    } catch (e) {
      return AuthResult.failure(
        message: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Update user profile
  Future<AuthResult> updateProfile(Map<String, dynamic> profileData) async {
    try {
      final response = await _apiService.updateProfile(profileData);

      if (response['success'] == true && response['data'] != null) {
        final userData = response['data'] as Map<String, dynamic>;

        // Update local storage
        await _storageService.saveUserData(userData);

        return AuthResult.success(
          message: 'Profile updated successfully',
          userData: userData,
        );
      } else {
        return AuthResult.failure(
          message: response['message'] as String? ?? 'Profile update failed',
        );
      }
    } catch (e) {
      return AuthResult.failure(
        message: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Check if current user is verified
  Future<bool> isUserVerified() async {
    try {
      final userData = await getCurrentUser();
      if (userData != null) {
        return userData['is_verified'] == true ||
            userData['verification_status'] == 'verified';
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get verification status details
  Future<Map<String, dynamic>?> getVerificationStatus() async {
    try {
      final userData = await getCurrentUser();
      if (userData != null) {
        return {
          'is_verified': userData['is_verified'] ?? false,
          'verification_status': userData['verification_status'] ?? 'pending',
          'has_selfie': userData['has_selfie'] ?? false,
          'has_voice': userData['has_voice'] ?? false,
          'verification_completed_at': userData['verification_completed_at'],
        };
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Validate email format
  bool isValidEmail(String email) {
    return RegExp(ApiConstants.emailRegex).hasMatch(email);
  }

  /// Validate password strength
  bool isValidPassword(String password) {
    if (password.length < ApiConstants.minPasswordLength) return false;
    if (password.length > ApiConstants.maxPasswordLength) return false;

    // Check for at least one uppercase, one lowercase, and one number
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(password)) {
      return false;
    }

    return true;
  }

  /// Get password validation message
  String getPasswordValidationMessage(String password) {
    if (password.isEmpty) {
      return 'Password is required';
    }

    if (password.length < ApiConstants.minPasswordLength) {
      return 'Password must be at least ${ApiConstants.minPasswordLength} characters long';
    }

    if (password.length > ApiConstants.maxPasswordLength) {
      return 'Password cannot exceed ${ApiConstants.maxPasswordLength} characters';
    }

    if (!RegExp(r'(?=.*[a-z])').hasMatch(password)) {
      return 'Password must contain at least one lowercase letter';
    }

    if (!RegExp(r'(?=.*[A-Z])').hasMatch(password)) {
      return 'Password must contain at least one uppercase letter';
    }

    if (!RegExp(r'(?=.*\d)').hasMatch(password)) {
      return 'Password must contain at least one number';
    }

    return '';
  }

  /// Validate name format
  bool isValidName(String name) {
    if (name.trim().length < ApiConstants.minNameLength) return false;
    if (name.trim().length > ApiConstants.maxNameLength) return false;
    return RegExp(ApiConstants.nameRegex).hasMatch(name.trim());
  }

  /// Clear all authentication data (for app reset/debugging)
  Future<void> clearAllAuthData() async {
    try {
      await _storageService.clearAllUserData();
    } catch (e) {
      // Ignore errors during cleanup
    }
  }
}

/// Result class for authentication operations
class AuthResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? userData;
  final Map<String, dynamic>? data;
  final bool requiresVerification;
  final bool requiresLogin;

  const AuthResult._({
    required this.success,
    required this.message,
    this.userData,
    this.data,
    this.requiresVerification = false,
    this.requiresLogin = false,
  });

  /// Create successful result
  factory AuthResult.success({
    required String message,
    Map<String, dynamic>? userData,
    Map<String, dynamic>? data,
    bool requiresVerification = false,
    bool requiresLogin = false,
  }) {
    return AuthResult._(
      success: true,
      message: message,
      userData: userData,
      data: data,
      requiresVerification: requiresVerification,
      requiresLogin: requiresLogin,
    );
  }

  /// Create failure result
  factory AuthResult.failure({
    required String message,
    Map<String, dynamic>? data,
  }) {
    return AuthResult._(
      success: false,
      message: message,
      data: data,
    );
  }

  @override
  String toString() {
    return 'AuthResult(success: $success, message: $message, requiresVerification: $requiresVerification, requiresLogin: $requiresLogin)';
  }
}

/// Extension for easy access to user properties
extension UserDataExtension on Map<String, dynamic> {
  String? get id => this['id'] as String?;
  String? get email => this['email'] as String?;
  String? get firstName => this['first_name'] as String?;
  String? get lastName => this['last_name'] as String?;

  String? get fullName {
    final first = firstName;
    final last = lastName;
    if (first != null && last != null) {
      return '$first $last';
    }
    return first ?? last;
  }

  String? get phone => this['phone'] as String?;
  String? get selfieUrl => this['selfie_url'] as String?;
  bool get isVerified => this['is_verified'] == true;
  bool get hasSelfie => this['has_selfie'] == true;
  bool get hasVoice => this['has_voice'] == true;
  String get verificationStatus => this['verification_status'] as String? ?? 'pending';

  DateTime? get createdAt {
    final dateStr = this['created_at'] as String?;
    return dateStr != null ? DateTime.tryParse(dateStr) : null;
  }

  DateTime? get verificationCompletedAt {
    final dateStr = this['verification_completed_at'] as String?;
    return dateStr != null ? DateTime.tryParse(dateStr) : null;
  }
}
