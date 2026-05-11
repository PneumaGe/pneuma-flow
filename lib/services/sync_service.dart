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
  // Sync (upload)
  // ---------------------------------------------------------------------------

  /// Upload a project and all its measurements to the cloud.
  ///
  /// Returns an updated [Project] with [SyncStatus.synced].
  Future<Project> syncProject(
    Project project,
    List<Measurement> measurements,
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

  /// Upload a single measurement: metadata to Firestore, samples to Storage.
  Future<void> _syncMeasurement(
    String projectId,
    Measurement measurement,
  ) async {
    // Measurement metadata (without the samples array)
    final metaData = measurement.toJson()..remove('samples');
    await _measurementsCol(projectId)
        .doc(measurement.id)
        .set(metaData);

    // Bulk sample data to Cloud Storage
    final samplesJson = jsonEncode(
      measurement.samples.map((s) => s.toJson()).toList(),
    );
    await _samplesBucket(projectId, measurement.id)
        .putString(samplesJson, format: PutStringFormat.raw);
  }

  // ---------------------------------------------------------------------------
  // Restore (download)
  // ---------------------------------------------------------------------------

  /// Download a project and all its measurements from the cloud.
  ///
  /// Returns the project (with [SyncStatus.synced]) and its measurements.
  Future<({Project project, List<Measurement> measurements})> restoreProject(
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

    // Concurrently fetch all measurement samples from Cloud Storage.
    final measurementFutures = measurementDocs.docs.map((doc) async {
      final meta = doc.data();

      // Download samples from Cloud Storage
      final samplesData =
          await _samplesBucket(projectId, doc.id).getData();
      if (samplesData == null) {
        // Or handle this case more gracefully depending on requirements
        throw StateError('Sample data not found for measurement ${doc.id}');
      }
      meta['samples'] = jsonDecode(utf8.decode(samplesData));
      return Measurement.fromJson(meta);
    });
    final measurements = await Future.wait(measurementFutures);

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
