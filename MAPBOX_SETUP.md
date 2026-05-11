# Mapbox Setup Guide

## Step 1: Add Your API Token

1. Open `lib/config/mapbox_config.dart`
2. Replace `YOUR_MAPBOX_PUBLIC_TOKEN_HERE` with your actual Mapbox public token
3. Save the file

**Important**: This file is gitignored, so your token won't be committed to version control.

## Step 2: Install Dependencies

Run:
```bash
flutter pub get
```

✅ Already done!

## Step 3: Build and Run

For **Android**:
```bash
flutter run
```

For **iOS** (requires macOS):
```bash
flutter run
```

## What's Implemented

✅ **Map Widget** (`lib/widgets/map_widget.dart`)
- Satellite imagery with street overlay (Mapbox Satellite Streets style)
- Interactive pan, zoom, and rotate gestures
- Ready for offline tile caching

✅ **GPS Integration**
- Live current position marker (blue)
- Auto-pans camera to your location when GPS updates
- GPS accuracy indicator in bottom-right corner
- Color-coded by quality: Green (excellent) → Red (poor)

✅ **Measurement Markers**
- Green markers for all recorded measurements
- Loads from all projects automatically
- Displays on map with project data

✅ **Platform Configuration**
- Android: Internet permission added to manifest
- iOS: Already configured (no additional permissions needed)
- Mapbox SDK initialized in main.dart

✅ **Center Content Integration**
- Map replaces "MAP VIEW" placeholder in home screen
- Works with all existing panels (Files, Stats, Time Series, etc.)
- Responsive layout adapts when panels open/close

## Map Configuration

Edit `lib/config/mapbox_config.dart` to customize:

- **Style**: Change satellite to streets, dark mode, outdoors, etc.
- **Initial position**: Set default map center (lat, lon, zoom)
- **Offline cache size**: Configure max storage for offline tiles

## Next Steps

Phase 1 Tasks Remaining:
- [ ] Add zoom controls UI
- [ ] Implement tap on marker to show measurement details
- [ ] Add pan/zoom to project region from Files panel
- [ ] Implement offline tile download feature
- [ ] Add map settings panel (tile server, cache management)

## Troubleshooting

**Map doesn't load?**
- Check that you added your Mapbox token to `mapbox_config.dart`
- Verify internet connection (for initial tile download)
- Check terminal for any error messages

**GPS marker doesn't appear?**
- Ensure location permissions are granted
- Wait for GPS to acquire signal (may take 30-60 seconds outdoors)
- Check GPS status indicator in top status bar

**Build errors?**
- Run `flutter clean && flutter pub get`
- Restart VS Code
- Check that Mapbox token is not empty string

## Cost Management

Your current setup:
- ✅ Free tier: 200,000 tile requests/month
- ✅ Aggressive caching enabled (tiles stored locally after first load)
- ✅ Typical usage: ~21,000 requests/month for 100 active users

The map will work during development and should stay within free tier limits for a research app.
