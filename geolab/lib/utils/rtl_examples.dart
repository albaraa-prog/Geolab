import 'package:flutter/material.dart';
import 'package:geolab/utils/rtl_wrapper.dart';
import 'package:geolab/utils/app_localizations.dart';

/// Example widget showing RTL-aware layout
class RTLExampleWidget extends StatelessWidget {
  const RTLExampleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return RTLWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.t('app.title')),
          leading: IconButton(
            icon: Icon(RTLUtils.arrowIcon(context)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: RTLUtils.startCrossAxisAlignment(context),
            children: [
              // RTL-aware text alignment
              Text(
                context.t('settings.profile.title'),
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: RTLUtils.startTextAlignment(context),
              ),
              const SizedBox(height: 16),
              
              // RTL-aware card with padding
              Card(
                child: Padding(
                  padding: RTLUtils.padding(
                    left: 16,
                    right: 8,
                    context: context,
                  ),
                  child: Row(
                    mainAxisAlignment: RTLUtils.startMainAxisAlignment(context),
                    children: [
                      Icon(
                        Icons.info,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          context.t('settings.profile.subtitle'),
                          textAlign: RTLUtils.startTextAlignment(context),
                        ),
                      ),
                      Icon(
                        RTLUtils.chevronIcon(context),
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // RTL-aware button row
              Row(
                mainAxisAlignment: RTLUtils.startMainAxisAlignment(context),
                children: RTLUtils.reverseIfRTL([
                  ElevatedButton(
                    onPressed: () {},
                    child: Text(context.t('common.save')),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () {},
                    child: Text(context.t('common.cancel')),
                  ),
                ], context),
              ),
              const SizedBox(height: 16),
              
              // RTL-aware list items
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.language,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(
                        context.t('settings.language.title'),
                        textAlign: RTLUtils.startTextAlignment(context),
                      ),
                      trailing: Icon(
                        RTLUtils.chevronIcon(context),
                      ),
                      onTap: () {},
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.dark_mode,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      title: Text(
                        context.t('settings.theme.title'),
                        textAlign: RTLUtils.startTextAlignment(context),
                      ),
                      trailing: Icon(
                        RTLUtils.chevronIcon(context),
                      ),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // RTL-aware input field
              TextField(
                decoration: InputDecoration(
                  labelText: context.t('auth.email'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(RTLUtils.startAlignment(context) == Alignment.centerLeft ? 8 : 0),
                      topRight: Radius.circular(RTLUtils.startAlignment(context) == Alignment.centerRight ? 8 : 0),
                      bottomLeft: Radius.circular(RTLUtils.startAlignment(context) == Alignment.centerLeft ? 0 : 8),
                      bottomRight: Radius.circular(RTLUtils.startAlignment(context) == Alignment.centerRight ? 0 : 8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Example of RTL-aware navigation drawer
class RTLNavigationDrawer extends StatelessWidget {
  const RTLNavigationDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return RTLWrapper(
      child: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Column(
                crossAxisAlignment: RTLUtils.startCrossAxisAlignment(context),
                children: [
                  const CircleAvatar(
                    radius: 30,
                    child: Icon(Icons.person, size: 30),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.t('app.title'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.home,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                context.t('navigation.home'),
                textAlign: RTLUtils.startTextAlignment(context),
              ),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(
                Icons.camera_alt,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                context.t('navigation.camera'),
                textAlign: RTLUtils.startTextAlignment(context),
              ),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(
                Icons.settings,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                context.t('navigation.settings'),
                textAlign: RTLUtils.startTextAlignment(context),
              ),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

/// Example of RTL-aware bottom navigation
class RTLBottomNavigation extends StatelessWidget {
  const RTLBottomNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return RTLWrapper(
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: RTLUtils.reverseIfRTL([
          BottomNavigationBarItem(
            icon: Icon(RTLUtils.icon(
              ltr: Icons.home,
              rtl: Icons.home,
              context: context,
            )),
            label: context.t('navigation.home'),
          ),
          BottomNavigationBarItem(
            icon: Icon(RTLUtils.icon(
              ltr: Icons.camera_alt,
              rtl: Icons.camera_alt,
              context: context,
            )),
            label: context.t('navigation.camera'),
          ),
          BottomNavigationBarItem(
            icon: Icon(RTLUtils.icon(
              ltr: Icons.photo_library,
              rtl: Icons.photo_library,
              context: context,
            )),
            label: context.t('navigation.gallery'),
          ),
          BottomNavigationBarItem(
            icon: Icon(RTLUtils.icon(
              ltr: Icons.settings,
              rtl: Icons.settings,
              context: context,
            )),
            label: context.t('navigation.settings'),
          ),
        ], context),
        currentIndex: 0,
        onTap: (index) {},
      ),
    );
  }
}

/// Example of RTL-aware form
class RTLFormExample extends StatelessWidget {
  const RTLFormExample({super.key});

  @override
  Widget build(BuildContext context) {
    return RTLWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.t('auth.signUp')),
          leading: IconButton(
            icon: Icon(RTLUtils.arrowIcon(context)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            child: Column(
              crossAxisAlignment: RTLUtils.startCrossAxisAlignment(context),
              children: [
                TextFormField(
                  decoration: InputDecoration(
                    labelText: context.t('auth.name'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(RTLUtils.startAlignment(context) == Alignment.centerLeft ? 8 : 0),
                        topRight: Radius.circular(RTLUtils.startAlignment(context) == Alignment.centerRight ? 8 : 0),
                        bottomLeft: Radius.circular(RTLUtils.startAlignment(context) == Alignment.centerLeft ? 0 : 8),
                        bottomRight: Radius.circular(RTLUtils.startAlignment(context) == Alignment.centerRight ? 0 : 8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: context.t('auth.email'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(RTLUtils.startAlignment(context) == Alignment.centerLeft ? 8 : 0),
                        topRight: Radius.circular(RTLUtils.startAlignment(context) == Alignment.centerRight ? 8 : 0),
                        bottomLeft: Radius.circular(RTLUtils.startAlignment(context) == Alignment.centerLeft ? 0 : 8),
                        bottomRight: Radius.circular(RTLUtils.startAlignment(context) == Alignment.centerRight ? 0 : 8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: context.t('auth.password'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(RTLUtils.startAlignment(context) == Alignment.centerLeft ? 8 : 0),
                        topRight: Radius.circular(RTLUtils.startAlignment(context) == Alignment.centerRight ? 8 : 0),
                        bottomLeft: Radius.circular(RTLUtils.startAlignment(context) == Alignment.centerLeft ? 0 : 8),
                        bottomRight: Radius.circular(RTLUtils.startAlignment(context) == Alignment.centerRight ? 0 : 8),
                      ),
                    ),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: RTLUtils.startMainAxisAlignment(context),
                  children: RTLUtils.reverseIfRTL([
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        child: Text(context.t('auth.signUp')),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        child: Text(context.t('common.cancel')),
                      ),
                    ),
                  ], context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
