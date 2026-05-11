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

import 'package:hive/hive.dart';
import '../services/filter_service.dart';
import '../services/kalman_filter_service.dart';

part 'device_settings.g.dart';

/// Per-device user preferences, keyed by deviceId.
@HiveType(typeId: 6)
class DeviceSettings {
  @HiveField(0)
  final String deviceId;
  @HiveField(1)
  final String pumpSpeed; // 'LOW', 'MEDIUM', or 'HIGH'
  @HiveField(2)
  final Map<String, bool> channelVisibility; // keyed by channel ID
  @HiveField(3)
  final Map<String, FilterConfig>? filterConfigs; // Alpha-Beta filter configs (keyed by channel ID)
  @HiveField(4)
  final Map<String, KalmanConfig>? kalmanConfigs; // Kalman filter configs (keyed by channel ID)

  const DeviceSettings({
    required this.deviceId,
    this.pumpSpeed = 'MEDIUM',
    this.channelVisibility = const {},
    this.filterConfigs,
    this.kalmanConfigs,
  });

  DeviceSettings copyWith({
    String? pumpSpeed,
    Map<String, bool>? channelVisibility,
    Map<String, FilterConfig>? filterConfigs,
    Map<String, KalmanConfig>? kalmanConfigs,
  }) => DeviceSettings(
    deviceId: deviceId,
    pumpSpeed: pumpSpeed ?? this.pumpSpeed,
    channelVisibility: channelVisibility ?? this.channelVisibility,
    filterConfigs: filterConfigs ?? this.filterConfigs,
    kalmanConfigs: kalmanConfigs ?? this.kalmanConfigs,
  );

  Map<String, dynamic> toJson() => {
    'deviceId': deviceId,
    'pumpSpeed': pumpSpeed,
    'channelVisibility': channelVisibility,
    'filterConfigs': filterConfigs?.map(
      (k, v) => MapEntry(k, v.toJson()),
    ),
    'kalmanConfigs': kalmanConfigs?.map(
      (k, v) => MapEntry(k, v.toJson()),
    ),
  };

  factory DeviceSettings.fromJson(Map<String, dynamic> json) =>
      DeviceSettings(
        deviceId: json['deviceId'] as String,
        pumpSpeed: json['pumpSpeed'] as String? ?? 'MEDIUM',
        channelVisibility: (json['channelVisibility'] as Map<String, dynamic>?)
            ?.map((k, v) => MapEntry(k, v as bool)) ?? {},
        filterConfigs: (json['filterConfigs'] as Map<String, dynamic>?)
            ?.map((k, v) => MapEntry(k, FilterConfig.fromJson(v as Map<String, dynamic>))),
        kalmanConfigs: (json['kalmanConfigs'] as Map<String, dynamic>?)
            ?.map((k, v) => MapEntry(k, KalmanConfig.fromJson(v as Map<String, dynamic>))),
      );
}
