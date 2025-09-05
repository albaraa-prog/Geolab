import 'package:flutter/material.dart';
import 'package:geolab/features/Settings/SettingsPage.dart';
import 'package:geolab/utils/app_localizations.dart';
import 'package:geolab/utils/rtl_wrapper.dart';
import 'package:hugeicons/hugeicons.dart';

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
                  // TODO: Implement logout functionality
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
    return RTLWrapper(
      child: Drawer(
        backgroundColor: const Color.fromARGB(255, 235, 235, 235),
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Colors.black),
              accountName: Text(
                context.t('settings.profile.userName'),
                style: const TextStyle(color: Colors.white),
              ),
              accountEmail: Text(
                context.t('settings.profile.userEmail'),
                style: const TextStyle(color: Colors.white70),
              ),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.grey,
                child: Icon(HugeIcons.strokeRoundedUserQuestion01,
                    color: Colors.white, size: 40),
              ),
              otherAccountsPictures: [
                IconButton(
                  icon: const Icon(HugeIcons.strokeRoundedAccountSetting01,
                      color: Colors.white, size: 30),
                  onPressed: () => _showBottomSheet(context),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: context.t('navigation.searchHistory'),
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(HugeIcons.strokeRoundedSearch01,
                      color: Colors.black),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: const BorderSide(color: Colors.black),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: const BorderSide(color: Colors.black),
                  ),
                ),
                onChanged: (value) {
                  // Implement search functionality here
                },
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: 10, // Replace with actual history length
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: const Icon(HugeIcons.strokeRoundedAbacus),
                    title:
                        Text('${context.t('navigation.historyItem')} $index'),
                    subtitle: Text(
                        '${context.t('navigation.historyPreview')} $index'),
                    onTap: () {
                      // Handle opening past conversation
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
