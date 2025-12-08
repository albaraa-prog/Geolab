import 'package:geolab/Service/api_service.dart';
import 'package:geolab/models/subscription_model.dart';

class SubscriptionService {
  final ApiService _apiService;

  SubscriptionService({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  /// Get current subscription status
  Future<SubscriptionModel> getSubscriptionStatus() async {
    try {
      return await _apiService.getSubscriptionStatus();
    } catch (e) {
      throw Exception('Failed to get subscription status: $e');
    }
  }

  /// Upgrade subscription tier
  Future<Map<String, dynamic>> upgradeSubscription(String newTier) async {
    try {
      return await _apiService.upgradeSubscription(newTier);
    } catch (e) {
      throw Exception('Failed to upgrade subscription: $e');
    }
  }

  /// Get usage statistics
  Future<Map<String, dynamic>> getUsageStatistics() async {
    try {
      return await _apiService.getUsageStatistics();
    } catch (e) {
      throw Exception('Failed to get usage statistics: $e');
    }
  }

  /// Get available subscription plans
  Future<Map<String, dynamic>> getSubscriptionPlans() async {
    try {
      return await _apiService.getSubscriptionPlans();
    } catch (e) {
      throw Exception('Failed to get subscription plans: $e');
    }
  }

  /// Check if user can make requests
  Future<bool> canMakeRequest() async {
    try {
      final subscription = await getSubscriptionStatus();
      return subscription.canMakeRequests;
    } catch (e) {

      return false;
    }
  }

  /// Get remaining requests for today
  Future<int> getRemainingRequests() async {
    try {
      final subscription = await getSubscriptionStatus();
      return subscription.remainingRequests;
    } catch (e) {

      return 0;
    }
  }

  /// Get subscription features
  List<String> getSubscriptionFeatures(String tier) {
    switch (tier.toLowerCase()) {
      case 'free':
        return [
          'Basic rock classification',
          'Standard XAI visualizations',
          'Community support',
          '5 requests per day',
        ];
      case 'premium':
        return [
          'Unlimited rock classification',
          'Advanced XAI visualizations',
          'User feedback collection',
          'Priority support',
          '1000 requests per day',
        ];
      case 'enterprise':
        return [
          'All Premium features',
          'API access for integration',
          'Custom model training',
          'Batch processing',
          'Dedicated support',
          '10,000 requests per day',
        ];
      default:
        return [
          'Basic rock classification',
          'Standard XAI visualizations',
          'Community support',
          '5 requests per day',
        ];
    }
  }

  /// Get subscription pricing
  Map<String, dynamic> getSubscriptionPricing() {
    return {
      'free': {
        'price': 0.0,
        'currency': 'USD',
        'billing': 'Free',
        'features': getSubscriptionFeatures('free'),
      },
      'premium': {
        'price': 9.99,
        'currency': 'USD',
        'billing': 'Monthly',
        'features': getSubscriptionFeatures('premium'),
      },
      'enterprise': {
        'price': 99.99,
        'currency': 'USD',
        'billing': 'Monthly',
        'features': getSubscriptionFeatures('enterprise'),
      },
    };
  }

  /// Validate subscription tier
  bool isValidSubscriptionTier(String tier) {
    return ['free', 'premium', 'enterprise'].contains(tier.toLowerCase());
  }

  /// Get upgrade recommendations based on usage
  List<String> getUpgradeRecommendations(SubscriptionModel subscription) {
    final recommendations = <String>[];

    if (subscription.isFree) {
      if (subscription.usagePercentage > 80) {
        recommendations
            .add('Consider upgrading to Premium for unlimited requests');
      }
      if (subscription.requestCount > 3) {
        recommendations
            .add('Upgrade to Premium to submit feedback and improve accuracy');
      }
    }

    if (subscription.isPremium && subscription.usagePercentage > 90) {
      recommendations
          .add('Consider Enterprise for higher daily limits and API access');
    }

    return recommendations;
  }
}
