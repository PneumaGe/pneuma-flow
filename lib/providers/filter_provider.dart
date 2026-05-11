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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/filter_service.dart';

/// Provider for the FilterService singleton
///
/// Use this to access the filter service throughout the app:
/// ```dart
/// final filterService = ref.watch(filterServiceProvider);
/// ```
final filterServiceProvider = Provider<FilterService>((ref) {
  final service = FilterService();

  // Cleanup on dispose (though singleton typically lives for app lifetime)
  ref.onDispose(() {
    service.clear();
  });

  return service;
});

/// State notifier for managing filter configurations
///
/// Provides reactive updates when filter settings change.
/// This allows UI to rebuild when filter enabled state or parameters change.
class FilterConfigNotifier extends StateNotifier<Map<String, FilterConfig>> {
  final FilterService _filterService;

  FilterConfigNotifier(this._filterService) : super(_filterService.getAllConfigs());

  /// Enable/disable filtering for a channel
  void setEnabled(String channelId, bool enabled) {
    _filterService.configureFilter(channelId, enabled: enabled);
    state = _filterService.getAllConfigs();
  }

  /// Update filter parameters for a channel
  void updateConfig(
    String channelId, {
    double? alpha,
    double? beta,
    double? dt,
    bool? enabled,
  }) {
    _filterService.configureFilter(
      channelId,
      alpha: alpha,
      beta: beta,
      dt: dt,
      enabled: enabled,
    );
    state = _filterService.getAllConfigs();
  }

  /// Reset a specific filter
  void reset(String channelId) {
    _filterService.resetFilter(channelId);
    // State doesn't change, but could trigger UI update if needed
  }

  /// Reset all filters
  void resetAll() {
    _filterService.resetAllFilters();
  }

  /// Get config for a specific channel
  FilterConfig? getConfig(String channelId) {
    return state[channelId];
  }

  /// Check if filtering is enabled for a channel
  bool isEnabled(String channelId) {
    return state[channelId]?.enabled ?? false;
  }
}

/// Provider for filter configurations with state management
///
/// Use this for reactive UI updates when filter settings change:
/// ```dart
/// final configs = ref.watch(filterConfigProvider);
/// final isCO2Filtered = configs['co2']?.enabled ?? false;
/// ```
final filterConfigProvider =
    StateNotifierProvider<FilterConfigNotifier, Map<String, FilterConfig>>((ref) {
  final filterService = ref.watch(filterServiceProvider);
  return FilterConfigNotifier(filterService);
});

/// Provider for checking if a specific channel has filtering enabled
///
/// Use this for conditional logic based on filter state:
/// ```dart
/// final isCO2Filtered = ref.watch(isFilterEnabledProvider('co2'));
/// ```
final isFilterEnabledProvider = Provider.family<bool, String>((ref, channelId) {
  final configs = ref.watch(filterConfigProvider);
  return configs[channelId]?.enabled ?? false;
});

/// Provider for getting a specific channel's filter configuration
///
/// Use this to display/edit individual channel settings:
/// ```dart
/// final co2Config = ref.watch(channelFilterConfigProvider('co2'));
/// ```
final channelFilterConfigProvider = Provider.family<FilterConfig?, String>((ref, channelId) {
  final configs = ref.watch(filterConfigProvider);
  return configs[channelId];
});
