# Plugin Integration Guide

## Current Status

✅ **Plugin Structure Complete**: Dart API, Android native code, and example app all implemented  
⚠️ **Build Blocked**: Requires Mapbox secret downloads token (sk.*) for Maven repository access  
📝 **Ready for Integration**: Once token issue is resolved, plugin can be integrated into main app

## The Authentication Issue

### Problem

Mapbox's Maven repository (`https://api.mapbox.com/downloads/v2/releases/maven`) requires authentication to download SDK artifacts. The current token in `gradle.properties` is a **public token** (pk.*), which only works for:
- Map display (runtime)
- Mapbox APIs

It does **NOT** work for:
- Maven artifact downloads (compile-time)
- SDK dependency resolution

### Error Symptoms

```
Could not GET 'https://api.mapbox.com/downloads/v2/releases/maven/...'
Received status code 403 from server: Forbidden
```

### Solution Options

#### Option 1: Get Secret Downloads Token (Recommended)

1. Go to https://account.mapbox.com/access-tokens/
2. Create a new **Secret Token** with `DOWNLOADS:READ` scope
3. Token will start with `sk.` instead of `pk.`
4. Add to `android/gradle.properties`:
   ```properties
   MAPBOX_DOWNLOADS_TOKEN=sk.your_secret_token_here
   ```

#### Option 2: Use Local Maven Repository

If you have the Mapbox SDK .aar files locally:
```gradle
repositories {
    maven { url = uri("file:///path/to/local/maven/repo") }
}
```

#### Option 3: Defer Native Implementation

Continue using the simulation in `/lib/services/offline_map_service.dart` until token is obtained.

## Plugin Architecture

### Directory Structure

```
pneumage_offline_maps/
├── lib/
│   └── pneumage_offline_maps.dart       # Public Dart API
├── android/
│   ├── build.gradle                      # Gradle config with Mapbox SDK
│   └── src/main/kotlin/.../
│       └── PneumageOfflineMapsPlugin.kt  # Native TileStore implementation
├── example/
│   └── lib/main.dart                     # Test app demonstrating usage
├── pubspec.yaml                          # Plugin metadata
└── README.md                             # Usage documentation
```

### Key Implementation Files

#### 1. Dart API (`lib/pneumage_offline_maps.dart`)

**Implemented:**
- `PneumageOfflineMaps.downloadRegion()` - Download tiles for bounding box
- `PneumageOfflineMaps.deleteRegion()` - Remove cached region
- `PneumageOfflineMaps.clearAllRegions()` - Clear all tiles
- `PneumageOfflineMaps.getProgressStream()` - Real-time progress updates
- Data classes: `OfflineRegionResult`, `DownloadProgress`, exception types

**Status:** ✅ Complete, no Dart errors

#### 2. Android Native (`android/src/main/kotlin/.../PneumageOfflineMapsPlugin.kt`)

**Implemented:**
- Mapbox TileStore initialization
- MethodChannel handlers for download/delete/clear operations
- TileRegionLoadOptions configuration with bounding box polygon
- Progress tracking via TileRegionLoadProgressCallback
- EventChannel integration for streaming progress updates

**Dependencies Required:**
```gradle
implementation 'com.mapbox.maps:android:11.2.0'
implementation 'com.mapbox.common:common:24.2.0'
```

**Status:** ✅ Code complete, ⚠️ Cannot compile without downloads token

#### 3. Android Build Config (`android/build.gradle`)

**Configured:**
```gradle
allprojects {
    repositories {
        google()
        mavenCentral()
        maven {
            url "https://api.mapbox.com/downloads/v2/releases/maven"
            credentials {
                username = "mapbox"
                password = project.findProperty("MAPBOX_DOWNLOADS_TOKEN") ?: ""
            }
            authentication {
                basic(BasicAuthentication)
            }
        }
    }
}

android {
    compileSdk = 36
    defaultConfig {
        minSdk = 24  // Required for Mapbox TileStore
    }
    
    dependencies {
        implementation 'com.mapbox.maps:android:11.2.0'
        implementation 'com.mapbox.common:common:24.2.0'
    }
}
```

**Status:** ✅ Syntax correct, ⚠️ Maven authentication fails

## Integration Steps (Once Token Obtained)

### Step 1: Verify Plugin Build

```bash
cd pneumage_offline_maps
export MAPBOX_DOWNLOADS_TOKEN=sk.your_secret_token_here  # Linux/macOS
flutter pub get

cd example
flutter build apk --debug
```

Expected: Clean build, no errors

### Step 2: Test Plugin in Isolation

```bash
cd pneumage_offline_maps/example
flutter run
```

Test:
1. Tap "Download Sample Region" - should download SF downtown
2. Watch progress bar update in real-time
3. Check logs for actual tile counts and sizes
4. Tap "Delete Sample Region" - should clear tiles
5. Verify storage freed

### Step 3: Add Plugin to Main App

In `pneumage_app/pubspec.yaml`:
```yaml
dependencies:
  pneumage_offline_maps:
    path: ../pneumage_offline_maps
```

Run:
```bash
cd pneumage-app
flutter pub get
```

### Step 4: Update OfflineMapService

Replace simulation in `/lib/services/offline_map_service.dart`:

```dart
import 'package:pneumage_offline_maps/pneumage_offline_maps.dart';

Future<void> _downloadTiles() async {
  try {
    // Set up progress listener
    final progressStream = PneumageOfflineMaps.getProgressStream(_region.id);
    progressStream.listen(
      (progress) {
        _region.progress = progress.progress;
        _region.estimatedSize = progress.totalBytes;
        notifyListeners();
        
        if ((progress.progress * 100).toInt() % 10 == 0) {
          _showToast('${progress.percentageString} complete');
        }
      },
    );

    // Start download
    final result = await PneumageOfflineMaps.downloadRegion(
      north: _region.northLat,
      south: _region.southLat,
      east: _region.eastLng,
      west: _region.westLng,
      minZoom: _region.minZoom,
      maxZoom: _region.maxZoom,
      regionId: _region.id,
    );

    // Update with actual values
    _region.status = OfflineRegionStatus.downloaded;
    _region.actualSize = result.sizeBytes;
    _region.tileCount = result.tileCount;
    _region.progress = 1.0;
    
    await _persistRegion(_region);
    _showToast('Downloaded ${result.tileCount} tiles');
    
  } on PneumageOfflineMapsException catch (e) {
    _region.status = OfflineRegionStatus.failed;
    _showToast('Download failed: ${e.message}');
  }
}
```

### Step 5: Update Delete Operations

```dart
Future<void> deleteRegion(String regionId) async {
  await PneumageOfflineMaps.deleteRegion(regionId);
  // ... existing UI update code
}

Future<void> clearAllRegions() async {
  await PneumageOfflineMaps.clearAllRegions();
  // ... existing UI update code
}
```

### Step 6: Test in Main App

```bash
cd pneumage-app
flutter run
```

Test scenarios:
1. Open Map screen, tap "Cache this view"
2. Navigate to Settings > OFFLINE tab
3. Verify real download progress (not simulation)
4. Enable airplane mode, verify map tiles load
5. Test delete operations
6. Test clearing all regions

## Technical Verification Checklist

Once plugin builds successfully:

- [ ] Plugin compiles without errors (`flutter build apk`)
- [ ] Example app runs and downloads tiles
- [ ] Progress updates stream in real-time
- [ ] Actual tile counts match expectations
- [ ] Storage calculations accurate
- [ ] Delete operations free storage
- [ ] Main app integrates successfully
- [ ] No dependency conflicts with `mapbox_maps_flutter`
- [ ] Offline maps work in airplane mode
- [ ] Multiple regions can be downloaded
- [ ] Storage limits enforced correctly

## Why This Approach Works

The plugin architecture solves the dependency conflict:

| Approach | Problem | Resolution |
|----------|---------|------------|
| **Direct app-level SDK** | Conflicts with `mapbox_maps_flutter`'s internal SDK | ❌ Gradle duplicate class errors |
| **Plugin architecture** | Isolated dependency tree | ✅ No conflicts - plugin has own Gradle scope |

## Next Steps Summary

1. **Immediate**: Obtain Mapbox secret downloads token (sk.*)
2. **Verify**: Build and test plugin in isolation
3. **Integrate**: Update `offline_map_service.dart` to use plugin
4. **Validate**: Test end-to-end offline functionality
5. **Document**: Update REQUIREMENTS.md with completion status

## Development Notes

- **Mapbox SDK Version**: 11.2.0 (verified compatible with TileStore API)
- **minSdkVersion**: 24 (Android 7.0+) - required by Mapbox
- **compileSdkVersion**: 36 (latest)
- **Platform Channels**: MethodChannel + EventChannel for bidirectional communication
- **Storage**: Managed by TileStore, location: `/data/data/com.example.pneumage_app/files/`

## Resources

- Mapbox TileStore API: https://docs.mapbox.com/android/maps/guides/offline/
- Flutter Plugin Development: https://docs.flutter.dev/development/packages-and-plugins/developing-packages
- Mapbox Downloads API: https://docs.mapbox.com/android/downloads-api/
- Token Management: https://account.mapbox.com/access-tokens/
