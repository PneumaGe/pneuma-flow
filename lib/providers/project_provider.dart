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
import '../models/measurement.dart';
import '../models/project.dart';
import '../services/project_service.dart';

/// Provider for the project service singleton
/// Phase 2: Initialize service to run migration on first access
final projectServiceProvider = Provider<ProjectService>((ref) {
  final service = ProjectService();
  // Initialize in background (runs migration if needed)
  service.initialize();
  return service;
});

/// Provider for all projects
/// This is a FutureProvider that loads projects and can be invalidated to refresh
final projectsProvider = FutureProvider<List<Project>>((ref) async {
  final service = ref.watch(projectServiceProvider);
  return await service.loadProjects();
});

/// Provider for the current project ID
/// Uses AsyncNotifier for reactive updates when selection changes
final currentProjectIdProvider = FutureProvider<String?>((ref) async {
  final service = ref.watch(projectServiceProvider);
  return await service.getCurrentProjectId();
});

/// Provider for the currently selected project object
final currentProjectProvider = FutureProvider<Project?>((ref) async {
  final service = ref.watch(projectServiceProvider);
  return await service.getCurrentProject();
});

/// Provider for measurements of a specific project
/// Family provider - takes projectId as parameter
final projectMeasurementsProvider = FutureProvider.family<List<Measurement>, String>(
  (ref, projectId) async {
    final service = ref.watch(projectServiceProvider);
    return await service.loadMeasurements(projectId);
  },
);

/// StateNotifier for managing project operations with reactive updates
class ProjectsNotifier extends StateNotifier<AsyncValue<List<Project>>> {
  final ProjectService _service;
  final Ref _ref;

  ProjectsNotifier(this._service, this._ref) : super(const AsyncValue.loading()) {
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    state = const AsyncValue.loading();
    try {
      final projects = await _service.loadProjects();
      state = AsyncValue.data(projects);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Create a new project and set it as current
  Future<Project?> createProject({
    required String name,
    required String ownerId,
    String filenamePrefix = 'PG',
  }) async {
    try {
      final project = await _service.createProject(
        name: name,
        ownerId: ownerId,
        filenamePrefix: filenamePrefix,
      );

      // Set as current project
      await _service.setCurrentProject(project.id);

      // Refresh providers
      await _loadProjects();
      _ref.invalidate(currentProjectIdProvider);
      _ref.invalidate(currentProjectProvider);

      return project;
    } catch (e) {
      print('Error creating project: $e');
      return null;
    }
  }

  /// Update a project
  Future<void> updateProject(Project project) async {
    try {
      await _service.updateProject(project);
      await _loadProjects();
      
      // If this is the current project, refresh current project provider
      final currentId = await _service.getCurrentProjectId();
      if (currentId == project.id) {
        _ref.invalidate(currentProjectProvider);
      }
    } catch (e) {
      print('Error updating project: $e');
      rethrow;
    }
  }

  /// Delete a project
  Future<void> deleteProject(String projectId) async {
    try {
      await _service.deleteProject(projectId);
      await _loadProjects();
      _ref.invalidate(currentProjectIdProvider);
      _ref.invalidate(currentProjectProvider);
    } catch (e) {
      print('Error deleting project: $e');
      rethrow;
    }
  }

  /// Set the current project
  Future<void> setCurrentProject(String? projectId) async {
    try {
      if (projectId == null) {
        await _service.clearCurrentProject();
      } else {
        await _service.setCurrentProject(projectId);
      }
      _ref.invalidate(currentProjectIdProvider);
      _ref.invalidate(currentProjectProvider);
    } catch (e) {
      print('Error setting current project: $e');
      rethrow;
    }
  }

  /// Refresh the projects list
  Future<void> refresh() async {
    await _loadProjects();
  }
}

/// Provider for the projects notifier (for operations)
final projectsNotifierProvider = StateNotifierProvider<ProjectsNotifier, AsyncValue<List<Project>>>(
  (ref) {
    final service = ref.watch(projectServiceProvider);
    return ProjectsNotifier(service, ref);
  },
);

/// Provider for the selected measurement ID (for viewing time series)
/// When a measurement file is selected in FilesPanel, this is updated
final selectedMeasurementIdProvider = StateProvider<String?>((ref) => null);

/// Provider for the selected measurement data (with all samples)
/// Automatically loads when selectedMeasurementIdProvider changes
final selectedMeasurementProvider = FutureProvider<Measurement?>((ref) async {
  final measurementId = ref.watch(selectedMeasurementIdProvider);
  
  if (measurementId == null) {
    return null;
  }
  
  final service = ref.watch(projectServiceProvider);
  return await service.getMeasurement(measurementId);
});
