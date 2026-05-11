# Offline Maps Implementation Summary

**Status**: ✅ **Successfully Implemented** (May 2026)  
**Ready for**: Functional testing

---

## What Was Built

A complete native offline map tile downloading system for Pneumage using Mapbox TileStore API. Users can:

1. **Download regions** - Cache satellite imagery for specific areas
2. **Manage storage** - View, delete individual regions or clear all
3. **Work offline** - Maps render from cached tiles without connectivity

## The Challenge

We needed native Mapbox offline functionality, but hit a critical blocker:

**Dependency Conflict**: The app uses `mapbox_maps_flutter` for map display, which internally bundles Mapbox SDK. When we tried to add Mapbox SDK directly to the app for offline APIs, Android Gradle encountered "duplicate class" errors (hundreds of them).

Even with matching versions, the build system cannot handle the same SDK classes in multiple dependency scopes.

## The Solution

**Separate Flutter Plugin Architecture**

Created `pneumage_offline_maps` as an isolated Flutter plugin with its own Gradle configuration:

```
pneumage-app/ (monorepo root)
├── lib/, android/, ios/ ... (main app code)
├── pubspec.yaml (depends on local plugin)
└── plugins/
    └── pneumage_offline_maps/
        ├── android/ (Mapbox SDK dependency)
        ├── lib/ (Dart API)
        └── Gradle scope isolated from main app
```

**Why This Works**: The plugin's dependencies never enter the main app's dependency resolution scope. They're compiled separately and bundled as part of the plugin, avoiding all conflicts.

**Monorepo Structure**: Both main app and plugin live in one repository for easier management and atomic commits.

## Implementation Details

### Plugin Structure

**Dart API** (`pneumage_offline_maps/lib/pneumage_offline_maps.dart`):
```dart
// Clean, type-safe API
await PneumageOfflineMaps.downloadRegion(
  north: 37.8, south: 37.7,
  east: -122.3, west: -122.5,
  minZoom: 10, maxZoom: 16,
  regionId: 'my_study_area',
);
```

**Native Implementation** (Android Kotlin):
- Uses Mapbox `OfflineManager` + `TileStore`
- Downloads actual tiles (not simulation)
- Persistent storage across app restarts
- Proper error handling and propagation

### Main App Integration

**OfflineMapService** updated to use plugin:
```dart
// Before: Simulation
// After: Real downloads via plugin
import 'package:pneumage_offline_maps/pneumage_offline_maps.dart';

final result = await PneumageOfflineMaps.downloadRegion(...);
```

**No platform channels in main app** - MainActivity is clean, no native code needed.

## Key Technical Discoveries

### 1. SDK Variant Matters

Mapbox provides multiple build variants:
- `com.mapbox.maps:android:11.23.0` - Standard
- `com.mapbox.maps:android-ndk27:11.23.0` - NDK 27

**Critical**: These are NOT interchangeable. Using mismatched variants causes conflicts even at the same version.

**Solution**: Plugin uses `android-ndk27:11.23.0` to match `mapbox_maps_flutter`.

### 2. Correct Import Paths

Documentation gaps made finding the right classes difficult:

**Correct paths** (discovered through research):
```kotlin
// Core offline classes
import com.mapbox.maps.OfflineManager
import com.mapbox.maps.TilesetDescriptorOptions

// Supporting classes
import com.mapbox.common.TileStore
import com.mapbox.common.TileRegionLoadOptions
import com.mapbox.common.NetworkRestriction
// ... etc
```

**Wrong paths** (don't exist):
```kotlin
import com.mapbox.maps.offline.OfflineManager  // ❌
import com.mapbox.maps.StyleURI  // ❌ iOS only
```

### 3. Authentication Requirements

**Public tokens fail** with 403 Forbidden errors.

**Required**: Secret token with `OFFLINE:READ` scope:
```properties
# gradle.properties
MAPBOX_DOWNLOADS_TOKEN=sk.ey...  # Not pk.*
```

### 4. Style Optimization for Offline Use

**Style Choice**: Uses `mapbox://styles/mapbox/light-v11` instead of `standard`.

**Benefits**:
- **Minimal download size** - Fewer resources (fonts, icons, styling)
- **Faster downloads** - Less data to transfer
- **Storage efficient** - Important for caching large regions
- **Still functional** - All essential map features present

Alternative styles (not recommended for offline):
- `streets-v12` - More detailed, larger downloads
- `standard` - Full-featured, significantly larger

## Repository Structure (Monorepo)

```
pneumage-app/
├── lib/                    # Main app code
├── android/                # Main app Android
├── ios/                    # Main app iOS
├── pubspec.yaml            # path: plugins/pneumage_offline_maps
├── plugins/                # Local plugins
│   └── pneumage_offline_maps/
│       ├── lib/            # Plugin Dart API
│       ├── android/        # Native implementation
│       └── IMPLEMENTATION_NOTES.md
└── OFFLINE_MAPS_IMPLEMENTATION_SUMMARY.md
```

### Key Files
- `pubspec.yaml` - References plugin via `path: plugins/pneumage_offline_maps`
- `lib/services/offline_map_service.dart` - Uses plugin API
- `plugins/pneumage_offline_maps/android/.../PneumageOfflineMapsPlugin.kt` - Native implementation
- `android/app/MainActivity.kt` - Clean (no native code needed)

## Current Status

### ✅ Complete

1. Plugin compiles successfully
2. Main app integrates without errors  
3. Build system resolves dependencies correctly
4. Dart API fully implemented
5. Native Android implementation complete
6. Documentation comprehensive

### ⏳ Ready for Testing

**Next step**: Deploy to device and test actual tile downloads

**Test scenarios**:
1. Download a small region (e.g., 1km² at zoom 10-14)
2. Verify tiles are cached (check storage)
3. Enable airplane mode
4. Confirm map renders from cache
5. Test delete/clear operations

### ⚠️ Known Limitations

1. **Progress Tracking**: Currently simulated in Dart
   - TODO: Implement EventChannel for real-time native progress
   
2. **iOS**: Not implemented yet (Android only)

3. **clearAllRegions()**: Simplified implementation
   - May need refinement for complete region enumeration

## Documentation

Complete technical documentation available in:

1. **Plugin README** - `pneumage_offline_maps/README.md`
   - Feature overview
   - Why this architecture
   - Quick start guide

2. **Integration Guide** - `pneumage_offline_maps/INTEGRATION_GUIDE.md`
   - API reference
   - Usage examples
   - Troubleshooting

3. **Implementation Notes** - `pneumage_offline_maps/IMPLEMENTATION_NOTES.md`
   - Full journey documentation
   - All challenges and solutions
   - Key technical discoveries
   - Build verification timeline

4. **Main App Requirements** - `pneumage-app/REQUIREMENTS.md`
   - Offline maps feature spec (Phase 1A/1B/1C)
   - Integration status
   - Future enhancements

## Build Verification

**Plugin standalone**:
```bash
cd pneumage_offline_maps/example
flutter build apk --debug
# ✓ Built in 1.7s
```

**Main app with plugin**:
```bash
cd pneumage-app
flutter build apk --debug
# ✓ Built in 23.1s
```

## Timeline

- **Initial Attempt**: Direct integration → Failed (duplicate classes)
- **Analysis**: Root cause identified (dependency conflict)
- **Design**: Plugin architecture planned
- **Implementation**: Plugin scaffolded and coded
- **SDK Research**: Correct imports/variants discovered
- **Integration**: Main app updated to use plugin
- **Result**: ✅ Successful build
- **Documentation**: Comprehensive docs created
- **Next**: Functional testing

## Lessons Learned

1. **Plugin isolation solves "impossible" conflicts** - When dependencies clash, a separate plugin provides complete isolation

2. **SDK variants matter** - Build variants are distinct artifacts, not just different builds

3. **Documentation has gaps** - Even major SDKs lack clear import paths and platform differences

4. **Auth scopes matter for build** - Maven repos can require specific token scopes

## Next Steps

### Immediate
1. Deploy app to physical device
2. Test actual tile downloads
3. Verify offline map rendering
4. Test management operations

### Short Term
1. Implement real-time progress (EventChannel)
2. Fix clearAllRegions() iteration
3. Enhance error handling

### Medium Term  
1. iOS implementation
2. Background downloads
3. Storage quota management
4. Production-ready polish

---

**For detailed technical information, see**:
- [IMPLEMENTATION_NOTES.md](plugins/pneumage_offline_maps/IMPLEMENTATION_NOTES.md)
- [INTEGRATION_GUIDE.md](plugins/pneumage_offline_maps/INTEGRATION_GUIDE.md)
- [Plugin README.md](plugins/pneumage_offline_maps/README.md)

**Last Updated**: May 10, 2026  
**By**: Development team
