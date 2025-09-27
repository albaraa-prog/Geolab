import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolab/Service/subscription_service.dart';
import 'package:geolab/features/Auth/Bloc/auth_bloc.dart';
import 'package:geolab/features/Auth/Bloc/auth_state.dart';
import 'package:geolab/models/subscription_model.dart';
import 'package:geolab/config/theme_service.dart';
import 'package:geolab/features/Settings/bloc/settings_bloc.dart';
import 'package:geolab/features/Settings/bloc/settings_event.dart';
import 'package:geolab/features/Settings/bloc/settings_state.dart';
import 'package:geolab/features/Settings/components/localization.dart';
import 'package:geolab/utils/custom_back_button.dart';
import 'package:geolab/utils/rtl_wrapper.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RTLWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            context.read<LocalizationService>().translate('app.settings'),
          ),
          leading: const CustomBackButton(),
        ),
        body: Consumer2<LocalizationService, ThemeService>(
          builder: (context, localizationService, themeService, child) {
            return BlocBuilder<SettingsBloc, SettingsState>(
              builder: (context, state) {
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const SizedBox(height: 20),
                    _buildProfileSection(context, localizationService),
                    const SizedBox(height: 30),
                    _buildThemeSection(context, themeService, state),
                    const SizedBox(height: 20),
                    _buildLanguageSection(context, localizationService, state),
                    const SizedBox(height: 20),
                    _buildAboutSection(context, localizationService),
                  ],
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            final isAuthed = authState is AuthAuthenticated;
            final userEmail = isAuthed ? authState.user.email : '';
            final fallbackTitle =
                localizationService.translate('settings.profile.title');
            final fallbackSubtitle =
                localizationService.translate('settings.profile.subtitle');

            return Column(
              children: [
                const CircleAvatar(
                  radius: 40,
                  child: Icon(HugeIcons.strokeRoundedUserQuestion01,
                      size: 50, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  isAuthed && userEmail.isNotEmpty ? userEmail : fallbackTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: RTLUtils.startTextAlignment(context),
                ),
                const SizedBox(height: 8),
                if (isAuthed)
                  FutureBuilder<SubscriptionModel>(
                    future: subscriptionService.getSubscriptionStatus(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Text(
                          localizationService.translate('common.loading'),
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
                        );
                      }
                      if (!snapshot.hasData || snapshot.hasError) {
                        return Text(
                          fallbackSubtitle,
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
                        );
                      }
                      final sub = snapshot.data!;
                      final usage = '${sub.requestCount}/${sub.dailyLimit}';
                      return Column(
                        children: [
                          Text(
                            '${sub.subscriptionTier} • $usage',
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
                          if (sub.remainingRequests <= 1)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                localizationService
                                    .translate('subscription.almostOut'),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  )
                else
                  Text(
                    fallbackSubtitle,
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
              ],
            );
          },
        ),
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
            padding: RTLUtils.padding(
              left: 16,
              right: 16,
              context: context,
            ),
            child: Text(
              context
                  .read<LocalizationService>()
                  .translate('settings.theme.title'),
              style: Theme.of(context).textTheme.titleLarge,
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
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: RTLUtils.padding(
              left: 16,
              right: 16,
              context: context,
            ),
            child: Text(
              context
                  .read<LocalizationService>()
                  .translate('settings.language.title'),
              style: Theme.of(context).textTheme.titleLarge,
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
            trailing: Icon(
              RTLUtils.chevronIcon(context),
            ),
            onTap: () => _showLanguageDialog(context, localizationService),
          ),
          if (localizationService.isRTL)
            ListTile(
              leading: Icon(
                Icons.text_fields,
                color: Theme.of(context).colorScheme.secondary,
              ),
              title: Text(
                context
                    .read<LocalizationService>()
                    .translate('settings.language.rtl'),
              ),
              subtitle: Text(
                context
                    .read<LocalizationService>()
                    .translate('settings.language.rtlDescription'),
              ),
            ),
        ],
      ),
    );
  }

  

  Widget _buildAboutSection(
      BuildContext context, LocalizationService localizationService) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: RTLUtils.padding(
              left: 16,
              right: 16,
              context: context,
            ),
            child: Text(
              context
                  .read<LocalizationService>()
                  .translate('settings.about.title'),
              style: Theme.of(context).textTheme.titleLarge,
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
            trailing: Icon(
              RTLUtils.chevronIcon(context),
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
                  onTap: () {
                    localizationService.setLanguageCode(language['code']!);
                    Navigator.of(context).pop();
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

  void _showColorPickerDialog(BuildContext context, ThemeService themeService) {
    // Placeholder for color picker dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context
              .read<LocalizationService>()
              .translate('settings.appearance.colorsComingSoon'),
        ),
      ),
    );
  }

  void _showTypographyDialog(BuildContext context, ThemeService themeService) {
    // Placeholder for typography dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context
              .read<LocalizationService>()
              .translate('settings.appearance.typographyComingSoon'),
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
