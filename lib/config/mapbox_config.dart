// Copyright 2026 PneumaGe Contributors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

/// Mapbox API Configuration
/// 
/// CONFIGURATION OPTIONS:
/// 
/// Option 1 (Development - Recommended):
///   1. Copy 'mapbox_config_local.dart.example' to 'mapbox_config_local.dart'
///   2. Add your tokens to the new file
///   3. Run normally: flutter run
/// 
/// Option 2 (Production - CI/CD):
///   Use --dart-define flag:
///   flutter run --dart-define=MAPBOX_ACCESS_TOKEN=pk.your_token_here
///   flutter build apk --dart-define=MAPBOX_ACCESS_TOKEN=pk.your_token_here
/// 
/// Get your tokens from: https://account.mapbox.com/access-tokens/
/// - Public token (pk.*) - for map display
/// - Secret token (sk.*) - for downloading SDK dependencies (Android gradle)

// Import local config (ignored by git)
// Falls back to stub only on web platform
import 'mapbox_config_local.dart' if (dart.library.html) 'mapbox_config_stub.dart';

class MapboxConfig {
  /// Public access token for map display and tile downloads
  /// Priority: --dart-define > mapbox_config_local.dart > empty string
  static String get accessToken {
    const envToken = String.fromEnvironment('MAPBOX_ACCESS_TOKEN', defaultValue: '');
    if (envToken.isNotEmpty) return envToken;
    
    // Try to use local config if available (will fail gracefully if not found)
    try {
      return MapboxConfigLocal.accessToken;
    } catch (e) {
      return '';
    }
  }
  
  /// Optional: Secret token for server-side operations (not used in mobile app)
  /// Keep this secure and never embed it in the app
  static const String? secretToken = null;
  
  /// Default map style URL
  /// Options:
  /// - 'mapbox://styles/mapbox/satellite-v9' (satellite imagery)
  /// - 'mapbox://styles/mapbox/satellite-streets-v12' (satellite with street overlay)
  /// - 'mapbox://styles/mapbox/streets-v12' (street map)
  /// - 'mapbox://styles/mapbox/outdoors-v12' (topographic)
  /// - 'mapbox://styles/mapbox/dark-v11' (dark mode)
  static const String defaultStyleUrl = 'mapbox://styles/mapbox/satellite-streets-v12';
  
  /// Initial map camera position (lat, lon, zoom)
  /// Default: Center of USA
  static const double initialLatitude = 39.8283;
  static const double initialLongitude = -98.5795;
  static const double initialZoom = 4.0;
  
  /// Offline map settings
  static const int maxOfflineTileCacheSize = 1000 * 1024 * 1024; // 1 GB
  static const int tileDownloadConcurrency = 4;
}
