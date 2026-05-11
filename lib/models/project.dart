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

part 'project.g.dart';

/// Lifecycle state for cloud sync.
@HiveType(typeId: 4)
enum SyncStatus {
  @HiveField(0)
  local,     // not yet synced (new or modified since last sync)
  @HiveField(1)
  syncing,   // upload/download in progress
  @HiveField(2)
  synced,    // local copy matches cloud copy
  @HiveField(3)
  archived,  // removed from local storage, exists only in cloud
  @HiveField(4)
  restoring, // downloading from cloud back to local
}

@HiveType(typeId: 0)
class Project {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String ownerId;
  @HiveField(3)
  final String filenamePrefix;
  @HiveField(4)
  final int nextMeasurementCounter;
  @HiveField(5)
  final DateTime createdAt;
  @HiveField(6)
  final List<String> collaboratorEmails;
  @HiveField(7)
  final List<String> measurementIds;
  @HiveField(8)
  final SyncStatus syncStatus;
  @HiveField(9)
  final DateTime? lastSyncedAt;

  const Project({
    required this.id,
    required this.name,
    required this.ownerId,
    this.filenamePrefix = 'PG',
    this.nextMeasurementCounter = 1,
    required this.createdAt,
    this.collaboratorEmails = const [],
    this.measurementIds = const [],
    this.syncStatus = SyncStatus.local,
    this.lastSyncedAt,
  });

  Project copyWith({
    String? name,
    String? filenamePrefix,
    int? nextMeasurementCounter,
    List<String>? collaboratorEmails,
    List<String>? measurementIds,
    SyncStatus? syncStatus,
    DateTime? lastSyncedAt,
  }) => Project(
    id: id,
    name: name ?? this.name,
    ownerId: ownerId,
    filenamePrefix: filenamePrefix ?? this.filenamePrefix,
    nextMeasurementCounter: nextMeasurementCounter ?? this.nextMeasurementCounter,
    createdAt: createdAt,
    collaboratorEmails: collaboratorEmails ?? this.collaboratorEmails,
    measurementIds: measurementIds ?? this.measurementIds,
    syncStatus: syncStatus ?? this.syncStatus,
    lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'ownerId': ownerId,
    'filenamePrefix': filenamePrefix,
    'nextMeasurementCounter': nextMeasurementCounter,
    'createdAt': createdAt.toIso8601String(),
    'collaboratorEmails': collaboratorEmails,
    'measurementIds': measurementIds,
    'syncStatus': syncStatus.name,
    if (lastSyncedAt != null)
      'lastSyncedAt': lastSyncedAt!.toIso8601String(),
  };

  factory Project.fromJson(Map<String, dynamic> json) => Project(
    id: json['id'] as String,
    name: json['name'] as String,
    ownerId: json['ownerId'] as String,
    filenamePrefix: json['filenamePrefix'] as String? ?? 'PG',
    nextMeasurementCounter: json['nextMeasurementCounter'] as int? ?? 1,
    createdAt: DateTime.parse(json['createdAt'] as String),
    collaboratorEmails: (json['collaboratorEmails'] as List?)
        ?.cast<String>() ?? [],
    measurementIds: (json['measurementIds'] as List?)
        ?.cast<String>() ?? [],
    syncStatus: SyncStatus.values.byName(
      json['syncStatus'] as String? ?? 'local',
    ),
    lastSyncedAt: json['lastSyncedAt'] != null
        ? DateTime.parse(json['lastSyncedAt'] as String)
        : null,
  );
}
