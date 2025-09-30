class UserModel {
  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? selfieUrl;
  final bool isVerified;
  final bool hasSelfie;
  final bool hasVoice;
  final String verificationStatus;
  final DateTime createdAt;
  final DateTime? verificationCompletedAt;

  UserModel({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.phone,
    this.selfieUrl,
    this.isVerified = false,
    this.hasSelfie = false,
    this.hasVoice = false,
    this.verificationStatus = 'pending',
    required this.createdAt,
    this.verificationCompletedAt,
  });

// Factory constructor from JSON
factory UserModel.fromJson(Map<String, dynamic> json) {
  return UserModel(
    id: json['id']?.toString() ?? '',
    email: json['email']?.toString() ?? '',
    firstName: json['first_name']?.toString(),
    lastName: json['last_name']?.toString(),
    phone: json['phone']?.toString(),
    selfieUrl: json['selfie_url']?.toString(),
    isVerified: json['is_verified'] as bool? ?? false,
    hasSelfie: json['has_selfie'] as bool? ?? false,
    hasVoice: json['has_voice'] as bool? ?? false,
    verificationStatus: json['verification_status']?.toString() ?? 'pending',
    createdAt: DateTime.parse(json['created_at'] as String),
    verificationCompletedAt: json['verification_completed_at'] != null
        ? DateTime.parse(json['verification_completed_at'] as String)
        : null,
  );
}

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'selfie_url': selfieUrl,
      'is_verified': isVerified,
      'has_selfie': hasSelfie,
      'has_voice': hasVoice,
      'verification_status': verificationStatus,
      'created_at': createdAt.toIso8601String(),
      'verification_completed_at': verificationCompletedAt?.toIso8601String(),
    };
  }

  // Helper getters
  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return firstName ?? lastName ?? email;
  }

  String get displayName => fullName;

  // Copy with method
  UserModel copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? phone,
    String? selfieUrl,
    bool? isVerified,
    bool? hasSelfie,
    bool? hasVoice,
    String? verificationStatus,
    DateTime? createdAt,
    DateTime? verificationCompletedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      selfieUrl: selfieUrl ?? this.selfieUrl,
      isVerified: isVerified ?? this.isVerified,
      hasSelfie: hasSelfie ?? this.hasSelfie,
      hasVoice: hasVoice ?? this.hasVoice,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      createdAt: createdAt ?? this.createdAt,
      verificationCompletedAt: verificationCompletedAt ?? this.verificationCompletedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, fullName: $fullName, isVerified: $isVerified)';
  }
}