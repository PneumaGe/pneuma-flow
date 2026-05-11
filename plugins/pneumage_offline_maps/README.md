# pneumage_offline_maps

Flutter plugin for downloading and managing offline map tiles using Mapbox TileStore API.

This plugin provides native offline functionality by directly interfacing with Mapbox's TileStore, allowing apps to cache map tiles for offline use without dependency conflicts.

## Features

- ✅ Download map tiles for specific geographic regions
- ✅ Configure zoom level range (e.g., 10-16)
- ✅ Real-time download progress tracking
- ✅ Delete individual cached regions
- ✅ Clear all cached regions
- ✅ Automatic storage management via Mapbox TileStore
- ✅ Works alongside `mapbox_maps_flutter` without conflicts

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  pneumage_offline_maps:
    path: ../pneumage_offline_maps  # Local path during development
```

### Android Configuration

1. Add your Mapbox token to `android/gradle.properties`:

```properties
MAPBOX_DOWNLOADS_TOKEN=pk.your_token_here
```

2. Ensure minimum SDK version in `android/app/build.gradle.kts`:

```kotlin
defaultConfig {
    minSdk = 24  // Required for Mapbox TileStore
}
```

## Usage

### Download a Region

```dart
import 'package:pneumage_offline_maps/pneumage_offline_maps.dart';

// Define bounding box
final result = await PneumageOfflineMaps.downloadRegion(
  north: 37.8,
  south: 37.7,
  east: -122.3,
  west: -122.5,
  minZoom: 10,
  maxZoom: 16,
  regionId: 'san_francisco_downtown',
);

print('Downloaded ${result.tileCount} tiles (${result.sizeBytes} bytes)');
```

### Track Download Progress

```dart
// Listen to progress updates
final progressStream = PneumageOfflineMaps.getProgressStream(regionId);
progressStream.listen((progress) {
  print('${progress.percentageString} - ${progress.sizeString}');
  print('Tiles: ${progress.completedTiles}/${progress.totalTiles}');
});
```

### Delete a Region

```dart
await PneumageOfflineMaps.deleteRegion('san_francisco_downtown');
```

### Clear All Regions

```dart
await PneumageOfflineMaps.clearAllRegions();
```

## Technical Details

### Map Style

The plugin uses `mapbox://styles/mapbox/light-v11` for offline downloads. This lightweight style is optimized for offline use:

- **Minimal size** - Reduces download time and storage requirements
- **Essential features** - All necessary map data without excessive styling
- **Efficient caching** - Smaller tiles mean more areas can be cached

This is ideal for offline medical field work where storage is limited and broad area coverage is needed.

### Architecture

This plugin solves the dependency conflict that occurs when trying to use Mapbox SDK directly in an app that already uses `mapbox_maps_flutter`. By isolating the Mapbox SDK dependency within the plugin's Gradle configuration, both the plugin and `mapbox_maps_flutter` can coexist.

**Key Components:**
- **Dart API**: Flutter interface with `MethodChannel` and `EventChannel`
- **Android Native**: Kotlin implementation using Mapbox TileStore API
- **TileStore**: Mapbox's official offline tile management system

### Why a Separate Plugin?

The main app uses `mapbox_maps_flutter` (v2.3.0), which internally bundles Mapbox Android SDK 11.23.0-ndk27. Attempting to add the Mapbox SDK at the app level causes Gradle duplicate class errors.

**Solution**: This plugin has its own isolated Gradle dependency tree, preventing conflicts. Platform channels bridge between Flutter and native code.

### Storage Location

Tiles are stored in Android's internal storage using Mapbox's default TileStore location. Storage is managed automatically by the SDK.

## API Reference

### `PneumageOfflineMaps`

#### Methods

- **`downloadRegion(...)`** → `Future<OfflineRegionResult>`
  - Downloads map tiles for a bounding box
  - Parameters: `north`, `south`, `east`, `west`, `minZoom`, `maxZoom`, `regionId`
  - Returns: Download statistics (tile count, size, resources)

- **`deleteRegion(String regionId)`** → `Future<void>`
  - Deletes a specific cached region
  
- **`clearAllRegions()`** → `Future<void>`
  - Removes all cached regions

- **`getProgressStream(String regionId)`** → `Stream<DownloadProgress>`
  - Real-time progress updates during download

### Data Classes

#### `OfflineRegionResult`

```dart
class OfflineRegionResult {
  final String id;                     // Region identifier
  final int sizeBytes;                 // Total size in bytes
  final int tileCount;                 // Number of tiles downloaded
  final int completedResourceCount;    // Resources downloaded
  final int requiredResourceCount;     // Total resources requested
}
```

#### `DownloadProgress`

```dart
class DownloadProgress {
  final double progress;               // 0.0 to 1.0
  final int loadedBytes;               // Bytes downloaded
  final int totalBytes;                // Total bytes (estimated)
  final int completedTiles;            // Tiles completed
  final int totalTiles;                // Total tiles
  
  String get percentageString;         // "45%"
  String get sizeString;               // "12.5 MB / 28.0 MB"
}
```

## Development

### Building the Plugin

```bash
cd pneumage_offline_maps
flutter pub get
```

### Testing

Run the example app:

```bash
cd example
flutter run
```

### Testing with Main App

From the main app directory:

```yaml
# pubspec.yaml
dependencies:
  pneumage_offline_maps:
    path: ../pneumage_offline_maps
```

Then:

```bash
flutter pub get
flutter run
```

## License

MIT License - see LICENSE file

## Credits

Built for the PneumAge app to provide robust offline map functionality using Mapbox TileStore.

