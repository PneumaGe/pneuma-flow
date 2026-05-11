# Implementation Notes: Pneumage Offline Maps Plugin

**Date**: May 2026  
**Status**: ✅ Successfully implemented and integrated

This document captures the complete journey of implementing native Mapbox offline map functionality for the Pneumage app, including all challenges encountered and solutions discovered.

---

## Executive Summary

**Goal**: Enable offline map tile downloads in Pneumage app using Mapbox SDK.

**Challenge**: Dependency conflicts between app-level Mapbox SDK usage and `mapbox_maps_flutter` plugin's internal SDK.

**Solution**: Created separate Flutter plugin (`pneumage_offline_maps`) with isolated Gradle dependency tree.

**Outcome**: ✅ Successful - App compiles, plugin integrates cleanly, native offline functionality ready for testing.

---

## The Problem: Dependency Conflicts

### Initial Approach (Failed)

We first attempted to implement offline functionality directly in the main app by:

1. Adding Mapbox SDK dependency to `android/app/build.gradle.kts`:
   ```kotlin
   implementation("com.mapbox.maps:android:11.23.0")
   ```

2. Implementing native code in `MainActivity.kt` with MethodChannel

3. Using Mapbox classes: `TileStore`, `OfflineManager`, `TilesetDescriptorOptions`

### The Result

**BUILD FAILED** with hundreds of duplicate class errors:

```
Duplicate class com.mapbox.maps.* found in modules:
  - android-11.23.0.aar (com.mapbox.maps:android:11.23.0)
  - android-ndk27-11.23.0.aar (com.mapbox.maps:android-ndk27:11.23.0)
```

### Root Cause Analysis

The main app uses `mapbox_maps_flutter: ^2.23.0` for map display, which internally bundles:
```
com.mapbox.maps:android-ndk27:11.23.0
```

When we add explicit Mapbox SDK dependency at the app level:
- App declares: `com.mapbox.maps:android:11.23.0` (or `android-ndk27:11.23.0`)
- Plugin internally has: `com.mapbox.maps:android-ndk27:11.23.0`  
- **Gradle cannot resolve same classes in multiple scopes**
- Even with version matching, Android build system sees duplicate classes
- Result: Build failure

### Why Version Matching Didn't Help

Even when we tried to match exact versions:
```kotlin
// App level
implementation("com.mapbox.maps:android-ndk27:11.23.0")

// Plugin internal (from mapbox_maps_flutter)  
com.mapbox.maps:android-ndk27:11.23.0
```

The issue persists because:
1. Both declare the same dependency
2. Gradle sees duplicate class definitions
3. Build system cannot merge or exclude properly
4. The scope overlap is the fundamental problem, not the version

---

## The Solution: Separate Plugin Architecture

### Why It Works

A Flutter plugin maintains **its own isolated Gradle build configuration**:

```
Main App (pneumage-app)
├── android/app/build.gradle.kts
│   ├── No direct Mapbox SDK dependency
│   └── Depends on: mapbox_maps_flutter (internal SDK)
│
Plugin (pneumage_offline_maps)  
├── android/build.gradle
│   ├── implementation 'com.mapbox.maps:android-ndk27:11.23.0'
│   └── Completely isolated from main app's Gradle scope
```

**Key Insight**: The plugin's dependencies never enter the main app's dependency resolution scope. They're compiled separately and bundled as part of the plugin's AAR.

### Implementation Steps

1. **Created Plugin Structure**:
   ```bash
   flutter create --template=plugin --platforms=android pneumage_offline_maps
   ```

2. **Added Mapbox Dependencies** (`android/build.gradle`):
   ```gradle
   repositories {
       maven {
           url "https://api.mapbox.com/downloads/v2/releases/maven"
           credentials {
               username = "mapbox"
               password = MAPBOX_DOWNLOADS_TOKEN
           }
       }
   }
   
   dependencies {
       implementation 'com.mapbox.maps:android-ndk27:11.23.0'
   }
   ```

3. **Implemented Native Code** (`PneumageOfflineMapsPlugin.kt`):
   - Full OfflineManager + TileStore implementation
   - MethodChannel for Dart-Kotlin communication
   - Progress tracking (TODO: EventChannel for real-time updates)

4. **Created Dart API** (`lib/pneumage_offline_maps.dart`):
   - Clean Dart interface wrapping platform channels
   - Type-safe data classes
   - Exception handling

5. **Integrated into Main App**:
   ```yaml
   # pubspec.yaml
   dependencies:
     pneumage_offline_maps:
       path: ../pneumage_offline_maps
   ```

---

## Key Technical Discoveries

### 1. SDK Import Paths

**Challenge**: Mapbox documentation doesn't clearly show import paths for offline classes.

**Initial Attempts** (failed):
```kotlin
import com.mapbox.maps.offline.OfflineManager  // ❌ Package doesn't exist
import com.mapbox.maps.offline.TilesetDescriptorOptions  // ❌ Doesn't exist
```

**Correct Imports** (discovered through research):
```kotlin
// Core offline classes from com.mapbox.maps
import com.mapbox.maps.OfflineManager
import com.mapbox.maps.TilesetDescriptorOptions

// Supporting classes from com.mapbox.common  
import com.mapbox.common.MapboxOptions
import com.mapbox.common.TilesetDescriptor
import com.mapbox.common.TileStore
import com.mapbox.common.TileRegionLoadOptions
import com.mapbox.common.NetworkRestriction
import com.mapbox.common.TileRegionLoadProgressCallback
import com.mapbox.common.TileRegionCallback
import com.mapbox.common.TileRegionsCallback

// Geometry
import com.mapbox.geojson.Point
```

### 2. SDK Variants Matter

**Discovery**: Mapbox provides multiple build variants of each version.

For version 11.23.0:
- `com.mapbox.maps:android:11.23.0` - Standard build
- `com.mapbox.maps:android-ndk27:11.23.0` - NDK 27 build
- `com.mapbox.maps:android-core:11.23.0` - Core module
- etc.

**Critical**: These variants are **NOT interchangeable**. Using the wrong variant causes duplicate class conflicts even with matching version numbers.

**Solution**: Match the exact variant used by `mapbox_maps_flutter`:
```gradle
implementation 'com.mapbox.maps:android-ndk27:11.23.0'  // ✅ Matches flutter plugin
```

### 3. Zoom Levels Type Constraint

**Issue**: `minZoom` and `maxZoom` expect `Byte`, not `Int`.

```kotlin
// From Dart (Int)
val minZoomInt = call.argument<Int>("minZoom")!!
val maxZoomInt = call.argument<Int>("maxZoom")!!

// Convert to Byte for SDK
val minZoom = minZoomInt.toByte()
val maxZoom = maxZoomInt.toByte()

val descriptorOptions = TilesetDescriptorOptions.Builder()
    .minZoom(minZoom)  // Requires Byte
    .maxZoom(maxZoom)  // Requires Byte
    .build()
```

### 4. StyleURI in Android vs iOS

**Discovery**: `StyleURI` constant class only exists in iOS SDK.

Android requires string literal:
```kotlin
// ❌ Android doesn't have this
import com.mapbox.maps.StyleURI
val style = StyleURI.STANDARD

// ✅ Use string directly (using light-v11 for minimal offline downloads)
val styleURI = "mapbox://styles/mapbox/light-v11"
```

**Style Choice for Offline**: The `light-v11` style is specifically chosen to minimize download size and storage requirements:
- Minimal styling (fewer resources)
- Smaller tile sizes
- Faster downloads
- Less device storage consumed

Alternative styles available:
- `mapbox://styles/mapbox/streets-v12` - More detailed streets (larger)
- `mapbox://styles/mapbox/outdoors-v12` - Terrain/hiking features (larger)
- `mapbox://styles/mapbox/standard` - Full-featured (largest, not recommended for offline)

### 5. Callback Types

**Issue**: Mapbox uses different callback types for single vs. multiple regions.

```kotlin
// Single region callback
val callback = TileRegionCallback { expected -> ... }
tileStore.loadTileRegion(id, options, progressCallback, callback)

// Multiple regions callback (different type!)
val callback = TileRegionsCallback { expected -> ... }
tileStore.getAllTileRegions(callback)
```

### 6. Expected/Result Pattern

Mapbox uses a Result-like pattern called `Expected`:

```kotlin
callback { expected ->
    // CRITICAL: Mapbox Expected.fold() uses (onError, onValue) order!
    // This is OPPOSITE of most Kotlin Result types which use (onSuccess, onFailure)
    expected.fold(
        { error ->
            // Error case - got error object (FIRST parameter)
            val message = error.toString()  // No .message property!
        },
        { success ->
            // Success case - got TileRegion or TileRegions (SECOND parameter)
        }
    )
}
```

**IMPORTANT**: 
- Mapbox `Expected.fold()` takes error handler **first**, value handler **second**
- Most Kotlin libraries (Arrow, Result) use the opposite order
- Using wrong order causes successful downloads to be treated as errors!
- Error objects don't have a `.message` property - use `.toString()` instead

**Bug Note**: This was discovered during testing when successful downloads (100% complete) were being reported as failures because the handlers were in wrong order.

---

## Authentication Requirements

### Secret Token Required

**Public tokens fail**:
```
403 Forbidden from https://api.mapbox.com/downloads/v2/releases/maven
```

**Solution**: Use secret token with `OFFLINE:READ` scope:
```properties
# gradle.properties
MAPBOX_DOWNLOADS_TOKEN=sk.ey...  # Secret token, not pk.*
```

### How to Get Secret Token

1. Go to https://account.mapbox.com/access-tokens/
2. Create new token
3. Enable **"OFFLINE:READ"** scope
4. Copy the `sk.*` token (not the `pk.*` public token)
5. Add to `gradle.properties` in both plugin and app

---

## Build Verification Timeline

### Plugin Standalone Build

✅ **Success** with NDK27 variant:
```bash
cd pneumage_offline_maps/example
flutter build apk --debug
# ✓ Built build/app/outputs/flutter-apk/app-debug.apk (1.7s)
```

### Main App Integration Build

❌ **Initial Failure** with standard variant:
```
Duplicate class errors (android:11.23.0 vs android-ndk27:11.23.0)
```

✅ **Success** after switching to NDK27 variant:
```bash
cd pneumage-app
flutter build apk --debug
# ✓ Built build/app/outputs/flutter-apk/app-debug.apk (23.1s)
```

---

## Current Implementation Status

### ✅ Completed

1. **Plugin Architecture**: Fully implemented and compiling
2. **Native Android Code**: Complete with OfflineManager + TileStore  
3. **Dart API**: Clean interface with proper data classes
4. **Main App Integration**: Successfully integrated, compiles without errors
5. **OfflineMapService Updated**: Using plugin APIs instead of simulation
6. **Authentication**: Configured with secret token
7. **Build System**: Resolves dependencies correctly
8. **Documentation**: README, INTEGRATION_GUIDE, and this file

### ⚠️ In Progress

1. **Progress Tracking**: Currently simulated in Dart
   - TODO: Implement EventChannel for real-time native progress
   - Native callbacks exist but not wired to Dart yet

2. **clearAllRegions()**: Simplified implementation
   - Calls `getAllTileRegions()` but iteration needs work
   - `TileRegions` collection type iteration unclear

### ⏳ Not Started

1. **iOS Implementation**: Android only currently
2. **Comprehensive Testing**: Native downloads not tested yet
3. **Error Handling**: Basic implementation, needs refinement
4. **Storage Management**: No quota enforcement yet

---

## File Structure

```
pneumage-app/
├── lib/services/offline_map_service.dart
│   └── Uses: PneumageOfflineMaps plugin API
├── pubspec.yaml
│   └── Depends on: pneumage_offline_maps (local)
└── android/
    ├── app/build.gradle.kts
    │   └── No Mapbox SDK dependency (clean!)
    └── gradle.properties
        └── MAPBOX_DOWNLOADS_TOKEN configured

pneumage_offline_maps/
├── lib/pneumage_offline_maps.dart
│   └── Dart API: downloadRegion, deleteRegion, clearAllRegions
├── android/
│   ├── build.gradle
│   │   └── implementation 'com.mapbox.maps:android-ndk27:11.23.0'
│   └── src/main/kotlin/.../PneumageOfflineMapsPlugin.kt
│       └── Native implementation: 347 lines
├── example/
│   └── Test app with token configuration
├── README.md
├── INTEGRATION_GUIDE.md
└── IMPLEMENTATION_NOTES.md (this file)
```

---

## Lessons Learned

### 1. Plugin Isolation is Powerful

When platform dependencies conflict, creating a separate plugin provides complete isolation. This pattern can solve many "impossible" dependency conflicts.

### 2. SDK Variants Are Not Versions

Build variants (`android` vs `android-ndk27`) are distinct artifacts, not just different builds of the same library. They must match exactly across all dependencies.

### 3. Documentation Gaps Exist

Even major SDKs like Mapbox have documentation gaps - especially for:
- Exact import paths for Kotlin/Java
- Platform-specific API differences (iOS vs Android)
- Build variant requirements

### 4. Auth Scope Matters

Maven repositories can require specific token scopes (`OFFLINE:READ`). Public tokens that work for runtime APIs may not work for build-time dependencies.

### 5. Gradle Dependency Resolution is Strict

Android Gradle requires perfect class uniqueness. Even transitive dependencies bringing in duplicate classes will fail the build. Exclusions and variants must be managed precisely.

---

## Next Steps

### Immediate (Testing Phase)

1. **Test Native Downloads**:
   - Deploy app to physical device
   - Trigger offline download
   - Verify tiles are actually cached
   - Check storage location and size

2. **Verify Offline Usage**:
   - Enable airplane mode
   - Load map in cached region
   - Confirm map renders from cache

3. **Test Management Operations**:
   - Delete individual region
   - Clear all regions
   - Verify storage freed

### Short Term (Enhancement)

1. **Real-time Progress**:
   - Implement EventChannel in plugin
   - Stream progress from native to Dart
   - Update UI during download

2. **Fix clearAllRegions()**:
   - Research proper TileRegions iteration
   - Implement complete enumeration
   - Test with multiple regions

3. **Error Handling**:
   - Map native errors to meaningful Dart exceptions
   - Add error codes for all failure modes
   - Improve error messages

### Medium Term (Production Ready)

1. **iOS Implementation**:
   - Port Android implementation to iOS/Swift
   - Handle platform differences
   - Test on iPhone/iPad

2. **Background Downloads**:
   - Implement background task handling
   - Survive app backgrounding
   - Resume interrupted downloads

3. **Storage Management**:
   - Enforce storage quotas
   - Warn before large downloads
   - Auto-cleanup old regions

---

## Performance Notes

### Build Times

- Plugin alone: ~1.7s (cached)
- Main app with plugin: ~23s (first build with plugin)
- Main app subsequent: ~5-10s (incremental)

### Download Estimates

Based on Mapbox tile sizes:
- Zoom 10-12: ~5-10 MB per square kilometer
- Zoom 10-16: ~50-100 MB per square kilometer
- City-scale (10km²): ~500 MB - 1 GB

### Recommendations

- Default zoom range: 10-14 (balance detail and size)
- High detail areas: 10-16 (user opt-in)
- Background areas: 10-12 (minimal storage)
- Storage limit: 1 GB (configurable)

---

## References

### Mapbox Documentation

- [Android Maps SDK](https://docs.mapbox.com/android/maps/guides/)
- [Offline Maps Guide](https://docs.mapbox.com/android/maps/guides/offline/)
- [TileStore API](https://docs.mapbox.com/android/maps/api/11.0.0/) (Note: v11 docs)

### Flutter Plugin Development

- [Plugin Development](https://docs.flutter.dev/packages-and-plugins/developing-packages)
- [Platform Channels](https://docs.flutter.dev/platform-integration/platform-channels)
- [EventChannel](https://api.flutter.dev/flutter/services/EventChannel-class.html)

### Gradle & Dependencies

- [Gradle Dependency Management](https://docs.gradle.org/current/userguide/dependency_management.html)
- [Android Gradle Plugin](https://developer.android.com/studio/build)
- [Resolving Dependency Conflicts](https://docs.gradle.org/current/userguide/dependency_resolution.html)

---

## Acknowledgments

This implementation was completed through iterative problem-solving, documentation research, and systematic debugging. Key contributors:

- Architecture design and dependency analysis
- Native Mapbox SDK integration
- Plugin development and testing

**Date Completed**: May 10, 2026  
**Status**: ✅ Ready for functional testing
