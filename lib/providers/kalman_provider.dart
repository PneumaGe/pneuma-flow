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
import '../services/kalman_filter_service.dart';

/// Provider for the KalmanFilterService singleton
///
/// Use this to access the Kalman filter service throughout the app:
/// ```dart
/// final kalmanService = ref.watch(kalmanFilterServiceProvider);
/// ```
final kalmanFilterServiceProvider = Provider<KalmanFilterService>((ref) {
  final service = KalmanFilterService();

  // Cleanup on dispose (though singleton typically lives for app lifetime)
  ref.onDispose(() {
    service.clear();
  });

  return service;
});

/// State notifier for managing Kalman filter configurations
///
/// Provides reactive updates when Kalman filter settings change.
/// This allows UI to rebuild when filter enabled state or parameters change.
class KalmanConfigNotifier extends StateNotifier<Map<String, KalmanConfig>> {
  final KalmanFilterService _kalmanService;

  KalmanConfigNotifier(this._kalmanService)
      : super(_kalmanService.getAllConfigs());

  /// Enable/disable Kalman filtering for a channel
  void setEnabled(String channelId, bool enabled) {
    _kalmanService.configureFilter(channelId, enabled: enabled);
    state = _kalmanService.getAllConfigs();
  }

  /// Update Kalman filter parameters for a channel
  void updateConfig(
    String channelId, {
    double? r,
    double? baseQ,
    bool? enabled,
  }) {
    _kalmanService.configureFilter(
      channelId,
      r: r,
      baseQ: baseQ,
      enabled: enabled,
    );
    state = _kalmanService.getAllConfigs();
  }

  /// Reset a specific filter
  void reset(String channelId) {
    _kalmanService.resetFilter(channelId);
    // State doesn't change, but could trigger UI update if needed
  }

  /// Reset all filters
  void resetAll() {
    _kalmanService.resetAllFilters();
  }

  /// Get config for a specific channel
  KalmanConfig? getConfig(String channelId) {
    return state[channelId];
  }

  /// Check if Kalman filtering is enabled for a channel
  bool isEnabled(String channelId) {
    return state[channelId]?.enabled ?? false;
  }
}

/// Provider for Kalman filter configurations with state management
///
/// Use this for reactive UI updates when Kalman filter settings change:
/// ```dart
/// final configs = ref.watch(kalmanConfigProvider);
/// final isCO2Filtered = configs['co2']?.enabled ?? false;
/// ```
final kalmanConfigProvider =
    StateNotifierProvider<KalmanConfigNotifier, Map<String, KalmanConfig>>(
        (ref) {
  final kalmanService = ref.watch(kalmanFilterServiceProvider);
  return KalmanConfigNotifier(kalmanService);
});

/// Provider for checking if a specific channel has Kalman filtering enabled
///
/// Use this for conditional logic based on filter state:
/// ```dart
/// final isCO2KalmanEnabled = ref.watch(isKalmanEnabledProvider('co2'));
/// ```
final isKalmanEnabledProvider = Provider.family<bool, String>((ref, channelId) {
  final configs = ref.watch(kalmanConfigProvider);
  return configs[channelId]?.enabled ?? false;
});

/// Provider for getting a specific channel's Kalman filter configuration
///
/// Use this to display/edit individual channel settings:
/// ```dart
/// final co2Config = ref.watch(channelKalmanConfigProvider('co2'));
/// ```
final channelKalmanConfigProvider =
    Provider.family<KalmanConfig?, String>((ref, channelId) {
  final configs = ref.watch(kalmanConfigProvider);
  return configs[channelId];
});

/// Provider for checking if a Kalman filter has converged
///
/// Use this to display convergence status in the UI:
/// ```dart
/// final co2Converged = ref.watch(kalmanConvergedProvider('co2'));
/// if (!co2Converged) {
///   // Show "Stabilizing..." indicator
/// }
/// ```
final kalmanConvergedProvider = Provider.family<bool, String>((ref, channelId) {
  final kalmanService = ref.watch(kalmanFilterServiceProvider);
  // Note: This won't auto-update during filtering - need to manually refresh
  // or create a StreamProvider if real-time convergence monitoring is needed
  return kalmanService.isConverged(channelId);
});

/// Provider for getting filter covariance (estimation error)
///
/// Use this to display confidence/quality metrics:
/// ```dart
/// final co2Covariance = ref.watch(kalmanCovarianceProvider('co2'));
/// // Lower values = higher confidence
/// ```
final kalmanCovarianceProvider =
    Provider.family<double?, String>((ref, channelId) {
  final kalmanService = ref.watch(kalmanFilterServiceProvider);
  return kalmanService.getCovariance(channelId);
});
