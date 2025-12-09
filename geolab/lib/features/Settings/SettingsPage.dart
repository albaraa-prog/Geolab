import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolab/Service/subscription_service.dart';
import 'package:geolab/features/Auth/Bloc/auth_bloc.dart';
import 'package:geolab/features/Auth/Bloc/auth_state.dart';
import 'package:geolab/models/subscription_model.dart';
import 'package:geolab/Service/theme_service.dart';
import 'package:geolab/features/Settings/bloc/settings_bloc.dart';
import 'package:geolab/features/Settings/bloc/settings_event.dart';
import 'package:geolab/features/Settings/bloc/settings_state.dart';
import 'package:geolab/features/Settings/components/localization.dart';
import 'package:geolab/features/Settings/EditProfilePage.dart';
import 'package:geolab/utils/custom_back_button.dart';
import 'package:geolab/utils/rtl_wrapper.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import 'package:flutter/foundation.dart' show kIsWeb;

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RTLWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: Consumer<LocalizationService>(
            builder: (context, localizationService, child) {
              return Text(
                localizationService.translate('app.settings'),
              );
            },
          ),
          leading: const CustomBackButton(),
        ),
        body: Consumer2<LocalizationService, ThemeService>(
          builder: (context, localizationService, themeService, child) {
            return BlocBuilder<SettingsBloc, SettingsState>(
              builder: (context, state) {
                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: kIsWeb ? 800 : double.infinity),
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      children: [
                    const SizedBox(height: 20),
                    _buildProfileSection(context, localizationService),
                    const SizedBox(height: 30),
                    _buildSubscriptionSection(context, localizationService),
                    const SizedBox(height: 30),
                    _buildThemeSection(context, themeService, state),
                    const SizedBox(height: 20),
                    _buildLanguageSection(context, localizationService, state),
                    const SizedBox(height: 20),
                    _buildAboutSection(context, localizationService),
                  ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileSection(
      BuildContext context, LocalizationService localizationService) {
    final subscriptionService = SubscriptionService();
    final themeService = ThemeService.instance;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            final isAuthed = authState is AuthAuthenticated;
            final userEmail = isAuthed ? authState.user.email : '';
            // Get name from user model, fallback to email prefix if not available
            final userName = isAuthed 
                ? (authState.user.name ?? userEmail.split('@')[0])
                : '';
            final fallbackTitle =
                localizationService.translate('settings.profile.title');
            final fallbackSubtitle =
                localizationService.translate('settings.profile.subtitle');

            return Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor:
                          themeService.primaryColor.withOpacity(0.1),
                      child: Icon(
                        HugeIcons.strokeRoundedUserQuestion01,
                        size: 50,
                        color: themeService.primaryColor,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: themeService.primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: themeService.surfaceColor,
                            width: 2,
                          ),
                        ),
                        child: IconButton(
                          icon: Icon(
                            HugeIcons.strokeRoundedEdit01,
                            color: themeService.onPrimaryColor,
                            size: 16,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EditProfilePage(),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  userName.isNotEmpty
                      ? userName
                      : (isAuthed && userEmail.isNotEmpty
                          ? userEmail
                          : fallbackTitle),
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: RTLUtils.startTextAlignment(context),
                ),
                const SizedBox(height: 8),
                if (isAuthed)
                  FutureBuilder<SubscriptionModel>(
                    // future: subscriptionService.getSubscriptionStatus(),
                    future: Future.error('Disabled'),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Text(
                          localizationService.translate('common.loading'),
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.7),
                                  ),
                          textAlign: TextAlign.center,
                        );
                      }
                      if (!snapshot.hasData || snapshot.hasError) {
                        return Text(
                          fallbackSubtitle,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.7),
                                  ),
                          textAlign: TextAlign.center,
                        );
                      }
                      final sub = snapshot.data!;
                      final usage = '${sub.requestCount}/${sub.dailyLimit}';
                      final remaining = sub.remainingRequests;
                      final tier = sub.subscriptionTier.toUpperCase();

                      return Column(
                        children: [
                          // Subscription Tier Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: themeService.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color:
                                    themeService.primaryColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              tier,
                              style: TextStyle(
                                color: themeService.primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Usage Information
                          Text(
                            '${localizationService.translate('subscription.usage')}: $usage',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.7),
                                ),
                            textAlign: TextAlign.center,
                          ),

                          // Progress Bar
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: sub.dailyLimit > 0
                                  ? (sub.requestCount / sub.dailyLimit)
                                      .clamp(0.0, 1.0)
                                  : 0.0,
                              backgroundColor: themeService.dividerColor,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                remaining <= 1
                                    ? themeService.errorColor
                                    : themeService.primaryColor,
                              ),
                            ),
                          ),

                          // Warning or Success Message
                          if (remaining <= 1)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    HugeIcons.strokeRoundedAlert01,
                                    color: themeService.errorColor,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    localizationService
                                        .translate('subscription.almostOut'),
                                    style: TextStyle(
                                      color: themeService.errorColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else if (remaining <= 5)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    HugeIcons.strokeRoundedAlert01,
                                    color: themeService.warningColor,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${localizationService.translate('subscription.remaining')}: $remaining',
                                    style: TextStyle(
                                      color: themeService.warningColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      );
                    },
                  )
                else
                  Text(
                    fallbackSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.7),
                        ),
                    textAlign: TextAlign.center,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSubscriptionSection(
      BuildContext context, LocalizationService localizationService) {
    final subscriptionService = SubscriptionService();
    final themeService = ThemeService.instance;

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(
              top: 20,
              bottom: 8,
            ).add(RTLUtils.padding(
              left: 16,
              right: 16,
              context: context,
            )),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      context
                          .read<LocalizationService>()
                          .translate('settings.subscription.title'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),

                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 1,
                  color: themeService.dividerColor,
                ),
              ],
            ),
          ),
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              final isAuthed = authState is AuthAuthenticated;
              
              if (!isAuthed) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      localizationService.translate('settings.subscription.notLoggedIn'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              return FutureBuilder<SubscriptionModel>(
                // future: subscriptionService.getSubscriptionStatus(),
                future: Future.error('Coming Soon'), // Force error state
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: Column(
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Text(
                              localizationService.translate('common.loading'),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: Text(
                          localizationService.translate('common.comingSoon'),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  final sub = snapshot.data!;
                  final usage = '${sub.requestCount}/${sub.dailyLimit}';
                  final remaining = sub.remainingRequests;
                  final tier = sub.subscriptionTier.toUpperCase();

                  return Column(
                    children: [
                      // Subscription Tier
                      ListTile(
                        leading: Icon(
                          HugeIcons.strokeRoundedUserQuestion01,
                          color: themeService.primaryColor,
                        ),
                        title: Text(
                          localizationService.translate('settings.subscription.tier'),
                        ),
                        subtitle: Text(tier),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: themeService.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: themeService.primaryColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            tier,
                            style: TextStyle(
                              color: themeService.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      
                      // Usage Information
                      ListTile(
                        leading: Icon(
                          Icons.bar_chart,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        title: Text(
                          localizationService.translate('settings.subscription.usage'),
                        ),
                        subtitle: Text(usage),
                        trailing: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: SizedBox(
                            width: 60,
                            child: LinearProgressIndicator(
                              value: sub.dailyLimit > 0
                                  ? (sub.requestCount / sub.dailyLimit).clamp(0.0, 1.0)
                                  : 0.0,
                              backgroundColor: themeService.dividerColor,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                remaining <= 1
                                    ? themeService.errorColor
                                    : themeService.primaryColor,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Remaining Requests
                      ListTile(
                        leading: Icon(
                          Icons.timer,
                          color: remaining <= 1 
                              ? themeService.errorColor 
                              : remaining <= 5 
                                  ? themeService.warningColor 
                                  : themeService.primaryColor,
                        ),
                        title: Text(
                          localizationService.translate('settings.subscription.remaining'),
                        ),
                        subtitle: Text(
                          remaining <= 1
                              ? localizationService.translate('settings.subscription.almostOut')
                              : remaining <= 5
                                  ? '${localizationService.translate('settings.subscription.remaining')}: $remaining'
                                  : '${localizationService.translate('settings.subscription.remaining')}: $remaining',
                        ),
                        trailing: remaining <= 1
                            ? Icon(
                                HugeIcons.strokeRoundedAlert01,
                                color: themeService.errorColor,
                              )
                            : remaining <= 5
                                ? Icon(
                                    HugeIcons.strokeRoundedAlert01,
                                    color: themeService.warningColor,
                                  )
                                : Icon(
                                    Icons.check_circle,
                                    color: themeService.primaryColor,
                                  ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSection(
      BuildContext context, ThemeService themeService, SettingsState state) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(
              top: 20,
              bottom: 8,
            ).add(RTLUtils.padding(
              left: 16,
              right: 16,
              context: context,
            )),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context
                      .read<LocalizationService>()
                      .translate('settings.theme.title'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Container(
                  height: 1,
                  color: themeService.dividerColor,
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(
              state.isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              context
                  .read<LocalizationService>()
                  .translate('settings.theme.mode'),
            ),
            subtitle: Text(
              state.isDarkMode
                  ? context
                      .read<LocalizationService>()
                      .translate('settings.theme.darkMode')
                  : context
                      .read<LocalizationService>()
                      .translate('settings.theme.lightMode'),
            ),
            trailing: Switch(
              value: state.isDarkMode,
              onChanged: (value) {
                // Update both the bloc and theme service
                context.read<SettingsBloc>().add(
                      ThemeToggled(isDarkMode: value),
                    );
                themeService.setTheme(value);
              },
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.brightness_auto,
              color: Theme.of(context).colorScheme.secondary,
            ),
            title: Text(
              context
                  .read<LocalizationService>()
                  .translate('settings.theme.system'),
            ),
            subtitle: Text(
              context
                  .read<LocalizationService>()
                  .translate('settings.theme.systemDescription'),
            ),
            trailing: Switch(
              value: themeService.useSystemTheme,
              onChanged: (value) {
                themeService.setUseSystemTheme(value);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSection(BuildContext context,
      LocalizationService localizationService, SettingsState state) {
    final themeService = ThemeService.instance;
    
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(
              top: 20,
              bottom: 8,
            ).add(RTLUtils.padding(
              left: 16,
              right: 16,
              context: context,
            )),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context
                      .read<LocalizationService>()
                      .translate('settings.language.title'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Container(
                  height: 1,
                  color: themeService.dividerColor,
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.language,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              context
                  .read<LocalizationService>()
                  .translate('settings.language.current'),
            ),
            subtitle: Text(
              localizationService
                  .getLocaleDisplayName(localizationService.currentLocale),
            ),
            onTap: () => _showLanguageDialog(context, localizationService),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(
      BuildContext context, LocalizationService localizationService) {
    final themeService = ThemeService.instance;
    
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(
              top: 20,
              bottom: 8,
            ).add(RTLUtils.padding(
              left: 16,
              right: 16,
              context: context,
            )),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context
                      .read<LocalizationService>()
                      .translate('settings.about.title'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Container(
                  height: 1,
                  color: themeService.dividerColor,
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              context
                  .read<LocalizationService>()
                  .translate('settings.about.version'),
            ),
            subtitle: const Text('1.0.0'),
          ),
          ListTile(
            leading: Icon(
              Icons.description,
              color: Theme.of(context).colorScheme.secondary,
            ),
            title: Text(
              context
                  .read<LocalizationService>()
                  .translate('settings.about.license'),
            ),  
            onTap: () => _showLicenseDialog(context),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(
      BuildContext context, LocalizationService localizationService) {
    showDialog(
      context: context,
      builder: (context) => RTLWrapper(
        child: AlertDialog(
          title: Text(
            context
                .read<LocalizationService>()
                .translate('settings.language.select'),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: localizationService.availableLanguages.length,
              itemBuilder: (context, index) {
                final language = localizationService.availableLanguages[index];
                final isCurrent = language['code'] ==
                    localizationService.currentLocale.languageCode;

                return ListTile(
                  leading: Text(
                    language['flag']!,
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(language['name']!),
                  subtitle: Text(language['code']!.toUpperCase()),
                  trailing: isCurrent
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () async {
                    // Show loading indicator
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );

                    // Change language
                    await localizationService
                        .setLanguageCode(language['code']!);

                    // Close loading dialog and language dialog
                    if (context.mounted) {
                      Navigator.of(context).pop(); // Close loading
                      Navigator.of(context).pop(); // Close language dialog
                    }
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                context.read<LocalizationService>().translate('common.cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLicenseDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Geolab',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.rocket_launch),
      children: [
        Text(
          context
              .read<LocalizationService>()
              .translate('settings.about.licenseText'),
        ),
      ],
    );
  }
}
