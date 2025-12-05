# GeoLab App Setup Guide

## Prerequisites

1. Flutter SDK installed (>=3.2.3)
2. Supabase account and project
3. Android Studio / VS Code with Flutter extensions

## Environment Configuration

### 1. Install Dependencies

```bash
cd geolab
flutter pub get
```

### 2. Configure Supabase

1. Create a `.env` file in the `geolab` directory (root of the Flutter project)
2. Add your Supabase credentials:

```env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

**How to get your Supabase credentials:**
1. Go to [Supabase Dashboard](https://app.supabase.com)
2. Select your project
3. Go to **Settings** → **API**
4. Copy:
   - **Project URL** → `SUPABASE_URL`
   - **anon/public key** → `SUPABASE_ANON_KEY`

### 3. Verify Configuration

The app will automatically:
- Load environment variables from `.env` file on startup
- Initialize Supabase connection
- Display error messages if configuration is missing

## Running the App

```bash
# For Android
flutter run

# For iOS (Mac only)
flutter run -d ios

# For Web
flutter run -d chrome
```

## Troubleshooting

### Supabase Not Connecting

1. **Check .env file exists**: Make sure `.env` is in the `geolab` directory
2. **Verify credentials**: Double-check your `SUPABASE_URL` and `SUPABASE_ANON_KEY`
3. **Check console logs**: Look for initialization errors in the console
4. **Network issues**: Ensure your device/emulator has internet access

### Environment Variables Not Loading

- Make sure `.env` file is in the correct location (`geolab/.env`)
- Verify the file format (no spaces around `=`)
- Restart the app after creating/modifying `.env`

### Build Errors

```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

## Security Notes

⚠️ **Important**: 
- The `.env` file is in `.gitignore` and should NOT be committed to version control
- Never share your Supabase keys publicly
- Use `.env.example` as a template for other developers

## Project Structure

```
geolab/
├── .env                 # Your Supabase credentials (not in git)
├── .env.example         # Template file (safe to commit)
├── lib/
│   ├── config/
│   │   └── app_config.dart  # Reads from .env
│   ├── Service/
│   │   └── supabase_service.dart  # Supabase client
│   └── main.dart        # Initializes Supabase on startup
└── pubspec.yaml         # Dependencies including flutter_dotenv
```

