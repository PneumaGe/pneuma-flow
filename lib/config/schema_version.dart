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

/// PneumaGe Master Schema version supported by this app
/// 
/// This version must match the schema version used in:
/// - PneumaGeRecord.version field
/// - DeviceInfo.dataModelVersion field (from firmware)
/// - JSON exports
const String kSchemaVersion = '1.9.0';

/// Parse semantic version string to [major, minor, patch]
/// 
/// Returns [0, 0, 0] if version string is invalid
List<int> parseVersion(String version) {
  try {
    return version.split('.').map((s) {
      try {
        return int.parse(s);
      } catch (e) {
        return 0;
      }
    }).toList();
  } catch (e) {
    return [0, 0, 0];
  }
}

/// Check if device schema version is compatible with app
/// 
/// Compatibility rules:
/// - Major version must match exactly
/// - App minor version must be >= device minor version
/// - Patch versions are ignored for compatibility
/// - Null device version (legacy firmware) is considered compatible
/// 
/// Examples:
/// - Device 1.9.0, App 1.9.0 ✅ Compatible
/// - Device 1.8.0, App 1.9.0 ✅ Compatible (app newer)
/// - Device 1.10.0, App 1.9.0 ❌ Incompatible (app too old)
/// - Device 2.0.0, App 1.9.0 ❌ Incompatible (major version mismatch)
bool isSchemaCompatible(String? deviceVersion, {String appVersion = kSchemaVersion}) {
  if (deviceVersion == null) {
    return true; // Legacy firmware without version field
  }
  
  final deviceParts = parseVersion(deviceVersion);
  final appParts = parseVersion(appVersion);
  
  if (deviceParts.length < 2 || appParts.length < 2) {
    return false; // Invalid version format
  }
  
  // Major version must match
  if (deviceParts[0] != appParts[0]) {
    return false;
  }
  
  // App minor version must be >= device minor version
  if (appParts[1] < deviceParts[1]) {
    return false; // App is too old
  }
  
  return true;
}

/// Get human-readable version comparison message
String getVersionComparisonMessage(String? deviceVersion, {String appVersion = kSchemaVersion}) {
  if (deviceVersion == null) {
    return 'Legacy firmware (no schema version)';
  }
  
  if (isSchemaCompatible(deviceVersion, appVersion: appVersion)) {
    if (deviceVersion == appVersion) {
      return 'Versions match: $deviceVersion';
    }
    return 'Compatible: Device $deviceVersion, App $appVersion';
  }
  
  final deviceParts = parseVersion(deviceVersion);
  final appParts = parseVersion(appVersion);
  
  if (deviceParts[0] != appParts[0]) {
    return 'INCOMPATIBLE: Major version mismatch (Device ${deviceParts[0]}.x, App ${appParts[0]}.x)';
  }
  
  if (appParts[1] < deviceParts[1]) {
    return 'INCOMPATIBLE: App too old (Device $deviceVersion, App $appVersion)';
  }
  
  return 'INCOMPATIBLE: Device $deviceVersion, App $appVersion';
}
