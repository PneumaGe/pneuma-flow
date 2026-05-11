# Mapbox Configuration Setup Guide

This project uses Mapbox for map functionality. To build and run the app, you'll need to configure your Mapbox access tokens.

## Why This Setup?

We don't commit Mapbox tokens to version control for security. Instead, you configure them locally on your development machine.

## Quick Setup (For Local Development)

### 1. Get Your Mapbox Tokens

1. Go to [https://account.mapbox.com/access-tokens/](https://account.mapbox.com/access-tokens/)
2. You'll need two tokens:
   - **Public token** (starts with `pk.`) - for map display in the app
   - **Secret/Downloads token** (starts with `sk.`) - for downloading Mapbox SDK dependencies

### 2. Configure Flutter (Dart) Side

**Option A: Using local config file (easiest for development)**

```bash
# Copy the example file
cp lib/config/mapbox_config_local.dart.example lib/config/mapbox_config_local.dart

# Edit the file and add your public token
# Replace 'pk.your_public_token_here' with your actual token
```

**Option B: Using --dart-define (for CI/CD or production builds)**

```bash
flutter run --dart-define=MAPBOX_ACCESS_TOKEN=pk.your_actual_token_here
flutter build apk --dart-define=MAPBOX_ACCESS_TOKEN=pk.your_actual_token_here
```

### 3. Configure Android (Gradle) Side

```bash
# Copy the example file
cp android/local.properties.example android/local.properties

# Edit android/local.properties and add:
# 1. Your Android SDK path (if not already there)
# 2. Your Mapbox downloads token (the sk.* token)
```

Your `android/local.properties` should look like:
```properties
sdk.dir=/path/to/your/Android/sdk
MAPBOX_DOWNLOADS_TOKEN=sk.your_actual_secret_token_here
```

### 4. For Plugin Example App (Optional)

If you're working on the offline maps plugin:

```bash
cp plugins/pneumage_offline_maps/example/android/local.properties.example plugins/pneumage_offline_maps/example/android/local.properties

# Edit and add your tokens
```

## How It Works at Build Time

### Flutter/Dart Code

1. **Development**: The app checks for `MapboxConfigLocal.accessToken` from your local (gitignored) file
2. **Production**: Use `--dart-define=MAPBOX_ACCESS_TOKEN=pk.xxx` which overrides the local config

### Android Gradle

1. Gradle reads `MAPBOX_DOWNLOADS_TOKEN` from `android/local.properties`
2. This token is used to authenticate with Mapbox Maven repository
3. Allows downloading Mapbox SDK dependencies during build

## Verify Your Setup

Run the app:
```bash
flutter run
```

If you see errors about missing Mapbox tokens:
- Check that `lib/config/mapbox_config_local.dart` exists (or use --dart-define)
- Check that `android/local.properties` has `MAPBOX_DOWNLOADS_TOKEN`
- Verify your tokens are valid at [Mapbox Account](https://account.mapbox.com/)

## CI/CD Setup

For continuous integration or production builds:

1. Store tokens as environment variables or secrets in your CI system
2. Use `--dart-define` to pass the public token:
   ```bash
   flutter build apk --dart-define=MAPBOX_ACCESS_TOKEN=$MAPBOX_PUBLIC_TOKEN
   ```
3. Create `android/local.properties` in CI with the downloads token:
   ```bash
   echo "MAPBOX_DOWNLOADS_TOKEN=$MAPBOX_SECRET_TOKEN" > android/local.properties
   ```

## Troubleshooting

**Error: "Failed to authenticate with Mapbox Maven"**
- Check `android/local.properties` has valid `MAPBOX_DOWNLOADS_TOKEN`
- Verify the token starts with `sk.` (it's the secret token, not public)

**Error: "Mapbox token is empty"**
- Either create `lib/config/mapbox_config_local.dart` from the example
- OR run with `flutter run --dart-define=MAPBOX_ACCESS_TOKEN=pk.your_token`

**Token still appears in git status**
- Make sure you created the files from `.example` templates
- Run `git status` - you should NOT see `mapbox_config_local.dart` or `local.properties`
- These files are in `.gitignore`

## Security Notes

- ✅ `.example` template files are safe to commit (contain no real tokens)
- ✅ `mapbox_config_local.dart` is gitignored - never commits your tokens  
- ✅ `android/local.properties` is gitignored - already standard for Android
- ⚠️ Public tokens (pk.*) are meant to be in your app - that's okay
- 🔒 Secret tokens (sk.*) should NEVER be committed or embedded in code

## Need Help?

- [Mapbox Access Tokens Documentation](https://docs.mapbox.com/help/how-mapbox-works/access-tokens/)
- [Flutter --dart-define Guide](https://docs.flutter.dev/deployment/flavors)
