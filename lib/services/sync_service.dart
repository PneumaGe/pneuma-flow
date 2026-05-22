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

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../config/schema_version.dart';
import '../models/app_settings.dart';
import '../models/measurement.dart';
import '../models/project.dart';

/// Handles manual cloud sync, archive, and restore of projects.
///
/// - Project metadata and measurement metadata → Firestore
/// - Bulk sample data → Cloud Storage (avoids Firestore 1MB doc limit)
///
/// Requires Firebase to be initialised before use.
class SyncService {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  SyncService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  // ---------------------------------------------------------------------------
  // References
  // ---------------------------------------------------------------------------

  CollectionReference<Map<String, dynamic>> get _projectsCol =>
      _firestore.collection('projects');

  CollectionReference<Map<String, dynamic>> _measurementsCol(
    String projectId,
  ) => _projectsCol.doc(projectId).collection('measurements');

  Reference _samplesBucket(String projectId, String measurementId) =>
      _storage.ref('projects/$projectId/measurements/$measurementId.json');

  // ---------------------------------------------------------------------------
  // Validation
  // ---------------------------------------------------------------------------

  /// Validate that user profile is complete before syncing.
  ///
  /// Throws [StateError] if required profile fields are missing.
  void validateUserProfile(AppSettings settings) {
    final missingFields = <String>[];
    
    if (settings.creatorName.trim().isEmpty) {
      missingFields.add('Creator Name');
    }
    
    if (settings.operatorId.trim().isEmpty) {
      missingFields.add('Operator ID');
    }
    
    if (missingFields.isNotEmpty) {
      throw StateError(
        'User profile incomplete. Please complete the following fields in '
        'Settings > User Profile: ${missingFields.join(', ')}'
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Sync (upload)
  // ---------------------------------------------------------------------------

  /// Upload a project and all its measurements to the cloud.
  ///
  /// Returns an updated [Project] with [SyncStatus.synced].
  Future<Project> syncProject(
    Project project,
    List<PneumaGeRecord> measurements,
  ) async {
    // Upload project metadata (without local-only fields)
    final projectData = project.toJson()
      ..remove('syncStatus')
      ..remove('lastSyncedAt');
    await _projectsCol.doc(project.id).set(projectData);

    // Upload each measurement
    for (final m in measurements) {
      await _syncMeasurement(project.id, m);
    }

    final now = DateTime.now();
    return project.copyWith(
      syncStatus: SyncStatus.synced,
      lastSyncedAt: now,
    );
  }

  /// Upload a single measurement: metadata to Firestore, full data to Storage.
  Future<void> _syncMeasurement(
    String projectId,
    PneumaGeRecord measurement,
  ) async {
    // Validate schema before upload
    _validateRecordSchema(measurement);
    
    // Lightweight metadata to Firestore (without sample arrays)
    final metaData = {
      'record_uuid': measurement.recordUuid,
      'version': measurement.version,
      'project_id': measurement.projectId,
      'cycle_id': measurement.measurementCycle.cycleId,
      'timestamp_start': measurement.startTime.toIso8601String(),
      'coordinates': {
        'lat': measurement.latitude,
        'lon': measurement.longitude,
        'elevation_m': measurement.elevation,
      },
      'channels': measurement.measurementCycle.channels.map((ch) => ch.targetGas).toList(),
    };
    await _measurementsCol(projectId)
        .doc(measurement.id)
        .set(metaData);

    // Full record data to Cloud Storage (includes all samples)
    final fullDataJson = jsonEncode(measurement.toJson());
    await _samplesBucket(projectId, measurement.id)
        .putString(fullDataJson, format: PutStringFormat.raw);
  }

  // ---------------------------------------------------------------------------
  // Restore (download)
  // ---------------------------------------------------------------------------

  /// Download a project and all its measurements from the cloud.
  ///
  /// Returns the project (with [SyncStatus.synced]) and its measurements.
  Future<({Project project, List<PneumaGeRecord> measurements})> restoreProject(
    String projectId,
  ) async {
    // Fetch project metadata
    final projectDoc = await _projectsCol.doc(projectId).get();
    if (!projectDoc.exists) {
      throw StateError('Project $projectId not found in cloud');
    }
    final project = Project.fromJson(projectDoc.data()!).copyWith(
      syncStatus: SyncStatus.synced,
      lastSyncedAt: DateTime.now(),
    );

    // Fetch all measurement metadata
    final measurementDocs =
        await _measurementsCol(projectId).get();

    // Concurrently fetch all full measurement data from Cloud Storage.
    final measurementFutures = measurementDocs.docs.map((doc) async {
      // Download full record from Cloud Storage
      final fullData =
          await _samplesBucket(projectId, doc.id).getData();
      if (fullData == null) {
        throw StateError('Measurement data not found for measurement ${doc.id}');
      }
      final recordJson = jsonDecode(utf8.decode(fullData));
      final record = PneumaGeRecord.fromJson(recordJson);
      
      // Validate restored record
      try {
        _validateRestoredRecord(record);
        return record;
      } catch (e) {
        print('⚠️ Skipping invalid measurement ${record.recordUuid}: $e');
        return null; // Mark for filtering
      }
    });
    final allResults = await Future.wait(measurementFutures);
    
    // Filter out null (invalid) measurements
    final measurements = allResults.whereType<PneumaGeRecord>().toList();
    
    // Ensure we have at least some valid data
    if (measurements.isEmpty && measurementDocs.docs.isNotEmpty) {
      throw StateError(
        'No valid measurements found in project $projectId. '
        'Schema version incompatible? Update app to restore this data.'
      );
    }

    return (project: project, measurements: measurements);
  }

  // ---------------------------------------------------------------------------
  // Archive
  // ---------------------------------------------------------------------------

  /// Verify a project is synced and eligible for archiving.
  ///
  /// Returns `true` if the project can be safely archived.
  bool canArchive(Project project) => project.syncStatus == SyncStatus.synced;

  // ---------------------------------------------------------------------------
  // List cloud projects
  // ---------------------------------------------------------------------------

  /// Fetch all projects owned by or shared with the given user.
  Future<List<Project>> getCloudProjects(String userId) async {
    // Projects owned by user
    final ownedQuery = await _projectsCol
        .where('ownerId', isEqualTo: userId)
        .get();

    // Projects shared with user
    final sharedQuery = await _projectsCol
        .where('collaboratorEmails', arrayContains: userId)
        .get();

    final projectMap = <String, Project>{};
    for (final doc in [...ownedQuery.docs, ...sharedQuery.docs]) {
      projectMap.putIfAbsent(
        doc.id,
        () => Project.fromJson(doc.data()).copyWith(
              syncStatus: SyncStatus.archived,
            ),
      );
    }

    return projectMap.values.toList();
  }

  // ---------------------------------------------------------------------------
  // Validation
  // ---------------------------------------------------------------------------

  /// Validate a record's schema before uploading to Firebase.
  ///
  /// Throws [StateError] if validation fails.
  void _validateRecordSchema(PneumaGeRecord measurement) {
    // Check schema version compatibility
    if (measurement.version != kSchemaVersion) {
      throw StateError(
        'Schema version mismatch: Record is ${measurement.version}, '
        'but app expects $kSchemaVersion. Cannot sync incompatible data.'
      );
    }
    
    // Validate required fields
    if (measurement.recordUuid.isEmpty) {
      throw StateError('Invalid record: missing recordUuid');
    }
    
    if (measurement.measurementCycle.channels.isEmpty) {
      throw StateError('Invalid record: no flux channels defined');
    }
    
    // Validate data integrity for each channel
    for (final channel in measurement.measurementCycle.channels) {
      // Check that channel has sample data
      if (channel.rawData.samples.isEmpty) {
        throw StateError(
          'Invalid channel ${channel.targetGas}: no raw sample data'
        );
      }
      
      // Validate sample format is defined
      if (channel.rawData.sampleFormat.isEmpty) {
        throw StateError(
          'Invalid channel ${channel.targetGas}: missing sample format'
        );
      }
      
      // Validate all samples match the format length
      final expectedLength = channel.rawData.sampleFormat.length;
      for (var i = 0; i < channel.rawData.samples.length; i++) {
        if (channel.rawData.samples[i].length != expectedLength) {
          throw StateError(
            'Invalid channel ${channel.targetGas}: '
            'sample $i has ${channel.rawData.samples[i].length} values, '
            'expected $expectedLength (matching sample_format)'
          );
        }
      }
    }
    
    // Validate provenance exists
    if (measurement.provenance.creator.isEmpty) {
      throw StateError('Invalid record: missing provenance.creator');
    }
  }

  /// Validate a restored record's compatibility with current app version.
  ///
  /// Throws [StateError] if record cannot be used by this app version.
  void _validateRestoredRecord(PneumaGeRecord record) {
    // Check version compatibility using semantic versioning
    if (!isSchemaCompatible(record.version, appVersion: kSchemaVersion)) {
      throw StateError(
        'Incompatible schema version ${record.version} '
        '(app supports $kSchemaVersion)'
      );
    }
    
    // Validate required data structures exist
    if (record.provenance.creator.isEmpty) {
      throw StateError('Missing required provenance data');
    }
    
    // Check for required measurement data
    if (record.measurementCycle.channels.isEmpty) {
      throw StateError('No flux channels in measurement');
    }
    
    // Basic data integrity check
    for (final channel in record.measurementCycle.channels) {
      if (channel.rawData.samples.isEmpty) {
        throw StateError('Channel ${channel.targetGas} has no data');
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Delete from cloud
  // ---------------------------------------------------------------------------

  /// Permanently delete a project and all its data from the cloud.
  Future<void> deleteCloudProject(String projectId) async {
    // Delete all measurement docs and sample files
    final measurementDocs =
        await _measurementsCol(projectId).get();
    for (final doc in measurementDocs.docs) {
      try {
        await _samplesBucket(projectId, doc.id).delete();
      } on FirebaseException {
        // Sample file may not exist; continue cleanup
      }
      await doc.reference.delete();
    }

    // Delete project doc
    await _projectsCol.doc(projectId).delete();
  }
}
