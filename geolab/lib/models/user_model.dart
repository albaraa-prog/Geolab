// import 'package:json_annotation/json_annotation.dart';

// part 'user_model.g.dart';

// @JsonSerializable(fieldRename: FieldRename.snake)
class UserModel {
  final String id;
  final String email;
  final String subscriptionTier;
  final int requestCount;
  final int dailyLimit;
  final DateTime createdAt;
  final DateTime? lastLogin;

  UserModel({
    required this.id,
    required this.email,
    required this.subscriptionTier,
    required this.requestCount,
    required this.dailyLimit,
    required this.createdAt,
    this.lastLogin,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      subscriptionTier:
          json['subscription_tier'] ?? json['subscriptionTier'] ?? 'free',
      requestCount: (json['request_count'] ?? json['requestCount'] ?? 0) as int,
      dailyLimit: (json['daily_limit'] ?? json['dailyLimit'] ?? 5) as int,
      createdAt:
          DateTime.tryParse(json['created_at'] ?? json['createdAt'] ?? '') ??
              DateTime.now(),
      lastLogin: (json['last_login'] ?? json['lastLogin']) != null
          ? DateTime.tryParse(json['last_login'] ?? json['lastLogin'])
          : null,
    );
  }
  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'subscription_tier': subscriptionTier,
        'request_count': requestCount,
        'daily_limit': dailyLimit,
        'created_at': createdAt.toIso8601String(),
        'last_login': lastLogin?.toIso8601String(),
      };

  int get remainingRequests => dailyLimit - requestCount;
  bool get canMakeRequests => requestCount < dailyLimit;
  bool get isPremium =>
      subscriptionTier == 'premium' || subscriptionTier == 'enterprise';
  bool get isEnterprise => subscriptionTier == 'enterprise';

  UserModel copyWith({
    String? id,
    String? email,
    String? subscriptionTier,
    int? requestCount,
    int? dailyLimit,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      requestCount: requestCount ?? this.requestCount,
      dailyLimit: dailyLimit ?? this.dailyLimit,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, subscriptionTier: $subscriptionTier, requestCount: $requestCount, dailyLimit: $dailyLimit)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
