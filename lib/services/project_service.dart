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
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';

import '../models/measurement.dart';
import '../models/project.dart';

/// Service for local project and measurement storage
/// Phase 4: Hive-only database (JSON migration complete)
class ProjectService {
  static const _migrationKey = 'hive_migration_completed';
  
  // Legacy constants (used only for migration/validation)
  static const _projectsFile = 'projects.json';
  static const _currentProjectKey = 'current_project_id';

  // Hive box getters
  Box<Project> get _projectsBox => Hive.box<Project>('projects');
  Box<Measurement> get _measurementsBox => Hive.box<Measurement>('measurements');
  Box get _settingsBox => Hive.box('settings');

  /// Initialize the service (run migration if needed)
  Future<void> initialize() async {
    await _migrateExistingDataToHive();
    
    // Phase 3: Validate data consistency in debug mode
    assert(() {
      validateDataConsistency();
      return true;
    }());
  }

  /// One-time migration: Copy all JSON data to Hive boxes
  Future<void> _migrateExistingDataToHive() async {
    // Check if migration already completed
    final migrationCompleted = _settingsBox.get(_migrationKey, defaultValue: false);
    if (migrationCompleted) return;

    print('[ProjectService] Starting migration of JSON data to Hive...');

    try {
      // Migrate projects
      final projects = await loadProjects();
      for (final project in projects) {
        await _projectsBox.put(project.id, project);
      }
      print('[ProjectService] Migrated ${projects.length} projects to Hive');

      // Migrate measurements for each project
      int totalMeasurements = 0;
      for (final project in projects) {
        final measurements = await loadMeasurements(project.id);
        for (final measurement in measurements) {
          await _measurementsBox.put(measurement.id, measurement);
        }
        totalMeasurements += measurements.length;
      }
      print('[ProjectService] Migrated $totalMeasurements measurements to Hive');

      // Migrate current project ID from SharedPreferences to Hive
      final currentProjectId = await getCurrentProjectId();
      if (currentProjectId != null) {
        await _settingsBox.put('current_project_id', currentProjectId);
      }

      // Mark migration complete
      await _settingsBox.put(_migrationKey, true);
      print('[ProjectService] Migration completed successfully');
    } catch (e) {
      print('[ProjectService] Migration failed: $e');
      // Don't mark as complete so it will retry next time
      rethrow;
    }
  }

  /// Phase 3: Data consistency validator (development mode only)
  /// Compares JSON data vs Hive data and logs discrepancies
  Future<void> validateDataConsistency() async {
    try {
      print('[ProjectService] Starting data consistency validation...');
      
      // Load projects from JSON file directly
      final file = await _projectsFile_();
      List<Project> jsonProjects = [];
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          final jsonList = jsonDecode(content) as List;
          jsonProjects = jsonList
              .map((json) => Project.fromJson(json as Map<String, dynamic>))
              .toList();
        }
      }

      // Get projects from Hive
      final hiveProjects = _projectsBox.values.toList();

      // Compare counts
      if (jsonProjects.length != hiveProjects.length) {
        print('[CONSISTENCY ERROR] Project count mismatch: JSON=${jsonProjects.length}, Hive=${hiveProjects.length}');
      } else {
        print('[Consistency Check] ✓ Project counts match: ${jsonProjects.length}');
      }

      // Compare each project
      for (final jsonProject in jsonProjects) {
        final hiveProject = _projectsBox.get(jsonProject.id);
        if (hiveProject == null) {
          print('[CONSISTENCY ERROR] Project ${jsonProject.id} exists in JSON but not in Hive');
        } else if (jsonProject.name != hiveProject.name ||
                   jsonProject.filenamePrefix != hiveProject.filenamePrefix ||
                   jsonProject.nextMeasurementCounter != hiveProject.nextMeasurementCounter) {
          print('[CONSISTENCY ERROR] Project ${jsonProject.id} data mismatch between JSON and Hive');
        }
      }

      // Check current project ID
      final prefs = await SharedPreferences.getInstance();
      final jsonCurrentId = prefs.getString(_currentProjectKey);
      final hiveCurrentId = _settingsBox.get('current_project_id') as String?;
      
      if (jsonCurrentId != hiveCurrentId) {
        print('[CONSISTENCY ERROR] Current project ID mismatch: JSON=$jsonCurrentId, Hive=$hiveCurrentId');
      } else {
        print('[Consistency Check] ✓ Current project ID matches');
      }

      // Validate measurements (sample check - checking all would be expensive)
      int checkedMeasurements = 0;
      int measurementErrors = 0;
      for (final project in jsonProjects.take(3)) { // Check first 3 projects only
        final dir = await getApplicationDocumentsDirectory();
        final projectDir = Directory('${dir.path}/projects/${project.id}');
        
        if (await projectDir.exists()) {
          final files = await projectDir.list().toList();
          for (final file in files.take(5)) { // Check up to 5 measurements per project
            if (file is File && file.path.endsWith('.json')) {
              try {
                final content = await file.readAsString();
                final json = jsonDecode(content) as Map<String, dynamic>;
                final jsonMeasurement = Measurement.fromJson(json);
                final hiveMeasurement = _measurementsBox.get(jsonMeasurement.id);
                
                if (hiveMeasurement == null) {
                  print('[CONSISTENCY ERROR] Measurement ${jsonMeasurement.id} exists in JSON but not in Hive');
                  measurementErrors++;
                } else if (jsonMeasurement.samples.length != hiveMeasurement.samples.length) {
                  print('[CONSISTENCY ERROR] Measurement ${jsonMeasurement.id} sample count mismatch');
                  measurementErrors++;
                }
                checkedMeasurements++;
              } catch (e) {
                print('[CONSISTENCY ERROR] Error validating measurement: $e');
              }
            }
          }
        }
      }
      
      if (measurementErrors == 0) {
        print('[Consistency Check] ✓ Checked $checkedMeasurements measurements - all match');
      } else {
        print('[CONSISTENCY ERROR] $measurementErrors measurement errors found out of $checkedMeasurements checked');
      }
      
      print('[ProjectService] Data consistency validation complete');
    } catch (e) {
      print('[ProjectService] Consistency validation error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // File paths
  // ---------------------------------------------------------------------------

  Future<File> _projectsFile_() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_projectsFile');
  }

  // Legacy method - no longer used (measurements stored in Hive only)
  // Kept for potential future migration utilities
  // ignore: unused_element
  Future<File> _measurementFile(String projectId, String measurementId) async {
    final dir = await getApplicationDocumentsDirectory();
    final projectDir = Directory('${dir.path}/projects/$projectId');
    if (!await projectDir.exists()) {
      await projectDir.create(recursive: true);
    }
    return File('${projectDir.path}/$measurementId.json');
  }

  // ---------------------------------------------------------------------------
  // Projects
  // ---------------------------------------------------------------------------

  /// Load all projects from local storage
  /// Phase 3: Read from Hive (dual-write continues as backup)
  Future<List<Project>> loadProjects() async {
    try {
      // Read from Hive box (fast, indexed access)
      return _projectsBox.values.toList();
    } catch (e) {
      print('Error loading projects from Hive: $e');
      return [];
    }
  }

  /// Save all projects to local storage
  /// Phase 4: Hive-only (JSON removed)
  Future<void> saveProjects(List<Project> projects) async {
    try {
      // Clear and write to Hive box
      await _projectsBox.clear();
      for (final project in projects) {
        await _projectsBox.put(project.id, project);
      }
    } catch (e) {
      print('Error saving projects: $e');
      rethrow;
    }
  }

  /// Create a new project
  /// Phase 4: Hive-only (JSON removed)
  Future<Project> createProject({
    required String name,
    required String ownerId,
    String filenamePrefix = 'PG',
  }) async {
    final project = Project(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      ownerId: ownerId,
      filenamePrefix: filenamePrefix,
      createdAt: DateTime.now(),
    );

    // Write to Hive box
    await _projectsBox.put(project.id, project);

    return project;
  }

  /// Update an existing project
  /// Phase 4: Hive-only (JSON removed)
  Future<void> updateProject(Project project) async {
    // Validate project exists
    if (!_projectsBox.containsKey(project.id)) {
      throw StateError('Project ${project.id} not found');
    }
    
    // Update Hive box
    await _projectsBox.put(project.id, project);
  }

  /// Delete a project and all its measurements
  /// Phase 4: Hive-only (JSON removed)
  Future<void> deleteProject(String projectId) async {
    // Delete from Hive
    await _projectsBox.delete(projectId);

    // Delete measurements from Hive
    final measurements = await loadMeasurements(projectId);
    for (final measurement in measurements) {
      await _measurementsBox.delete(measurement.id);
    }

    // Clear current project if it was deleted
    final currentId = await getCurrentProjectId();
    if (currentId == projectId) {
      await clearCurrentProject();
    }
  }

  // ---------------------------------------------------------------------------
  // Current Project Selection
  // ---------------------------------------------------------------------------

  /// Get the ID of the currently active project
  /// Phase 3: Read from Hive (dual-write continues as backup)
  Future<String?> getCurrentProjectId() async {
    try {
      return _settingsBox.get('current_project_id') as String?;
    } catch (e) {
      print('Error loading current project ID from Hive: $e');
      return null;
    }
  }

  /// Set the currently active project
  /// Phase 4: Hive-only (SharedPreferences removed)
  Future<void> setCurrentProject(String projectId) async {
    // Write to Hive
    await _settingsBox.put('current_project_id', projectId);
  }

  /// Clear the current project selection
  /// Phase 4: Hive-only (SharedPreferences removed)
  Future<void> clearCurrentProject() async {
    // Clear from Hive
    await _settingsBox.delete('current_project_id');
  }

  /// Get the currently active project object
  Future<Project?> getCurrentProject() async {
    final currentId = await getCurrentProjectId();
    if (currentId == null) return null;

    final projects = await loadProjects();
    try {
      return projects.firstWhere((p) => p.id == currentId);
    } catch (e) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Measurements
  // ---------------------------------------------------------------------------

  /// Load all measurements for a project
  /// Phase 3: Read from Hive (dual-write continues as backup)
  Future<List<Measurement>> loadMeasurements(String projectId) async {
    try {
      // Query Hive box - filter by projectId
      return _measurementsBox.values
          .where((m) => m.projectId == projectId)
          .toList();
    } catch (e) {
      print('Error loading measurements from Hive for project $projectId: $e');
      return [];
    }
  }

  /// Load a single measurement by ID
  /// Returns null if measurement not found
  Future<Measurement?> getMeasurement(String measurementId) async {
    try {
      return _measurementsBox.get(measurementId);
    } catch (e) {
      print('Error loading measurement $measurementId from Hive: $e');
      return null;
    }
  }

  /// Save a measurement to local storage
  /// Phase 4: Hive-only (JSON removed)
  Future<void> saveMeasurement(Measurement measurement) async {
    try {
      // Write to Hive box
      await _measurementsBox.put(measurement.id, measurement);

      // Update project's measurement IDs and increment counter
      final project = await _getProjectById(measurement.projectId);
      if (project != null) {
        final updatedIds = List<String>.from(project.measurementIds);
        if (!updatedIds.contains(measurement.id)) {
          updatedIds.add(measurement.id);
          await updateProject(project.copyWith(
            measurementIds: updatedIds,
            nextMeasurementCounter: project.nextMeasurementCounter + 1,
            syncStatus: SyncStatus.local, // Mark as needing sync
          ));
        }
      }
    } catch (e) {
      print('Error saving measurement: $e');
      rethrow;
    }
  }

  /// Update an existing measurement (e.g., for fit boundaries, notes)
  /// Phase 4: Hive-only
  Future<void> updateMeasurement(Measurement measurement) async {
    try {
      // Verify measurement exists
      final existing = _measurementsBox.get(measurement.id);
      if (existing == null) {
        throw Exception('Measurement ${measurement.id} not found');
      }
      
      // Update in Hive box
      await _measurementsBox.put(measurement.id, measurement);
      
      // Mark project as needing sync
      final project = await _getProjectById(measurement.projectId);
      if (project != null && project.syncStatus == SyncStatus.synced) {
        await updateProject(project.copyWith(syncStatus: SyncStatus.local));
      }
    } catch (e) {
      print('Error updating measurement: $e');
      rethrow;
    }
  }

  /// Generate the next measurement filename for a project
  /// Format: {prefix}_{counter:03d} (e.g., PG_001, PG_002)
  String getNextMeasurementFilename(Project project) {
    return '${project.filenamePrefix}_${project.nextMeasurementCounter.toString().padLeft(3, '0')}';
  }

  /// Delete a measurement
  /// Phase 4: Hive-only (JSON removed)
  Future<void> deleteMeasurement(String projectId, String measurementId) async {
    try {
      // Delete from Hive box
      await _measurementsBox.delete(measurementId);

      // Update project's measurement IDs
      final project = await _getProjectById(projectId);
      if (project != null) {
        final updatedIds = List<String>.from(project.measurementIds);
        updatedIds.remove(measurementId);
        await updateProject(project.copyWith(
          measurementIds: updatedIds,
          syncStatus: SyncStatus.local,
        ));
      }
    } catch (e) {
      print('Error deleting measurement: $e');
      rethrow;
    }
  }

  /// Get a specific project by ID
  /// Phase 3: Direct Hive lookup (O(1) instead of O(n))
  Future<Project?> _getProjectById(String projectId) async {
    try {
      return _projectsBox.get(projectId);
    } catch (e) {
      print('Error getting project $projectId from Hive: $e');
      return null;
    }
  }
}
