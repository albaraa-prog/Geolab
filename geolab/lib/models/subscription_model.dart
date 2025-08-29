import 'package:json_annotation/json_annotation.dart';

part 'subscription_model.g.dart';

@JsonSerializable()
class SubscriptionModel {
  final String subscriptionTier;
  final int dailyLimit;
  final int requestCount;
  final int remainingRequests;
  final bool canMakeRequests;
  final List<String> features;

  SubscriptionModel({
    required this.subscriptionTier,
    required this.dailyLimit,
    required this.requestCount,
    required this.remainingRequests,
    required this.canMakeRequests,
    required this.features,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionModelFromJson(json);
  Map<String, dynamic> toJson() => _$SubscriptionModelToJson(this);

  bool get isFree => subscriptionTier == 'free';
  bool get isPremium => subscriptionTier == 'premium';
  bool get isEnterprise => subscriptionTier == 'enterprise';
  double get usagePercentage =>
      dailyLimit > 0 ? (requestCount / dailyLimit) * 100 : 0;

  SubscriptionModel copyWith({
    String? subscriptionTier,
    int? dailyLimit,
    int? requestCount,
    int? remainingRequests,
    bool? canMakeRequests,
    List<String>? features,
  }) {
    return SubscriptionModel(
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      dailyLimit: dailyLimit ?? this.dailyLimit,
      requestCount: requestCount ?? this.requestCount,
      remainingRequests: remainingRequests ?? this.remainingRequests,
      canMakeRequests: canMakeRequests ?? this.canMakeRequests,
      features: features ?? this.features,
    );
  }

  @override
  String toString() {
    return 'SubscriptionModel(tier: $subscriptionTier, requests: $requestCount/$dailyLimit)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SubscriptionModel &&
        other.subscriptionTier == subscriptionTier &&
        other.requestCount == requestCount;
  }

  @override
  int get hashCode => subscriptionTier.hashCode ^ requestCount.hashCode;
}
