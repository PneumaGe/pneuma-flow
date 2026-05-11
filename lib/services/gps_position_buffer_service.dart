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

/// OPTION 4: Dedicated GPS Position Buffer Notifier
///
/// A robust, production-ready GPS tracking solution with:
/// - Automatic time-window based data collection
/// - Auto-clearing after measurements
/// - Minimum accuracy threshold enforcement
/// - Built-in noise reduction through averaging
///
/// NOT YET INTEGRATED - Available for testing and future implementation

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// Represents a single GPS sample with metadata
class GpsSample {
  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime timestamp;

  GpsSample({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
  });

  /// Create a Position object from this sample
  Position toPosition() {
    return Position(
      latitude: latitude,
      longitude: longitude,
      timestamp: timestamp,
      accuracy: accuracy,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }
}

/// Configuration for the GPS buffer
class GpsBufferConfig {
  /// How long to keep GPS samples (older samples are discarded)
  final Duration timeWindow;

  /// Minimum accuracy (in meters) required to keep a sample
  final double minAccuracyThreshold;

  /// Minimum number of samples needed for valid averaging
  final int minSamplesRequired;

  /// Whether to auto-clear samples after getting averaged result
  final bool autoClearAfterMeasurement;

  const GpsBufferConfig({
    this.timeWindow = const Duration(seconds: 120),
    this.minAccuracyThreshold = 50.0, // meters — relaxed for field conditions
    this.minSamplesRequired = 3,
    this.autoClearAfterMeasurement = true,
  });
}

/// State class for GPS buffer notifier
class GpsBufferState {
  final List<GpsSample> samples;
  final bool isCollecting;
  final String? lastError;

  const GpsBufferState({
    this.samples = const [],
    this.isCollecting = false,
    this.lastError,
  });

  /// Number of samples currently in buffer
  int get sampleCount => samples.length;

  /// Average position from all samples in buffer
  Position? getAveragedPosition() {
    if (samples.isEmpty) return null;

    double avgLat = 0;
    double avgLon = 0;
    double minAccuracy = double.infinity;

    for (final sample in samples) {
      avgLat += sample.latitude;
      avgLon += sample.longitude;
      minAccuracy =
          minAccuracy > sample.accuracy ? sample.accuracy : minAccuracy;
    }

    avgLat /= samples.length;
    avgLon /= samples.length;

    return Position(
      latitude: avgLat,
      longitude: avgLon,
      timestamp: DateTime.now(),
      accuracy: minAccuracy,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }

  /// Median position from all samples in buffer
  Position? getMedianPosition() {
    if (samples.isEmpty) return null;

    final latitudes = samples.map((s) => s.latitude).toList()..sort();
    final longitudes = samples.map((s) => s.longitude).toList()..sort();
    final accuracies = samples.map((s) => s.accuracy).toList()..sort();

    double median(List<double> values) {
      final mid = values.length ~/ 2;
      if (values.length.isOdd) {
        return values[mid];
      }
      return (values[mid - 1] + values[mid]) / 2;
    }

    final medianLat = median(latitudes);
    final medianLon = median(longitudes);
    final medianAccuracy = median(accuracies);

    return Position(
      latitude: medianLat,
      longitude: medianLon,
      timestamp: DateTime.now(),
      accuracy: medianAccuracy,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }

  /// Get most recent sample
  GpsSample? getMostRecentSample() {
    if (samples.isEmpty) return null;
    return samples.last;
  }

  GpsBufferState copyWith({
    List<GpsSample>? samples,
    bool? isCollecting,
    String? lastError,
  }) {
    return GpsBufferState(
      samples: samples ?? this.samples,
      isCollecting: isCollecting ?? this.isCollecting,
      lastError: lastError,
    );
  }
}

/// GPS Position Buffer Notifier - Manages GPS sample collection with time-window filtering
class GpsPositionBufferNotifier extends Notifier<GpsBufferState> {
  late GpsBufferConfig config;
  StreamSubscription<Position>? _locationSubscription;

  @override
  GpsBufferState build() {
    config = const GpsBufferConfig();
    return const GpsBufferState();
  }

  /// Start collecting GPS samples
  Future<void> startCollecting() async {
    if (state.isCollecting) return;

    state = state.copyWith(isCollecting: true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = state.copyWith(
          isCollecting: false,
          lastError: 'GPS service is disabled',
        );
        return;
      }

      _locationSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 0,
        ),
      ).listen(
        (Position position) {
          _addSample(position);
        },
        onError: (e) {
          state = state.copyWith(lastError: 'GPS Error: $e');
        },
      );
    } catch (e) {
      state = state.copyWith(
        isCollecting: false,
        lastError: 'Failed to start GPS: $e',
      );
    }
  }

  /// Stop collecting GPS samples
  void stopCollecting() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
    state = state.copyWith(isCollecting: false);
  }

  /// Add a new GPS sample to the buffer
  void _addSample(Position position) {
    // Check accuracy threshold
    if (position.accuracy > config.minAccuracyThreshold) {
      print(
          'GPS accuracy too low: ${position.accuracy}m (threshold: ${config.minAccuracyThreshold}m)');
      return;
    }

    final sample = GpsSample(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      timestamp: position.timestamp,
    );

    // Remove old samples outside time window
    final now = DateTime.now();
    final filteredSamples = state.samples
        .where((s) =>
            now.difference(s.timestamp).compareTo(config.timeWindow) <= 0)
        .toList();

    // Add new sample
    filteredSamples.add(sample);

    state = state.copyWith(samples: filteredSamples);
  }

  /// Get averaged position and optionally clear buffer
  Position? getMeasurement({bool clearAfter = true}) {
    // final result = state.getAveragedPosition();
    final result = state.getMedianPosition();

    if (clearAfter && config.autoClearAfterMeasurement) {
      clearBuffer();
    }

    return result;
  }

  /// Manually clear the sample buffer
  void clearBuffer() {
    state = state.copyWith(samples: []);
  }

  /// Get all current samples
  List<GpsSample> getSamples() => List.unmodifiable(state.samples);
}

/// Provider for GPS position buffer
final gpsPositionBufferProvider =
    NotifierProvider<GpsPositionBufferNotifier, GpsBufferState>(
  GpsPositionBufferNotifier.new,
);
