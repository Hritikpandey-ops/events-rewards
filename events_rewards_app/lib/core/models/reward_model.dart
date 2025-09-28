class Reward {
  final String id;
  final String name;
  final String? description;
  final String? rewardType;
  final double? value;
  final double probability;
  final int? totalAvailable;
  final int totalClaimed;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Reward({
    required this.id,
    required this.name,
    this.description,
    this.rewardType,
    this.value,
    required this.probability,
    this.totalAvailable,
    required this.totalClaimed,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      rewardType: json['reward_type'] as String?,
      value: json['value'] != null 
          ? (json['value'] is num 
              ? (json['value'] as num).toDouble() 
              : double.tryParse(json['value'].toString()) ?? 0.0) 
          : null,
      probability: json['probability'] is num 
          ? (json['probability'] as num).toDouble() 
          : double.tryParse(json['probability'].toString()) ?? 0.0,
      totalAvailable: json['total_available'] as int?,
      totalClaimed: (json['total_claimed'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'reward_type': rewardType,
      'value': value,
      'probability': probability,
      'total_available': totalAvailable,
      'total_claimed': totalClaimed,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isNoReward => rewardType == 'none';
  bool get isAvailable => isActive && (totalAvailable == null || totalClaimed < totalAvailable!);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Reward && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Reward(id: $id, name: $name, type: $rewardType, value: $value)';
  }
}

class UserReward {
  final String id;
  final String userId;
  final String rewardId;
  final DateTime createdAt; // Changed from claimedAt to createdAt for when reward was earned
  final DateTime? claimedAt; // When reward was actually claimed (nullable)
  final String status;
  final String? claimCode;
  final DateTime? expiresAt;
  final Reward? reward; // Made nullable to handle potential null values

  UserReward({
    required this.id,
    required this.userId,
    required this.rewardId,
    required this.createdAt,
    this.claimedAt,
    required this.status,
    this.claimCode,
    this.expiresAt,
    this.reward,
  });

  factory UserReward.fromJson(Map<String, dynamic> json) {
    return UserReward(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      rewardId: json['reward_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      claimedAt: json['claimed_at'] != null 
          ? DateTime.parse(json['claimed_at'] as String) 
          : null,
      status: json['status'] as String,
      claimCode: json['claim_code'] as String?,
      expiresAt: json['expires_at'] != null 
          ? DateTime.parse(json['expires_at'] as String) 
          : null,
      reward: json['reward'] != null 
          ? Reward.fromJson(json['reward'] as Map<String, dynamic>) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'reward_id': rewardId,
      'created_at': createdAt.toIso8601String(),
      'claimed_at': claimedAt?.toIso8601String(),
      'status': status,
      'claim_code': claimCode,
      'expires_at': expiresAt?.toIso8601String(),
      'reward': reward?.toJson(),
    };
  }

  bool get isPending => status == 'pending';
  bool get isClaimed => status == 'claimed';
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get canClaim => isPending && !isExpired;

  String get formattedCreatedDate {
    final localTime = createdAt.toLocal(); 
    return '${localTime.day.toString().padLeft(2, '0')}/${localTime.month.toString().padLeft(2, '0')}/${localTime.year}';
  }

  String get formattedClaimedDate {
    if (claimedAt == null) return 'Not claimed';
    
    final localTime = claimedAt!.toLocal(); 
    return '${localTime.day.toString().padLeft(2, '0')}/${localTime.month.toString().padLeft(2, '0')}/${localTime.year}';
  }

  String get formattedExpiryDate {
    if (expiresAt == null) return 'No expiry';
    
    final localTime = expiresAt!.toLocal(); 
    return '${localTime.day.toString().padLeft(2, '0')}/${localTime.month.toString().padLeft(2, '0')}/${localTime.year}';
  }


  String get formattedCreatedDateTime {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}';
  }

  String get formattedClaimedDateTime {
    final localTime = createdAt.toLocal();
    return '${localTime.day.toString().padLeft(2, '0')}/${localTime.month.toString().padLeft(2, '0')}/${localTime.year}';
  }

  String get timeAgoCreated {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String get timeAgoExpiry {
    if (expiresAt == null) return 'Never expires';
    
    final now = DateTime.now();
    final difference = expiresAt!.difference(now);
    
    if (difference.isNegative) {
      return 'Expired';
    } else if (difference.inDays > 0) {
      return 'Expires in ${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return 'Expires in ${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return 'Expires in ${difference.inMinutes}m';
    } else {
      return 'Expires soon';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserReward && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'UserReward(id: $id, status: $status, reward: ${reward?.name})';
  }
}

class SpinAttempt {
  final String id;
  final String userId;
  final DateTime attemptDate;
  final int attemptsCount;
  final DateTime lastAttempt;

  SpinAttempt({
    required this.id,
    required this.userId,
    required this.attemptDate,
    required this.attemptsCount,
    required this.lastAttempt,
  });

  factory SpinAttempt.fromJson(Map<String, dynamic> json) {
    return SpinAttempt(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      attemptDate: DateTime.parse(json['attempt_date'] as String),
      attemptsCount: json['attempts_count'] as int,
      lastAttempt: DateTime.parse(json['last_attempt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'attempt_date': attemptDate.toIso8601String(),
      'attempts_count': attemptsCount,
      'last_attempt': lastAttempt.toIso8601String(),
    };
  }
}

class SpinResponse {
  final bool success;
  final Reward? reward;
  final String? claimCode;
  final String message;
  final DateTime? expiresAt;

  SpinResponse({
    required this.success,
    this.reward,
    this.claimCode,
    required this.message,
    this.expiresAt,
  });

  factory SpinResponse.fromJson(Map<String, dynamic> json) {
    return SpinResponse(
      success: json['success'] as bool? ?? false,
      reward: json['reward'] != null 
          ? Reward.fromJson(json['reward'] as Map<String, dynamic>) 
          : null,
      claimCode: json['claim_code'] as String?,
      message: json['message'] as String? ?? 'Unknown result',
      expiresAt: json['expires_at'] != null 
          ? DateTime.parse(json['expires_at'] as String) 
          : null,
    );
  }

  bool get isNoReward => reward?.isNoReward ?? true;

  @override
  String toString() {
    return 'SpinResponse(success: $success, reward: ${reward?.name}, message: $message)';
  }
}

class UserRewardStats {
  final int totalSpins;
  final int totalWins;
  final int pendingRewards;
  final int claimedRewards;

  UserRewardStats({
    required this.totalSpins,
    required this.totalWins,
    required this.pendingRewards,
    required this.claimedRewards,
  });

  factory UserRewardStats.fromJson(Map<String, dynamic> json) {
    return UserRewardStats(
      totalSpins: (json['total_spins'] as num?)?.toInt() ?? 0,
      totalWins: (json['total_wins'] as num?)?.toInt() ?? 0,
      pendingRewards: (json['pending_rewards'] as num?)?.toInt() ?? 0,
      claimedRewards: (json['claimed_rewards'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_spins': totalSpins,
      'total_wins': totalWins,
      'pending_rewards': pendingRewards,
      'claimed_rewards': claimedRewards,
    };
  }

  double get winRate => totalSpins > 0 ? totalWins / totalSpins : 0.0;

  @override
  String toString() {
    return 'UserRewardStats(spins: $totalSpins, wins: $totalWins, pending: $pendingRewards, claimed: $claimedRewards)';
  }
}
