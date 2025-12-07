import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolab/features/Auth/Bloc/auth_bloc.dart';
import 'package:geolab/features/Auth/Bloc/auth_state.dart';
import 'package:geolab/features/Auth/Bloc/auth_event.dart';
import 'package:geolab/Service/subscription_service.dart';
import 'package:geolab/models/subscription_model.dart';
import 'package:geolab/features/Settings/SettingsPage.dart';
import 'package:geolab/Service/api_service.dart';
import 'package:geolab/models/prediction_model.dart';
import 'package:geolab/utils/app_localizations.dart';
import 'package:geolab/utils/rtl_wrapper.dart';
import 'package:geolab/Service/theme_service.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:geolab/features/Home/components/ClassificationResultModal.dart';
import 'package:geolab/features/Home/components/ShimmerLoading.dart';
import 'package:geolab/features/RockClassification/Bloc/rock_classification_state.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return RTLWrapper(
          child: AlertDialog(
            title: Text(context.t('auth.logout.confirm')),
            content: Text(context.t('auth.logout.confirmMessage')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(context.t('common.cancel')),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  // Dispatch logout
                  context.read<AuthBloc>().add(AuthLogoutRequested());
                },
                child: Text(
                  context.t('auth.logout.title'),
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return RTLWrapper(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(HugeIcons.strokeRoundedSetting06),
                  title: Text(context.t('navigation.settings')),
                  onTap: () {
                    Navigator.pop(context);
                    // context.go('/settings');
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsPage(),
                        ));
                  },
                ),
                ListTile(
                  leading: const Icon(HugeIcons.strokeRoundedLogout01,
                      color: Colors.red),
                  title: Text(
                    context.t('auth.logout.title'),
                    style: const TextStyle(color: Colors.red),
                  ),
                  onTap: () => _showLogoutConfirmation(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeService = ThemeService.instance;
    return RTLWrapper(
      child: Drawer(
        backgroundColor: themeService.surfaceColor,
        child: Column(
          children: [
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, authState) {

                String displayName = context.t('settings.profile.userName');
                String displayEmail = context.t('settings.profile.userEmail');
                if (authState is AuthAuthenticated) {
                  final email = authState.user.email;
                  if (email.isNotEmpty) {
                    displayEmail = email;
                    // Use actual name from user model, fallback to email prefix
                    displayName = authState.user.name ?? 
                        (email.split('@').first);
                  }
                }

                return UserAccountsDrawerHeader(
                  decoration: BoxDecoration(color: themeService.primaryColor),
                  accountName: Text(
                    displayName,
                    style: TextStyle(color: themeService.onPrimaryColor),
                  ),
                  accountEmail: Text(
                    displayEmail,
                    style: TextStyle(color: themeService.onPrimaryColor.withOpacity(0.7)),
                  ),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: themeService.primaryColor.withOpacity(0.3),
                    child: Icon(HugeIcons.strokeRoundedUserQuestion01,
                        color: themeService.onPrimaryColor, size: 40),
                  ),
                  otherAccountsPictures: [
                    IconButton(
                      icon: Icon(HugeIcons.strokeRoundedAccountSetting01,
                          color: themeService.onPrimaryColor, size: 30),
                      onPressed: () => _showBottomSheet(context),
                    ),
                  ],
                );
              },
            ),
            // Dynamic usage summary card under header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: FutureBuilder<SubscriptionModel>(
                future: SubscriptionService().getSubscriptionStatus(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox.shrink();
                  }
                  if (!snapshot.hasData) {
                    return const SizedBox.shrink();
                  }
                  final sub = snapshot.data!;
                  final used = sub.requestCount;
                  final total = sub.dailyLimit;
                  final pct = total > 0 ? (used / total).clamp(0.0, 1.0) : 0.0;
                  return Container(
                    decoration: BoxDecoration(
                      color: themeService.cardColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Usage', style: Theme.of(context).textTheme.bodyLarge),
                            Text('${used}/${total}')
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(value: pct),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // History list from backend
            Expanded(
              child: FutureBuilder<List<PredictionModel>>(
                future: ApiService().getMyPredictions(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SidebarShimmerPlaceholder();
                  }
                  final items = snapshot.data ?? const <PredictionModel>[];
                  if (items.isEmpty) {
                    return Center(
                      child: Text(
                        context.t('navigation.historyEmpty'),
                        style: TextStyle(color: themeService.textColor.withOpacity(0.6)),
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final p = items[index];
                      return ListTile(
                        leading: const Icon(HugeIcons.strokeRoundedTime04),
                        title: Text(p.prediction),
                        subtitle: Text('${p.confidencePercentage} • ${p.timestamp.toLocal()}'),
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: themeService.surfaceColor,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                            ),
                            builder: (context) => ClassificationResultModal(
                              state: ClassificationComplete(
                                rockType: p.prediction,
                                confidence: p.confidence,
                                image: null,
                                additionalData: {
                                  'xai_visualization': p.xaiVisualization,
                                  'image_url': p.imagePath,
                                  'probabilities': p.probabilities,
                                  'confidence_breakdown': p.confidenceBreakdown,
                                  'reasoning': p.reasoning,
                                  'stage1': p.stage1,
                                  'stage2': p.stage2,
                                  'stage3': p.stage3,
                                },
                              ),
                              themeService: themeService,
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
