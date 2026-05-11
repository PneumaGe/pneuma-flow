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

part 'kalman_filter_service.g.dart';

/// Kalman Filter with temperature and pressure compensation using ideal gas law.
///
/// This filter is specifically designed for gas concentration measurements in
/// an accumulation chamber environment where temperature and pressure fluctuations
/// affect the true molar density of the gas.
///
/// Key features:
/// - Ideal gas law correction (PV = nRT) to compensate for pressure/temperature
/// - Dynamic process noise scaling based on pressure rate of change
/// - Optimal state estimation for noisy sensor readings
///
/// Inputs required:
/// - Raw gas concentration (ppm)
/// - Chamber temperature (°C)
/// - Chamber pressure (Pa) - should be smoothed via Alpha-Beta filter
/// - Pressure derivative (Pa/s) - from Alpha-Beta filter velocity
class PneumaKalmanFilter {
  double _x = 0.0; // Estimated CO2 concentration (molar density corrected)
  double _p = 1.0; // Estimation error covariance

  final double r; // Measurement noise (sensor precision)
  final double baseQ; // Base process noise

  PneumaKalmanFilter({
    required this.r,
    required this.baseQ,
  });

  /// Updates the filter using pressure-compensated molar density logic.
  ///
  /// [rawPpm] - Raw sensor reading in ppm
  /// [tempC] - Chamber temperature in Celsius
  /// [pressurePa] - Smoothed chamber pressure in Pascals (from Alpha-Beta filter)
  /// [pressureDeriv] - Pressure rate of change in Pa/s (from Alpha-Beta filter)
  ///
  /// Returns the compensated and filtered gas concentration estimate.
  double update(
    double rawPpm,
    double tempC,
    double pressurePa,
    double pressureDeriv,
  ) {
    // 1. Ideal Gas Law Correction (ppm to molar density factor)
    // n/V = P / RT
    double tempK = tempC + 273.15;
    const double R = 8.314; // Universal gas constant (J/(mol·K))
    double molarDensityFactor = pressurePa / (R * tempK);

    // Compensated measurement
    double z = rawPpm * molarDensityFactor;

    // 2. Dynamic Process Noise Scaling
    // Scale Q based on the magnitude of pressure fluctuations
    // Rapid pressure changes indicate more uncertainty in the system
    double dynamicQ = baseQ * (1.0 + pressureDeriv.abs());

    // 3. Prediction Step
    // x_k = x_{k-1} (Assuming steady state between updates)
    _p = _p + dynamicQ;

    // 4. Update Step (Correction)
    double kalmanGain = _p / (_p + r);
    _x = _x + kalmanGain * (z - _x);
    _p = (1 - kalmanGain) * _p;

    return _x;
  }

  /// Returns the current filtered estimate.
  double get estimate => _x;

  /// Returns the current estimation error covariance.
  double get covariance => _p;

  /// Returns whether the filter has converged (low covariance).
  bool get isConverged => _p < 0.01;

  /// Resets the filter to uninitialized state.
  void reset() {
    _x = 0.0;
    _p = 1.0;
  }
}

/// Configuration for a single channel's Kalman filter.
@HiveType(typeId: 8)
class KalmanConfig {
  @HiveField(0)
  final String channelId;
  @HiveField(1)
  final double r; // Measurement noise
  @HiveField(2)
  final double baseQ; // Base process noise
  @HiveField(3)
  final bool enabled;

  const KalmanConfig({
    required this.channelId,
    this.r = 0.5,
    this.baseQ = 0.01,
    this.enabled = false,
  });

  KalmanConfig copyWith({
    String? channelId,
    double? r,
    double? baseQ,
    bool? enabled,
  }) {
    return KalmanConfig(
      channelId: channelId ?? this.channelId,
      r: r ?? this.r,
      baseQ: baseQ ?? this.baseQ,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'channelId': channelId,
        'r': r,
        'baseQ': baseQ,
        'enabled': enabled,
      };

  factory KalmanConfig.fromJson(Map<String, dynamic> json) => KalmanConfig(
        channelId: json['channelId'] as String,
        r: (json['r'] as num?)?.toDouble() ?? 0.5,
        baseQ: (json['baseQ'] as num?)?.toDouble() ?? 0.01,
        enabled: json['enabled'] as bool? ?? false,
      );
}

/// Input data bundle for Kalman filter update.
///
/// Contains all required sensor readings for temperature/pressure compensation.
class KalmanInput {
  final double rawPpm; // Raw gas concentration
  final double tempC; // Chamber temperature (Celsius)
  final double pressurePa; // Chamber pressure (Pascals)
  final double pressureDeriv; // Pressure rate of change (Pa/s)

  const KalmanInput({
    required this.rawPpm,
    required this.tempC,
    required this.pressurePa,
    required this.pressureDeriv,
  });
}

/// Service for managing Kalman filters with temperature/pressure compensation.
///
/// This service is designed specifically for gas concentration measurements
/// (CO2, CH4) where pressure and temperature fluctuations affect the true
/// molar density of the gas in the accumulation chamber.
///
/// Requires integration with Alpha-Beta filter service for smoothed pressure
/// readings and pressure derivative estimates.
///
/// Usage:
/// ```dart
/// final kalmanService = KalmanFilterService();
/// kalmanService.configureFilter('co2', r: 0.5, baseQ: 0.01, enabled: true);
///
/// // Get smoothed pressure from Alpha-Beta filter
/// double smoothPressure = alphaBetaService.applyFilter('chamber_pressure', rawPressure);
/// double pressureDeriv = alphaBetaService.getVelocity('chamber_pressure');
///
/// // Apply Kalman filter with compensation
/// double filtered = kalmanService.applyFilter('co2', KalmanInput(
///   rawPpm: rawCO2,
///   tempC: chamberTemp,
///   pressurePa: smoothPressure,
///   pressureDeriv: pressureDeriv,
/// ));
/// ```
class KalmanFilterService {
  // Filter instances keyed by channel ID (typically 'co2', 'ch4')
  final Map<String, PneumaKalmanFilter> _filters = {};

  // Configuration for each channel
  final Map<String, KalmanConfig> _configs = {};

  // Default configurations for gas concentration channels
  static const Map<String, KalmanConfig> _defaultConfigs = {
    'co2': KalmanConfig(
      channelId: 'co2',
      r: 0.5, // Measurement noise (adjust based on sensor datasheet)
      baseQ: 0.01, // Base process noise
      enabled: false,
    ),
    'ch4': KalmanConfig(
      channelId: 'ch4',
      r: 0.5,
      baseQ: 0.01,
      enabled: false,
    ),
  };

  KalmanFilterService() {
    // Initialize with default configurations
    _configs.addAll(_defaultConfigs);
  }

  /// Configures the Kalman filter for a specific gas channel.
  ///
  /// If the filter is already running, it will be reset when configuration changes.
  void configureFilter(
    String channelId, {
    double? r,
    double? baseQ,
    bool? enabled,
  }) {
    final currentConfig =
        _configs[channelId] ?? KalmanConfig(channelId: channelId);

    final newConfig = currentConfig.copyWith(
      r: r,
      baseQ: baseQ,
      enabled: enabled,
    );

    _configs[channelId] = newConfig;

    // Reset existing filter if parameters changed (except enabled flag)
    if (_filters.containsKey(channelId)) {
      final currentFilter = _filters[channelId]!;
      if (currentFilter.r != newConfig.r ||
          currentFilter.baseQ != newConfig.baseQ) {
        _filters.remove(channelId);
      }
    }

    // Create new filter if enabled
    if (newConfig.enabled && !_filters.containsKey(channelId)) {
      _filters[channelId] = PneumaKalmanFilter(
        r: newConfig.r,
        baseQ: newConfig.baseQ,
      );
    }

    // Remove filter if disabled
    if (!newConfig.enabled && _filters.containsKey(channelId)) {
      _filters.remove(channelId);
    }
  }

  /// Applies the Kalman filter with temperature/pressure compensation.
  ///
  /// If filtering is disabled for this channel, returns the raw measurement.
  /// Requires temperature, pressure, and pressure derivative from Alpha-Beta filter.
  double applyFilter(String channelId, KalmanInput input) {
    final config = _configs[channelId];

    // If filtering is disabled, return raw value
    if (config == null || !config.enabled) {
      return input.rawPpm;
    }

    // Get or create filter
    final filter = _filters[channelId] ??= PneumaKalmanFilter(
      r: config.r,
      baseQ: config.baseQ,
    );

    return filter.update(
      input.rawPpm,
      input.tempC,
      input.pressurePa,
      input.pressureDeriv,
    );
  }

  /// Returns the current filtered estimate for a channel.
  ///
  /// Returns null if no filter exists or filter is not initialized.
  double? getFilteredEstimate(String channelId) {
    final filter = _filters[channelId];
    if (filter == null) return null;
    return filter.estimate;
  }

  /// Returns the estimation error covariance for a channel.
  ///
  /// Lower values indicate higher confidence in the estimate.
  double? getCovariance(String channelId) {
    final filter = _filters[channelId];
    return filter?.covariance;
  }

  /// Returns whether the filter has converged (low estimation error).
  bool isConverged(String channelId) {
    final filter = _filters[channelId];
    return filter?.isConverged ?? false;
  }

  /// Returns whether filtering is enabled for a channel.
  bool isFilterEnabled(String channelId) {
    return _configs[channelId]?.enabled ?? false;
  }

  /// Returns the configuration for a channel.
  KalmanConfig? getConfig(String channelId) {
    return _configs[channelId];
  }

  /// Returns all channel configurations.
  Map<String, KalmanConfig> getAllConfigs() {
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

  // ============================================================================
  // HOOKS FOR FUTURE INTEGRATION
  // ============================================================================

  /// Hook: Apply Kalman filter to incoming BLE gas concentration data.
  ///
  /// This should be wired into BleService notification handlers along with
  /// the Alpha-Beta filter for pressure smoothing.
  ///
  /// Example integration point:
  /// ```dart
  /// // In BleService._parseGasConcentration()
  /// double rawCO2 = data.getFloat32(0, Endian.little);
  ///
  /// // First smooth pressure with Alpha-Beta
  /// double smoothPressure = alphaBetaService.applyFilter('chamber_pressure', rawPressure);
  /// double pressureDeriv = alphaBetaService.getVelocity('chamber_pressure');
  ///
  /// // Then apply Kalman with compensation
  /// double filtered = kalmanService.hookBleDataFilter(
  ///   'co2',
  ///   KalmanInput(
  ///     rawPpm: rawCO2,
  ///     tempC: chamberTemp,
  ///     pressurePa: smoothPressure,
  ///     pressureDeriv: pressureDeriv,
  ///   ),
  /// );
  /// _gasConcentrationController.add(filtered);
  /// ```
  double hookBleDataFilter(String channelId, KalmanInput input) {
    return applyFilter(channelId, input);
  }

  /// Hook: Filter Sample data during measurement recording.
  ///
  /// Requires temperature and pressure data to be available in the sample.
  ///
  /// Example integration point:
  /// ```dart
  /// // In ProjectService when recording measurement
  /// double smoothPressure = alphaBetaService.applyFilter('chamber_pressure', rawPressure);
  /// double pressureDeriv = alphaBetaService.getVelocity('chamber_pressure');
  ///
  /// double filteredCO2 = kalmanService.hookSampleFilter(
  ///   'co2',
  ///   KalmanInput(
  ///     rawPpm: rawCO2,
  ///     tempC: chamberTemp,
  ///     pressurePa: smoothPressure,
  ///     pressureDeriv: pressureDeriv,
  ///   ),
  /// );
  ///
  /// final sample = Sample(
  ///   timestamp: now,
  ///   channelValues: {'co2': filteredCO2, 'chamber_temp': chamberTemp, ...},
  /// );
  /// ```
  double hookSampleFilter(String channelId, KalmanInput input) {
    return applyFilter(channelId, input);
  }

  /// Hook: Monitor filter convergence for quality assurance.
  ///
  /// Can be used to display confidence indicators in the UI or delay
  /// measurement start until filters have stabilized.
  ///
  /// Example integration point:
  /// ```dart
  /// // After filtering in real-time data stream
  /// bool co2Converged = kalmanService.hookCheckConvergence('co2');
  /// double covariance = kalmanService.getCovariance('co2') ?? 1.0;
  ///
  /// if (!co2Converged) {
  ///   // Show "Stabilizing..." indicator in UI
  ///   // Or delay recording start
  /// }
  /// ```
  bool hookCheckConvergence(String channelId) {
    return isConverged(channelId);
  }

  /// Hook: Reset filters when starting a new measurement session.
  ///
  /// Should be called when Record button is pressed to clear filter state
  /// from previous measurements and allow fresh convergence.
  ///
  /// Example integration point:
  /// ```dart
  /// // In ProjectService.startMeasurement() or Record button handler
  /// alphaBetaService.hookResetOnMeasurementStart();
  /// kalmanService.hookResetOnMeasurementStart();
  /// ```
  void hookResetOnMeasurementStart() {
    resetAllFilters();
  }
}
