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

import 'dart:collection';
import 'package:hive/hive.dart';

part 'filter_service.g.dart';

/// Alpha-Beta Filter for real-time signal smoothing and derivative estimation.
///
/// This is a simplified Kalman filter that uses two gain parameters:
/// - alpha: controls state prediction (position tracking)
/// - beta: controls velocity estimation (rate of change)
///
/// Useful for:
/// - Smoothing noisy sensor data
/// - Estimating rate of change (velocity/slope)
/// - Real-time filtering with low computational overhead
class AlphaBetaFilter {
  final double alpha;
  final double beta;
  final double dt;

  double _state = 0.0;
  double _velocity = 0.0;
  bool _initialized = false;

  AlphaBetaFilter({
    this.alpha = 0.85,
    this.beta = 0.005,
    required this.dt,
  });

  /// Updates the filter with a new measurement and returns the smoothed state.
  double update(double measurement) {
    if (!_initialized) {
      _state = measurement;
      _initialized = true;
      return _state;
    }

    // Predict
    double predictedState = _state + (_velocity * dt);

    // Innovation (Residual)
    double residual = measurement - predictedState;

    // Update state and velocity
    _state = predictedState + (alpha * residual);
    _velocity = _velocity + (beta / dt * residual);

    return _state;
  }

  /// Returns the current rate of change (derivative).
  double get velocity => _velocity;

  /// Returns the current filtered state value.
  double get state => _state;

  /// Returns whether the filter has been initialized with at least one measurement.
  bool get isInitialized => _initialized;

  /// Resets the filter to uninitialized state.
  void reset() {
    _state = 0.0;
    _velocity = 0.0;
    _initialized = false;
  }
}

/// Configuration for a single channel's Alpha-Beta filter.
@HiveType(typeId: 7)
class FilterConfig {
  @HiveField(0)
  final String channelId;
  @HiveField(1)
  final double alpha;
  @HiveField(2)
  final double beta;
  @HiveField(3)
  final double dt;
  @HiveField(4)
  final bool enabled;

  const FilterConfig({
    required this.channelId,
    this.alpha = 0.85,
    this.beta = 0.005,
    this.dt = 1.0, // Default 1 second sample interval
    this.enabled = false, // Disabled by default until user enables
  });

  FilterConfig copyWith({
    String? channelId,
    double? alpha,
    double? beta,
    double? dt,
    bool? enabled,
  }) {
    return FilterConfig(
      channelId: channelId ?? this.channelId,
      alpha: alpha ?? this.alpha,
      beta: beta ?? this.beta,
      dt: dt ?? this.dt,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'channelId': channelId,
        'alpha': alpha,
        'beta': beta,
        'dt': dt,
        'enabled': enabled,
      };

  factory FilterConfig.fromJson(Map<String, dynamic> json) => FilterConfig(
        channelId: json['channelId'] as String,
        alpha: (json['alpha'] as num?)?.toDouble() ?? 0.85,
        beta: (json['beta'] as num?)?.toDouble() ?? 0.005,
        dt: (json['dt'] as num?)?.toDouble() ?? 1.0,
        enabled: json['enabled'] as bool? ?? false,
      );
}

/// Service for managing real-time data filtering using Alpha-Beta filters.
///
/// Provides:
/// - Per-channel filter instances (CO2, CH4, Temperature, Pressure, etc.)
/// - Configuration management (alpha, beta, dt parameters)
/// - Optional filtering hooks for data pipeline integration
/// - Filter reset capabilities
///
/// Usage:
/// ```dart
/// final filterService = FilterService();
/// filterService.configureFilter('co2', alpha: 0.85, beta: 0.005, dt: 1.0, enabled: true);
/// double filtered = filterService.applyFilter('co2', rawValue);
/// double rate = filterService.getVelocity('co2');
/// ```
class FilterService {
  // Filter instances keyed by channel ID (e.g., 'co2', 'ch4', 'chamber_temp')
  final Map<String, AlphaBetaFilter> _filters = {};

  // Configuration for each channel
  final Map<String, FilterConfig> _configs = {};

  // Default configurations for standard channels
  static const Map<String, FilterConfig> _defaultConfigs = {
    'co2': FilterConfig(
      channelId: 'co2',
      alpha: 0.85,
      beta: 0.005,
      dt: 1.0,
      enabled: false,
    ),
    'ch4': FilterConfig(
      channelId: 'ch4',
      alpha: 0.85,
      beta: 0.005,
      dt: 1.0,
      enabled: false,
    ),
    'chamber_temp': FilterConfig(
      channelId: 'chamber_temp',
      alpha: 0.90,
      beta: 0.003,
      dt: 1.0,
      enabled: false,
    ),
    'chamber_pressure': FilterConfig(
      channelId: 'chamber_pressure',
      alpha: 0.90,
      beta: 0.003,
      dt: 1.0,
      enabled: false,
    ),
  };

  FilterService() {
    // Initialize with default configurations
    _configs.addAll(_defaultConfigs);
  }

  /// Configures the Alpha-Beta filter for a specific channel.
  ///
  /// If the filter is already running, it will be reset when configuration changes.
  void configureFilter(
    String channelId, {
    double? alpha,
    double? beta,
    double? dt,
    bool? enabled,
  }) {
    final currentConfig = _configs[channelId] ?? FilterConfig(channelId: channelId);

    final newConfig = currentConfig.copyWith(
      alpha: alpha,
      beta: beta,
      dt: dt,
      enabled: enabled,
    );

    _configs[channelId] = newConfig;

    // Reset existing filter if parameters changed (except enabled flag)
    if (_filters.containsKey(channelId)) {
      final currentFilter = _filters[channelId]!;
      if (currentFilter.alpha != newConfig.alpha ||
          currentFilter.beta != newConfig.beta ||
          currentFilter.dt != newConfig.dt) {
        _filters.remove(channelId);
      }
    }

    // Create new filter if enabled
    if (newConfig.enabled && !_filters.containsKey(channelId)) {
      _filters[channelId] = AlphaBetaFilter(
        alpha: newConfig.alpha,
        beta: newConfig.beta,
        dt: newConfig.dt,
      );
    }

    // Remove filter if disabled
    if (!newConfig.enabled && _filters.containsKey(channelId)) {
      _filters.remove(channelId);
    }
  }

  /// Applies the Alpha-Beta filter to a measurement.
  ///
  /// If filtering is disabled for this channel, returns the raw measurement.
  /// If no filter exists for this channel, creates one using current config.
  double applyFilter(String channelId, double measurement) {
    final config = _configs[channelId];

    // If filtering is disabled, return raw value
    if (config == null || !config.enabled) {
      return measurement;
    }

    // Get or create filter
    final filter = _filters[channelId] ??= AlphaBetaFilter(
      alpha: config.alpha,
      beta: config.beta,
      dt: config.dt,
    );

    return filter.update(measurement);
  }

  /// Returns the estimated velocity (rate of change) for a channel.
  ///
  /// Returns 0.0 if no filter exists or filter is not initialized.
  double getVelocity(String channelId) {
    final filter = _filters[channelId];
    return filter?.velocity ?? 0.0;
  }

  /// Returns the current filtered state for a channel.
  ///
  /// Returns null if no filter exists or filter is not initialized.
  double? getFilteredState(String channelId) {
    final filter = _filters[channelId];
    if (filter == null || !filter.isInitialized) return null;
    return filter.state;
  }

  /// Returns whether filtering is enabled for a channel.
  bool isFilterEnabled(String channelId) {
    return _configs[channelId]?.enabled ?? false;
  }

  /// Returns the configuration for a channel.
  FilterConfig? getConfig(String channelId) {
    return _configs[channelId];
  }

  /// Returns all channel configurations.
  Map<String, FilterConfig> getAllConfigs() {
    return UnmodifiableMapView(_configs);
  }

  /// Resets the filter for a specific channel.
  ///
  /// The filter will be reinitialized on the next measurement.
  void resetFilter(String channelId) {
    _filters[channelId]?.reset();
  }

  /// Resets all filters.
  void resetAllFilters() {
    for (var filter in _filters.values) {
      filter.reset();
    }
  }

  /// Removes the filter for a specific channel.
  void removeFilter(String channelId) {
    _filters.remove(channelId);
    _configs.remove(channelId);
  }

  /// Removes all filters.
  void clear() {
    _filters.clear();
    _configs.clear();
    _configs.addAll(_defaultConfigs);
  }

  /// Batch filters multiple channel measurements at once.
  ///
  /// Returns a map of channelId -> filtered value.
  /// Useful for filtering complete Sample objects.
  Map<String, double> applyFilters(Map<String, double> measurements) {
    final filtered = <String, double>{};
    for (var entry in measurements.entries) {
      filtered[entry.key] = applyFilter(entry.key, entry.value);
    }
    return filtered;
  }

  // ============================================================================
  // HOOKS FOR FUTURE INTEGRATION
  // ============================================================================

  /// Hook: Apply filter to incoming BLE data before DataService caching.
  ///
  /// This can be wired into BleService notification handlers to filter
  /// raw sensor data in real-time before it reaches the UI.
  ///
  /// Example integration point:
  /// ```dart
  /// // In BleService._parseGasConcentration()
  /// double rawValue = data.getFloat32(0, Endian.little);
  /// double filtered = filterService.applyFilter('co2', rawValue);
  /// _gasConcentrationController.add(filtered);
  /// ```
  double hookBleDataFilter(String channelId, double rawValue) {
    return applyFilter(channelId, rawValue);
  }

  /// Hook: Filter Sample data during measurement recording.
  ///
  /// Can be used in ProjectService when creating Sample objects.
  ///
  /// Example integration point:
  /// ```dart
  /// // In ProjectService when recording measurement
  /// final rawChannelValues = {
  ///   'co2': gasConcentration,
  ///   'chamber_temp': chamberTemp,
  ///   // ...
  /// };
  /// final filteredValues = filterService.hookSampleFilter(rawChannelValues);
  /// final sample = Sample(timestamp: now, channelValues: filteredValues);
  /// ```
  Map<String, double> hookSampleFilter(Map<String, double> channelValues) {
    return applyFilters(channelValues);
  }

  /// Hook: Real-time velocity monitoring for rapid change detection.
  ///
  /// Can be used to detect anomalies or trigger alerts when rate of change
  /// exceeds a threshold.
  ///
  /// Example integration point:
  /// ```dart
  /// // After filtering in real-time data stream
  /// double velocity = filterService.hookGetVelocity('co2');
  /// if (velocity.abs() > threshold) {
  ///   // Trigger alert or log event
  /// }
  /// ```
  double hookGetVelocity(String channelId) {
    return getVelocity(channelId);
  }

  /// Hook: Reset filters when starting a new measurement session.
  ///
  /// Should be called when Record button is pressed to clear filter state
  /// from previous measurements.
  ///
  /// Example integration point:
  /// ```dart
  /// // In ProjectService.startMeasurement() or Record button handler
  /// filterService.hookResetOnMeasurementStart();
  /// ```
  void hookResetOnMeasurementStart() {
    resetAllFilters();
  }
}
