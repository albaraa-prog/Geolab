# Geolab Localization and Theme System

This document describes the comprehensive localization and theme system implemented in the Geolab app.

## Overview

The app now includes a complete localization and theme system that supports:
- Multiple languages (English, Arabic, French, Spanish, German, Chinese, Japanese, Korean, Portuguese, Russian)
- Light and dark themes with Material 3 design
- RTL (Right-to-Left) language support
- Dynamic theme switching
- Persistent user preferences
- Easy-to-use utility classes

## Architecture

### Core Components

1. **Theme System**
   - `AppTheme` - Theme definitions and configurations
   - `ThemeService` - Theme state management and persistence
   - `AppThemeUtils` - Utility class for easy theme access

2. **Localization System**
   - `LocalizationService` - Translation management and locale switching
   - `LocalizationConfig` - Supported locales and configuration
   - `AppLocalizations` - Utility class for easy translation access

3. **Settings Integration**
   - Enhanced settings page with theme and language controls
   - Real-time theme switching
   - Language selection with flags and native names

## Usage

### Basic Theme Usage

```dart
import 'package:geolab/utils/app_theme.dart';

// Check if dark mode is enabled
bool isDark = AppThemeUtils.isDarkMode;

// Get current theme
ThemeData theme = AppThemeUtils.currentTheme;

// Toggle theme
await AppThemeUtils.toggleTheme();

// Set specific theme
await AppThemeUtils.setTheme(true); // true for dark, false for light
```

### Basic Localization Usage

```dart
import 'package:geolab/utils/app_localizations.dart';

// Get translation
String title = AppLocalizations.t('app.title');

// Get translation with parameters
String message = AppLocalizations.tWithParams('welcome.message', {'name': 'John'});

// Get plural translation
String count = AppLocalizations.tPlural('items.count', 5);

// Check current locale
Locale locale = AppLocalizations.currentLocale;
bool isRTL = AppLocalizations.isRTL;
```

### Using with BuildContext Extensions

```dart
// Theme extensions
bool isDark = context.isDarkMode;
Color primaryColor = context.primaryColor;
Color backgroundColor = context.backgroundColor;

// Localization extensions
String title = context.t('app.title');
String message = context.tWithParams('welcome.message', {'name': 'John'});
bool isRTL = context.isRTL;
```

### In Widgets

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      color: context.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(AppThemeConstants.spacingM),
        child: Column(
          children: [
            Text(
              context.t('settings.profile.title'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              context.t('settings.profile.subtitle'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.textColor.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

## Adding New Languages

### 1. Create Translation File

Create a new JSON file in `assets/translations/` with the language code (e.g., `fr.json` for French):

```json
{
  "app": {
    "title": "Geolab",
    "settings": "Paramètres"
  },
  "settings": {
    "profile": {
      "title": "Profil Utilisateur",
      "subtitle": "Gérez vos paramètres de compte et préférences"
    }
  }
}
```

### 2. Update LocalizationConfig

Add the new locale to `LocalizationConfig.supportedLocales`:

```dart
static const List<Locale> supportedLocales = [
  Locale('en', 'US'),
  Locale('ar', 'SA'),
  Locale('fr', 'FR'), // New language
  // ... other locales
];
```

### 3. Add Display Name and Flag

Update the `getLocaleDisplayName` and `getLocaleFlag` methods:

```dart
static String getLocaleDisplayName(Locale locale) {
  switch (locale.languageCode) {
    case 'en':
      return 'English';
    case 'ar':
      return 'العربية';
    case 'fr':
      return 'Français'; // New language
    // ... other cases
  }
}

static String getLocaleFlag(Locale locale) {
  switch (locale.languageCode) {
    case 'en':
      return '🇺🇸';
    case 'ar':
      return '🇸🇦';
    case 'fr':
      return '🇫🇷'; // New language
    // ... other cases
  }
}
```

## Adding New Theme Colors

### 1. Update AppTheme

Add new colors to the `AppTheme` class:

```dart
class AppTheme {
  // New custom colors
  static const Color customColor = Color(0xFF9C27B0);
  static const Color customLightColor = Color(0xFFBA68C8);
  static const Color customDarkColor = Color(0xFF7B1FA2);
  
  // ... existing colors
}
```

### 2. Update ThemeService

Add getters for the new colors:

```dart
class ThemeService extends ChangeNotifier {
  // ... existing code
  
  Color get customColor => _isDarkMode ? AppTheme.customLightColor : AppTheme.customColor;
}
```

### 3. Update AppThemeUtils

Add utility methods:

```dart
class AppThemeUtils {
  // ... existing code
  
  static Color get customColor => _service.customColor;
}
```

## Best Practices

### 1. Use Translation Keys

Always use translation keys instead of hardcoded strings:

```dart
// ❌ Bad
Text('Settings')

// ✅ Good
Text(context.t('app.settings'))
```

### 2. Use Theme-Aware Colors

Use theme-aware colors instead of hardcoded colors:

```dart
// ❌ Bad
Color(0xFF1976D2)

// ✅ Good
context.primaryColor
// or
ThemeAwareColors.getPrimaryColor(context)
```

### 3. Use Constants for Spacing and Sizing

Use the predefined constants for consistent spacing:

```dart
// ❌ Bad
const EdgeInsets.all(16)

// ✅ Good
const EdgeInsets.all(AppThemeConstants.spacingM)
```

### 4. Handle RTL Languages

Always consider RTL languages when designing layouts:

```dart
// Use Directionality or check isRTL
if (context.isRTL) {
  // Handle RTL layout
}

// Or use Directionality widget
Directionality(
  textDirection: context.textDirection,
  child: Row(
    children: [
      Icon(Icons.arrow_back),
      Text(context.t('navigation.back')),
    ],
  ),
)
```

## Testing

### Theme Testing

```dart
testWidgets('Theme switching works', (WidgetTester tester) async {
  await tester.pumpWidget(MyApp());
  
  // Check initial theme
  expect(Theme.of(tester.element(find.byType(MaterialApp))).brightness, 
         equals(Brightness.light));
  
  // Toggle theme
  await tester.tap(find.byType(Switch));
  await tester.pump();
  
  // Check theme changed
  expect(Theme.of(tester.element(find.byType(MaterialApp))).brightness, 
         equals(Brightness.dark));
});
```

### Localization Testing

```dart
testWidgets('Language switching works', (WidgetTester tester) async {
  await tester.pumpWidget(MyApp());
  
  // Check initial language
  expect(find.text('Settings'), findsOneWidget);
  
  // Change language
  await tester.tap(find.byType(DropdownButton<String>));
  await tester.pump();
  await tester.tap(find.text('العربية'));
  await tester.pump();
  
  // Check language changed
  expect(find.text('الإعدادات'), findsOneWidget);
});
```

## Troubleshooting

### Common Issues

1. **Translations not loading**
   - Check if the translation file exists in `assets/translations/`
   - Verify the file is included in `pubspec.yaml`
   - Check for JSON syntax errors

2. **Theme not switching**
   - Ensure `ThemeService` is properly initialized
   - Check if the theme change is being persisted
   - Verify the MaterialApp is using the correct theme mode

3. **RTL layout issues**
   - Use `Directionality` widget for complex layouts
   - Test with Arabic or Hebrew locales
   - Check if all widgets support RTL

### Debug Mode

Enable debug logging by checking the console output:

```dart
// In LocalizationService
print('Translations loaded successfully for ${_currentLocale.languageCode}');

// In ThemeService
print('Theme changed to: ${_isDarkMode ? 'dark' : 'light'}');
```

## Dependencies

The system requires these packages:

```yaml
dependencies:
  flutter_localizations:
    sdk: flutter
  provider: ^6.1.1
  shared_preferences: ^2.2.2
  intl: ^0.19.0
```

## Future Enhancements

- [ ] Dynamic theme color customization
- [ ] Font family selection
- [ ] Custom theme presets
- [ ] Language-specific formatting (dates, numbers, currency)
- [ ] Accessibility theme support
- [ ] Theme animation transitions
- [ ] Export/import theme preferences
- [ ] Cloud theme synchronization

## Contributing

When adding new features:

1. Add corresponding translation keys
2. Update all language files
3. Consider RTL language support
4. Test with different themes
5. Update this documentation

## Support

For issues or questions about the localization and theme system, please refer to:
- Flutter localization documentation
- Material 3 design guidelines
- RTL language support best practices
