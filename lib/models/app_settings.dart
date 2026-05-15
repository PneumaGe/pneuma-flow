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

part 'app_settings.g.dart';

/// Global app-level settings (not tied to any device or project).
@HiveType(typeId: 5)
class AppSettings {
  @HiveField(0)
  final String units; // 'metric' or 'imperial'

  @HiveField(1)
  final bool volumeButtonsEnabled; // Use volume buttons to control recording

  @HiveField(2, defaultValue: '')
  final String creatorName; // User's full name for provenance

  @HiveField(3, defaultValue: '')
  final String organization; // Organization/institution name

  @HiveField(4, defaultValue: '')
  final String operatorId; // Operator ID (email, username, etc.)

  const AppSettings({
    this.units = 'metric',
    this.volumeButtonsEnabled = true,
    this.creatorName = '',
    this.organization = '',
    this.operatorId = '',
  });

  AppSettings copyWith({
    String? units,
    bool? volumeButtonsEnabled,
    String? creatorName,
    String? organization,
    String? operatorId,
  }) => AppSettings(
    units: units ?? this.units,
    volumeButtonsEnabled: volumeButtonsEnabled ?? this.volumeButtonsEnabled,
    creatorName: creatorName ?? this.creatorName,
    organization: organization ?? this.organization,
    operatorId: operatorId ?? this.operatorId,
  );

  Map<String, dynamic> toJson() => {
    'units': units,
    'volumeButtonsEnabled': volumeButtonsEnabled,
    'creatorName': creatorName,
    'organization': organization,
    'operatorId': operatorId,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    units: json['units'] as String? ?? 'metric',
    volumeButtonsEnabled: json['volumeButtonsEnabled'] as bool? ?? true,
    creatorName: json['creatorName'] as String? ?? '',
    organization: json['organization'] as String? ?? '',
    operatorId: json['operatorId'] as String? ?? '',
  );
}
