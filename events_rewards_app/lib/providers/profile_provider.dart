import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart'; 
import '../core/services/auth_service.dart';
import '../core/models/user_model.dart';

class ProfileProvider with ChangeNotifier {
  final AuthService _authService = AuthService.instance;

  // State variables
  UserModel? _user;
  bool _isLoading = false;
  bool _isSelfieUploading = false;
  bool _isVoiceUploading = false;
  final bool _isVerifying = false;
  String? _error;

  // Getters
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isSelfieUploading => _isSelfieUploading;
  bool get isVoiceUploading => _isVoiceUploading;
  bool get isVerifying => _isVerifying;
  String? get error => _error;
  String? get errorMessage => _error; // Alias for consistency

  // Verification status getters
  bool get hasSelfie {
    return user?.hasSelfie == true;
  }

  bool get hasVoice {
    return user?.hasVoice == true;
  }

  bool get isVerified {
    return user?.isVerified == true || 
           user?.verificationStatus == 'verified';
  }

  bool get canVerifyIdentity {
    return hasSelfie && hasVoice && !isVerified;
  }

  // Verification progress (0.0 to 1.0)
  double get verificationProgress {
    int completedSteps = 0;
    if (hasSelfie) completedSteps++;
    if (hasVoice) completedSteps++;
    if (isVerified) completedSteps++;
    
    return completedSteps / 3.0;
  }

  // Load profile data - FIXED VERSION
  Future<void> loadProfile() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final result = await _authService.getProfile();
      
      if (result.success && result.userData != null) {
        try {
          // Extract the nested user data from the response
          final userDataMap = Map<String, dynamic>.from(result.userData!);
          final userData = userDataMap['user'] != null 
              ? Map<String, dynamic>.from(userDataMap['user']!)
              : <String, dynamic>{};
          
          _user = UserModel.fromJson(userData);
          _error = null;
        } catch (e) {
          _error = 'Error parsing profile data: ${e.toString()}';
          print('Error in loadProfile parsing: $e');
        }
      } else {
        _error = result.message;
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      print('Error loading profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update profile 
  Future<bool> updateProfile(Map<String, dynamic> profileData) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final result = await _authService.updateProfile(profileData);

      if (result.success) {
        _error = null;
        
        // Refresh the profile data to get updated information
        await loadProfile();
        
        return true;
      } else {
        _error = result.message;
        return false;
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Upload selfie (File - for mobile)
  Future<bool> uploadSelfie(File file) async {
    try {
      _setSelfieUploading(true);
      _clearError();

      final result = await _authService.uploadSelfie(file);
      if (result.success) {
        // Refresh profile to get updated status
        await loadProfile();
        return true;
      } else {
        _setError(result.message);
        return false;
      }
    } catch (e) {
      _setError('Failed to upload selfie: $e');
      return false;
    } finally {
      _setSelfieUploading(false);
    }
  }

  // Upload selfie from bytes (for web)
  Future<bool> uploadSelfieBytes(Uint8List imageBytes) async {
    try {
      _setSelfieUploading(true);
      _clearError();
      
      // Convert bytes to MultipartFile for web upload
      final multipartFile = MultipartFile.fromBytes(
        imageBytes,
        filename: 'selfie.jpg',
        contentType: MediaType('image', 'jpeg'),
      );
      
      final result = await _authService.uploadSelfieMultipart(multipartFile);
      
      if (result.success) {
        await loadProfile(); // Refresh profile data
        return true;
      } else {
        _setError(result.message);
        return false;
      }
    } catch (e) {
      _setError('Network error occurred: $e');
      return false;
    } finally {
      _setSelfieUploading(false);
    }
  }

  // Upload voice (File - for mobile)
  Future<bool> uploadVoice(File file) async {
    try {
      _setVoiceUploading(true);
      _clearError();

      final result = await _authService.uploadVoice(file);
      if (result.success) {
        // Refresh profile to get updated status
        await loadProfile();
        return true;
      } else {
        _setError(result.message);
        return false;
      }
    } catch (e) {
      _setError('Failed to upload voice: $e');
      return false;
    } finally {
      _setVoiceUploading(false);
    }
  }

  // Upload voice from bytes (for web)
  Future<bool> uploadVoiceBytes(Uint8List audioBytes) async {
    try {
      _setVoiceUploading(true);
      _clearError();
      
      // Convert bytes to MultipartFile for web upload
      final multipartFile = MultipartFile.fromBytes(
        audioBytes,
        filename: 'voice.wav',
        contentType: MediaType('audio', 'wav'),
      );
      
      final result = await _authService.uploadVoiceMultipart(multipartFile);
      
      if (result.success) {
        await loadProfile();
        return true;
      } else {
        _setError(result.message);
        return false;
      }
    } catch (e) {
      _setError('Network error occurred: $e');
      return false;
    } finally {
      _setVoiceUploading(false);
    }
  }

  // Verify identity
  Future<bool> verifyIdentity() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final result = await _authService.verifyIdentity();

      if (result.success) {
        // Reload profile to get updated verification status
        await loadProfile();
        return true;
      } else {
        _error = result.message;
        return false;
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get verification status details
  Map<String, dynamic> getVerificationStatus() {
    return {
      'has_selfie': hasSelfie,
      'has_voice': hasVoice,
      'is_verified': isVerified,
      'progress': verificationProgress,
      'can_verify': canVerifyIdentity,
      'next_step': _getNextVerificationStep(),
    };
  }

  // Get next verification step
  String _getNextVerificationStep() {
    if (!hasSelfie) return 'Upload selfie';
    if (!hasVoice) return 'Record voice';
    if (!isVerified && canVerifyIdentity) return 'Complete verification';
    if (isVerified) return 'Verification complete';
    return 'Unknown';
  }

  // Initialize profile data from user model
  void initializeFromUser(UserModel user) {
    _user = user;
    notifyListeners();
  }

  // Clear profile data
  void clearProfile() {
    _user = null;
    _clearError();
    notifyListeners();
  }

  // Helper methods
  void _setSelfieUploading(bool uploading) {
    _isSelfieUploading = uploading;
    notifyListeners();
  }

  void _setVoiceUploading(bool uploading) {
    _isVoiceUploading = uploading;
    notifyListeners();
  }

  // void _setVerifying(bool verifying) {
  //   _isVerifying = verifying;
  //   notifyListeners();
  // }

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