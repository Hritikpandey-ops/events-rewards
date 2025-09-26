class RewardModel {
  final String id;
  final String name;
  final String description;
  final String type;
  final dynamic value;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? expiresAt;

  RewardModel({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.value,
    required this.isActive,
    required this.createdAt,
    this.expiresAt,
  });

  // Factory constructor from JSON
  factory RewardModel.fromJson(Map<String, dynamic> json) {
    return RewardModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      type: json['type'] as String,
      value: json['value'], // Dynamic value
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type,
      'value': value,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
    };
  }

  // Helper getters
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  String get formattedValue {
    if (value is num) {
      return value.toString();
    }
    return value.toString();
  }

  String get formattedExpiry {
    if (expiresAt == null) return 'No expiry';
    if (isExpired) return 'Expired';
    final date = expiresAt!;
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RewardModel &&
        other.id == id &&
        other.name == name &&
        other.type == type;
  }

  @override
  int get hashCode {
    return id.hashCode ^ name.hashCode ^ type.hashCode;
  }

  @override
  String toString() {
    return 'RewardModel(id: $id, name: $name, type: $type, isExpired: $isExpired)';
  }
}

// UserRewardModel - represents a reward earned by a user
class UserRewardModel {
  final String id;
  final String rewardId;
  final String userId;
  final RewardModel reward;
  final String status; // 'earned', 'redeemed', 'expired'
  final DateTime earnedAt;
  final DateTime? redeemedAt;
  final DateTime? expiresAt;

  UserRewardModel({
    required this.id,
    required this.rewardId,
    required this.userId,
    required this.reward,
    required this.status,
    required this.earnedAt,
    this.redeemedAt,
    this.expiresAt,
  });

  // Factory constructor from JSON
  factory UserRewardModel.fromJson(Map<String, dynamic> json) {
    return UserRewardModel(
      id: json['id'] as String,
      rewardId: json['reward_id'] as String,
      userId: json['user_id'] as String,
      reward: RewardModel.fromJson(json['reward'] as Map<String, dynamic>),
      status: json['status'] as String,
      earnedAt: DateTime.parse(json['earned_at'] as String),
      redeemedAt: json['redeemed_at'] != null
          ? DateTime.parse(json['redeemed_at'] as String)
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reward_id': rewardId,
      'user_id': userId,
      'reward': reward.toJson(),
      'status': status,
      'earned_at': earnedAt.toIso8601String(),
      'redeemed_at': redeemedAt?.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
    };
  }

  // Helper getters
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  bool get canRedeem {
    return status == 'earned' && !isExpired;
  }

  String get formattedEarnedDate {
    return '${earnedAt.day}/${earnedAt.month}/${earnedAt.year}';
  }

  String get formattedRedeemedDate {
    if (redeemedAt == null) return '';
    return '${redeemedAt!.day}/${redeemedAt!.month}/${redeemedAt!.year}';
  }

  String get formattedExpiryDate {
    if (expiresAt == null) return 'No expiry';
    return '${expiresAt!.day}/${expiresAt!.month}/${expiresAt!.year}';
  }

  // Copy with method for updating the model
  UserRewardModel copyWith({
    String? id,
    String? rewardId,
    String? userId,
    RewardModel? reward,
    String? status,
    DateTime? earnedAt,
    DateTime? redeemedAt,
    DateTime? expiresAt,
  }) {
    return UserRewardModel(
      id: id ?? this.id,
      rewardId: rewardId ?? this.rewardId,
      userId: userId ?? this.userId,
      reward: reward ?? this.reward,
      status: status ?? this.status,
      earnedAt: earnedAt ?? this.earnedAt,
      redeemedAt: redeemedAt ?? this.redeemedAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserRewardModel &&
        other.id == id &&
        other.rewardId == rewardId &&
        other.userId == userId;
  }

  @override
  int get hashCode {
    return id.hashCode ^ rewardId.hashCode ^ userId.hashCode;
  }

  @override
  String toString() {
    return 'UserRewardModel(id: $id, reward: ${reward.name}, status: $status)';
  }
}
