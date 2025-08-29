// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubscriptionModel _$SubscriptionModelFromJson(Map<String, dynamic> json) =>
    SubscriptionModel(
      subscriptionTier: json['subscriptionTier'] as String,
      dailyLimit: (json['dailyLimit'] as num).toInt(),
      requestCount: (json['requestCount'] as num).toInt(),
      remainingRequests: (json['remainingRequests'] as num).toInt(),
      canMakeRequests: json['canMakeRequests'] as bool,
      features:
          (json['features'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$SubscriptionModelToJson(SubscriptionModel instance) =>
    <String, dynamic>{
      'subscriptionTier': instance.subscriptionTier,
      'dailyLimit': instance.dailyLimit,
      'requestCount': instance.requestCount,
      'remainingRequests': instance.remainingRequests,
      'canMakeRequests': instance.canMakeRequests,
      'features': instance.features,
    };
