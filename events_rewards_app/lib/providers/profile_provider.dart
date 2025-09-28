import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart'; // Add this import for MultipartFile
import 'package:http_parser/http_parser.dart'; // Add this import for MediaType
import '../core/services/auth_service.dart';
import '../core/models/user_model.dart';

class ProfileProvider with ChangeNotifier {
  final AuthService _authService = AuthService.instance;

  // State variables
  UserModel? _user;
  bool _isLoading = false;
  bool _isSelfieUploading = false;
  bool _isVoiceUploading = false;
  bool _isVerifying = false;
  String? _error;

  // Getters
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isSelfieUploading => _isSelfieUploading;
  bool get isVoiceUploading => _isVoiceUploading;
  bool get isVerifying => _isVerifying;
  String? get error => _error;

  // Verification status getters
bool get hasSelfie {
  final result = user?.hasSelfie ?? false;
  return result;
}

bool get hasVoice {
  final result = user?.hasVoice ?? false;
  return result;
}

bool get isVerified {
  final result = user?.isVerified ?? false;
  return result;
}

bool get canVerifyIdentity {
  final result = hasSelfie && hasVoice && !isVerified;
  return result;
}


  // Verification progress (0.0 to 1.0)
  double get verificationProgress {
    if (_user == null) return 0.0;
    double progress = 0.0;
    if (hasSelfie) progress += 0.5;
    if (hasVoice) progress += 0.3;
    if (isVerified) progress = 1.0;
    return progress;
  }

  // Load profile data
Future<void> loadProfile() async {
  try {
    _setLoading(true);
    _clearError();
    
    
    // Use the correct method that returns AuthResult
    final result = await _authService.getProfile();
    
    if (result.success && result.userData != null) {
      _user = UserModel.fromJson(result.userData!);
      notifyListeners();  
    } else {
      _setError(result.message);
    }
  } catch (e) {
    _setError('Failed to load profile: $e');
  } finally {
    _setLoading(false);
  }
}


  // Update profile
  Future<bool> updateProfile(Map<String, dynamic> profileData) async {
    try {
      _setLoading(true);
      _clearError();

      final result = await _authService.updateProfile(profileData);
      if (result.success && result.userData != null) {
        _user = UserModel.fromJson(result.userData!);
        notifyListeners();
        return true;
      } else {
        _setError(result.message);
        return false;
      }
    } catch (e) {
      _setError('Failed to update profile: $e');
      return false;
    } finally {
      _setLoading(false);
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
      _setVoiceUploading(false);
    }
  }

  // Verify identity
  Future<bool> verifyIdentity() async {
    if (!canVerifyIdentity) {
      _setError('Please upload both selfie and voice recording first');
      return false;
    }

    try {
      _setVerifying(true);
      _clearError();

      final result = await _authService.verifyIdentity();
      if (result.success) {
        // Refresh profile to get updated verification status
        await loadProfile();
        return true;
      } else {
        _setError(result.message);
        return false;
      }
    } catch (e) {
      _setError('Failed to verify identity: $e');
      return false;
    } finally {
      _setVerifying(false);
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
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setSelfieUploading(bool uploading) {
    _isSelfieUploading = uploading;
    notifyListeners();
  }

  void _setVoiceUploading(bool uploading) {
    _isVoiceUploading = uploading;
    notifyListeners();
  }

  void _setVerifying(bool verifying) {
    _isVerifying = verifying;
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
