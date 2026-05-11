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

import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';

import '../models/app_settings.dart';
import '../models/device_settings.dart';

/// Handles persistence for app-level and per-device settings.
///
/// Phase 4: Hive-only database (JSON/SharedPreferences migration complete)
///
/// - [AppSettings] stored in Hive settingsBox
/// - [DeviceSettings] stored in Hive settingsBox (keyed by device_$deviceId)
class SettingsService {
  static const _migrationKey = 'settings_migration_completed';
  
  // Legacy constants (used only for migration)
  static const _appSettingsKey = 'app_settings';
  static const _deviceSettingsFile = 'device_settings.json';

  // Hive box getter
  Box get _settingsBox => Hive.box('settings');

  /// Initialize the service (run migration if needed)
  Future<void> initialize() async {
    await _migrateExistingDataToHive();
  }

  /// One-time migration: Copy all existing settings to Hive
  Future<void> _migrateExistingDataToHive() async {
    // Check if migration already completed
    final migrationCompleted = _settingsBox.get(_migrationKey, defaultValue: false);
    if (migrationCompleted) return;

    print('[SettingsService] Starting migration of settings data to Hive...');

    try {
      // Migrate app settings from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final appSettingsJson = prefs.getString(_appSettingsKey);
      if (appSettingsJson != null) {
        final appSettings = AppSettings.fromJson(
          jsonDecode(appSettingsJson) as Map<String, dynamic>,
        );
        await _settingsBox.put('app_settings', appSettings);
        print('[SettingsService] Migrated app settings to Hive');
      }

      // Migrate device settings from JSON file
      final deviceSettingsMap = await _loadAllDeviceSettings();
      for (final entry in deviceSettingsMap.entries) {
        await _settingsBox.put('device_${entry.key}', entry.value);
      }
      print('[SettingsService] Migrated ${deviceSettingsMap.length} device settings to Hive');

      // Mark migration complete
      await _settingsBox.put(_migrationKey, true);
      print('[SettingsService] Settings migration completed successfully');
    } catch (e) {
      print('[SettingsService] Settings migration failed: $e');
      // Don't mark as complete so it will retry next time
      rethrow;
    }
  }

  // -- App Settings (SharedPreferences + Hive) --

  /// Phase 3: Read from Hive (dual-write continues as backup)
  Future<AppSettings> loadAppSettings() async {
    try {
      final settings = _settingsBox.get('app_settings');
      if (settings != null) {
        return settings as AppSettings;
      }
      // Return defaults if not found
      return const AppSettings();
    } catch (e) {
      print('Error loading app settings from Hive: $e');
      return const AppSettings();
    }
  }

  /// Phase 4: Write to Hive only
  Future<void> saveAppSettings(AppSettings settings) async {
    // Write to Hive
    await _settingsBox.put('app_settings', settings);
  }

  // -- Device Settings (JSON file) --

  Future<File> _deviceSettingsFile_() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_deviceSettingsFile');
  }

  Future<Map<String, DeviceSettings>> _loadAllDeviceSettings() async {
    final file = await _deviceSettingsFile_();
    if (!await file.exists()) return {};
    final content = await file.readAsString();
    if (content.isEmpty) return {};
    final map = jsonDecode(content) as Map<String, dynamic>;
    return map.map(
      (key, value) => MapEntry(
        key,
        DeviceSettings.fromJson(value as Map<String, dynamic>),
      ),
    );
  }

  // Legacy method - no longer used (settings stored in Hive only)
  // Kept for potential future migration utilities
  // ignore: unused_element
  Future<void> _saveAllDeviceSettings(
    Map<String, DeviceSettings> allSettings,
  ) async {
    final file = await _deviceSettingsFile_();
    final map = allSettings.map(
      (key, value) => MapEntry(key, value.toJson()),
    );
    await file.writeAsString(jsonEncode(map));
  }

  /// Load settings for a specific device. Returns defaults if none saved.
  /// Phase 3: Read from Hive (dual-write continues as backup)
  Future<DeviceSettings> loadDeviceSettings(String deviceId) async {
    try {
      final settings = _settingsBox.get('device_$deviceId');
      if (settings != null) {
        return settings as DeviceSettings;
      }
      // Return defaults if not found
      return DeviceSettings(deviceId: deviceId);
    } catch (e) {
      print('Error loading device settings from Hive for $deviceId: $e');
      return DeviceSettings(deviceId: deviceId);
    }
  }

  /// Save settings for a specific device.
  /// Phase 4: Write to Hive only
  Future<void> saveDeviceSettings(DeviceSettings settings) async {
    // Write to Hive
    await _settingsBox.put('device_${settings.deviceId}', settings);
  }

  /// Remove saved settings for a device.
  /// Phase 4: Delete from Hive only
  Future<void> deleteDeviceSettings(String deviceId) async {
    // Delete from Hive
    await _settingsBox.delete('device_$deviceId');
  }
}
