import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import '../core/services/auth_service.dart';
import '../core/models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService.instance;

  // State variables
  UserModel? _user;
  bool _isLoading = false;
  bool _isLoggedIn = false;
  String? _error;

  // Getters
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String? get error => _error;
  bool get isIdentityVerified => _user?.isVerified ?? false;

  // Initialize provider
  Future<void> initialize() async {
    await _checkAuthenticationStatus();
  }

  // Check if user is already logged in
  Future<void> _checkAuthenticationStatus() async {
    try {
      _setLoading(true);

      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn) {
        final userData = await _authService.getCurrentUser();
        if (userData != null) {
          _user = UserModel.fromJson(userData);
          _isLoggedIn = true;
        }
      }

      _clearError();
    } catch (e) {
      _setError('Failed to check authentication status');
    } finally {
      _setLoading(false);
    }
  }

  // Login user
  Future<bool> login(String email, String password) async {
    try {
      _setLoading(true);
      _clearError();

      final result = await _authService.login(
        email: email,
        password: password,
      );

      if (result.success) {
        if (result.userData != null) {
          _user = UserModel.fromJson(result.userData!);
          _isLoggedIn = true;
          notifyListeners();
        }
        return true;
      } else {
        _setError(result.message);
        return false;
      }
    } catch (e) {
      _setError('Login failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Register user
  Future<bool> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final result = await _authService.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
      );

      if (result.success) {
        if (result.userData != null && !result.requiresVerification && !result.requiresLogin) {
          _user = UserModel.fromJson(result.userData!);
          _isLoggedIn = true;
        }
        notifyListeners();
        return true;
      } else {
        _setError(result.message);
        return false;
      }
    } catch (e) {
      _setError('Registration failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Logout user
  Future<void> logout() async {
    try {
      _setLoading(true);
      await _authService.logout();

      _user = null;
      _isLoggedIn = false;
      _clearError();

      notifyListeners();
    } catch (e) {
      _setError('Logout failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Upload selfie
  Future<bool> uploadSelfie(File file) async {
    try {
      _setLoading(true);
      _clearError();

      final result = await _authService.uploadSelfie(file);

      if (result.success) {
        // Refresh user data
        await _refreshUserData();
        return true;
      } else {
        _setError(result.message);
        return false;
      }
    } catch (e) {
      _setError('Selfie upload failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Upload voice
  Future<bool> uploadVoice(File file) async {
    try {
      _setLoading(true);
      _clearError();

      final result = await _authService.uploadVoice(file);

      if (result.success) {
        // Refresh user data
        await _refreshUserData();
        return true;
      } else {
        _setError(result.message);
        return false;
      }
    } catch (e) {
      _setError('Voice upload failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Verify identity
  Future<bool> verifyIdentity() async {
    try {
      _setLoading(true);
      _clearError();

      final result = await _authService.verifyIdentity();

      if (result.success) {
        // Refresh user data
        await _refreshUserData();
        return true;
      } else {
        _setError(result.message);
        return false;
      }
    } catch (e) {
      _setError('Identity verification failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Refresh user data
  Future<void> _refreshUserData() async {
    try {
      final result = await _authService.getProfile();
      if (result.success && result.userData != null) {
        _user = UserModel.fromJson(result.userData!);
        notifyListeners();
      }
    } catch (e) {
      // Ignore refresh errors
    }
  }

  // Update profile
  Future<void> updateProfile() async {
    try {
      final authService = AuthService.instance;
      final result = await authService.getProfile();
      
      if (result.success && result.userData != null) {
        _user = UserModel.fromJson(result.userData!);
        notifyListeners();
      }
    } catch (e) {
      Logger('Error updating auth user data: $e');
    }
  }


  Future<void> syncUserData() async {
    try {
      final authService = AuthService.instance;
      final result = await authService.getProfile();
      
      if (result.success && result.userData != null) {
        _user = UserModel.fromJson(result.userData!);
        notifyListeners();
      }
    } catch (e) {
      Logger('Error syncing user data: $e');
    }
  }

  Future<void> handleSelfieUpload() async {
    await syncUserData();
  }

  Future<void> handleVoiceUpload() async {
    await syncUserData();
  }

  // Validation methods
  bool isValidEmail(String email) {
    return _authService.isValidEmail(email);
  }

  bool isValidPassword(String password) {
    return _authService.isValidPassword(password);
  }

  String getPasswordValidationMessage(String password) {
    return _authService.getPasswordValidationMessage(password);
  }

  bool isValidName(String name) {
    return _authService.isValidName(name);
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }
}